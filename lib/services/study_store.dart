import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/content_item.dart';
import '../models/models.dart';
import 'demo_data.dart';

class StudyGroup {
  final String name;
  final bool isTracked;
  final int contentCount;
  const StudyGroup(this.name, this.isTracked, this.contentCount);
}

class CourseProgress {
  final String name;
  final int lecturesCompleted;
  final int totalLectures;
  const CourseProgress(this.name, this.lecturesCompleted, this.totalLectures);

  bool get isComplete => totalLectures > 0 && lecturesCompleted >= totalLectures;
  double get fraction => totalLectures == 0
      ? 0
      : (lecturesCompleted / totalLectures).clamp(0.0, 1.0).toDouble();
}

class StudyStore {
  StudyStore._();
  static final StudyStore instance = StudyStore._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getApplicationSupportDirectory();
    final db = await openDatabase(
      p.join(directory.path, 'study_companion.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE content (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_name TEXT NOT NULL,
            sender TEXT NOT NULL DEFAULT '',
            sent_at TEXT NOT NULL,
            message_text TEXT NOT NULL,
            course_name TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT 'other',
            media_path TEXT,
            extracted_text TEXT,
            UNIQUE(group_name, sender, sent_at, message_text)
          )
        ''');
        await db.execute('CREATE INDEX content_sent_at ON content(sent_at DESC)');
        await db.execute('CREATE INDEX content_course_category ON content(course_name, category)');
        await db.execute('''
          CREATE TABLE study_groups (
            name TEXT PRIMARY KEY,
            is_tracked INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE courses (
            name TEXT PRIMARY KEY,
            total_lectures INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
    _database = db;
    await _seedCourses(db);
    return db;
  }

  Future<void> _seedCourses(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM courses')) ?? 0;
    if (count != 0) return;
    final batch = db.batch();
    for (final course in DemoData.courses) {
      batch.insert('courses', {
        'name': course.name,
        'total_lectures': course.totalLectures,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getCourseNames() async {
    final db = await database;
    final rows = await db.query('courses', columns: ['name'], where: 'is_active = 1', orderBy: 'name');
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<void> saveCourse(String name, {int totalLectures = 0}) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final db = await database;
    await db.insert('courses', {
      'name': clean,
      'total_lectures': totalLectures,
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCourse(String name) async {
    final db = await database;
    await db.update('courses', {'is_active': 0}, where: 'name = ?', whereArgs: [name]);
  }

  Future<void> updateCourseTotal(String name, int totalLectures) async {
    final db = await database;
    await db.update('courses', {'total_lectures': totalLectures}, where: 'name = ?', whereArgs: [name]);
  }

  Future<int> insertContent(List<ContentItem> items) async {
    if (items.isEmpty) return 0;
    final db = await database;
    var inserted = 0;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        batch.insert('content', item.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
        batch.insert('study_groups', {'name': item.groupName}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final results = await batch.commit(noResult: false);
      for (var i = 0; i < results.length; i += 2) {
        if ((results[i] as int?) != null && (results[i] as int) > 0) inserted++;
      }
    });
    return inserted;
  }

  Future<void> saveMediaRecord(ContentItem item) async {
    final db = await database;
    await db.insert('content', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('study_groups', {'name': item.groupName}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<ContentItem>> searchContent({
    String query = '',
    ContentCategory? category,
    String? courseName,
    int limit = 300,
  }) async {
    final db = await database;
    final clauses = <String>['COALESCE(g.is_tracked, 1) = 1'];
    final args = <Object?>[];
    if (query.trim().isNotEmpty) {
      clauses.add('(c.message_text LIKE ? OR c.extracted_text LIKE ? OR c.group_name LIKE ? OR c.course_name LIKE ?)');
      final term = '%${query.trim()}%';
      args.addAll([term, term, term, term]);
    }
    if (category != null) {
      clauses.add('c.category = ?');
      args.add(category.name);
    }
    if (courseName != null && courseName.isNotEmpty) {
      clauses.add('c.course_name = ?');
      args.add(courseName);
    }
    final rows = await db.rawQuery('''
      SELECT c.* FROM content c
      LEFT JOIN study_groups g ON g.name = c.group_name
      WHERE ${clauses.join(' AND ')}
      ORDER BY c.sent_at DESC
      LIMIT ?
    ''', [...args, limit]);
    return rows.map(ContentItem.fromMap).toList();
  }

  Future<List<ContentItem>> contentBetween(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.* FROM content c
      LEFT JOIN study_groups g ON g.name = c.group_name
      WHERE c.sent_at >= ? AND c.sent_at < ? AND COALESCE(g.is_tracked, 1) = 1
      ORDER BY c.sent_at DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return rows.map(ContentItem.fromMap).toList();
  }

  Future<void> updateClassification(int id, {required String courseName, required ContentCategory category}) async {
    final db = await database;
    await db.update('content', {'course_name': courseName, 'category': category.name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateExtractedText(int id, String extractedText) async {
    final db = await database;
    await db.update('content', {'extracted_text': extractedText}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StudyGroup>> getGroups() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT g.name, g.is_tracked, COUNT(c.id) AS item_count
      FROM study_groups g LEFT JOIN content c ON c.group_name = g.name
      GROUP BY g.name ORDER BY g.name
    ''');
    return rows.map((row) => StudyGroup(
      row['name'] as String,
      (row['is_tracked'] as int? ?? 1) == 1,
      row['item_count'] as int? ?? 0,
    )).toList();
  }

  Future<void> setGroupTracked(String name, bool tracked) async {
    final db = await database;
    await db.update('study_groups', {'is_tracked': tracked ? 1 : 0}, where: 'name = ?', whereArgs: [name]);
  }

  Future<List<CourseProgress>> getCourseProgress() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.name, s.total_lectures, COALESCE(progress.done, 0) AS done
      FROM courses s
      LEFT JOIN (
        SELECT c.course_name, COUNT(DISTINCT substr(c.sent_at, 1, 10)) AS done
        FROM content c
        INNER JOIN study_groups g ON g.name = c.group_name AND g.is_tracked = 1
        WHERE c.category IN ('lecture','section')
        GROUP BY c.course_name
      ) progress ON progress.course_name = s.name
      WHERE s.is_active = 1
      ORDER BY s.name
    ''');
    return rows.map((row) => CourseProgress(
      row['name'] as String,
      row['done'] as int? ?? 0,
      row['total_lectures'] as int? ?? 0,
    )).toList();
  }

  Future<int> contentCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM content')) ?? 0;
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    final rows = await db.query('settings', columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
