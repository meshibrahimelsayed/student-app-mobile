import '../models/models.dart';

/// Local preview content so the app can be explored before a backend exists.
class DemoData {
  static final List<ScheduleItem> schedule = [
    ScheduleItem(id: 's1', subjectName: 'قواعد البيانات', type: 'LECTURE', time: '09:00 ص', location: 'قاعة 204', doctor: 'د. أحمد محمود'),
    ScheduleItem(id: 's2', subjectName: 'الذكاء الاصطناعي', type: 'LECTURE', time: '11:00 ص', location: 'مدرج الحاسبات', doctor: 'د. منى إبراهيم'),
    ScheduleItem(id: 's3', subjectName: 'شبكات الحاسب', type: 'SECTION', time: '01:00 م', location: 'معمل 3', doctor: 'م. كريم حسن'),
  ];

  static final List<AssignmentItem> assignments = [
    AssignmentItem(id: 'a1', title: 'تطبيع جداول قاعدة البيانات', subjectName: 'قواعد البيانات', deadline: '2026-11-14', description: 'حل أسئلة 1NF و2NF من المحاضرة الرابعة'),
    AssignmentItem(id: 'a2', title: 'ملخص خوارزميات البحث', subjectName: 'الذكاء الاصطناعي', deadline: '2026-11-16', description: 'مقارنة BFS وDFS وA*', isCompleted: true),
    AssignmentItem(id: 'a3', title: 'حل ورقة subnetting', subjectName: 'شبكات الحاسب', deadline: '2026-11-18', description: 'الورقة المرفقة في جروب السكشن'),
  ];

  static final List<SubjectCourse> courses = [
    SubjectCourse(id: 'c1', name: 'قواعد البيانات', code: 'DB', doctor: 'د. أحمد محمود', lectureCount: 8, materialsCount: 12, pendingSheets: 2, completedLectures: 8, totalLectures: 12),
    SubjectCourse(id: 'c2', name: 'الذكاء الاصطناعي', code: 'AI', doctor: 'د. منى إبراهيم', lectureCount: 6, materialsCount: 9, pendingSheets: 1, completedLectures: 6, totalLectures: 10),
    SubjectCourse(id: 'c3', name: 'شبكات الحاسب', code: 'NET', doctor: 'د. خالد سمير', lectureCount: 5, materialsCount: 7, pendingSheets: 1, completedLectures: 5, totalLectures: 8),
    SubjectCourse(id: 'c4', name: 'هندسة البرمجيات', code: 'SE', doctor: 'د. سارة علي', lectureCount: 4, materialsCount: 6, pendingSheets: 0, completedLectures: 4, totalLectures: 10),
  ];

  static final List<AlertItem> alerts = [
    AlertItem(id: 'n1', type: 'ملخص محاضرة', body: 'محاضرة قواعد البيانات: شرحنا التطبيع حتى 3NF، مع مثال عملي على تقسيم جدول الطلبات. الملف المرفق: DB_Lecture_04.pdf', source: 'جروب قواعد البيانات · ملف PDF', createdAt: DateTime(2026, 11, 11, 9, 45)),
    AlertItem(id: 'n2', type: 'ميديا جديدة', body: 'تم رصد صورة سبورة من محاضرة الذكاء الاصطناعي. تتضمن مقارنة بين خوارزميات البحث غير الموجّه.', source: 'جروب AI · صورة', createdAt: DateTime(2026, 11, 11, 11, 20)),
    AlertItem(id: 'n3', type: 'تقدم المنهج', body: 'شبكات الحاسب: تم شرح 5 من 8 محاضرات. آخر موضوع: IPv4 وSubnetting.', source: 'متابعة المحاضرات', createdAt: DateTime(2026, 11, 10, 14, 10)),
    AlertItem(id: 'n4', type: 'موعد تسليم', body: 'ورقة subnetting مطلوبة قبل 18 نوفمبر. استخرج التطبيق الموعد من رسالة في جروب السكشن.', source: 'جروب شبكات الحاسب', createdAt: DateTime(2026, 11, 10, 12, 30)),
  ];
}
