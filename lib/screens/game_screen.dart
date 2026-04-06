import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/engine.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../widgets/score_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameEngine _engine = GameEngine();

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onEngineUpdate);
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
    if (_engine.state == GameState.gameOver) {
      _showGameOver();
    }
  }

  void _showGameOver() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Game Over! 🐾', style: TextStyle(color: Colors.white)),
        content: Text(
          'Score: ${_engine.score}\nLines: ${_engine.lines}\nLevel: ${_engine.level}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _engine.startGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      body: SafeArea(
        child: _engine.state == GameState.idle ? _buildStartScreen() : _buildGameLayout(),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🐾 BEASTRIS 🐾',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Animal Blocks Falling!',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: const [
              Text('🐍', style: TextStyle(fontSize: 28)),
              Text('🐊', style: TextStyle(fontSize: 28)),
              Text('🐛', style: TextStyle(fontSize: 28)),
              Text('🐢', style: TextStyle(fontSize: 28)),
              Text('🦅', style: TextStyle(fontSize: 28)),
              Text('🐕', style: TextStyle(fontSize: 28)),
              Text('🐈', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _engine.startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF533483),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('START GAME', style: TextStyle(fontSize: 20, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameLayout() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🐾 BEASTRIS',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  _engine.state == GameState.paused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                ),
                onPressed: _engine.togglePause,
              ),
            ],
          ),
        ),
        // Game area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Board
                Expanded(
                  flex: 3,
                  child: GameBoard(engine: _engine),
                ),
                const SizedBox(width: 8),
                // Side panel
                SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NextPiecePreview(piece: _engine.nextPiece),
                      const SizedBox(height: 12),
                      ScorePanel(
                        score: _engine.score,
                        lines: _engine.lines,
                        level: _engine.level,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Touch controls
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(Icons.arrow_left, _engine.moveLeft),
          _controlButton(Icons.rotate_right, _engine.rotate),
          _controlButton(Icons.arrow_drop_down, _engine.softDrop),
          _controlButton(Icons.keyboard_double_arrow_down, _engine.hardDrop),
          _controlButton(Icons.arrow_right, _engine.moveRight),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
