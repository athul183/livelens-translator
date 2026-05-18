import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/language_utils.dart';
import '../../providers/settings_provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/language_selector_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.translate, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConstants.appName,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('v${AppConstants.appVersion}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionTitle('Translation'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Source Language',
                  trailing: Text(
                    '${languageFlag(settings.sourceLanguage)} ${languageDisplayName(settings.sourceLanguage)}',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500),
                  ),
                  onTap: () => LanguageSelectorSheet.show(
                    context: context,
                    selectedCode: settings.sourceLanguage,
                    onSelected: (code) => ref
                        .read(appSettingsProvider.notifier)
                        .setSourceLanguage(code),
                    title: 'Source Language',
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.translate,
                  title: 'Target Language',
                  trailing: Text(
                    '${languageFlag(settings.targetLanguage)} ${languageDisplayName(settings.targetLanguage)}',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500),
                  ),
                  onTap: () => LanguageSelectorSheet.show(
                    context: context,
                    selectedCode: settings.targetLanguage,
                    onSelected: (code) => ref
                        .read(appSettingsProvider.notifier)
                        .setTargetLanguage(code),
                    title: 'Target Language',
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.auto_awesome,
                  title: 'Auto-detect Language',
                  trailing: Switch.adaptive(
                    value: settings.autoDetect,
                    onChanged: (_) => ref
                        .read(appSettingsProvider.notifier)
                        .toggleAutoDetect(),
                    activeColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle('Accessibility'),
          Card(
            child: _SettingsTile(
              icon: Icons.volume_up,
              title: 'Text-to-Speech',
              trailing: Switch.adaptive(
                value: settings.ttsEnabled,
                onChanged: (_) =>
                    ref.read(appSettingsProvider.notifier).toggleTts(),
                activeColor: AppTheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle('History'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.history,
                  title: 'Saved Translations',
                  trailing: Text(
                    '${history.length}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.delete_sweep,
                  title: 'Clear All History',
                  titleColor: AppTheme.error,
                  iconColor: AppTheme.error,
                  onTap: () => _confirmClearHistory(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Built with Flutter + ML Kit',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear History'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(historyProvider.notifier).clearAll();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppTheme.textPrimary,
          fontSize: 15,
        ),
      ),
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary)
          : null),
      onTap: onTap,
    );
  }
}
