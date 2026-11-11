import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CoursesScreen extends StatefulWidget {
  final ValueChanged<String> onOpenStudyCourse;
  const CoursesScreen({super.key, required this.onOpenStudyCourse});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<List<SubjectCourse>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = ApiService.getCourses();
  }

  Future<void> _reload() async {
    setState(() => _coursesFuture = ApiService.getCourses());
    await _coursesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.accentGold,
          backgroundColor: AppTheme.surfaceCard,
          onRefresh: _reload,
          child: FutureBuilder<List<SubjectCourse>>(
            future: _coursesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return _loading();
              if (snapshot.hasError || ApiService.lastError != null) return _state('تعذر تحميل المواد', 'تحقق من اتصال الخادم ثم اسحب الشاشة للمحاولة مرة أخرى', Icons.cloud_off_rounded, _reload);
              final courses = snapshot.data ?? const <SubjectCourse>[];
              if (courses.isEmpty) return _state('لا توجد مواد بعد', 'ستظهر موادك هنا بعد مزامنة حسابك مع نظام الجامعة', Icons.menu_book_outlined, _reload);
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _header(courses.length)),
                  SliverList(delegate: SliverChildBuilderDelegate((_, i) => Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: _courseCard(courses[i], i)), childCount: courses.length)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('المقررات الدراسية', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      const SizedBox(height: 4),
      Text('$count مواد مرتبطة بحسابك', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]),
  );

  Widget _courseCard(SubjectCourse course, int index) {
    final colors = [AppTheme.accentWarm, AppTheme.accentGold, AppTheme.accentSage, AppTheme.accentCobalt];
    final color = colors[index % colors.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderSubtle)),
      child: Row(children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(15)), child: Center(child: Text(course.code.isEmpty ? '—' : course.code, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 11)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
          if (course.doctor.isNotEmpty) Text(course.doctor, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          if (course.totalLectures > 0) ...[
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (course.completedLectures / course.totalLectures).clamp(0.0, 1.0).toDouble(),
                  minHeight: 5,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )),
              const SizedBox(width: 8),
              Text('${course.completedLectures}/${course.totalLectures} محاضرات', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ]),
          ],
          const SizedBox(height: 7),
          Wrap(spacing: 6, children: [if (course.lectureCount > 0) _pill('${course.lectureCount} محاضرة', color), if (course.materialsCount > 0) _pill('${course.materialsCount} ملف', AppTheme.accentSage), if (course.pendingSheets > 0) _pill('${course.pendingSheets} شيت', AppTheme.accentGold)]),
        ])),
        IconButton(onPressed: () => widget.onOpenStudyCourse(course.name), icon: Icon(Icons.auto_awesome_rounded, color: color)),
      ]),
    );
  }

  Widget _pill(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)));

  Widget _loading() => const Center(child: CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 2));

  Widget _state(String title, String body, IconData icon, VoidCallback retry) => ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(28, 150, 28, 100), children: [Icon(icon, size: 48, color: AppTheme.textMuted), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)), const SizedBox(height: 8), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)), const SizedBox(height: 20), Center(child: OutlinedButton(onPressed: retry, child: const Text('إعادة المحاولة')))]);
}
