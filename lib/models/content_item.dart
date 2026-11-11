enum ContentCategory {
  lecture,
  section,
  assignment,
  exam,
  announcement,
  material,
  other,
}

extension ContentCategoryLabel on ContentCategory {
  String get label => switch (this) {
        ContentCategory.lecture => 'محاضرة',
        ContentCategory.section => 'سكشن',
        ContentCategory.assignment => 'واجب',
        ContentCategory.exam => 'امتحان',
        ContentCategory.announcement => 'إعلان',
        ContentCategory.material => 'ملف',
        ContentCategory.other => 'أخرى',
      };

  String get englishLabel => switch (this) {
        ContentCategory.lecture => 'Lecture',
        ContentCategory.section => 'Section',
        ContentCategory.assignment => 'Assignment',
        ContentCategory.exam => 'Exam',
        ContentCategory.announcement => 'Announcement',
        ContentCategory.material => 'File',
        ContentCategory.other => 'Other',
      };

  static ContentCategory fromStorage(String? value) {
    for (final category in ContentCategory.values) {
      if (category.name == value) return category;
    }
    return ContentCategory.other;
  }
}

class ContentItem {
  final int? id;
  final String groupName;
  final String sender;
  final DateTime sentAt;
  final String text;
  final String courseName;
  final ContentCategory category;
  final String? mediaPath;
  final String? extractedText;

  const ContentItem({
    this.id,
    required this.groupName,
    required this.sender,
    required this.sentAt,
    required this.text,
    this.courseName = '',
    this.category = ContentCategory.other,
    this.mediaPath,
    this.extractedText,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'group_name': groupName,
        'sender': sender,
        'sent_at': sentAt.toIso8601String(),
        'message_text': text,
        'course_name': courseName,
        'category': category.name,
        'media_path': mediaPath,
        'extracted_text': extractedText,
      };

  factory ContentItem.fromMap(Map<String, Object?> row) => ContentItem(
        id: row['id'] as int?,
        groupName: row['group_name'] as String? ?? '',
        sender: row['sender'] as String? ?? '',
        sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ?? DateTime.now(),
        text: row['message_text'] as String? ?? '',
        courseName: row['course_name'] as String? ?? '',
        category: ContentCategoryLabel.fromStorage(row['category'] as String?),
        mediaPath: row['media_path'] as String?,
        extractedText: row['extracted_text'] as String?,
      );
}
