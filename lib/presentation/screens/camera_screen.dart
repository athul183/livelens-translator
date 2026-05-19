import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/text_block.dart' as domain;
import '../../domain/entities/translation_history.dart';
import '../../providers/camera_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/photo_capture_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/service_providers.dart';
import '../overlays/text_overlay_painter.dart';
import '../widgets/common_widgets.dart';
import '../widgets/translate_panel.dart';
import 'history_screen.dart';
import 'download_manager_screen.dart';
import 'photo_text_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      ref.read(cameraProvider).controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      ref.read(cameraProvider.notifier).initializeCamera(cameras);
    } else {
      ref.read(cameraProvider.notifier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, camState),
      body: Stack(
        children: [
          _buildCameraPreview(camState),

          if (camState.lastOcrResult != null &&
              camState.lastOcrResult!.isNotEmpty)
            _buildOcrOverlay(camState),

          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            left: 0,
            right: 0,
            child: TranslatePanel(
              settings: settings,
              onSwap: () =>
                  ref.read(appSettingsProvider.notifier).swapLanguages(),
              onSourceChanged: (code) =>
                  ref.read(appSettingsProvider.notifier).setSourceLanguage(code),
              onTargetChanged: (code) =>
                  ref.read(appSettingsProvider.notifier).setTargetLanguage(code),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(context, camState, settings),
          ),

          if (camState.isProcessing)
            const Positioned(
              top: 16,
              right: 16,
              child: _ProcessingIndicator(),
            ),

          if (camState.isFrozen)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('FROZEN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CameraState camState) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: camState.status == CameraStatus.ready
                  ? AppTheme.accent
                  : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: (camState.status == CameraStatus.ready
                          ? AppTheme.accent
                          : Colors.red)
                      .withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LiveLens',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DownloadManagerScreen())),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(CameraState camState) {
    if (camState.status == CameraStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              camState.errorMessage ?? 'Camera error',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Retry',
              icon: Icons.refresh,
              onTap: _requestCameraPermission,
            ),
          ],
        ),
      );
    }

    if (camState.status == CameraStatus.initializing ||
        camState.controller == null ||
        !camState.controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return SizedBox.expand(
      child: CameraPreview(camState.controller!),
    );
  }

  Widget _buildOcrOverlay(CameraState camState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _onTapBlock(details.localPosition, camState),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: TextOverlayPainter(
              blocks: camState.lastOcrResult?.blocks ?? [],
            ),
          ),
        );
      },
    );
  }

  void _onTapBlock(Offset tapPos, CameraState camState) {
    final blocks = camState.lastOcrResult?.blocks ?? [];
    for (final block in blocks) {
      if (block.boundingBox.contains(tapPos)) {
        _showBlockDetail(block);
        return;
      }
    }
  }

  void _showBlockDetail(domain.TextBlock block) {
    final settings = ref.read(appSettingsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TextBlockDetailSheet(
        block: block,
        settings: settings,
        onSave: () => _saveToHistory(block, settings),
        onCopy: () {
          Clipboard.setData(ClipboardData(
              text: block.translatedText ?? block.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        },
        onShare: () => Share.share(block.translatedText ?? block.text),
        onSpeak: () {
          final tts = ref.read(ttsServiceProvider);
          tts.speak(block.translatedText ?? block.text,
              language: settings.targetLanguage);
        },
      ),
    );
  }

  void _saveToHistory(domain.TextBlock block, AppSettingsState settings) {
    if (block.translatedText == null) return;
    ref.read(historyProvider.notifier).addHistory(
          TranslationHistory(
            originalText: block.text,
            translatedText: block.translatedText!,
            sourceLanguage: settings.sourceLanguage,
            targetLanguage: settings.targetLanguage,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to history')),
    );
  }

  Widget _buildBottomControls(
      BuildContext context, CameraState camState, AppSettingsState settings) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlowIconButton(
            icon: camState.flashOn ? Icons.flash_on : Icons.flash_off,
            isActive: camState.flashOn,
            color: Colors.amber,
            tooltip: 'Flash',
            onTap: () => ref.read(cameraProvider.notifier).toggleFlash(),
          ),

          GlowIconButton(
            icon: camState.isFrozen ? Icons.play_arrow : Icons.pause,
            isActive: camState.isFrozen,
            color: Colors.orange,
            tooltip: camState.isFrozen ? 'Resume' : 'Freeze',
            onTap: () => ref.read(cameraProvider.notifier).toggleFreeze(),
          ),

          _CaptureButton(
            isCapturing: camState.isCapturing,
            onTap: () => _captureAndNavigate(context, ref),
          ),

          GlowIconButton(
            icon: settings.ttsEnabled ? Icons.volume_up : Icons.volume_off,
            isActive: settings.ttsEnabled,
            color: AppTheme.accent,
            tooltip: 'Text-to-Speech',
            onTap: () => ref.read(appSettingsProvider.notifier).toggleTts(),
          ),

          if (camState.status == CameraStatus.ready)
            _ZoomControl(
              zoom: camState.zoomLevel,
              min: camState.minZoom,
              max: camState.maxZoom,
              onChanged: (z) =>
                  ref.read(cameraProvider.notifier).setZoom(z),
            ),
        ],
      ),
    );
  }

  Future<void> _captureAndNavigate(BuildContext context, WidgetRef ref) async {
    final path = await ref.read(cameraProvider.notifier).capturePhoto();
    if (path == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture photo. Try again.')),
        );
      }
      return;
    }

    ref.read(photoCaptureProvider.notifier).reset();

    if (!context.mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PhotoTextScreen(imagePath: path),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 150));
    ref.read(photoCaptureProvider.notifier).processPhoto(File(path));
  }
}

class _ProcessingIndicator extends StatefulWidget {
  const _ProcessingIndicator();

  @override
  State<_ProcessingIndicator> createState() => _ProcessingIndicatorState();
}

class _ProcessingIndicatorState extends State<_ProcessingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Text('OCR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}

class _ZoomControl extends StatelessWidget {
  final double zoom;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _ZoomControl({
    required this.zoom,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final next = zoom >= max ? min : zoom + 0.5;
        onChanged(next.clamp(min, max));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          '${zoom.toStringAsFixed(1)}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TextBlockDetailSheet extends StatelessWidget {
  final domain.TextBlock block;
  final AppSettingsState settings;
  final VoidCallback onSave;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSpeak;

  const _TextBlockDetailSheet({
    required this.block,
    required this.settings,
    required this.onSave,
    required this.onCopy,
    required this.onShare,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Translation',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Original',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(block.text,
              style: Theme.of(context).textTheme.bodyLarge),
          const Divider(height: 24),
          Text(
            'Translated',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            block.translatedText ?? 'No translation available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ActionButton(
                icon: Icons.volume_up,
                label: 'Speak',
                onTap: () {
                  onSpeak();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  onCopy();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  onShare();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.bookmark_add,
                label: 'Save',
                color: AppTheme.primary,
                onTap: () {
                  onSave();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.surfaceLight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatefulWidget {
  final bool isCapturing;
  final VoidCallback onTap;

  const _CaptureButton({required this.isCapturing, required this.onTap});

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Capture photo & extract text',
      child: GestureDetector(
        onTap: widget.isCapturing ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: widget.isCapturing ? 0.9 : _pulseAnim.value,
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isCapturing
                      ? const LinearGradient(
                          colors: [Colors.grey, Colors.blueGrey])
                      : AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: widget.isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
