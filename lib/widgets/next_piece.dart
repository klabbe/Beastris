import 'package:flutter/material.dart';

import '../models/piece.dart';

class NextPiecePreview extends StatelessWidget {
  final BeastPiece? piece;

  const NextPiecePreview({super.key, required this.piece});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          if (piece != null) ...[
            Text(piece!.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              height: 60,
              child: CustomPaint(
                painter: _PreviewPainter(piece: piece!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final BeastPiece piece;

  _PreviewPainter({required this.piece});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 4;
    final offsetX = (size.width - piece.width * cellSize) / 2;
    final offsetY = (size.height - piece.height * cellSize) / 2;

    final paint = Paint()
      ..color = piece.color
      ..style = PaintingStyle.fill;

    for (final block in piece.shape) {
      final rect = Rect.fromLTWH(
        offsetX + block[1] * cellSize + 1,
        offsetY + block[0] * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => old.piece != piece;
}
