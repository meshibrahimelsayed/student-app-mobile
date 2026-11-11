import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../services/app_preferences.dart';
import '../services/api_service.dart';
import '../services/chat_export_service.dart';
import '../theme/app_theme.dart';

class StudyCopilotScreen extends StatefulWidget {
  final String? initialPrompt;
  const StudyCopilotScreen({super.key, this.initialPrompt});

  @override
  State<StudyCopilotScreen> createState() => _StudyCopilotScreenState();
}

class _StudyCopilotScreenState extends State<StudyCopilotScreen> {
  final List<StudyChatMessage> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isThinking = false;
  String selectedSubject = 'عام';

  static const List<String> subjectOptions = ['عام', 'الذكاء الاصطناعي', 'قواعد البيانات', 'شبكات الحاسب', 'هندسة البرمجيات', 'بحوث العمليات'];

  List<Map<String, String>> _quickPrompts() => AppStrings.isArabic(context)
      ? [
          {'label': '💡 شرح الـ Normalization', 'prompt': 'اشرحلي الـ Normalization ببساطة مع مثال عملي'},
          {'label': '🎯 كويز في الـ AI', 'prompt': 'اعملي كويز سريع من 3 أسئلة في خوارزميات الذكاء الاصطناعي'},
          {'label': '📝 OSI Model', 'prompt': 'لخصلي طبقات الـ OSI Model في جملتين لكل طبقة'},
          {'label': '⚡ مراجعة سريعة', 'prompt': 'أعطني أهم 5 نقاط للمراجعة قبل الامتحان في مادة'},
        ]
      : [
          {'label': '💡 Explain normalization', 'prompt': 'Explain database normalization with a practical example'},
          {'label': '🎯 AI quiz', 'prompt': 'Give me a quick 3-question quiz on AI search algorithms'},
          {'label': '📝 OSI model', 'prompt': 'Summarize each OSI layer in one sentence'},
          {'label': '⚡ Quick review', 'prompt': 'Give me five key points to review before the exam'},
        ];

  @override
  void initState() {
    super.initState();
    _addAIMessage(AppPreferences.locale.value.languageCode == 'ar' ? 'أهلاً بك في رفيق المذاكرة. اكتب سؤالك أو اختر مادة، وسأساعدك عندما تكون خدمة الذكاء الاصطناعي متاحة.' : 'Welcome to Study Buddy. Ask a question or choose a course. AI replies need a connected service.');
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sendMessage(widget.initialPrompt!));
    }
  }

  String _subjectEnglish(String subject) => switch (subject) {
        'عام' => 'General',
        'الذكاء الاصطناعي' => 'Artificial intelligence',
        'قواعد البيانات' => 'Databases',
        'شبكات الحاسب' => 'Computer networks',
        'هندسة البرمجيات' => 'Software engineering',
        'بحوث العمليات' => 'Operations research',
        _ => subject,
      };

  void _addAIMessage(String text) {
    messages.add(StudyChatMessage(sender: 'assistant', text: text, timestamp: DateTime.now()));
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || isThinking) return;
    controller.clear();
    HapticFeedback.selectionClick();

    setState(() {
      messages.add(StudyChatMessage(sender: 'user', text: query, timestamp: DateTime.now()));
      isThinking = true;
    });
    _scrollToBottom();

    final reply = await ApiService.chatWithStudyBuddy(query, selectedSubject);
    if (mounted) {
      setState(() {
        _addAIMessage(reply);
        isThinking = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _exportChat() async {
    if (messages.isEmpty) return;
    try {
      await ChatExportService.export(messages);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.text(context, 'تم تجهيز ملف المحادثة للمشاركة', 'Chat export is ready to share'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.text(context, 'تعذر تصدير المحادثة', 'Could not export the chat'))),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickPrompts = _quickPrompts();
    return Scaffold(
      body: Column(
        children: [
          // ── Context Bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentEmerald),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppStrings.text(context, 'اختر المادة ثم ابدأ سؤالك', 'Choose a course, then ask away'), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
                  DropdownButton<String>(
                    value: selectedSubject,
                    dropdownColor: AppTheme.surfaceElevated,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted, size: 16),
                    style: const TextStyle(fontSize: 11, color: AppTheme.accentCobalt, fontWeight: FontWeight.bold),
                    items: subjectOptions.map((s) => DropdownMenuItem(value: s, child: Text(AppStrings.isArabic(context) ? s : _subjectEnglish(s)))).toList(),
                    onChanged: (val) => setState(() => selectedSubject = val ?? 'عام'),
                  ),
                  IconButton(onPressed: _exportChat, tooltip: AppStrings.text(context, 'تصدير المحادثة', 'Export chat'), icon: const Icon(Icons.ios_share_rounded, color: AppTheme.accentGold, size: 19)),
                ],
              ),
            ),
          ),

          // ── Quick Prompt Chips ───────────────────────────
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final p = quickPrompts[i];
                return ActionChip(
                  label: Text(p['label']!, style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0))),
                  backgroundColor: AppTheme.surfaceColor,
                  side: const BorderSide(color: AppTheme.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => sendMessage(p['prompt']!),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // ── Chat Messages Area ───────────────────────────
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              itemCount: messages.length + (isThinking ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == messages.length && isThinking) return _buildThinkingIndicator();
                return _buildBubble(messages[i]);
              },
            ),
          ),

          // ── Floating Input Area ──────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: BoxDecoration(
              color: AppTheme.canvasColor,
              border: const Border(top: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: sendMessage,
                        decoration: const InputDecoration(
                          hintText: AppStrings.text(context, 'اسأل عن أي مفهوم أو اطلب تلخيصاً...', 'Ask about a topic or request a summary…'),
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => sendMessage(controller.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.accentCobalt,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.accentCobalt.withOpacity(0.35), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(StudyChatMessage msg) {
    final isUser = msg.sender == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30, margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accentCobalt.withOpacity(0.18) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: isUser ? AppTheme.accentCobalt.withOpacity(0.3) : AppTheme.borderSubtle,
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(fontSize: 13, height: 1.55, color: Colors.white),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('أح',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppTheme.accentCobalt,
                    )),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 30, height: 30, margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentCobalt)),
                SizedBox(width: 10),
                Text(AppStrings.text(context, 'رفيق المذاكرة يجهز الشرح...', 'Study Buddy is thinking…'), style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
