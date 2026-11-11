String _stringValue(dynamic value, [String fallback = '']) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

int _intValue(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

class ScheduleItem {
  final String id;
  final String subjectName;
  final String type;
  final String time;
  final String location;
  final String doctor;

  ScheduleItem({required this.id, required this.subjectName, required this.type, required this.time, required this.location, required this.doctor});

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    id: _stringValue(json['id']),
    subjectName: _stringValue(json['subjectName'], 'مادة دراسية'),
    type: _stringValue(json['type'], 'LECTURE'),
    time: _stringValue(json['time']),
    location: _stringValue(json['location'], 'مدرج الكلية'),
    doctor: _stringValue(json['doctor']),
  );
}

class AssignmentItem {
  final String id;
  final String title;
  final String subjectName;
  final String deadline;
  final String description;
  bool isCompleted;

  AssignmentItem({required this.id, required this.title, required this.subjectName, required this.deadline, required this.description, this.isCompleted = false});

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    final status = _stringValue(json['status']).toUpperCase();
    return AssignmentItem(
      id: _stringValue(json['id']),
      title: _stringValue(json['title'], 'تكليف جديد'),
      subjectName: _stringValue(json['subjectName'], 'عام'),
      deadline: _stringValue(json['deadline'], 'غير محدد'),
      description: _stringValue(json['description']),
      isCompleted: status == 'DONE' || json['isCompleted'] == true,
    );
  }
}

class SubjectCourse {
  final String id;
  final String name;
  final String code;
  final String doctor;
  final int materialsCount;
  final int lectureCount;
  final int pendingSheets;
  final int completedLectures;
  final int totalLectures;

  SubjectCourse({required this.id, required this.name, required this.code, required this.doctor, this.materialsCount = 0, this.lectureCount = 0, this.pendingSheets = 0, this.completedLectures = 0, this.totalLectures = 0});

  factory SubjectCourse.fromJson(Map<String, dynamic> json) => SubjectCourse(
    id: _stringValue(json['id']),
    name: _stringValue(json['name'], 'مادة دراسية'),
    code: _stringValue(json['code']),
    doctor: _stringValue(json['doctor']),
    materialsCount: _intValue(json['materialsCount']),
    lectureCount: _intValue(json['lectureCount']),
    pendingSheets: _intValue(json['pendingSheets']),
    completedLectures: _intValue(json['completedLectures']),
    totalLectures: _intValue(json['totalLectures']),
  );
}

class AlertItem {
  final String id;
  final String type;
  final String body;
  final String source;
  final DateTime? createdAt;

  AlertItem({required this.id, required this.type, required this.body, required this.source, this.createdAt});

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
    id: _stringValue(json['id']),
    type: _stringValue(json['type'], 'إعلان'),
    body: _stringValue(json['body'], _stringValue(json['message'])),
    source: _stringValue(json['source'], 'مصدر غير محدد'),
    createdAt: DateTime.tryParse(_stringValue(json['createdAt'])),
  );
}

class StudyChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;

  StudyChatMessage({required this.sender, required this.text, required this.timestamp});
}
