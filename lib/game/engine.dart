import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/cell.dart';
import '../models/piece.dart';

enum GameState { idle, playing, paused, gameOver }

enum BombType { grenade, bomb }

class GameEngine extends ChangeNotifier {
  static const int rows = 20;
  static const int cols = 10;

  final Random _random = Random();

  late List<List<Cell>> _board;
  BeastPiece? _currentPiece;
  BeastPiece? _nextPiece;
  int _pieceRow = 0;
  int _pieceCol = 0;
  int _score = 0;
  int _lines = 0;
  int _level = 1;
  GameState _state = GameState.idle;
  Timer? _timer;

  // Bomb state
  bool _grenadeAvailable = true;
  bool _bombAvailable = true;
  BombType? _activeBomb; // null = normal piece, non-null = bomb falling
  // Explosion cells: list of {row, col} that just exploded (for animation)
  List<({int row, int col})> _explosionCells = [];

  GameEngine() {
    _initBoard();
  }

  // --- Public getters ---
  List<List<Cell>> get board => _board;
  BeastPiece? get currentPiece => _currentPiece;
  BeastPiece? get nextPiece => _nextPiece;
  int get pieceRow => _pieceRow;
  int get pieceCol => _pieceCol;
  int get score => _score;
  int get lines => _lines;
  int get level => _level;
  GameState get state => _state;
  bool get grenadeAvailable => _grenadeAvailable;
  bool get bombAvailable => _bombAvailable;
  BombType? get activeBomb => _activeBomb;
  List<({int row, int col})> get explosionCells => _explosionCells;

  // --- Board with current piece merged (for rendering) ---
  List<List<Cell>> get displayBoard {
    final display = _board.map((row) => row.toList()).toList();
    if (_currentPiece != null) {
      for (final offset in _currentPiece!.shape) {
        final r = _pieceRow + offset[0];
        final c = _pieceCol + offset[1];
        if (r >= 0 && r < rows && c >= 0 && c < cols) {
          display[r][c] = Cell(
            color: _currentPiece!.color,
            emoji: _currentPiece!.emoji,
          );
        }
      }
    }
    return display;
  }

  // --- Ghost piece row (preview of where piece will land) ---
  int get ghostRow {
    if (_currentPiece == null) return _pieceRow;
    int ghostR = _pieceRow;
    while (_canPlace(_currentPiece!, ghostR + 1, _pieceCol)) {
      ghostR++;
    }
    return ghostR;
  }

  // --- Tick interval based on level ---
  int get _tickMs => max(100, 800 - (_level - 1) * 60);

  // --- Game lifecycle ---
  void startGame() {
    _initBoard();
    _score = 0;
    _lines = 0;
    _level = 1;
    _state = GameState.playing;
    _grenadeAvailable = true;
    _bombAvailable = true;
    _activeBomb = null;
    _explosionCells = [];
    _nextPiece = _randomPiece();
    _spawnPiece();
    _startTimer();
    notifyListeners();
  }

  void returnToMenu() {
    _timer?.cancel();
    _state = GameState.idle;
    notifyListeners();
  }

  void togglePause() {
    if (_state == GameState.playing) {
      _state = GameState.paused;
      _timer?.cancel();
    } else if (_state == GameState.paused) {
      _state = GameState.playing;
      _startTimer();
    }
    notifyListeners();
  }

  // --- Input actions ---
  void moveLeft() {
    if (_state != GameState.playing || _currentPiece == null) return;
    if (_canPlace(_currentPiece!, _pieceRow, _pieceCol - 1)) {
      _pieceCol--;
      notifyListeners();
    }
  }

  void moveRight() {
    if (_state != GameState.playing || _currentPiece == null) return;
    if (_canPlace(_currentPiece!, _pieceRow, _pieceCol + 1)) {
      _pieceCol++;
      notifyListeners();
    }
  }

  void rotate() {
    if (_state != GameState.playing || _currentPiece == null) return;
    final rotated = _currentPiece!.rotated();
    // Try current position, then wall kicks (-1, +1, -2, +2)
    for (final kick in [0, -1, 1, -2, 2]) {
      if (_canPlace(rotated, _pieceRow, _pieceCol + kick)) {
        _currentPiece = rotated;
        _pieceCol += kick;
        notifyListeners();
        return;
      }
    }
  }

  void softDrop() {
    if (_state != GameState.playing || _currentPiece == null) return;
    if (_canPlace(_currentPiece!, _pieceRow + 1, _pieceCol)) {
      _pieceRow++;
      _score += 1;
      notifyListeners();
    }
  }

  void hardDrop() {
    if (_state != GameState.playing || _currentPiece == null) return;
    int dropped = 0;
    while (_canPlace(_currentPiece!, _pieceRow + 1, _pieceCol)) {
      _pieceRow++;
      dropped++;
    }
    _score += dropped * 2;
    _lockPiece();
  }

  // --- Bomb actions ---
  // Activating grenade/bomb replaces the NEXT (queued) piece.
  void activateGrenade() {
    if (_state != GameState.playing) return;
    if (!_grenadeAvailable) return;
    _grenadeAvailable = false;
    _nextPiece = _makeBombPiece(BombType.grenade);
    notifyListeners();
  }

