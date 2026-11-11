import 'package:flutter/material.dart';

import 'study_store.dart';

class AppPreferences {
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static Future<void> initialize() async {
    final language = await StudyStore.instance.getSetting('language');
    locale.value = Locale(language == 'en' ? 'en' : 'ar');
    final theme = await StudyStore.instance.getSetting('theme_mode');
    themeMode.value = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setLanguage(String language) async {
    final normalized = language == 'en' ? 'en' : 'ar';
    locale.value = Locale(normalized);
    await StudyStore.instance.setSetting('language', normalized);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await StudyStore.instance.setSetting('theme_mode', value);
  }
}
