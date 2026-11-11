import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<AlertItem>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = ApiService.getAlerts();
  }

  Future<void> _reload() async {
    setState(() => _alertsFuture = ApiService.getAlerts());
    await _alertsFuture;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.canvasColor,
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppTheme.accentGold,
        backgroundColor: AppTheme.surfaceCard,
        onRefresh: _reload,
        child: FutureBuilder<List<AlertItem>>(
          future: _alertsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 2));
            if (snapshot.hasError || ApiService.lastError != null) return _state(AppStrings.text(context, 'تعذر تحميل الرادار', 'Could not load updates'), AppStrings.text(context, 'لا يمكن عرض إعلانات غير مؤكدة. تحقق من الخادم وحاول مرة أخرى.', 'Updates are unavailable. Check the server and try again.'), Icons.radar_outlined);
            final alerts = snapshot.data ?? const <AlertItem>[];
            if (alerts.isEmpty) return _state(AppStrings.text(context, 'لا توجد إعلانات', 'No updates yet'), AppStrings.text(context, 'سيظهر هنا كل إعلان يصل من المصادر المرتبطة بحسابك.', 'Updates from your connected sources will appear here.'), Icons.notifications_none_rounded);
            return CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [SliverToBoxAdapter(child: _header()), SliverList(delegate: SliverChildBuilderDelegate((_, i) => _card(alerts[i]), childCount: alerts.length)), const SliverToBoxAdapter(child: SizedBox(height: 100))]);
          },
        ),
      ),
    ),
  );

  Widget _header() => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppStrings.text(context, 'سجل الرادار', 'Updates'), style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)), const SizedBox(height: 4), Text(AppStrings.text(context, 'إعلانات مؤكدة من المصادر المرتبطة بحسابك', 'Updates from sources connected to your account'), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))]));

  Widget _card(AlertItem alert) => Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderSubtle)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentGold)), const SizedBox(width: 8), Expanded(child: Text(alert.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGold))), if (alert.createdAt != null) Text(_date(alert.createdAt!), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted))]), const SizedBox(height: 10), Text(alert.body, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.55)), const SizedBox(height: 12), Text(alert.source, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted))]));

  String _date(DateTime value) => '${value.toLocal().day}/${value.toLocal().month}';

  Widget _state(String title, String body, IconData icon) => ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(28, 150, 28, 100), children: [Icon(icon, size: 48, color: AppTheme.textMuted), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)), const SizedBox(height: 8), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)), const SizedBox(height: 20), Center(child: OutlinedButton(onPressed: _reload, child: Text(AppStrings.text(context, 'إعادة المحاولة', 'Try again')))]);
}
