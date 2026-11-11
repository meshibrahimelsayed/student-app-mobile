import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/content_item.dart';
import '../services/media_import_service.dart';
import '../services/study_store.dart';
import '../theme/app_theme.dart';

class ContentArchiveScreen extends StatefulWidget {
  const ContentArchiveScreen({super.key});

  @override
  State<ContentArchiveScreen> createState() => _ContentArchiveScreenState();
}

class _ContentArchiveScreenState extends State<ContentArchiveScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<ContentItem> _items = [];
  List<String> _courses = [];
  ContentCategory? _category;
  String _query = '';
  String _lastGroupName = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        StudyStore.instance.searchContent(query: _query, category: _category),
        StudyStore.instance.getCourseNames(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = values[0] as List<ContentItem>;
        _courses = values[1] as List<String>;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _search(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), _load);
  }

  Future<String?> _askGroupName(String suggested) async {
    final controller = TextEditingController(text: suggested.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.text(context, 'اسم جروب واتساب', 'WhatsApp group name')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(labelText: AppStrings.text(context, 'اسم الجروب أو مصدر المحتوى', 'Group name or content source')),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppStrings.text(context, 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: Text(AppStrings.text(context, 'متابعة', 'Continue'))),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.trim().isEmpty) return null;
    return result.trim();
  }

  Future<void> _importChat() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'zip'],
        withData: true,
      );
      if (selection == null || selection.files.isEmpty) return;
      final file = selection.files.single;
      final group = await _askGroupName(
        _lastGroupName.isEmpty ? file.name.replaceFirst(RegExp(r'\.(txt|zip)$', caseSensitive: false), '') : _lastGroupName,
      );
      if (group == null) return;
      final isZip = file.name.toLowerCase().endsWith('.zip');
      final result = isZip
          ? await MediaImportService.importWhatsAppZip(file: file, groupName: group, courseNames: _courses)
          : await MediaImportService.importChatFile(file: file, groupName: group, courseNames: _courses);
      _lastGroupName = group;
      await _load();
      if (mounted) _showMessage(result.message);
    } catch (error) {
      if (mounted) _showMessage('تعذّر استيراد المحادثة: $error');
    }
  }

  Future<void> _importMedia() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: const [
          'pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp',
          'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'amr',
          'mp4', 'ppt', 'pptx', 'doc', 'docx',
        ],
        withData: true,
      );
      if (selection == null || selection.files.isEmpty) return;
      final group = await _askGroupName(_lastGroupName.isEmpty ? 'ملفات الدراسة' : _lastGroupName);
      if (group == null) return;
      var imported = 0;
      final statuses = <String>[];
      for (final file in selection.files) {
        final result = await MediaImportService.importAttachment(
          file: file,
          groupName: group,
          courseNames: _courses,
        );
        imported += result.importedCount;
        statuses.add(result.message);
      }
      _lastGroupName = group;
      await _load();
      if (mounted) _showMessage('تم حفظ $imported ملف. ${statuses.take(2).join(' ')}');
    } catch (error) {
      if (mounted) _showMessage('تعذّر استيراد الملف: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(ContentItem item) async {
    if (item.id == null) return;
    var course = _courses.contains(item.courseName) ? item.courseName : '';
    var category = item.category;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: Text(AppStrings.text(context, 'تعديل التصنيف', 'Edit classification')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: course,
                decoration: InputDecoration(labelText: AppStrings.text(context, 'المادة', 'Course')),
                items: [
                  DropdownMenuItem(value: '', child: Text(AppStrings.text(context, 'غير مصنّف', 'Unassigned'))),
                  ..._courses.map((name) => DropdownMenuItem(value: name, child: Text(name))),
                ],
                onChanged: (value) => setDialogState(() => course = value ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ContentCategory>(
                value: category,
                decoration: InputDecoration(labelText: AppStrings.text(context, 'النوع', 'Type')),
                items: ContentCategory.values.map((value) => DropdownMenuItem(value: value, child: Text(AppStrings.isArabic(context) ? value.label : value.englishLabel))).toList(),
                onChanged: (value) => setDialogState(() => category = value ?? ContentCategory.other),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppStrings.text(context, 'إلغاء', 'Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppStrings.text(context, 'حفظ', 'Save'))),
          ],
        ),
      ),
    );
    if (saved == true) {
      await StudyStore.instance.updateClassification(item.id!, courseName: course, category: category);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.canvasColor,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppTheme.accentGold,
            backgroundColor: AppTheme.surfaceCard,
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _searchBox()),
                SliverToBoxAdapter(child: _filters()),
                if (_loading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  SliverFillRemaining(child: _empty(AppStrings.text(context, 'تعذّر فتح الأرشيف', 'Could not open the library'), AppStrings.text(context, 'اسحب الشاشة لإعادة المحاولة.', 'Pull down to try again.')))
                else if (_items.isEmpty)
                  SliverFillRemaining(child: _empty(AppStrings.text(context, 'الأرشيف لسه فاضي', 'Your library is empty'), AppStrings.text(context, 'استورد تصدير محادثة WhatsApp أو اختار ملفات المحاضرات للبدء.', 'Import a WhatsApp chat export or select lecture files to get started.')))
                else
                  SliverList.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _contentCard(_items[index]),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _importChat,
          icon: const Icon(Icons.chat_outlined),
          label: Text(AppStrings.text(context, 'استيراد محادثة', 'Import chat')),
        ),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppStrings.text(context, 'محتوى الدراسة', 'Study library'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
            Text(AppStrings.text(context, 'رسائل وملفات محاضراتك في أرشيف خاص على جهازك', 'Your lecture messages and files, organized privately on this device'), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _importMedia,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(AppStrings.text(context, 'إضافة صور وPDF وصوتيات وملفات', 'Add images, PDFs, audio and files')),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ),
        ]),
      );

  Widget _searchBox() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _searchController,
          textDirection: TextDirection.rtl,
          onChanged: _search,
          decoration: InputDecoration(
        hintText: AppStrings.text(context, 'ابحث في الرسائل والملفات…', 'Search messages and files…'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(onPressed: () { _searchController.clear(); _search(''); }, icon: const Icon(Icons.close_rounded)),
          ),
        ),
      );

  Widget _filters() => SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
        _filterChip(AppStrings.text(context, 'الكل', 'All'), null),
            ...ContentCategory.values.map((category) => _filterChip(AppStrings.isArabic(context) ? category.label : category.englishLabel, category)),
          ],
        ),
      );

  Widget _filterChip(String label, ContentCategory? value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(label),
          selected: _category == value,
          onSelected: (_) { setState(() => _category = value); _load(); },
        ),
      );

  Widget _contentCard(ContentItem item) => Card(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _edit(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _tag(AppStrings.isArabic(context) ? item.category.label : item.category.englishLabel),
                const SizedBox(width: 8),
                Expanded(child: Text(item.courseName.isEmpty ? item.groupName : item.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700))),
                Text('${item.sentAt.day}/${item.sentAt.month}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              Text(item.extractedText?.trim().isNotEmpty == true ? item.extractedText! : item.text,
                  maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, height: 1.5)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.forum_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 5),
                Expanded(child: Text(item.groupName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))),
                if (item.mediaPath != null) const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.accentGold),
                const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
              ]),
            ]),
          ),
        ),
      );

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: AppTheme.accentWarm.withOpacity(.14), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _empty(String title, String body) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.library_books_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      );
}
