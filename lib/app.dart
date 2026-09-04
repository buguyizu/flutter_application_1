import 'package:flutter/material.dart';

import 'clock_page.dart';
import 'models/clock_models.dart';

class ClockApp extends StatefulWidget {
  const ClockApp({super.key});

  @override
  State<ClockApp> createState() => _ClockAppState();
}

class _ClockAppState extends State<ClockApp> {
  AppThemeOption _themeOption = AppThemeOption.chronicleIndigoLight;
  late DisplayLanguage _language;

  @override
  void initState() {
    super.initState();
    _language = _initialDisplayLanguage();
  }

  DisplayLanguage _initialDisplayLanguage() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode.toLowerCase();
    final countryCode = locale.countryCode?.toUpperCase();
    final scriptCode = locale.scriptCode?.toLowerCase();
    if (languageCode == 'zh') {
      return scriptCode == 'hant' ||
              countryCode == 'TW' ||
              countryCode == 'HK' ||
              countryCode == 'MO'
          ? DisplayLanguage.traditionalChinese
          : DisplayLanguage.chinese;
    }
    if (languageCode == 'ja') return DisplayLanguage.japanese;
    if (languageCode == 'en') return DisplayLanguage.english;
    return DisplayLanguage.chinese;
  }

  String get _title => switch (_language) {
    DisplayLanguage.chinese => '时间旋流',
    DisplayLanguage.traditionalChinese => '時間旋流',
    DisplayLanguage.english => 'Time Flow',
    DisplayLanguage.japanese => '時間の流転',
  };

  void _changeLanguage(DisplayLanguage language) {
    setState(() => _language = language);
  }

  void _changeThemeOption(AppThemeOption themeOption) {
    setState(() => _themeOption = themeOption);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeOption.preset.seedColor,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeOption.preset.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeOption.themeMode,
      home: ClockPage(
        language: _language,
        onLanguageChanged: _changeLanguage,
        themeOption: _themeOption,
        onThemeOptionChanged: _changeThemeOption,
      ),
    );
  }
}