  void activateBomb() {
    if (_state != GameState.playing) return;
    if (!_bombAvailable) return;
    _bombAvailable = false;
    _nextPiece = _makeBombPiece(BombType.bomb);
    notifyListeners();
  }

  BeastPiece _makeBombPiece(BombType type) {
    return BeastPiece(
      name: type == BombType.grenade ? 'Grenade' : 'Bomb',
      emoji: type == BombType.grenade ? '💣' : '💥',
      color: type == BombType.grenade
          ? const Color(0xFF607D8B)
          : const Color(0xFFE53935),
      shape: const [[0, 0]],
    );
  }

  // --- Internal ---
  void _initBoard() {
    _board = List.generate(rows, (_) => List.filled(cols, Cell.empty));
  }

  BeastPiece _randomPiece() {
    return BeastPieces.all[_random.nextInt(BeastPieces.all.length)];
  }

  void _spawnPiece() {
    _currentPiece = _nextPiece ?? _randomPiece();
    // Detect if the spawned piece is a bomb/grenade
    if (_currentPiece!.name == 'Grenade') {
      _activeBomb = BombType.grenade;
    } else if (_currentPiece!.name == 'Bomb') {
      _activeBomb = BombType.bomb;
    } else {
      _activeBomb = null;
    }
    _nextPiece = _randomPiece();
    _pieceRow = 0;
    _pieceCol = (cols - _currentPiece!.width) ~/ 2;

    if (!_canPlace(_currentPiece!, _pieceRow, _pieceCol)) {
      _state = GameState.gameOver;
      _timer?.cancel();
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) => _tick());
  }

  void _tick() {
    if (_state != GameState.playing || _currentPiece == null) return;
    if (_canPlace(_currentPiece!, _pieceRow + 1, _pieceCol)) {
      _pieceRow++;
      notifyListeners();
    } else {
      _lockPiece();
    }
  }

  bool _canPlace(BeastPiece piece, int row, int col) {
    for (final offset in piece.shape) {
      final r = row + offset[0];
      final c = col + offset[1];
      if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
      if (!_board[r][c].isEmpty) return false;
    }
    return true;
  }

  void _lockPiece() {
    if (_currentPiece == null) return;

    if (_activeBomb != null) {
      // Explode at the blocking cell (one row below landing position),
      // or at landing row if already at the bottom.
      final impactRow = (_pieceRow + 1 < rows) ? _pieceRow + 1 : _pieceRow;
      final impactCol = _pieceCol;
      _explode(impactRow, impactCol, _activeBomb!);
      _activeBomb = null;
      _currentPiece = null;
      // Clear completed lines after explosion
      final cleared = _clearLines();
      if (cleared > 0) {
        _lines += cleared;
        _score += _lineScore(cleared);
        _applyLevelUp();
        _startTimer();
      }
      _spawnPiece();
      if (_state != GameState.gameOver) notifyListeners();
      return;
    }

    // Normal piece lock
    for (final offset in _currentPiece!.shape) {
      final r = _pieceRow + offset[0];
      final c = _pieceCol + offset[1];
      if (r >= 0 && r < rows && c >= 0 && c < cols) {
        _board[r][c] = Cell(
          color: _currentPiece!.color,
          emoji: _currentPiece!.emoji,
        );
      }
    }

    // Clear completed lines
    final cleared = _clearLines();
    if (cleared > 0) {
      _lines += cleared;
      _score += _lineScore(cleared);
      _applyLevelUp();
      // Restart timer with new speed
      _startTimer();
    }

    _spawnPiece();
    // _spawnPiece already called notifyListeners() when game over; skip duplicate
    if (_state != GameState.gameOver) {
      notifyListeners();
    }
  }

  void _explode(int row, int col, BombType type) {
    final cells = <({int row, int col})>[];
    // Grenade: only the cell itself
    // Bomb: 3x3 area around landing cell
    final offsets = type == BombType.grenade
        ? [const (0, 0)]
        : [
            const (-1, -1), const (-1, 0), const (-1, 1),
            const (0, -1),  const (0, 0),  const (0, 1),
            const (1, -1),  const (1, 0),  const (1, 1),
          ];
    for (final o in offsets) {
      final r = row + o.$1;
      final c = col + o.$2;
      if (r >= 0 && r < rows && c >= 0 && c < cols) {
        _board[r][c] = Cell.empty;
        cells.add((row: r, col: c));
      }
    }
    _explosionCells = cells;
    // Clear explosion markers after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      _explosionCells = [];
      notifyListeners();
    });
  }

  int _clearLines() {
    int cleared = 0;
    for (int r = rows - 1; r >= 0; r--) {
      if (_board[r].every((cell) => !cell.isEmpty)) {
        _board.removeAt(r);
        _board.insert(0, List.filled(cols, Cell.empty));
        cleared++;
        r++; // re-check this row index since rows shifted
      }
    }
    return cleared;
  }

  int _lineScore(int lines) {
    const scores = {1: 100, 2: 300, 3: 500, 4: 800};
    return (scores[lines] ?? 800) * _level;
  }

  void _applyLevelUp() {
    final newLevel = (_lines ~/ 5) + 1;
    if (newLevel > _level) {
      _level = newLevel;
      // Reactivate bombs on level up
      _grenadeAvailable = true;
      _bombAvailable = true;
    } else {
      _level = newLevel;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
