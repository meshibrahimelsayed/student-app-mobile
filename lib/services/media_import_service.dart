import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

import '../models/content_item.dart';
import 'api_service.dart';
import 'chat_import_service.dart';
import 'study_store.dart';

class ImportResult {
  final int importedCount;
  final String message;
  const ImportResult(this.importedCount, this.message);
}

class MediaImportService {
  static Future<ImportResult> importChatFile({
    required PlatformFile file,
    required String groupName,
    required List<String> courseNames,
  }) async {
    final bytes = await _readBytes(file);
    if (bytes.length > 75 * 1024 * 1024) {
      throw const FormatException('حجم ملف المحادثة أكبر من الحد المسموح (75 ميجابايت).');
    }
    final decoded = _decodeChatText(bytes);
    final messages = ChatImportService.parseWhatsAppExport(
      text: decoded,
      groupName: groupName,
      courseNames: courseNames,
    );
    final inserted = await StudyStore.instance.insertContent(messages);
    return ImportResult(inserted, 'تم استيراد $inserted رسالة من ${messages.length} رسالة.');
  }

  static Future<ImportResult> importWhatsAppZip({
    required PlatformFile file,
    required String groupName,
    required List<String> courseNames,
  }) async {
    if (file.size > 75 * 1024 * 1024) {
      throw const FormatException('حجم ملف التصدير المضغوط أكبر من الحد المسموح (75 ميجابايت).');
    }
    final archive = ZipDecoder().decodeBytes(
      await _readBytes(file),
      maxOutputSize: 150 * 1024 * 1024,
      verify: true,
    );
    if (archive.length > 2000) throw const FormatException('ملف ZIP يحتوي على عناصر أكثر من الحد المسموح.');
    final entries = archive.where((entry) => entry.isFile).toList();
    ArchiveFile? chatEntry;
    for (final entry in entries) {
      if (p.extension(entry.name).toLowerCase() != '.txt') continue;
      chatEntry = entry;
      if (entry.name.toLowerCase().contains('chat') || entry.name.toLowerCase().contains('whatsapp')) break;
    }
    if (chatEntry == null) throw const FormatException('لم أجد ملف محادثة TXT داخل ملف ZIP.');
    final messages = ChatImportService.parseWhatsAppExport(
      text: _decodeChatText(chatEntry.content as List<int>),
      groupName: groupName,
      courseNames: courseNames,
    );
    var imported = await StudyStore.instance.insertContent(messages);
    for (final entry in entries) {
      final extension = p.extension(entry.name).toLowerCase();
      if (!_supportedExtensions.contains(extension)) continue;
      final name = entry.name.replaceAll('\\', '/').split('/').last;
      final result = await _importAttachmentBytes(
        fileName: name,
        bytes: entry.content as List<int>,
        groupName: groupName,
        courseNames: courseNames,
      );
      imported += result.importedCount;
    }
    return ImportResult(imported, 'تم استيراد ${messages.length} رسالة وملفات المحادثة.');
  }

  static Future<ImportResult> importAttachment({
    required PlatformFile file,
    required String groupName,
    required List<String> courseNames,
  }) async {
    if (file.size > 150 * 1024 * 1024) {
      throw const FormatException('حجم الملف أكبر من الحد المسموح (150 ميجابايت).');
    }
    final bytes = await _readBytes(file);
    return _importAttachmentBytes(
      fileName: file.name,
      bytes: bytes,
      groupName: groupName,
      courseNames: courseNames,
    );
  }

