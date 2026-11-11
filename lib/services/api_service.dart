import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'demo_data.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
  static String? lastError;
  static final Map<String, bool> _demoCompletion = {};

  static Future<List<ScheduleItem>> getTodaySchedule() async {
    if (demoMode) return List.of(DemoData.schedule);
    final data = await _getObject('/api/schedule');
    final items = data?['today'];
    if (items is List) return items.whereType<Map>().map((e) => ScheduleItem.fromJson(Map<String, dynamic>.from(e))).toList();
    return [];
  }

  static Future<List<AssignmentItem>> getAssignments() async {
    if (demoMode) {
      return DemoData.assignments.map((item) => AssignmentItem(
        id: item.id, title: item.title, subjectName: item.subjectName,
        deadline: item.deadline, description: item.description,
        isCompleted: _demoCompletion[item.id] ?? item.isCompleted,
      )).toList();
    }
    final data = await _getObject('/api/assignments');
    final items = data?['assignments'];
    if (items is List) return items.whereType<Map>().map((e) => AssignmentItem.fromJson(Map<String, dynamic>.from(e))).toList();
    return [];
  }

  static Future<List<SubjectCourse>> getCourses() async {
    if (demoMode) return List.of(DemoData.courses);
    final data = await _getObject('/api/courses');
    final items = data?['courses'];
    if (items is List) return items.whereType<Map>().map((e) => SubjectCourse.fromJson(Map<String, dynamic>.from(e))).toList();
    return [];
  }

  static Future<List<AlertItem>> getAlerts() async {
    if (demoMode) return List.of(DemoData.alerts);
    final data = await _getObject('/api/alerts');
    final items = data?['alerts'];
    if (items is List) return items.whereType<Map>().map((e) => AlertItem.fromJson(Map<String, dynamic>.from(e))).toList();
    return [];
  }

  static Future<bool> toggleAssignment(String id, bool isDone) async {
    if (demoMode) {
      _demoCompletion[id] = isDone;
      return true;
    }
    try {
      final response = await http.patch(Uri.parse('$baseUrl/api/assignments/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'status': isDone ? 'DONE' : 'PENDING'})).timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  static Future<String> chatWithStudyBuddy(String query, String subject) async {
    if (demoMode) {
      final course = subject == 'عام' ? 'قواعد البيانات' : subject;
      return 'ملخص $course من محتوى جروباتك التجريبي:\n\n• آخر ما تم شرحه: التطبيع حتى 3NF.\n• أهم نقطة: كل عمود غير مفتاح يعتمد على المفتاح الأساسي فقط.\n• الملفات المرتبطة: DB_Lecture_04.pdf وصورة السبورة.\n• تقدّم المنهج: 8 من 12 محاضرة.\n\nاسألني عن أي نقطة أو اطلب أسئلة مراجعة.';
    }
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/study-buddy/chat'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'query': query, 'subjectName': subject})).timeout(const Duration(seconds: 15));
      final data = _decodeObject(response);
      final reply = data?['reply'];
      if (reply is String && reply.trim().isNotEmpty) return reply;
    } catch (error) {
      lastError = error.toString();
    }
    return 'تعذر الوصول إلى رفيق المذاكرة حاليًا. تحقق من اتصال الخادم وحاول مرة أخرى.';
  }

  /// Backend contract for WhatsApp Cloud API. Credentials stay on the server.
  static Future<Map<String, dynamic>?> getWhatsAppStatus() => _getObject('/api/integrations/whatsapp/status');

  static Future<bool> sendWhatsAppMessage({required String to, required String text}) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/integrations/whatsapp/messages'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'to': to, 'text': text})).timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  static Future<Map<String, dynamic>?> _getObject(String path) async {
    lastError = null;
    try {
      final response = await http.get(Uri.parse('$baseUrl$path')).timeout(const Duration(seconds: 6));
      final data = _decodeObject(response);
      if (data != null) return data;
      lastError = 'HTTP ${response.statusCode}';
    } catch (error) {
      lastError = error.toString();
    }
    return null;
  }

  static Map<String, dynamic>? _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }
}
