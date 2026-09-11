import 'package:flutter/material.dart';
import '../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// SİBER ETKİLEŞİMLİ BUTON – Neon glow + press-scale efekti
// ═══════════════════════════════════════════════════════════════════

class CyberButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color baseColor;
  final bool isOutline;

  const CyberButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.baseColor = AppColors.gold,
    this.isOutline = false,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _scale = 0.95),
      onTapUp: isDisabled ? null : (_) => setState(() => _scale = 1.0),
      onTapCancel: isDisabled ? null : () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: widget.isOutline
                  ? Colors.transparent
                  : widget.baseColor.withAlpha(isDisabled ? 80 : 220),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: widget.baseColor.withAlpha(isDisabled ? 60 : 180),
                width: widget.isOutline ? 2 : 1.5,
              ),
              boxShadow: widget.isOutline || isDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: widget.baseColor.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: widget.baseColor.withAlpha(30),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isOutline
                      ? widget.baseColor
                      : Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isOutline
                            ? widget.baseColor
                            : Colors.black87,
                        fontFamily: AppTextStyles.fontMono,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
