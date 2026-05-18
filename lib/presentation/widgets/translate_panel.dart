import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/language_utils.dart';
import '../../providers/settings_provider.dart';
import 'language_selector_sheet.dart';

class TranslatePanel extends StatelessWidget {
  final AppSettingsState settings;
  final VoidCallback onSwap;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;

  const TranslatePanel({
    super.key,
    required this.settings,
    required this.onSwap,
    required this.onSourceChanged,
    required this.onTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => LanguageSelectorSheet.show(
                context: context,
                selectedCode: settings.sourceLanguage,
                onSelected: onSourceChanged,
                title: 'Source Language',
              ),
              child: _LanguageChip(
                flag: languageFlag(settings.sourceLanguage),
                name: languageDisplayName(settings.sourceLanguage),
                sublabel: settings.autoDetect ? 'Auto' : null,
              ),
            ),
          ),

          GestureDetector(
            onTap: onSwap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: () => LanguageSelectorSheet.show(
                context: context,
                selectedCode: settings.targetLanguage,
                onSelected: onTargetChanged,
                title: 'Target Language',
              ),
              child: _LanguageChip(
                flag: languageFlag(settings.targetLanguage),
                name: languageDisplayName(settings.targetLanguage),
                alignRight: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String flag;
  final String name;
  final String? sublabel;
  final bool alignRight;

  const _LanguageChip({
    required this.flag,
    required this.name,
    this.sublabel,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight) ...[
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (alignRight) ...[
              const SizedBox(width: 6),
              Text(flag, style: const TextStyle(fontSize: 18)),
            ],
          ],
        ),
        if (sublabel != null)
          Text(
            sublabel!,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 8 : 4,
        right: alignRight ? 4 : 8,
      ),
      child: content,
    );
  }
}
