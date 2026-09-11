import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'main_shell.dart';

// ═══════════════════════════════════════════════════════════════════
// SPLASH SCREEN – Blokzincir Küp Birleşme Animasyonu
// Teknofest Blokzincir Logosu Konsepti:
// Etraftan gelen küçük küpler ekranın merkezinde birleşerek
// parlayan izometrik bir blokzincir amblemine dönüşür.
// ═══════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_MiniCubeParticle> _particles = [];
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _createParticles();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToMain();
      }
    });
  }

  void _createParticles() {
    final random = math.Random(42); // Sabit tohum ile tutarlı estetik
    const int count = 32;

    for (int i = 0; i < count; i++) {
      // Ekran dışından geliş açısı ve mesafesi
      final double angle = (i / count) * 2 * math.pi + (random.nextDouble() - 0.5) * 0.4;
      final double distance = 320.0 + random.nextDouble() * 220.0;

      final double startX = math.cos(angle) * distance;
      final double startY = math.sin(angle) * distance;

      // Hedef blok indeksi (7 ana bloktan biri)
      final int targetBlockIndex = i % 7;
      final double delay = (random.nextDouble() * 0.35); // 0.0 - 0.35 arası gecikme
      final double size = 8.0 + random.nextDouble() * 10.0;

      final bool isGold = random.nextDouble() > 0.35;

      _particles.add(
        _MiniCubeParticle(
          startX: startX,
          startY: startY,
          targetBlockIndex: targetBlockIndex,
          delay: delay,
          size: size,
          isGold: isGold,
          spinSpeed: (random.nextDouble() - 0.5) * 6.0,
        ),
      );
    }
  }

  void _goToMain() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToMain, // İstenirse dokunarak geçilebilir
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arka Plan Hafif Radyal Parıltı
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final glowProgress = (_controller.value * 1.5).clamp(0.0, 1.0);
                  return CustomPaint(
                    painter: _BackgroundGlowPainter(glowProgress),
                  );
                },
              ),
            ),

            // Blokzincir Küp Birleşme Animasyonu (CustomPainter)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(screenSize.width, screenSize.height),
                  painter: _BlockchainLogoPainter(
                    progress: _controller.value,
                    particles: _particles,
                  ),
                );
              },
            ),

            // Logo & Marka Metinleri (Animasyonun son fazında parıldayarak açılır)
            Positioned(
              bottom: screenSize.height * 0.12,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // 0.55'ten sonra yumuşakça görünmeye başlasın
                  final textProgress = ((_controller.value - 0.55) / 0.35)
                      .clamp(0.0, 1.0);
                  final curvedVal = Curves.easeOutCubic.transform(textProgress);

                  return Opacity(
                    opacity: curvedVal,
                    child: Transform.translate(
                      offset: Offset(0, (1.0 - curvedVal) * 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TEKNOFEST Etiketi
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.gold.withAlpha(80),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'TEKNOFEST · BLOKZİNCİR',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontMono,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // DEEPCHECK
                          Text(
                            'DEEPCHECK',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontMono,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8.0,
                              color: AppColors.gold,
                              shadows: [
                                Shadow(
                                  color: AppColors.gold.withAlpha(160),
                                  blurRadius: 24,
                                ),
                                Shadow(
                                  color: AppColors.neonBlue.withAlpha(100),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          // CHAIN
                          Text(
                            '─── CHAIN ───',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontMono,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8.0,
                              color: AppColors.neonBlue,
                              shadows: [
                                Shadow(
                                  color: AppColors.neonBlue.withAlpha(140),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Slogan
                          Text(
                            'Sıfır Güven · Sarsılmaz Mühür',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontMono,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              letterSpacing: 2.5,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // İlerleme çubuğu
                          SizedBox(
                            width: 140,
                            height: 2,
                            child: LinearProgressIndicator(
                              value: _controller.value,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Atla Butonu (Sağ üst)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: GestureDetector(
                onTap: _goToMain,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(120),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gold.withAlpha(30)),
                  ),
                  child: Text(
                    'ATLA ❯',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Parçacık veri modeli ──
class _MiniCubeParticle {
  final double startX, startY;
  final int targetBlockIndex;
  final double delay;
  final double size;
  final bool isGold;
  final double spinSpeed;

  _MiniCubeParticle({
    required this.startX,
    required this.startY,
    required this.targetBlockIndex,
    required this.delay,
    required this.size,
    required this.isGold,
    required this.spinSpeed,
  });
}

// ── Arka Plan Glow Painter ──
class _BackgroundGlowPainter extends CustomPainter {
  final double progress;

  _BackgroundGlowPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withAlpha((45 * progress).toInt()),
          AppColors.neonBlue.withAlpha((25 * progress).toInt()),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.65));

    canvas.drawCircle(center, size.width * 0.65, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundGlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Ana Blokzincir Logo Ressamı (CustomPainter) ──
class _BlockchainLogoPainter extends CustomPainter {
  final double progress;
  final List<_MiniCubeParticle> particles;

  _BlockchainLogoPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    // Ana Blokzincir Ambleminin 7 Düğüm Konumu (Teknofest Blokzincir Logosu Heksagonal Yapısı)
    // 0: Merkez
    // 1: Üst, 2: Üst-Sağ, 3: Alt-Sağ, 4: Alt, 5: Alt-Sol, 6: Üst-Sol
    const double radius = 62.0;
    const double blockSize = 26.0;

    // Hafif 3D salınım / süzülme (progress > 0.7 olduğunda)
    final double floatProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    final double floatOffsetY = math.sin(progress * 2 * math.pi) * 4.0 * floatProgress;

    final List<Offset> blockCenters = [
      center + Offset(0, floatOffsetY), // 0: Merkez
      center + Offset(0, -radius + floatOffsetY), // 1: Üst
      center + Offset(radius * 0.866, -radius * 0.5 + floatOffsetY), // 2: Üst-Sağ
      center + Offset(radius * 0.866, radius * 0.5 + floatOffsetY), // 3: Alt-Sağ
      center + Offset(0, radius + floatOffsetY), // 4: Alt
      center + Offset(-radius * 0.866, radius * 0.5 + floatOffsetY), // 5: Alt-Sol
      center + Offset(-radius * 0.866, -radius * 0.5 + floatOffsetY), // 6: Üst-Sol
    ];

    // ── 1. FAZ: Etraftan Gelen Uçan Küçük Küpler (0.0 -> 0.65) ──
    for (final p in particles) {
      final double pProgress = ((progress - p.delay) / (0.65 - p.delay)).clamp(0.0, 1.0);

      if (pProgress > 0.0 && pProgress < 1.0) {
        final double curve = Curves.easeInOutCubic.transform(pProgress);
        final target = blockCenters[p.targetBlockIndex];

        // Yay çizerek gelsin
        final currentX = p.startX + (target.dx - p.startX) * curve;
        final currentY = p.startY + (target.dy - p.startY) * curve;
        final currentPos = Offset(currentX, currentY);

        // Yaklaştıkça küçülüp asıl bloğa entegre olsun
        final currentSize = p.size * (1.0 - curve * 0.4);
        final double alpha = (curve * 2.0).clamp(0.0, 1.0);

        _drawIsometricCube(
          canvas: canvas,
          center: currentPos,
          size: currentSize,
          isGold: p.isGold,
          alpha: alpha,
          isEmblem: false,
        );
      }
    }

    // ── 2. FAZ: Blokzincir Bağlantı Çizgileri / Zincirleri (0.50 -> 1.0) ──
    if (progress >= 0.50) {
      final double chainProgress = ((progress - 0.50) / 0.35).clamp(0.0, 1.0);
      final double chainCurve = Curves.easeOutQuad.transform(chainProgress);

      _drawBlockchainConnections(
        canvas: canvas,
        blockCenters: blockCenters,
        progress: chainCurve,
        timeProgress: progress,
      );
    }

    // ── 3. FAZ: Şok Dalgası / Enerji Halkası (0.60 -> 0.95) ──
    if (progress >= 0.60 && progress <= 0.98) {
      final double shockProgress = ((progress - 0.60) / 0.38).clamp(0.0, 1.0);
      final double shockRadius = shockProgress * (radius * 2.6);
      final double shockAlpha = (1.0 - shockProgress).clamp(0.0, 1.0);

      final shockPaint = Paint()
        ..color = AppColors.gold.withAlpha((180 * shockAlpha).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - shockProgress * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

      canvas.drawCircle(blockCenters[0], shockRadius, shockPaint);

      final cyanShockPaint = Paint()
        ..color = AppColors.neonBlue.withAlpha((120 * shockAlpha).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(blockCenters[0], shockRadius * 0.85, cyanShockPaint);
    }

    // ── 4. FAZ: Ana Blokların Birleşip Kilitlenmesi (0.45 -> 1.0) ──
    if (progress >= 0.45) {
      for (int i = 0; i < blockCenters.length; i++) {
        // Blokların sırayla parıldayarak oluşumu (Merkez önce, sonra dıştakiler)
        final double blockDelay = i == 0 ? 0.45 : 0.48 + (i * 0.025);
        final double bProgress = ((progress - blockDelay) / 0.28).clamp(0.0, 1.0);

        if (bProgress > 0) {
          final double bScale = Curves.elasticOut.transform(bProgress);
          final bool isCenter = (i == 0);

          _drawIsometricCube(
            canvas: canvas,
            center: blockCenters[i],
            size: (isCenter ? blockSize * 1.25 : blockSize) * bScale,
            isGold: isCenter || (i % 2 == 1),
            alpha: bProgress.clamp(0.0, 1.0),
            isEmblem: true,
            hasCoreGlow: isCenter,
          );
        }
      }
    }
  }

  // ── Blokzincir Bağlantılarını Çizen Fonksiyon ──
  void _drawBlockchainConnections({
    required Canvas canvas,
    required List<Offset> blockCenters,
    required double progress,
    required double timeProgress,
  }) {
    final Paint linePaint = Paint()
      ..color = AppColors.neonBlue.withAlpha((140 * progress).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Paint glowLinePaint = Paint()
      ..color = AppColors.gold.withAlpha((100 * progress).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

    final center = blockCenters[0];

    // Merkezden her dış bloğa bağlantı
    for (int i = 1; i <= 6; i++) {
      final target = blockCenters[i];
      final currentTarget = Offset(
        center.dx + (target.dx - center.dx) * progress,
        center.dy + (target.dy - center.dy) * progress,
      );

      canvas.drawLine(center, currentTarget, glowLinePaint);
      canvas.drawLine(center, currentTarget, linePaint);

      // Çizgi üzerinde hareket eden veri paketi (ışık noktası)
      if (progress >= 0.8) {
        final double packetT = (timeProgress * 3.0 + (i * 0.2)) % 1.0;
        final packetPos = Offset(
          center.dx + (target.dx - center.dx) * packetT,
          center.dy + (target.dy - center.dy) * packetT,
        );
        final packetPaint = Paint()
          ..color = AppColors.goldLight
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
        canvas.drawCircle(packetPos, 2.5, packetPaint);
      }
    }

    // Dış blokların birbirine dairesel bağlantısı (Heksagon kenarları)
    for (int i = 1; i <= 6; i++) {
      final p1 = blockCenters[i];
      final p2 = blockCenters[i == 6 ? 1 : i + 1];

      final currentP2 = Offset(
        p1.dx + (p2.dx - p1.dx) * progress,
        p1.dy + (p2.dy - p1.dy) * progress,
      );

      final outerLinePaint = Paint()
        ..color = AppColors.gold.withAlpha((90 * progress).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawLine(p1, currentP2, outerLinePaint);
    }
  }

  // ── İzometrik 3D Küp Çizen Fonksiyon ──
  void _drawIsometricCube({
    required Canvas canvas,
    required Offset center,
    required double size,
    required bool isGold,
    required double alpha,
    required bool isEmblem,
    bool hasCoreGlow = false,
  }) {
    if (size <= 0.5 || alpha <= 0.01) return;

    // İzometrik projeksiyon sabitleri: cos(30°) = 0.866, sin(30°) = 0.5
    final double dx = size * 0.866025;
    final double dy = size * 0.5;

    // 7 Tepe Noktası:
    final Offset pCenter = center;
    final Offset pTop = Offset(center.dx, center.dy - size);
    final Offset pTopRight = Offset(center.dx + dx, center.dy - dy);
    final Offset pBottomRight = Offset(center.dx + dx, center.dy + dy);
    final Offset pBottom = Offset(center.dx, center.dy + size);
    final Offset pBottomLeft = Offset(center.dx - dx, center.dy + dy);
    final Offset pTopLeft = Offset(center.dx - dx, center.dy - dy);

    // Renk Tanımları (İzometrik 3 Yüzey: Üst ışıklı, Sol orta, Sağ gölgeli)
    final Color topColor = isGold
        ? AppColors.goldLight.withAlpha((235 * alpha).toInt())
        : const Color(0xFF80E8FF).withAlpha((235 * alpha).toInt());

    final Color leftColor = isGold
        ? AppColors.gold.withAlpha((220 * alpha).toInt())
        : AppColors.neonBlue.withAlpha((220 * alpha).toInt());

    final Color rightColor = isGold
        ? AppColors.goldDark.withAlpha((210 * alpha).toInt())
        : const Color(0xFF0075B5).withAlpha((210 * alpha).toInt());

    final Color strokeColor = isGold
        ? Colors.white.withAlpha((180 * alpha).toInt())
        : AppColors.neonBlue.withAlpha((180 * alpha).toInt());

    // 1. Üst Yüzey (Top Face): pTop -> pTopRight -> pCenter -> pTopLeft
    final Path topFace = Path()
      ..moveTo(pTop.dx, pTop.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pCenter.dx, pCenter.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..close();
    canvas.drawPath(topFace, Paint()..color = topColor..style = PaintingStyle.fill);

    // 2. Sol Yüzey (Left Face): pTopLeft -> pCenter -> pBottom -> pBottomLeft
    final Path leftFace = Path()
      ..moveTo(pTopLeft.dx, pTopLeft.dy)
      ..lineTo(pCenter.dx, pCenter.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pBottomLeft.dx, pBottomLeft.dy)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = leftColor..style = PaintingStyle.fill);

    // 3. Sağ Yüzey (Right Face): pCenter -> pTopRight -> pBottomRight -> pBottom
    final Path rightFace = Path()
      ..moveTo(pCenter.dx, pCenter.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = rightColor..style = PaintingStyle.fill);

    // Kenar Çizgileri (Siber Kontur)
    final Paint strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isEmblem ? 1.2 : 0.8;

    canvas.drawPath(topFace, strokePaint);
    canvas.drawPath(leftFace, strokePaint);
    canvas.drawPath(rightFace, strokePaint);

    // Merkez Blok İse Özel Siber Çekirdek Parıltısı
    if (hasCoreGlow) {
      final corePaint = Paint()
        ..color = AppColors.goldLight.withAlpha((200 * alpha).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      canvas.drawCircle(center, size * 0.25, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlockchainLogoPainter oldDelegate) => true;
}
