import '../models/content_item.dart';
import 'study_store.dart';

class StudyDigest {
  final int itemCount;
  final Map<String, int> categories;
  final List<String> highlights;
  const StudyDigest(this.itemCount, this.categories, this.highlights);
}

class StudyDigestService {
  static Future<StudyDigest> daily({DateTime? date}) async {
    final selected = date ?? DateTime.now();
    final start = DateTime(selected.year, selected.month, selected.day);
    return _digest(start, start.add(const Duration(days: 1)));
  }

  static Future<StudyDigest> weekly({DateTime? date}) async {
    final selected = date ?? DateTime.now();
    final end = DateTime(selected.year, selected.month, selected.day).add(const Duration(days: 1));
    return _digest(end.subtract(const Duration(days: 7)), end);
  }

  static Future<StudyDigest> _digest(DateTime start, DateTime end) async {
    final records = await StudyStore.instance.contentBetween(start, end);
    final counts = <String, int>{};
    for (final record in records) {
      counts.update(record.category.label, (count) => count + 1, ifAbsent: () => 1);
    }

    final byCourse = <String, List<ContentItem>>{};
    for (final record in records) {
      final course = record.courseName.isEmpty ? 'غير مصنفة' : record.courseName;
      byCourse.putIfAbsent(course, () => []).add(record);
    }
    final highlights = <String>[];
    for (final entry in byCourse.entries.take(4)) {
      final primary = entry.value.firstWhere(
        (item) => item.category == ContentCategory.lecture || item.category == ContentCategory.section,
        orElse: () => entry.value.first,
      );
      final snippet = primary.extractedText?.trim().isNotEmpty == true
          ? primary.extractedText!.trim()
          : primary.text.trim();
      highlights.add('${entry.key}: ${_truncate(snippet, 115)}');
    }
    return StudyDigest(records.length, counts, highlights);
  }

  static String _truncate(String value, int maxLength) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength).trimRight()}…';
  }
}
