import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/language_utils.dart';
import '../../core/theme/app_theme.dart';

class LanguageSelectorSheet extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String> onSelected;
  final String title;

  const LanguageSelectorSheet({
    super.key,
    required this.selectedCode,
    required this.onSelected,
    this.title = 'Select Language',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: AppConstants.supportedLanguages.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final code =
                    AppConstants.supportedLanguages.keys.elementAt(index);
                final name = AppConstants.supportedLanguages[code]!;
                final flag = languageFlag(code);
                final isSelected = code == selectedCode;

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    code.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    onSelected(code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String selectedCode,
    required ValueChanged<String> onSelected,
    String title = 'Select Language',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageSelectorSheet(
        selectedCode: selectedCode,
        onSelected: onSelected,
        title: title,
      ),
    );
  }
}
