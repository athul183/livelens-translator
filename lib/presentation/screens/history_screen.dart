import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/language_utils.dart';
import '../../domain/entities/translation_history.dart';
import '../../providers/history_provider.dart';
import '../../providers/service_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: AppTheme.surface,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: history.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return _HistoryCard(
                  item: item,
                  onDelete: () =>
                      ref.read(historyProvider.notifier).deleteHistory(item.id),
                  onFavorite: () =>
                      ref.read(historyProvider.notifier).toggleFavorite(item.id),
                  onSpeak: () {
                    final tts = ref.read(ttsServiceProvider);
                    tts.speak(item.translatedText,
                        language: item.targetLanguage);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off,
              size: 72, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'No history yet',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Translate text using the camera\nto save your history here.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear History'),
        content: const Text('Delete all translation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(historyProvider.notifier).clearAll();
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final TranslationHistory item;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onSpeak;

  const _HistoryCard({
    required this.item,
    required this.onDelete,
    required this.onFavorite,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${languageFlag(item.sourceLanguage)} ${languageDisplayName(item.sourceLanguage)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 12,
                        color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${languageFlag(item.targetLanguage)} ${languageDisplayName(item.targetLanguage)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatDateTime(item.timestamp),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.originalText,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                item.translatedText,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SmallAction(
                    icon: Icons.volume_up_rounded,
                    onTap: onSpeak,
                  ),
                  const SizedBox(width: 8),
                  _SmallAction(
                    icon: Icons.copy_rounded,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: item.translatedText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied!')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _SmallAction(
                    icon: Icons.share_rounded,
                    onTap: () => Share.share(item.translatedText),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onFavorite,
                    child: Icon(
                      item.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: item.isFavorite
                          ? Colors.amber
                          : AppTheme.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.error, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 16),
      ),
    );
  }
}
