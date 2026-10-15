import 'package:flutter/material.dart';

import '../models/die.dart';

class DieWidget extends StatelessWidget {
  const DieWidget({
    super.key,
    required this.die,
    required this.onTap,
    this.enabled = true,
  });

  final Die die;
  final VoidCallback onTap;
  final bool enabled;

  static const _dots = {
    1: [(0.5, 0.5)],
    2: [(0.25, 0.25), (0.75, 0.75)],
    3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
    4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
    5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
    6: [
      (0.25, 0.2),
      (0.75, 0.2),
      (0.25, 0.5),
      (0.75, 0.5),
      (0.25, 0.8),
      (0.75, 0.8)
    ],
  };

  @override
  Widget build(BuildContext context) {
    final held = die.held;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: held ? const Color(0xFF533483) : const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: held ? const Color(0xFF8B5CF6) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _DotsPainter(
            value: die.value,
            dotColor: held ? Colors.white : const Color(0xFF1a1a2e),
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter({required this.value, required this.dotColor});

  final int value;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    final positions = DieWidget._dots[value] ?? [];
    for (final (rx, ry) in positions) {
      canvas.drawCircle(
        Offset(size.width * rx, size.height * ry),
        size.width * 0.09,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.value != value || old.dotColor != dotColor;
}
