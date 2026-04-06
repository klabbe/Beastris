import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/cell.dart';
import '../models/piece.dart';

enum GameState { idle, playing, paused, gameOver }

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
    _nextPiece = _randomPiece();
    _spawnPiece();
    _startTimer();
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

  // --- Internal ---
  void _initBoard() {
    _board = List.generate(rows, (_) => List.filled(cols, Cell.empty));
  }

  BeastPiece _randomPiece() {
    return BeastPieces.all[_random.nextInt(BeastPieces.all.length)];
  }

  void _spawnPiece() {
    _currentPiece = _nextPiece ?? _randomPiece();
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
    // Place piece on board
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
      _level = (_lines ~/ 10) + 1;
      // Restart timer with new speed
      _startTimer();
    }

    _spawnPiece();
    notifyListeners();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
