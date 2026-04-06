import 'package:flutter/material.dart';

/// Represents a single cell on the game board.
class Cell {
  final Color? color;
  final String? emoji;

  const Cell({this.color, this.emoji});

  bool get isEmpty => color == null;

  static const Cell empty = Cell();
}
