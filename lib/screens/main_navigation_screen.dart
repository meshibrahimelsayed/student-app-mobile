import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'today_screen.dart';
import 'assignments_screen.dart';
import 'courses_screen.dart';
import 'study_copilot_screen.dart';
import 'alerts_screen.dart';
import 'content_archive_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _studyPrompt;

  void _navigateToTab(int index, {String? prompt}) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
      if (prompt != null) _studyPrompt = prompt;
    });
  }

  List<_NavItem> _navItems(BuildContext context) => [
    _NavItem(label: AppStrings.text(context, 'اليوم', 'Today'), icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItem(label: AppStrings.text(context, 'المحتوى', 'Library'), icon: Icons.library_books_outlined, activeIcon: Icons.library_books_rounded),
    _NavItem(label: AppStrings.text(context, 'المهام', 'Tasks'), icon: Icons.check_circle_outline, activeIcon: Icons.check_circle_rounded),
    _NavItem(label: AppStrings.text(context, 'المواد', 'Courses'), icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded),
    _NavItem(label: AppStrings.text(context, 'مذاكرة', 'Study'), icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded),
    _NavItem(label: AppStrings.text(context, 'تحديثات', 'Updates'), icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded),
  ];

  List<Widget> _buildScreens() {
    return [
      TodayScreen(onNavigateTab: _navigateToTab),
      const ContentArchiveScreen(),
      const AssignmentsScreen(),
      CoursesScreen(
        onOpenStudyCourse: (name) => _navigateToTab(
          4,
          prompt: AppStrings.text(context, 'لخصلي المحاضرات الأخيرة ونقاط مادة $name', 'Summarize the latest lectures and key points for $name'),
        ),
      ),
      StudyCopilotScreen(
        key: ValueKey(_studyPrompt),
        initialPrompt: _studyPrompt,
      ),
      const AlertsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasColor,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _buildScreens()),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── iOS-style bottom tab bar ───────────────────────────────
  Widget _buildBottomBar() {
    final items = _navItems(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: const Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
        height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _navigateToTab(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.accentWarm.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                          size: 20,
                            color: isActive ? AppTheme.accentGold : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                          fontSize: 9,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                            color: isActive ? AppTheme.accentGold : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}
