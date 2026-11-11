import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class ChatExportService {
  static Future<File> writeChatFile(List<StudyChatMessage> messages) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/study_chat_${DateTime.now().millisecondsSinceEpoch}.txt');
    final buffer = StringBuffer('محادثة رفيق المذاكرة\n\n');
    for (final message in messages) {
      final sender = message.sender == 'user' ? 'الطالب' : 'رفيق المذاكرة';
      buffer.writeln('[$sender - ${message.timestamp.toLocal()}]');
      buffer.writeln(message.text);
      buffer.writeln();
    }
    return file..writeAsStringSync(buffer.toString());
  }

  static Future<void> export(List<StudyChatMessage> messages) async {
    if (messages.isEmpty) return;
    final file = await writeChatFile(messages);
    await Share.shareXFiles([XFile(file.path)], text: 'محادثة رفيق المذاكرة');
  }
}
