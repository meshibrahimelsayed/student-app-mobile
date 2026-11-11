import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_navigation_screen.dart';
import 'services/api_service.dart';
import 'services/app_preferences.dart';
import 'services/study_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudyStore.instance.database;
  await ApiService.initialize();
  await AppPreferences.initialize();
  runApp(const StudentStudyCopilotApp());
}

class StudentStudyCopilotApp extends StatelessWidget {
  const StudentStudyCopilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppPreferences.locale,
      builder: (context, locale, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: AppPreferences.themeMode,
        builder: (context, themeMode, _) => MaterialApp(
      title: 'رفيق الكلية | College Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationScreen(),
        ),
      ),
    );
  }
}
