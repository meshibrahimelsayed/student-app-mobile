import 'package:flutter/widgets.dart';

class AppStrings {
  static bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  static String text(BuildContext context, String arabic, String english) =>
      isArabic(context) ? arabic : english;
}
