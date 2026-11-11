import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../services/app_preferences.dart';
import '../services/api_service.dart';
import '../services/study_store.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backendController = TextEditingController();
  List<StudyGroup> _groups = [];
  List<CourseProgress> _courses = [];
  bool _demoMode = ApiService.demoMode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _backendController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      StudyStore.instance.getGroups(),
      StudyStore.instance.getCourseProgress(),
      StudyStore.instance.getSetting('backend_url'),
    ]);
    if (!mounted) return;
    setState(() {
      _groups = values[0] as List<StudyGroup>;
      _courses = values[1] as List<CourseProgress>;
      _backendController.text = values[2] as String? ?? '';
      _demoMode = ApiService.demoMode;
      _loading = false;
    });
  }

  Future<void> _saveBackend() async {
    final value = _backendController.text.trim();
    final uri = Uri.tryParse(value);
    if (value.isNotEmpty &&
        (uri?.hasAuthority != true || !const {'http', 'https'}.contains(uri?.scheme))) {
      _message(AppStrings.text(context, 'اكتب رابطًا كاملًا يبدأ بـ http:// أو https://', 'Enter a complete URL starting with http:// or https://'));
      return;
    }
    await ApiService.setBaseUrl(value);
    _message(value.isEmpty ? AppStrings.text(context, 'تم مسح عنوان الخادم.', 'Server URL cleared.') : AppStrings.text(context, 'تم حفظ عنوان الخادم على الجهاز.', 'Server URL saved on this device.'));
  }

  Future<void> _setDemoMode(bool value) async {
    await ApiService.setDemoMode(value);
    if (mounted) setState(() => _demoMode = value);
    _message(value ? AppStrings.text(context, 'وضع المعاينة مفعّل.', 'Sample data is on.') : AppStrings.text(context, 'سيستخدم التطبيق الخادم وعنوان API المحفوظ.', 'The app will use the saved server URL.'));
  }

  Future<void> _editCourse({CourseProgress? course}) async {
    final nameController = TextEditingController(text: course?.name ?? '');
    final totalController = TextEditingController(text: '${course?.totalLectures ?? 0}');
    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(course == null ? AppStrings.text(context, 'إضافة مادة', 'Add course') : AppStrings.text(context, 'تعديل المادة', 'Edit course')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, textDirection: AppStrings.isArabic(context) ? TextDirection.rtl : TextDirection.ltr, decoration: InputDecoration(labelText: AppStrings.text(context, 'اسم المادة', 'Course name'))),
          const SizedBox(height: 12),
          TextField(
            controller: totalController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: AppStrings.text(context, 'عدد المحاضرات المتوقع', 'Expected lecture count')),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppStrings.text(context, 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () {
            final name = nameController.text.trim();
            final total = int.tryParse(totalController.text) ?? 0;
            if (name.isNotEmpty) Navigator.pop(dialogContext, (name, total));
          }, child: Text(AppStrings.text(context, 'حفظ', 'Save'))),
        ],
      ),
    );
    nameController.dispose();
    totalController.dispose();
    if (result == null) return;
    await StudyStore.instance.saveCourse(result.$1, totalLectures: result.$2);
    await _load();
  }

  Future<void> _deleteCourse(CourseProgress course) async {
    await StudyStore.instance.deleteCourse(course.name);
    await _load();
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppStrings.text(context, 'الإعدادات', 'Settings'))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [AppTheme.accentWarm.withOpacity(.24), AppTheme.surfaceCard],
                      ),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: AppTheme.accentWarm.withOpacity(.18), borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.tune_rounded, color: AppTheme.accentGold),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(AppStrings.text(context, 'ظبّط تجربتك', 'Make it yours'), style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(AppStrings.text(context, 'اللغة والمظهر والمحتوى في مكان واحد', 'Language, appearance and study content in one place'), style: Theme.of(context).textTheme.bodyMedium),
                      ])),
                    ]),
                  ),
                  Card(child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: Text(AppStrings.text(context, 'لغة التطبيق', 'App language')),
                      subtitle: Text(AppStrings.text(context, 'اختار اللغة اللي تريحك', 'Choose your preferred language')),
                      trailing: DropdownButton<String>(
                        value: Localizations.localeOf(context).languageCode,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'ar', child: Text('العربية')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (value) { if (value != null) AppPreferences.setLanguage(value); },
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(AppStrings.text(context, 'المظهر', 'Appearance')),
                      subtitle: Text(AppStrings.text(context, 'تلقائي حسب إعداد الجهاز أو اختيار يدوي', 'Follow system or choose a theme')),
                      trailing: ValueListenableBuilder<ThemeMode>(
                        valueListenable: AppPreferences.themeMode,
                        builder: (context, mode, _) => DropdownButton<ThemeMode>(
                          value: mode,
                          underline: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem(value: ThemeMode.system, child: Text(AppStrings.text(context, 'تلقائي', 'System'))),
                            DropdownMenuItem(value: ThemeMode.light, child: Text(AppStrings.text(context, 'فاتح', 'Light'))),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text(AppStrings.text(context, 'داكن', 'Dark'))),
                          ],
                          onChanged: (value) { if (value != null) AppPreferences.setThemeMode(value); },
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      title: Text(AppStrings.text(context, 'بيانات المعاينة', 'Sample data')),
                      subtitle: Text(AppStrings.text(context, 'استخدم محتوى تجريبيًا لاستكشاف الواجهة.', 'Explore the app with sample content.')),
                      value: _demoMode,
                      onChanged: _setDemoMode,
                      secondary: const Icon(Icons.preview_outlined),
                    ),
                  ])),
                  const SizedBox(height: 18),
                  _sectionTitle(AppStrings.text(context, 'المجموعات المتابَعة', 'Tracked groups')),
                  if (_groups.isEmpty)
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(AppStrings.text(context, 'هنا هتظهر المجموعات بعد استيراد ملف محادثة.', 'Groups appear here after you import a chat export.'))))
                  else
                    ..._groups.map((group) => Card(
                          child: SwitchListTile(
                            title: Text(group.name),
                            subtitle: Text(AppStrings.text(context, '${group.contentCount} رسالة أو ملف', '${group.contentCount} messages or files')),
                            value: group.isTracked,
                            onChanged: (value) async {
                              await StudyStore.instance.setGroupTracked(group.name, value);
                              await _load();
                            },
                            secondary: const Icon(Icons.forum_outlined),
                          ),
                        )),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: _sectionTitle(AppStrings.text(context, 'المواد', 'Courses'))),
                    IconButton.filledTonal(onPressed: () => _editCourse(), tooltip: AppStrings.text(context, 'إضافة مادة', 'Add course'), icon: const Icon(Icons.add)),
                  ]),
                  ..._courses.map((course) => Card(
                        child: ListTile(
                          title: Text(course.name),
                          subtitle: Text(AppStrings.text(context, 'مرصود ${course.lecturesCompleted} من ${course.totalLectures == 0 ? '—' : course.totalLectures} محاضرة', '${course.lecturesCompleted} of ${course.totalLectures == 0 ? '—' : course.totalLectures} lectures tracked')),
                          trailing: Wrap(spacing: 0, children: [
                            IconButton(onPressed: () => _editCourse(course: course), tooltip: AppStrings.text(context, 'تعديل', 'Edit'), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () => _deleteCourse(course), tooltip: AppStrings.text(context, 'إخفاء المادة', 'Hide course'), icon: const Icon(Icons.delete_outline)),
                          ]),
                        ),
                      )),
                  const SizedBox(height: 18),
                  _sectionTitle(AppStrings.text(context, 'خادم المعالجة الاختياري', 'Optional processing server')),
                  Card(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(AppStrings.text(context, 'عنوان Backend', 'Backend URL')),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _backendController,
                        keyboardType: TextInputType.url,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(hintText: 'https://example.edu/api'),
                      ),
                      const SizedBox(height: 10),
                      Text(AppStrings.text(context, 'يُرسل الصوت للخادم الذي تختاره فقط عند تعطيل بيانات المعاينة. لا تضع مفاتيح API هنا؛ خزّنها على الخادم.', 'Audio is sent only to this server when sample data is off. Keep API keys on your server, not in this app.'), style: const TextStyle(color: AppTheme.textMuted, height: 1.45, fontSize: 12)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _saveBackend, child: Text(AppStrings.text(context, 'حفظ العنوان', 'Save URL'))),
                    ]),
                  )),
                  const SizedBox(height: 18),
                  const Card(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(AppStrings.text(context, 'الاستيراد الحالي يدوي من ملف محادثة أو ملفات تختارها. لا يقرأ التطبيق محادثات WhatsApp في الخلفية؛ استخدم تصدير المحادثة من واتساب.', 'Imports are manual from chat exports and files you select. The app does not read WhatsApp in the background; use WhatsApp chat export.'), style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                  )),
                ],
              ),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}
