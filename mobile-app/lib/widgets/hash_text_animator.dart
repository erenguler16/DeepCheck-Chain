import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// HASH TEXT ANİMATÖRÜ – Rastgele karakter değiştirerek
// hash metnini fütüristik şekilde oluşturur
// ═══════════════════════════════════════════════════════════════════

class HashTextAnimator extends StatefulWidget {
  final String targetHash;
  final Duration duration;
  final TextStyle? style;

  const HashTextAnimator({
    super.key,
    required this.targetHash,
    this.duration = const Duration(milliseconds: 2000),
    this.style,
  });

  @override
  State<HashTextAnimator> createState() => _HashTextAnimatorState();
}

class _HashTextAnimatorState extends State<HashTextAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  static const String _chars = '0123456789abcdef';

  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _currentText = widget.targetHash;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addListener(_updateText);
    _controller.forward();
  }

  void _updateText() {
    final progress = _controller.value;
    final target = widget.targetHash;
    final length = target.length;
    final revealed = (length * progress).floor();

    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      if (i < revealed) {
        buffer.write(target[i]);
      } else {
        buffer.write(_chars[_random.nextInt(_chars.length)]);
      }
    }

    setState(() => _currentText = buffer.toString());
  }

  @override
  void didUpdateWidget(HashTextAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetHash != widget.targetHash) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateText);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentText,
      style: widget.style ?? AppTextStyles.hash,
    );
  }
}
