import '../models/content_item.dart';

class ChatImportService {
  static final RegExp _messageStart = RegExp(
    r'^\[?(\d{1,2})[/.](\d{1,2})[/.](\d{2,4})[,،]?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM|ص|م)?\]?(?:\s*-\s*|\s+)(.*)$',
    caseSensitive: false,
  );

  static List<ContentItem> parseWhatsAppExport({
    required String text,
    required String groupName,
    required List<String> courseNames,
  }) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final messages = <ContentItem>[];
    DateTime? timestamp;
    String sender = '';
    final body = StringBuffer();

    void flush() {
      if (timestamp == null || body.isEmpty) return;
      final content = body.toString().trim();
      if (content.isNotEmpty) {
        final course = inferCourse(content, courseNames);
        messages.add(ContentItem(
          groupName: groupName.trim(),
          sender: sender,
          sentAt: timestamp!,
          text: content,
          courseName: course,
          category: inferCategory(content),
        ));
      }
      body.clear();
    }

    for (final rawLine in lines) {
      final line = _normalizeDigits(rawLine).replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e]'), '').trimRight();
      final match = _messageStart.firstMatch(line);
      if (match == null) {
        if (timestamp != null && line.trim().isNotEmpty) body.writeln(line.trim());
        continue;
      }

      flush();
      timestamp = _parseTimestamp(match);
      var payload = match.group(8)?.trimLeft() ?? '';
      if (payload.startsWith('-')) payload = payload.substring(1).trimLeft();
      final senderBoundary = payload.indexOf(':');
      if (senderBoundary > 0 && senderBoundary < 80) {
        sender = payload.substring(0, senderBoundary).trim();
        body.write(payload.substring(senderBoundary + 1).trimLeft());
      } else {
        sender = '';
        body.write(payload);
      }
    }
    flush();
    return messages;
  }

  static ContentCategory inferCategory(String text) {
    final value = text.toLowerCase();
    if (_hasAny(value, ['امتحان', 'فاينل', 'midterm', 'final exam', 'quiz', 'كويز'])) return ContentCategory.exam;
    if (_hasAny(value, ['واجب', 'تكليف', 'assignment', 'homework', 'due date', 'تسليم'])) return ContentCategory.assignment;
    if (_hasAny(value, ['سكشن', 'section', 'معمل', 'lab'])) return ContentCategory.section;
    if (_hasAny(value, ['محاضرة', 'lecture', 'شرحنا', 'تم شرح', 'شرح اليوم'])) return ContentCategory.lecture;
    if (_hasAny(value, ['إعلان', 'اعلان', 'تنويه', 'مهم', 'notice', 'announcement', 'تأجيل', 'تغيير'])) return ContentCategory.announcement;
    if (_hasAny(value, ['.pdf', '.ppt', '.pptx', '.doc', '.docx', 'مرفق', 'ملف'])) return ContentCategory.material;
    return ContentCategory.other;
  }

  static String inferCourse(String text, List<String> courseNames) {
    final normalized = text.toLowerCase();
    for (final course in courseNames) {
      final name = course.trim();
      if (name.isEmpty) continue;
      if (normalized.contains(name.toLowerCase())) return name;
    }
    const aliases = <String, List<String>>{
      'قواعد البيانات': ['database', 'databases', 'sql', 'dbms', 'تطبيع'],
      'الذكاء الاصطناعي': ['artificial intelligence', ' ai ', 'خوارزميات البحث'],
      'شبكات الحاسب': ['network', 'networks', 'شبكات', 'subnetting', 'osi'],
      'هندسة البرمجيات': ['software engineering', 'uml', 'هندسة البرمجيات'],
    };
    for (final entry in aliases.entries) {
      if (_hasAny(normalized, entry.value)) return entry.key;
    }
    return '';
  }

  static bool _hasAny(String value, List<String> needles) =>
      needles.any(value.contains);

  static DateTime? _parseTimestamp(RegExpMatch match) {
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '');
    var hour = int.tryParse(match.group(4) ?? '');
    final minute = int.tryParse(match.group(5) ?? '');
    final second = int.tryParse(match.group(6) ?? '0');
    final meridiem = (match.group(7) ?? '').toUpperCase();
    if (day == null || month == null || year == null || hour == null || minute == null ||
        minute < 0 || minute > 59 || (second ?? 0) > 59) return null;
    if (meridiem.isNotEmpty && (hour < 1 || hour > 12)) return null;
    if (meridiem.isEmpty && (hour < 0 || hour > 23)) return null;
    if (year < 100) year += 2000;
    if (meridiem == 'PM' || meridiem == 'م') {
      if (hour < 12) hour += 12;
    } else if (meridiem == 'AM' || meridiem == 'ص') {
      if (hour == 12) hour = 0;
    }
    try {
      final result = DateTime(year, month, day, hour, minute, second ?? 0);
      if (result.year != year || result.month != month || result.day != day) return null;
      return result;
    } on ArgumentError {
      return null;
    }
  }

  static String _normalizeDigits(String value) {
    final output = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        output.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        output.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        output.writeCharCode(rune);
      }
    }
    return output.toString();
  }
}
