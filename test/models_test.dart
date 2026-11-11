import 'package:flutter_test/flutter_test.dart';
import 'package:student_study_copilot/models/models.dart';

void main() {
  group('API models', () {
    test('parses an assignment and its completion status', () {
      final item = AssignmentItem.fromJson({
        'id': 'a-1',
        'title': 'Assignment',
        'subjectName': 'Databases',
        'deadline': '2026-11-20',
        'description': 'Build a schema',
        'status': 'DONE',
      });

      expect(item.id, 'a-1');
      expect(item.isCompleted, isTrue);
      expect(item.subjectName, 'Databases');
    });

    test('uses safe defaults for incomplete course payloads', () {
      final course = SubjectCourse.fromJson({'id': 'c-1', 'name': 'AI'});

      expect(course.name, 'AI');
      expect(course.code, isEmpty);
      expect(course.materialsCount, 0);
      expect(course.lectureCount, 0);
    });

    test('parses alert message aliases', () {
      final alert = AlertItem.fromJson({
        'id': 'alert-1',
        'type': 'Notice',
        'message': 'The lecture moved online',
        'source': 'University portal',
      });

      expect(alert.body, 'The lecture moved online');
      expect(alert.source, 'University portal');
    });
  });
}
