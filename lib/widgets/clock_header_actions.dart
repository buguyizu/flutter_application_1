import 'package:flutter/material.dart';

import '../models/clock_models.dart';

class ClockHeaderActions extends StatelessWidget {
  const ClockHeaderActions({
    super.key,
    required this.language,
    required this.themeOption,
    required this.onLanguageSelected,
    required this.onThemeSelected,
    required this.languageTooltip,
    required this.themeTooltip,
    required this.themeLabel,
  });

  final DisplayLanguage language;
  final AppThemeOption themeOption;
  final ValueChanged<DisplayLanguage> onLanguageSelected;
  final ValueChanged<AppThemeOption> onThemeSelected;
  final String languageTooltip;
  final String themeTooltip;
  final String Function(AppThemeOption) themeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<DisplayLanguage>(
          padding: const EdgeInsets.all(6),
          iconSize: 22,
          constraints: const BoxConstraints(minWidth: 176),
          tooltip: languageTooltip,
          icon: const Icon(Icons.language),
          onSelected: onLanguageSelected,
          itemBuilder: (context) => [
            CheckedPopupMenuItem(
              value: DisplayLanguage.chinese,
              checked: language == DisplayLanguage.chinese,
              child: const Text('简体中文'),
            ),
            CheckedPopupMenuItem(
              value: DisplayLanguage.traditionalChinese,
              checked: language == DisplayLanguage.traditionalChinese,
              child: const Text('繁體中文'),
            ),
            CheckedPopupMenuItem(
              value: DisplayLanguage.english,
              checked: language == DisplayLanguage.english,
              child: const Text('English'),
            ),
            CheckedPopupMenuItem(
              value: DisplayLanguage.japanese,
              checked: language == DisplayLanguage.japanese,
              child: const Text('日本語'),
            ),
          ],
        ),
        PopupMenuButton<AppThemeOption>(
          padding: const EdgeInsets.all(6),
          iconSize: 22,
          tooltip: themeTooltip,
          icon: const Icon(Icons.palette_outlined),
          onSelected: onThemeSelected,
          itemBuilder: (context) => AppThemeOption.values
              .map(
                (option) => CheckedPopupMenuItem<AppThemeOption>(
                  value: option,
                  checked: themeOption == option,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: option.preset.seedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(themeLabel(option)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
