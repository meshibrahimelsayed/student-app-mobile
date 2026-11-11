import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  List<AssignmentItem> assignments = [];
  bool isLoading = true;
  String? loadError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadAssignments() async {
    final list = await ApiService.getAssignments();
    if (mounted) setState(() { assignments = list; loadError = ApiService.lastError; isLoading = false; });
  }

  List<AssignmentItem> get pending   => assignments.where((a) => !a.isCompleted).toList();
  List<AssignmentItem> get completed => assignments.where((a) =>  a.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(AppStrings.text(context, 'صندوق المهام', 'Tasks'), style: GoogleFonts.cairo(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5,
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
                    ),
                    child: Text(AppStrings.text(context, '${pending.length} معلّق', '${pending.length} pending'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(AppStrings.text(context, 'تُستخرج آلياً من جروبات الدكاترة', 'Collected from your study groups'),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                // Segmented tab control
                Container(
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.accentWarm,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [BoxShadow(color: AppTheme.accentWarm.withOpacity(0.3), blurRadius: 8)],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    tabs: [Tab(text: AppStrings.text(context, 'الكل', 'All')), Tab(text: AppStrings.text(context, 'المعلّق', 'Pending')), Tab(text: AppStrings.text(context, 'المكتمل', 'Done'))],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          // ── List ─────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(
                    color: AppTheme.accentWarm, strokeWidth: 2,
                  ))
                : loadError != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 44, color: AppTheme.textMuted), const SizedBox(height: 12), Text(AppStrings.text(context, 'تعذر تحميل المهام من الخادم', 'Could not load tasks from the server'), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)), const SizedBox(height: 8), OutlinedButton(onPressed: () { setState(() { isLoading = true; }); loadAssignments(); }, child: Text(AppStrings.text(context, 'إعادة المحاولة', 'Try again')))])))
                    : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(assignments),
                      _buildList(pending),
                      _buildList(completed),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AssignmentItem> list) {
    if (list.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline_rounded, size: 40, color: AppTheme.textMuted.withOpacity(0.3)),
        const SizedBox(height: 10),
        Text(AppStrings.text(context, 'لا توجد مهام هنا', 'Nothing here yet'), style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildTaskCard(list[i]),
    );
  }

  Widget _buildTaskCard(AssignmentItem item) {
    final isUrgent = !item.isCompleted && item.deadline.contains('اليوم');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? AppTheme.accentGold.withOpacity(0.35)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isCompleted ? AppTheme.accentSage : AppTheme.accentGold,
                ),
              ),
              const SizedBox(width: 6),
              Text(item.subjectName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (item.isCompleted ? AppTheme.accentSage : AppTheme.accentGold).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.deadline, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold,
                color: item.isCompleted ? AppTheme.accentSage : AppTheme.accentGold,
              )),
            ),
          ]),
          const SizedBox(height: 8),
          // Title
          Text(item.title, style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700, fontSize: 14,
            color: item.isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: AppTheme.textMuted,
          )),
          const SizedBox(height: 5),
          Text(item.description, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.5)),
          const SizedBox(height: 14),
          // Divider
          Container(height: 0.5, color: AppTheme.borderSubtle),
          const SizedBox(height: 10),
          // Footer
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 11, color: AppTheme.textMuted.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(AppStrings.text(context, 'رُصد تلقائياً من الجروب', 'Added from a group'),
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ]),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => item.isCompleted = !item.isCompleted);
                ApiService.toggleAssignment(item.id, item.isCompleted);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: item.isCompleted ? AppTheme.surfaceChip : AppTheme.accentSage,
                  borderRadius: BorderRadius.circular(12),
                  border: item.isCompleted ? Border.all(color: AppTheme.borderSubtle) : null,
                ),
                child: Text(
                  item.isCompleted ? AppStrings.text(context, 'إعادة للمعلّق', 'Mark pending') : AppStrings.text(context, 'تم الإنجاز ✔', 'Mark done ✔'),
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: item.isCompleted ? AppTheme.textMuted : Colors.white,
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