  static Future<ImportResult> _importAttachmentBytes({
    required String fileName,
    required List<int> bytes,
    required String groupName,
    required List<String> courseNames,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final mediaDirectory = Directory(p.join(directory.path, 'study_media'));
    await mediaDirectory.create(recursive: true);
    final cleanName = fileName.replaceAll('\\', '/').split('/').last;
    final extension = p.extension(cleanName).toLowerCase();
    final safeName = p.basenameWithoutExtension(cleanName).replaceAll(RegExp(r'[^\w\-\u0600-\u06FF]+'), '_');
    final storedPath = p.join(mediaDirectory.path, '${DateTime.now().microsecondsSinceEpoch}_$safeName$extension');
    final storedFile = await File(storedPath).writeAsBytes(bytes, flush: true);

    String? extracted;
    String processingStatus;
    if (extension == '.pdf') {
      try {
        extracted = (await getPDFtext(storedFile.path)).trim();
        processingStatus = extracted.isEmpty
            ? 'اتحفظ الملف. الـ PDF صورة ممسوحة؛ استخدم OCR للصور أو أعد استيراد نسخة قابلة للبحث.'
            : 'تم استخراج نص PDF على الجهاز.';
      } catch (_) {
        processingStatus = 'اتحفظ الملف، لكن تعذّر استخراج النص منه.';
      }
    } else if (_imageExtensions.contains(extension)) {
      try {
        extracted = (await TesseractOcr.extractText(
          storedFile.path,
          config: OCRConfig(language: 'ara+eng', engine: OCREngine.tesseract),
        )).trim();
        processingStatus = extracted.isEmpty ? 'لم يظهر نص واضح في الصورة.' : 'تم استخراج النص عربيًا وإنجليزيًا على الجهاز.';
      } catch (_) {
        processingStatus = 'اتحفظت الصورة، لكن OCR لم يكتمل.';
      }
    } else if (_audioExtensions.contains(extension)) {
      if (ApiService.hasConfiguredBackend && !ApiService.demoMode) {
        extracted = await ApiService.transcribeAudio(storedFile.path);
      }
      processingStatus = extracted == null
          ? 'اتحفظ الملف. التفريغ الصوتي يحتاج إعداد Backend متوافق.'
          : 'تم تفريغ الصوت عبر Backend الذي أعددته.';
    } else {
      processingStatus = 'اتحفظ الملف محليًا. لا يوجد مستخرج نص لهذا النوع بعد.';
    }

    final searchableText = extracted == null || extracted.isEmpty
        ? cleanName
        : '$cleanName\n$extracted';
    final inferredCourse = ChatImportService.inferCourse(searchableText, courseNames);
    final record = ContentItem(
      groupName: groupName,
      sender: 'ملف مرفق',
      sentAt: DateTime.now(),
      text: cleanName,
      courseName: inferredCourse,
      category: _audioExtensions.contains(extension) || _imageExtensions.contains(extension) || extension == '.pdf'
          ? ContentCategory.material
          : ChatImportService.inferCategory(cleanName),
      mediaPath: storedFile.path,
      extractedText: extracted,
    );
    await StudyStore.instance.saveMediaRecord(record);
    return ImportResult(1, processingStatus);
  }

  static Future<List<int>> _readBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    if (file.path != null) return File(file.path!).readAsBytes();
    throw const FileSystemException('تعذّر قراءة الملف المختار.');
  }

  static String _decodeChatText(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      final body = bytes.sublist(2, bytes.length - (bytes.length.isOdd ? 1 : 0));
      return String.fromCharCodes(List.generate(body.length ~/ 2, (i) => body[i * 2] | (body[i * 2 + 1] << 8))).replaceFirst('\uFEFF', '');
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final body = bytes.sublist(2, bytes.length - (bytes.length.isOdd ? 1 : 0));
      return String.fromCharCodes(List.generate(body.length ~/ 2, (i) => (body[i * 2] << 8) | body[i * 2 + 1])).replaceFirst('\uFEFF', '');
    }
    return utf8.decode(bytes, allowMalformed: true).replaceFirst('\uFEFF', '');
  }

  static const Set<String> _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};
  static const Set<String> _audioExtensions = {'.mp3', '.m4a', '.aac', '.wav', '.ogg', '.opus', '.amr'};
  static const Set<String> _supportedExtensions = {
    ..._imageExtensions,
    ..._audioExtensions,
    '.pdf', '.mp4', '.ppt', '.pptx', '.doc', '.docx',
  };
}
