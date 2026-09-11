import 'package:flutter/material.dart';
import '../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// NEON SONUÇ KARTI – Yeşil (Gerçek) / Kırmızı (Sahte)
// Glassmorphism + neon glow animasyonu ile belirme
// ═══════════════════════════════════════════════════════════════════

class NeonResultCard extends StatefulWidget {
  final bool isAuthentic;
  final String title;
  final String subtitle;
  final String? hashCode_;
  final String? confidence;

  const NeonResultCard({
    super.key,
    required this.isAuthentic,
    required this.title,
    required this.subtitle,
    this.hashCode_,
    this.confidence,
  });

  @override
  State<NeonResultCard> createState() => _NeonResultCardState();
}

class _NeonResultCardState extends State<NeonResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        widget.isAuthentic ? AppColors.neonGreen : AppColors.neonRed;
    final IconData statusIcon =
        widget.isAuthentic ? Icons.verified : Icons.warning_amber_rounded;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: accentColor.withAlpha(
                (100 * _glowAnimation.value).toInt(),
              ),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(
                  (40 * _glowAnimation.value).toInt(),
                ),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontMono,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontMono,
                            fontSize: 11,
                            color: accentColor.withAlpha(180),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Hash kodu
              if (widget.hashCode_ != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(60),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: accentColor.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHA-256 HASH',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontMono,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.hashCode_!,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontMono,
                          fontSize: 10,
                          color: AppColors.gold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Güven oranı
              if (widget.confidence != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.analytics, size: 14, color: accentColor.withAlpha(150)),
                    const SizedBox(width: 6),
                    Text(
                      'Güven Oranı: ${widget.confidence}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 11,
                        color: accentColor.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
