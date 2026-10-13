import 'package:flutter/material.dart';

import '../models/clock_models.dart';
import '../models/theme_model.dart';

class ClockHeaderActions extends StatelessWidget {
  const ClockHeaderActions({
    super.key,
    required this.language,
    required this.themeId,
    required this.onLanguageSelected,
    required this.onThemeSelected,
    required this.languageTooltip,
    required this.themeTooltip,
    required this.themeLabel,
    required this.themes,
  });

  final DisplayLanguage language;
  final String themeId;
  final ValueChanged<DisplayLanguage> onLanguageSelected;
  final ValueChanged<String> onThemeSelected;
  final String languageTooltip;
  final String themeTooltip;
  final String Function(AppThemeConfig) themeLabel;
  final List<AppThemeConfig> themes;

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
        PopupMenuButton<String>(
          padding: const EdgeInsets.all(6),
          iconSize: 22,
          tooltip: themeTooltip,
          icon: const Icon(Icons.palette_outlined),
          onSelected: onThemeSelected,
          itemBuilder: (context) => themes.map((theme) {
            return PopupMenuItem<String>(
              value: theme.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      themeLabel(theme),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
