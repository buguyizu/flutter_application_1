import 'package:flutter/material.dart';

import 'clock_page.dart';
import 'models/clock_models.dart';
import 'models/theme_model.dart';

class ClockApp extends StatefulWidget {
  const ClockApp({super.key});

  @override
  State<ClockApp> createState() => _ClockAppState();
}

class _ClockAppState extends State<ClockApp> {
  final ThemeManager _themeManager = ThemeManager();
  late DisplayLanguage _language;
  bool _themesLoaded = false;

  @override
  void initState() {
    super.initState();
    _language = _initialDisplayLanguage();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    await _themeManager.loadThemes();
    setState(() => _themesLoaded = true);
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

  void _changeThemeOption(String themeId) {
    if (!_themeManager.setThemeById(themeId)) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_themesLoaded) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final theme = _themeManager.currentTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: theme.themeData,
      darkTheme: theme.themeData,
      themeMode: theme.themeMode,
      home: ClockPage(
        language: _language,
        onLanguageChanged: _changeLanguage,
        theme: theme,
        themes: _themeManager.themes,
        onThemeChanged: _changeThemeOption,
      ),
    );
  }
}
