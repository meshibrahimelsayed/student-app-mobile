import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
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
  bool isLoading = true;
  int selectedDay = 1; // Sunday = index 1 (today)

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final sch = await ApiService.getTodaySchedule();
    final asg = await ApiService.getAssignments();
    if (mounted) {
      setState(() {
        schedule = sch;
        assignments = asg;
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
                child: _buildSectionLabel('جدول اليوم', '${schedule.length} فعاليات'),
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
                child: _buildSectionLabel('تكليفات قريبة', 'عرض الكل',
                    onTap: () => widget.onNavigateTab(1)),
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
                          Text('رفيق الكلية', style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                          )),
                          Text('معاينة تفاعلية · بيانات توضيحية', style: GoogleFonts.cairo(
                            fontSize: 10, color: AppTheme.textMuted,
                          )),
                        ]),
                      ]),
                      GestureDetector(
                        onTap: () => widget.onNavigateTab(4),
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Welcome text
                  Text('صباح الخير،', style: GoogleFonts.cairo(
                    fontSize: 13, color: AppTheme.textMuted,
                  )),
                  Text('الأربعاء ١١ نوفمبر', style: GoogleFonts.cairo(
                    fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.1,
                  )),
                  const SizedBox(height: 10),
                  Row(children: [
                    _buildStatChip(Icons.event_note_rounded, '${schedule.length} محاضرات', AppTheme.accentWarm),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.assignment_outlined, '${assignments.where((a) => !a.isCompleted).length} مهام', AppTheme.accentGold),
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

  // ─── Week Strip ───────────────────────────────────────────────
  Widget _buildWeekStrip() {
    final days = ['ث', 'ح', 'ن', 'ث', 'ر'];
    final numbers = ['9', '10', '11', '12', '13'];
    final dayNames = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء'];

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
          onTap: () => widget.onNavigateTab(3),
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
