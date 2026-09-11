import 'package:flutter/material.dart';
import '../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// NEFES ALAN KALKAN BUTONU – Breathing Shield
// Büyük, merkezdeki ana aksiyon butonu
// ═══════════════════════════════════════════════════════════════════

class BreathingShield extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isProcessing;

  const BreathingShield({
    super.key,
    this.onTap,
    this.isProcessing = false,
  });

  @override
  State<BreathingShield> createState() => _BreathingShieldState();
}

class _BreathingShieldState extends State<BreathingShield>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    // Nefes alma animasyonu
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // İşlem sırasında döndürme
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didUpdateWidget(BreathingShield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing && !_rotateController.isAnimating) {
      _rotateController.repeat();
    } else if (!widget.isProcessing && _rotateController.isAnimating) {
      _rotateController.stop();
      _rotateController.reset();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isProcessing ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathAnimation, _rotateController]),
        builder: (context, child) {
          final double scale = widget.isProcessing
              ? 0.95
              : _breathAnimation.value;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withAlpha(40),
                    AppColors.gold.withAlpha(15),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(
                      (30 * _breathAnimation.value).toInt(),
                    ),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: AppColors.gold.withAlpha(
                      (15 * _breathAnimation.value).toInt(),
                    ),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dış halka
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withAlpha(60),
                        width: 2,
                      ),
                    ),
                  ),
                  // İç halka (dönen)
                  Transform.rotate(
                    angle: _rotateController.value * 6.28,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withAlpha(100),
                          width: 1.5,
                        ),
                        gradient: SweepGradient(
                          colors: [
                            AppColors.gold.withAlpha(0),
                            AppColors.gold.withAlpha(50),
                            AppColors.gold.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Merkez ikon
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isProcessing
                            ? Icons.hourglass_top
                            : Icons.shield,
                        size: 44,
                        color: AppColors.gold,
                        shadows: [
                          Shadow(
                            color: AppColors.gold.withAlpha(120),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isProcessing ? 'TARANIYOR...' : 'ZIRHLA',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontMono,
                          fontSize: widget.isProcessing ? 10 : 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: AppColors.gold.withAlpha(100),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
