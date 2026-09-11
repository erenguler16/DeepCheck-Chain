import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// RADAR PAİNTER – Sistem durumu sayfası için dönen radar
// ═══════════════════════════════════════════════════════════════════

class RadarWidget extends StatefulWidget {
  final double size;
  final bool isOnline;

  const RadarWidget({
    super.key,
    this.size = 220,
    this.isOnline = false,
  });

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadarPainter(
            angle: _controller.value * 2 * math.pi,
            isOnline: widget.isOnline,
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final bool isOnline;

  _RadarPainter({required this.angle, required this.isOnline});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final Color radarColor = isOnline ? AppColors.neonGreen : AppColors.neonRed;

    // Arka plan daireleri (konsantrik)
    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      final circlePaint = Paint()
        ..color = radarColor.withAlpha(15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(center, r, circlePaint);
    }

    // Çapraz çizgiler
    final crossPaint = Paint()
      ..color = radarColor.withAlpha(12)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crossPaint,
    );
    // Çaprazlar
    canvas.drawLine(
      Offset(center.dx - radius * 0.707, center.dy - radius * 0.707),
      Offset(center.dx + radius * 0.707, center.dy + radius * 0.707),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.707, center.dy - radius * 0.707),
      Offset(center.dx - radius * 0.707, center.dy + radius * 0.707),
      crossPaint,
    );

    // Tarama ışını (sweep gradient)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 0.8,
        endAngle: angle,
        colors: [
          Colors.transparent,
          radarColor.withAlpha(5),
          radarColor.withAlpha(40),
        ],
        transform: GradientRotation(angle - 0.8),
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, sweepPaint);

    // Tarama çizgisi
    final lineEnd = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final linePaint = Paint()
      ..color = radarColor.withAlpha(100)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, lineEnd, linePaint);

    // Ping noktaları (sabit konumlar)
    if (isOnline) {
      final pings = [
        Offset(center.dx + radius * 0.4, center.dy - radius * 0.3),
        Offset(center.dx - radius * 0.5, center.dy + radius * 0.2),
        Offset(center.dx + radius * 0.15, center.dy + radius * 0.6),
      ];

      for (final ping in pings) {
        // Ping'in radar çizgisine yakınlığını hesapla
        final pingAngle = math.atan2(
          ping.dy - center.dy,
          ping.dx - center.dx,
        );
        var diff = (angle - pingAngle) % (2 * math.pi);
        if (diff < 0) diff += 2 * math.pi;

        double alpha = 0;
        if (diff < 1.0) {
          alpha = (1.0 - diff) * 200;
        }

        if (alpha > 10) {
          final dotPaint = Paint()
            ..color = radarColor.withAlpha(alpha.toInt().clamp(0, 255));
          canvas.drawCircle(ping, 4, dotPaint);

          // Glow
          final glowPaint = Paint()
            ..color = radarColor.withAlpha((alpha * 0.3).toInt().clamp(0, 255))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(ping, 8, glowPaint);
        }
      }
    }

    // Merkez noktası
    final centerDotPaint = Paint()
      ..color = radarColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawCircle(center, 4, centerDotPaint);
    canvas.drawCircle(center, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
