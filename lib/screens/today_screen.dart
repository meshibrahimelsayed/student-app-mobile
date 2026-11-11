import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/study_digest_service.dart';
import '../services/study_store.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';

class TodayScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  const TodayScreen({super.key, required this.onNavigateTab});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<ScheduleItem> schedule = [];
  List<AssignmentItem> assignments = [];
  StudyDigest _todayDigest = const StudyDigest(0, {}, []);
  StudyDigest _weekDigest = const StudyDigest(0, {}, []);
  List<CourseProgress> _courseProgress = [];
  bool isLoading = true;
  int selectedDay = 2;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final results = await Future.wait([
      ApiService.getTodaySchedule(),
      ApiService.getAssignments(),
      StudyDigestService.daily(),
      StudyDigestService.weekly(),
      StudyStore.instance.getCourseProgress(),
    ]);
    if (mounted) {
      setState(() {
        schedule = results[0] as List<ScheduleItem>;
        assignments = results[1] as List<AssignmentItem>;
        _todayDigest = results[2] as StudyDigest;
        _weekDigest = results[3] as StudyDigest;
        _courseProgress = results[4] as List<CourseProgress>;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      body: RefreshIndicator(
        onRefresh: loadData,
        color: AppTheme.accentGold,
        backgroundColor: AppTheme.surfaceCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero Header ─────────────────────────────────
            SliverToBoxAdapter(child: _buildHeroHeader()),
            // ── Week Strip ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _buildWeekStrip(),
              ),
            ),
            if (!isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildStudyOverview(),
                ),
              ),
            if (assignments.any((item) => !item.isCompleted))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildPriorityBanner(),
                ),
              ),
            // ── Today's Schedule ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildSectionLabel(AppStrings.text(context, 'جدول اليوم', 'Today’s schedule'), AppStrings.text(context, '${schedule.length} فعاليات', '${schedule.length} events')),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: isLoading ? _buildSkeleton() : _buildTimeline(),
              ),
            ),
            // ── Upcoming Tasks ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildSectionLabel(AppStrings.text(context, 'تكليفات قريبة', 'Upcoming tasks'), AppStrings.text(context, 'عرض الكل', 'See all'),
                    onTap: () => widget.onNavigateTab(2)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _buildTaskRow(assignments[i]),
                ),
                childCount: assignments.take(3).length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── Hero Header ─────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Warm gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A100A), Color(0xFF0E0B08)],
              ),
            ),
          ),
          // Warm glow
          Positioned(
            top: -40, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accentWarm.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.accentWarm.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentWarm.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.school_rounded, color: AppTheme.accentWarm, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(AppStrings.text(context, 'رفيق الكلية', 'College Companion'), style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                          )),
                          Text(ApiService.demoMode ? AppStrings.text(context, 'معاينة تفاعلية · بيانات توضيحية', 'Interactive preview · Sample data') : AppStrings.text(context, 'محتواك الدراسي ومتابعة المحاضرات', 'Your study feed and lecture progress'), style: GoogleFonts.cairo(
                            fontSize: 10, color: AppTheme.textMuted,
                          )),
                        ]),
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        GestureDetector(
                          onTap: () => widget.onNavigateTab(5),
                          child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Stack(children: [
                            const Center(child: Icon(Icons.notifications_outlined, size: 18, color: AppTheme.textSecondary)),
                            Positioned(
                              top: 8, left: 8,
                              child: Container(
                                width: 7, height: 7,
                                decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle),
                              ),
                            ),
                          ]),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          tooltip: AppStrings.text(context, 'الإعدادات', 'Settings'),
                          icon: const Icon(Icons.settings_outlined, size: 20, color: AppTheme.textSecondary),
                          style: IconButton.styleFrom(minimumSize: const Size(48, 48), backgroundColor: AppTheme.surfaceCard),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Welcome text
                  Text(AppStrings.text(context, 'صباح الخير،', 'Good day,'), style: GoogleFonts.cairo(
                    fontSize: 13, color: AppTheme.textMuted,
                  )),
                  Text(_todayLabel(), style: GoogleFonts.cairo(
                    fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.1,
                  )),
                  const SizedBox(height: 10),
                  Row(children: [
                    _buildStatChip(Icons.event_note_rounded, AppStrings.text(context, '${schedule.length} محاضرات', '${schedule.length} lectures'), AppTheme.accentWarm),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.assignment_outlined, AppStrings.text(context, '${assignments.where((a) => !a.isCompleted).length} مهام', '${assignments.where((a) => !a.isCompleted).length} tasks'), AppTheme.accentGold),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${_weekdayName(now.weekday)} ${now.day} ${_monthName(now.month)}';
  }

  String _weekdayName(int weekday) {
    const ar = ['', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const en = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return AppStrings.isArabic(context) ? ar[weekday] : en[weekday];
  }

  String _monthName(int month) {
    const ar = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    const en = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return AppStrings.isArabic(context) ? ar[month] : en[month];
  }

  Widget _buildStudyOverview() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildDigestCard(AppStrings.text(context, 'ملخص النهاردة', 'Today’s summary'), _todayDigest, Icons.today_rounded),
        const SizedBox(height: 10),
        _buildCourseProgressCard(),
        const SizedBox(height: 10),
        _buildDigestCard(AppStrings.text(context, 'آخر ٧ أيام', 'Last 7 days'), _weekDigest, Icons.date_range_rounded),
      ]);

  Widget _buildDigestCard(String title, StudyDigest digest, IconData icon) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderSubtle)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppTheme.accentGold, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
            Text(AppStrings.text(context, '${digest.itemCount} عنصر', '${digest.itemCount} items'), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
          const SizedBox(height: 9),
          if (digest.itemCount == 0)
            Row(children: [
              Expanded(child: Text(AppStrings.text(context, 'استورد محادثة أو ملفات عشان يظهر ملخص المحتوى هنا.', 'Import a chat or files to see a summary here.'), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.45))),
              TextButton(onPressed: () => widget.onNavigateTab(1), child: Text(AppStrings.text(context, 'استيراد', 'Import'))),
            ])
          else ...[
            if (digest.categories.isNotEmpty)
              Text(digest.categories.entries.map((entry) => '${_localizedCategory(entry.key)} ${entry.value}').join('  ·  '), style: const TextStyle(fontSize: 11, color: AppTheme.accentGold)),
            const SizedBox(height: 5),
            ...digest.highlights.take(3).map((line) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text('• $line', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                )),
          ],
        ]),
      );

  String _localizedCategory(String value) {
    if (AppStrings.isArabic(context)) return value;
    return switch (value) {
      'محاضرة' => 'Lecture',
      'سكشن' => 'Section',
      'واجب' => 'Assignment',
      'امتحان' => 'Exam',
      'إعلان' => 'Announcement',
      'ملف' => 'File',
      _ => 'Other',
    };
  }

  Widget _buildCourseProgressCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderSubtle)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_graph_rounded, color: AppTheme.accentSage, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(AppStrings.text(context, 'تقدم المواد', 'Course progress'), style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
            TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())), child: Text(AppStrings.text(context, 'إدارة', 'Manage'))),
          ]),
          if (_courseProgress.isEmpty)
            Text(AppStrings.text(context, 'أضف موادك من الإعدادات.', 'Add your courses in Settings.'), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
          else
            ..._courseProgress.take(3).map((course) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(course.name, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
                      Text(course.totalLectures == 0
                          ? AppStrings.text(context, '${course.lecturesCompleted} مرصود', '${course.lecturesCompleted} tracked')
                          : course.isComplete
                              ? AppStrings.text(context, 'اكتملت', 'Complete')
                              : AppStrings.text(context, '${course.lecturesCompleted}/${course.totalLectures} محاضرة', '${course.lecturesCompleted}/${course.totalLectures} lectures'),
                          style: TextStyle(fontSize: 10, color: course.isComplete ? AppTheme.accentSage : AppTheme.textMuted)),
                    ]),
                    if (course.totalLectures > 0) ...[
                      const SizedBox(height: 5),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: course.fraction, minHeight: 4, backgroundColor: AppTheme.surfaceElevated, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentSage))),
                    ],
                  ]),
                )),
        ]),
      );

  // ─── Week Strip ───────────────────────────────────────────────
  Widget _buildWeekStrip() {
    final today = DateTime.now();
    final dates = List.generate(5, (index) => DateTime(today.year, today.month, today.day + index - 2));
    final days = dates.map((date) => AppStrings.isArabic(context)
        ? ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'][date.weekday % 7]
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7]).toList();
    final numbers = dates.map((date) => '${date.day}').toList();

    return Row(
      children: List.generate(5, (i) {
        final isSelected = selectedDay == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedDay = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentWarm : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.accentWarm : AppTheme.borderSubtle,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppTheme.accentWarm.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(children: [
                Text(days[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 3),
                Text(numbers[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    )),
              ]),
            ),
          ),
        );
      }),
    );
  }

  // ─── Priority Banner ──────────────────────────────────────────
  Widget _buildPriorityBanner() {
    final priority = assignments.firstWhere((item) => !item.isCompleted);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppTheme.accentWarm.withOpacity(0.18), AppTheme.surfaceCard],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: AppTheme.accentWarm.withOpacity(0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('أولوية اليوم', style: GoogleFonts.cairo(
              fontSize: 11, color: AppTheme.accentGold, fontWeight: FontWeight.bold,
            )),
          ]),
          const SizedBox(height: 6),
          Text(priority.title,
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text('${priority.subjectName} — ${priority.deadline}',
              style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => widget.onNavigateTab(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.accentWarm,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppTheme.accentWarm.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Text('راجعه ⚡', style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,
            )),
          ),
        ),
      ]),
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────
  Widget _buildTimeline() {
    if (schedule.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text('لا فعاليات اليوم 🎉', style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 13))),
      );
    }
    return Column(
      children: schedule.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        final isLast = i == schedule.length - 1;
        final isLecture = item.type == 'LECTURE';
        final dotColor = isLecture ? AppTheme.accentWarm : AppTheme.accentSage;
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Spine
            SizedBox(width: 24, child: Column(children: [
              Container(
                width: 11, height: 11,
                decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 8)],
                ),
              ),
              if (!isLast)
                Expanded(child: Container(
                  width: 1.5,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: AppTheme.borderSubtle,
                )),
            ])),
            const SizedBox(width: 10),
            // Card
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(item.time, style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700, color: dotColor,
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceChip, borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item.location, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Text(item.subjectName, style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary,
                    )),
                    const SizedBox(height: 2),
                    Text(item.doctor, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ]),
                ),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  // ─── Task Row ─────────────────────────────────────────────────
  Widget _buildTaskRow(AssignmentItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => item.isCompleted = !item.isCompleted);
            ApiService.toggleAssignment(item.id, item.isCompleted);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.isCompleted ? AppTheme.accentSage : Colors.transparent,
              border: Border.all(
                color: item.isCompleted ? AppTheme.accentSage : AppTheme.textMuted,
                width: 1.5,
              ),
            ),
            child: item.isCompleted ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, style: GoogleFonts.cairo(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: item.isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          )),
          Text('${item.subjectName} · ${item.deadline}',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ])),
        if (!item.isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
            ),
            child: Text(
              item.deadline.contains('اليوم') ? '⚠ اليوم' : item.deadline,
              style: const TextStyle(fontSize: 10, color: AppTheme.accentGold, fontWeight: FontWeight.bold),
            ),
          ),
      ]),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, String sub, {VoidCallback? onTap}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.3)),
      GestureDetector(
        onTap: onTap,
        child: Text(sub, style: TextStyle(
          fontSize: 11,
          color: onTap != null ? AppTheme.accentGold : AppTheme.textMuted,
          fontWeight: onTap != null ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    ]);
  }

  Widget _buildSkeleton() {
    return Column(children: List.generate(3, (_) => Container(
      margin: const EdgeInsets.only(bottom: 10), height: 76,
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(18)),
    )));
  }
}
