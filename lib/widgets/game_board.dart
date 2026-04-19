import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/engine.dart';
import '../models/cell.dart';

class GameBoard extends StatelessWidget {
  final GameEngine engine;

  const GameBoard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final display = engine.displayBoard;
    final ghostRow = engine.ghostRow;
    final currentPiece = engine.currentPiece;

    return AspectRatio(
      aspectRatio: GameEngine.cols / GameEngine.rows,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFF1A1A2E),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: CustomPaint(
            painter: _BoardPainter(
              display: display,
              ghostRow: ghostRow,
              ghostCol: engine.pieceCol,
              ghostPiece: currentPiece,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final List<List<Cell>> display;
  final int ghostRow;
  final int ghostCol;
  final dynamic ghostPiece;

  _BoardPainter({
    required this.display,
    required this.ghostRow,
    required this.ghostCol,
    required this.ghostPiece,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / GameEngine.cols;
    final cellH = size.height / GameEngine.rows;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (int c = 1; c < GameEngine.cols; c++) {
      canvas.drawLine(
        Offset(c * cellW, 0),
        Offset(c * cellW, size.height),
        gridPaint,
      );
    }
    for (int r = 1; r < GameEngine.rows; r++) {
      canvas.drawLine(
        Offset(0, r * cellH),
        Offset(size.width, r * cellH),
        gridPaint,
      );
    }

    // Draw ghost piece
    if (ghostPiece != null) {
      final ghostPaint = Paint()
        ..color = (ghostPiece.color as Color).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      for (final offset in ghostPiece.shape) {
        final r = ghostRow + (offset as List<int>)[0];
        final c = ghostCol + offset[1];
        if (r >= 0 && r < GameEngine.rows && c >= 0 && c < GameEngine.cols) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellW + 1, r * cellH + 1, cellW - 2, cellH - 2),
              const Radius.circular(2),
            ),
            ghostPaint,
          );
        }
      }
    }

    // Draw cells
    for (int r = 0; r < GameEngine.rows; r++) {
      for (int c = 0; c < GameEngine.cols; c++) {
        final cell = display[r][c];
        if (!cell.isEmpty) {
          final rect = Rect.fromLTWH(
            c * cellW + 1,
            r * cellH + 1,
            cellW - 2,
            cellH - 2,
          );

          // Filled block
          final paint = Paint()
            ..color = cell.color!
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            paint,
          );

          // Highlight
          final highlightPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.left + 1, rect.top + 1, rect.width - 2, rect.height / 3),
              const Radius.circular(2),
            ),
            highlightPaint,
          );

          // Draw emoji on cell
          if (cell.emoji != null) {
            final paragraphBuilder = ui.ParagraphBuilder(
              ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: cellW * 0.6),
            )..addText(cell.emoji!);
            final paragraph = paragraphBuilder.build()
              ..layout(ui.ParagraphConstraints(width: rect.width));
            canvas.drawParagraph(
              paragraph,
              Offset(rect.left, rect.top + (rect.height - paragraph.height) / 2),
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
