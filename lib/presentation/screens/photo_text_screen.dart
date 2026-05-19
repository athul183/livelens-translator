import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/translation_history.dart';
import '../../providers/history_provider.dart';
import '../../providers/photo_capture_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../widgets/common_widgets.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class PhotoTextScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const PhotoTextScreen({super.key, required this.imagePath});

  @override
  ConsumerState<PhotoTextScreen> createState() => _PhotoTextScreenState();
}

class _PhotoTextScreenState extends ConsumerState<PhotoTextScreen>
    with SingleTickerProviderStateMixin {
  /// Whether the translated text overlay is currently shown on the image.
  bool _showOverlay = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleOverlay(bool hasText) {
    if (!hasText) return;
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) {
      _fadeCtrl.forward();
    } else {
      _fadeCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(photoCaptureProvider);
    final settings = ref.watch(appSettingsProvider);
    final hasText = captureState.status == PhotoCaptureStatus.done &&
        captureState.hasText;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context, ref, captureState),
      body: Column(
        children: [
          // ── Interactive image with overlay ──
          _ImageOverlayPanel(
            imagePath: widget.imagePath,
            captureState: captureState,
            showOverlay: _showOverlay,
            fadeAnim: _fadeAnim,
            hasText: hasText,
            onTap: () => _toggleOverlay(hasText),
          ),

          // ── Content below ──
          Expanded(
            child: _buildContent(context, ref, captureState, settings),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, PhotoCaptureState captureState) {
    final hasSelected = captureState.textItems.any((t) => t.isSelected);
    return AppBar(
      backgroundColor: AppTheme.surface,
      title: const Text('Photo to Text'),
      actions: [
        if (captureState.status == PhotoCaptureStatus.done &&
            captureState.hasText) ...[
          TextButton(
            onPressed: () {
              final allSelected =
                  captureState.textItems.every((t) => t.isSelected);
              ref
                  .read(photoCaptureProvider.notifier)
                  .toggleSelectAll(!allSelected);
            },
            child: Text(
              captureState.textItems.every((t) => t.isSelected)
                  ? 'None'
                  : 'All',
              style: const TextStyle(color: AppTheme.primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy selected',
            onPressed: hasSelected
                ? () {
                    Clipboard.setData(ClipboardData(
                        text: captureState.selectedTranslatedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share selected',
            onPressed: hasSelected
                ? () => Share.share(captureState.selectedTranslatedText)
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      PhotoCaptureState captureState, AppSettingsState settings) {
    switch (captureState.status) {
      case PhotoCaptureStatus.processing:
        return _ProcessingView(progress: captureState.processingProgress);

      case PhotoCaptureStatus.error:
        return _ErrorView(
          message: captureState.errorMessage ?? 'Processing failed',
          onRetry: () {
            ref
                .read(photoCaptureProvider.notifier)
                .processPhoto(File(widget.imagePath));
          },
        );

      case PhotoCaptureStatus.done:
        return captureState.hasText
            ? _TextResultList(
                items: captureState.textItems,
                settings: settings,
                onToggle: (i) =>
                    ref.read(photoCaptureProvider.notifier).toggleSelection(i),
                onSaveToHistory: (item) =>
                    _saveToHistory(context, ref, item, settings),
                onSpeak: (text) {
                  final tts = ref.read(ttsServiceProvider);
                  tts.speak(text, language: settings.targetLanguage);
                },
              )
            : const _NoTextView();

      default:
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
    }
  }

  void _saveToHistory(BuildContext context, WidgetRef ref, _TextItem item,
      AppSettingsState settings) {
    ref.read(historyProvider.notifier).addHistory(
          TranslationHistory(
            originalText: item.original,
            translatedText: item.translated,
            sourceLanguage: settings.sourceLanguage,
            targetLanguage: settings.targetLanguage,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to history!')),
    );
  }
}

// ─── Image + Overlay Panel ────────────────────────────────────────────────────

class _ImageOverlayPanel extends StatefulWidget {
  final String imagePath;
  final PhotoCaptureState captureState;
  final bool showOverlay;
  final Animation<double> fadeAnim;
  final bool hasText;
  final VoidCallback onTap;

  const _ImageOverlayPanel({
    required this.imagePath,
    required this.captureState,
    required this.showOverlay,
    required this.fadeAnim,
    required this.hasText,
    required this.onTap,
  });

  @override
  State<_ImageOverlayPanel> createState() => _ImageOverlayPanelState();
}

class _ImageOverlayPanelState extends State<_ImageOverlayPanel> {
  Size _imageNaturalSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _imageNaturalSize =
            Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBoundingBoxes = widget.captureState.textItems
        .any((t) => t.boundingBox != Rect.zero);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 260,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base image
            Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),

            // Translated text overlay (fades in/out on tap)
            if (widget.hasText && hasBoundingBoxes)
              FadeTransition(
                opacity: widget.fadeAnim,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return CustomPaint(
                      painter: _TranslationOverlayPainter(
                        items: widget.captureState.textItems,
                        imageNaturalSize: _imageNaturalSize,
                        widgetSize: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Tap hint badge
            if (widget.hasText)
              Positioned(
                bottom: 10,
                right: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.showOverlay
                        ? AppTheme.primary.withValues(alpha: 0.9)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.showOverlay
                          ? AppTheme.primary
                          : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.showOverlay
                            ? Icons.visibility_off_rounded
                            : Icons.translate_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.showOverlay ? 'Hide overlay' : 'Tap to translate',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // "No bounding box" fallback hint
            if (widget.hasText && !hasBoundingBoxes && !widget.showOverlay)
              const Positioned(
                bottom: 10,
                right: 10,
                child: _HintBadge(label: 'See list below'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Overlay Painter ──────────────────────────────────────────────────────────

/// Paints translated text rectangles over the original text positions,
/// scaled to fit the BoxFit.contain layout of the image widget.
class _TranslationOverlayPainter extends CustomPainter {
  final List<PhotoTextItem> items;
  final Size imageNaturalSize;
  final Size widgetSize;

  _TranslationOverlayPainter({
    required this.items,
    required this.imageNaturalSize,
    required this.widgetSize,
  });

  /// Computes the offset and scale of a BoxFit.contain image inside [widgetSize].
  ({double scale, double dx, double dy}) _fitContain() {
    if (imageNaturalSize.isEmpty || widgetSize.isEmpty) {
      return (scale: 1.0, dx: 0.0, dy: 0.0);
    }
    final scaleW = widgetSize.width / imageNaturalSize.width;
    final scaleH = widgetSize.height / imageNaturalSize.height;
    final scale = scaleW < scaleH ? scaleW : scaleH;
    final dx = (widgetSize.width - imageNaturalSize.width * scale) / 2;
    final dy = (widgetSize.height - imageNaturalSize.height * scale) / 2;
    return (scale: scale, dx: dx, dy: dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fit = _fitContain();

    for (final item in items) {
      if (item.boundingBox == Rect.zero) continue;

      // Scale bounding box from image pixels → widget pixels
      final scaledRect = Rect.fromLTRB(
        item.boundingBox.left * fit.scale + fit.dx,
        item.boundingBox.top * fit.scale + fit.dy,
        item.boundingBox.right * fit.scale + fit.dx,
        item.boundingBox.bottom * fit.scale + fit.dy,
      );

      // --- Background fill (opaque cover of original text) ---
      final bgPaint = Paint()
        ..color = const Color(0xE6121828) // dark navy, 90 % opaque
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(4)),
        bgPaint,
      );

      // --- Accent left border ---
      canvas.drawRect(
        Rect.fromLTWH(scaledRect.left, scaledRect.top, 3, scaledRect.height),
        Paint()..color = AppTheme.accent,
      );

      // --- Translated text ---
      final fontSize = (scaledRect.height * 0.55).clamp(9.0, 16.0);
      final tp = TextPainter(
        text: TextSpan(
          text: item.translatedText,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 3,
      )..layout(maxWidth: (scaledRect.width - 8).clamp(30.0, 400.0));

      // Vertically centre the text inside the rect
      final textOffsetY =
          scaledRect.top + (scaledRect.height - tp.height) / 2;
      tp.paint(canvas, Offset(scaledRect.left + 5, textOffsetY));
    }
  }

  @override
  bool shouldRepaint(_TranslationOverlayPainter old) =>
      old.items != items ||
      old.imageNaturalSize != imageNaturalSize ||
      old.widgetSize != widgetSize;
}

// ─── Small helper badge ───────────────────────────────────────────────────────

class _HintBadge extends StatelessWidget {
  final String label;
  const _HintBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style:
            const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

// ─── Processing / Error / No-text views ──────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final double progress;
  const _ProcessingView({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (_, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.document_scanner,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            pct < 40
                ? 'Reading image…'
                : pct < 70
                    ? 'Recognizing text…'
                    : 'Translating…',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '$pct%',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 64),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Retry',
              icon: Icons.refresh,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTextView extends StatelessWidget {
  const _NoTextView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.text_fields_rounded,
              size: 72, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'No text detected',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try capturing a photo with clear,\nwell-lit text.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Text result list (unchanged) ─────────────────────────────────────────────

class _TextItem {
  final String original;
  final String translated;
  const _TextItem({required this.original, required this.translated});
}

class _TextResultList extends StatelessWidget {
  final List<PhotoTextItem> items;
  final AppSettingsState settings;
  final ValueChanged<int> onToggle;
  final void Function(_TextItem item) onSaveToHistory;
  final ValueChanged<String> onSpeak;

  const _TextResultList({
    required this.items,
    required this.settings,
    required this.onToggle,
    required this.onSaveToHistory,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.format_list_bulleted,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${items.length} text block${items.length == 1 ? '' : 's'} detected',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.where((t) => t.isSelected).length} selected',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return _TextBlockCard(
                index: index,
                item: item,
                onToggle: () => onToggle(index),
                onCopy: () {
                  Clipboard.setData(
                      ClipboardData(text: item.translatedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied!')),
                  );
                },
                onShare: () => Share.share(item.translatedText),
                onSpeak: () => onSpeak(item.translatedText),
                onSave: () => onSaveToHistory(_TextItem(
                  original: item.originalText,
                  translated: item.translatedText,
                )),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TextBlockCard extends StatelessWidget {
  final int index;
  final PhotoTextItem item;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSpeak;
  final VoidCallback onSave;

  const _TextBlockCard({
    required this.index,
    required this.item,
    required this.onToggle,
    required this.onCopy,
    required this.onShare,
    required this.onSpeak,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: item.isSelected
            ? AppTheme.primary.withValues(alpha: 0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isSelected ? AppTheme.primary : AppTheme.surfaceLight,
          width: item.isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isSelected
                          ? AppTheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: item.isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        width: 1.5,
                      ),
                    ),
                    child: item.isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.originalText,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                        child: const Divider(
                            color: AppTheme.surfaceLight, height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: AppTheme.accent.withValues(alpha: 0.7),
                      ),
                    ),
                    Expanded(
                        child: const Divider(
                            color: AppTheme.surfaceLight, height: 1)),
                  ],
                ),
              ),
              Text(
                item.translatedText,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniAction(
                      icon: Icons.volume_up_rounded,
                      label: 'Speak',
                      onTap: onSpeak),
                  const SizedBox(width: 6),
                  _MiniAction(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      onTap: onCopy),
                  const SizedBox(width: 6),
                  _MiniAction(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: onShare),
                  const SizedBox(width: 6),
                  _MiniAction(
                      icon: Icons.bookmark_add_rounded,
                      label: 'Save',
                      onTap: onSave,
                      color: AppTheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.surfaceLight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
