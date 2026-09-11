import 'package:flutter/material.dart';
import '../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// LAZER TARAMA OVERLAY – Yükleme sırasında fütüristik tarama
// ═══════════════════════════════════════════════════════════════════

class ScanningOverlay extends StatefulWidget {
  final bool isScanning;

  const ScanningOverlay({
    super.key,
    required this.isScanning,
  });

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(ScanningOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Koyu overlay
            Container(color: Colors.black.withAlpha(180)),

            // Lazer tarama çizgisi
            Positioned(
              top: _controller.value * MediaQuery.of(context).size.height * 0.5,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.neonBlue.withAlpha(200),
                          AppColors.gold,
                          AppColors.neonBlue.withAlpha(200),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonBlue.withAlpha(120),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: AppColors.gold.withAlpha(60),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Merkez durum metni
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dönen ikili halka
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.gold.withAlpha(180),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.neonBlue.withAlpha(120),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.memory,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'YAPAY ZEKA TARIYOR...',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: AppColors.gold.withAlpha(100),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bloklar Mühürleniyor...',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 11,
                      color: AppColors.neonBlue.withAlpha(200),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
