import 'package:flutter/material.dart';

/// Each animal piece has a name, color, and shape defined as a list of
/// (row, col) offsets from a reference point.
class BeastPiece {
  final String name;
  final String emoji;
  final Color color;
  final List<List<int>> shape; // list of [row, col] offsets

  const BeastPiece({
    required this.name,
    required this.emoji,
    required this.color,
    required this.shape,
  });

  /// Rotate 90° clockwise: (r,c) -> (c, -r) then normalize to non-negative.
  BeastPiece rotated() {
    final rotated = shape.map((p) => [p[1], -p[0]]).toList();
    final minR = rotated.map((p) => p[0]).reduce((a, b) => a < b ? a : b);
    final minC = rotated.map((p) => p[1]).reduce((a, b) => a < b ? a : b);
    final normalized = rotated.map((p) => [p[0] - minR, p[1] - minC]).toList();
    return BeastPiece(name: name, emoji: emoji, color: color, shape: normalized);
  }

  int get width {
    return shape.map((p) => p[1]).reduce((a, b) => a > b ? a : b) + 1;
  }

  int get height {
    return shape.map((p) => p[0]).reduce((a, b) => a > b ? a : b) + 1;
  }
}

/// The 7 animal-shaped pieces for Beastris.
/// Each mimics a classic Tetris shape but is themed as an animal.
class BeastPieces {
  // 🐍 Snake — S-piece
  //  ##
  // ##
  static const snake = BeastPiece(
    name: 'Snake',
    emoji: '🐍',
    color: Color(0xFF4CAF50),
    shape: [
      [0, 1], [0, 2],
      [1, 0], [1, 1],
    ],
  );

  // 🐊 Croc — Z-piece
  // ##
  //  ##
  static const croc = BeastPiece(
    name: 'Croc',
    emoji: '🐊',
    color: Color(0xFF8BC34A),
    shape: [
      [0, 0], [0, 1],
      [1, 1], [1, 2],
    ],
  );

  // 🐛 Caterpillar — I-piece
  // ####
  static const caterpillar = BeastPiece(
    name: 'Caterpillar',
    emoji: '🐛',
    color: Color(0xFF00BCD4),
    shape: [
      [0, 0], [0, 1], [0, 2], [0, 3],
    ],
  );

  // 🐢 Turtle — O-piece (square)
  // ##
  // ##
  static const turtle = BeastPiece(
    name: 'Turtle',
    emoji: '🐢',
    color: Color(0xFFFFC107),
    shape: [
      [0, 0], [0, 1],
      [1, 0], [1, 1],
    ],
  );

  // 🦅 Eagle — T-piece
  // ###
  //  #
  static const eagle = BeastPiece(
    name: 'Eagle',
    emoji: '🦅',
    color: Color(0xFF9C27B0),
    shape: [
      [0, 0], [0, 1], [0, 2],
      [1, 1],
    ],
  );

  // 🐕 Dog — L-piece
  // #
  // #
  // ##
  static const dog = BeastPiece(
    name: 'Dog',
    emoji: '🐕',
    color: Color(0xFFFF9800),
    shape: [
      [0, 0],
      [1, 0],
      [2, 0], [2, 1],
    ],
  );

  // 🐈 Cat — J-piece
  //  #
  //  #
  // ##
  static const cat = BeastPiece(
    name: 'Cat',
    emoji: '🐈',
    color: Color(0xFFF44336),
    shape: [
      [0, 1],
      [1, 1],
      [2, 0], [2, 1],
    ],
  );

  static const List<BeastPiece> all = [
    snake,
    croc,
    caterpillar,
    turtle,
    eagle,
    dog,
    cat,
  ];
}
