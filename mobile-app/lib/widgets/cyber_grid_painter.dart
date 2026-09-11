import 'package:flutter/material.dart';
import '../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// SİBER GRİD ARKA PLAN – Tarama efektli ızgara
// ═══════════════════════════════════════════════════════════════════

class CyberGridBackground extends StatefulWidget {
  final Color gridColor;
  final Widget child;

  const CyberGridBackground({
    super.key,
    this.gridColor = AppColors.gold,
    required this.child,
  });

  @override
  State<CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<CyberGridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _CyberGridPainter(
                gridColor: widget.gridColor,
                animationValue: _controller.value,
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  final Color gridColor;
  final double animationValue;

  _CyberGridPainter({
    required this.gridColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Izgara çizgileri
    final gridPaint = Paint()
      ..color = gridColor.withAlpha(8)
      ..strokeWidth = 0.5;

    const double step = 35.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Tarama çizgisi efekti
    final scanY = animationValue * size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          gridColor.withAlpha(25),
          gridColor.withAlpha(40),
          gridColor.withAlpha(25),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, scanY - 60, size.width, 120),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 60, size.width, 120),
      scanPaint,
    );

    // Parlayan köşe noktaları (kesişim)
    final dotPaint = Paint()..color = gridColor.withAlpha(15);
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        double dist = (y - scanY).abs();
        if (dist < 60) {
          double brightness = (1.0 - dist / 60.0) * 0.4;
          dotPaint.color = gridColor.withAlpha((brightness * 255).toInt());
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CyberGridPainter oldDelegate) => true;
}
