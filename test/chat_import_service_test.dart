import 'package:flutter_test/flutter_test.dart';
import 'package:student_study_copilot/models/content_item.dart';
import 'package:student_study_copilot/services/chat_import_service.dart';

void main() {
  group('WhatsApp export parser', () {
    test('parses Android timestamps, categories, and continued lines', () {
      final items = ChatImportService.parseWhatsAppExport(
        groupName: 'DB 204',
        courseNames: const ['قواعد البيانات'],
        text: '''11/11/26, 09:12 - Ahmed: محاضرة قواعد البيانات: شرحنا التطبيع.
تكملة الرسالة هنا.
11/11/26, 01:30 PM - Mona: تسليم واجب SQL يوم الخميس''',
      );

      expect(items, hasLength(2));
      expect(items.first.sender, 'Ahmed');
      expect(items.first.text, contains('تكملة الرسالة هنا.'));
      expect(items.first.courseName, 'قواعد البيانات');
      expect(items.first.category, ContentCategory.lecture);
      expect(items.last.sentAt.hour, 13);
      expect(items.last.category, ContentCategory.assignment);
    });

    test('parses iOS brackets and Arabic numerals', () {
      final items = ChatImportService.parseWhatsAppExport(
        groupName: 'شبكات',
        courseNames: const ['شبكات الحاسب'],
        text: '[١١/١١/٢٠٢٦، ٩:١٤ م] Salma: إعلان: تم تغيير موعد السكشن',
      );

      expect(items, hasLength(1));
      expect(items.single.sentAt.year, 2026);
      expect(items.single.sentAt.hour, 21);
      expect(items.single.category, ContentCategory.announcement);
    });

    test('infers common courses and media categories', () {
      expect(ChatImportService.inferCourse('Network subnetting sheet', const []), 'شبكات الحاسب');
      expect(ChatImportService.inferCategory('DB_Lecture_04.pdf'), ContentCategory.material);
      expect(ChatImportService.inferCategory('موعد الامتحان النهائي'), ContentCategory.exam);
    });
  });
}
