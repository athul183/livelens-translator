import 'package:flutter/material.dart';
import '../../domain/entities/text_block.dart';
import '../../core/theme/app_theme.dart';

class TextOverlayPainter extends CustomPainter {
  final List<TextBlock> blocks;
  final bool showBoundingBoxes;

  TextOverlayPainter({
    required this.blocks,
    this.showBoundingBoxes = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    for (final block in blocks) {
      final rect = block.boundingBox;
      if (rect.isEmpty) continue;

      if (showBoundingBoxes) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          boxPaint,
        );
      }

      final textToShow = block.translatedText ?? block.text;
      if (textToShow.isEmpty) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: textToShow,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(blurRadius: 2, color: Colors.black),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 3,
      )..layout(maxWidth: rect.width.clamp(60.0, 300.0));

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - tp.height - 4,
        tp.width + 8,
        tp.height + 4,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        fillPaint,
      );

      canvas.drawRect(
        Rect.fromLTWH(labelRect.left, labelRect.top, 3, labelRect.height),
        Paint()..color = AppTheme.accent,
      );

      tp.paint(canvas, Offset(labelRect.left + 5, labelRect.top + 2));
    }
  }

  @override
  bool shouldRepaint(TextOverlayPainter oldDelegate) =>
      oldDelegate.blocks != blocks;
}
