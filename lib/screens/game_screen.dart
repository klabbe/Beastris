import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/engine.dart';
import '../models/game_history.dart';
import '../services/leaderboard_service.dart';
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
  final GameHistory _history = GameHistory();
  final LeaderboardService _leaderboard = LeaderboardService();
  List<LeaderboardEntry> _topGlobal = [];
  GameResult? _savedResult;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onEngineUpdate);
    _history.load().then((_) {
      if (mounted) setState(() {});
    });
    _loadGlobalLeaderboard();
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
    if (_engine.state == GameState.gameOver && _savedResult == null) {
      // Save exactly once, immediately
      _savedResult = GameResult(
        score: _engine.score,
        lines: _engine.lines,
        level: _engine.level,
        date: DateTime.now(),
      );
      _history.addResult(_savedResult!);
      // Defer dialog until after the current frame to avoid re-entrancy
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOverDialog();
      });
    }
  }

  void _goToMenu() {
    _savedResult = null;
    _engine.returnToMenu();
    _history.load().then((_) {
      if (mounted) setState(() {});
    });
    _loadGlobalLeaderboard();
  }

  Future<void> _loadGlobalLeaderboard() async {
    try {
      final entries = await _leaderboard.fetchTopScores();
      if (mounted) setState(() => _topGlobal = entries);
    } catch (_) {}
  }

  void _confirmLeaveGame() {
    if (_engine.state == GameState.playing) {
      _engine.togglePause();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Lämna spelet?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Det pågående spelet avslutas och resultatet sparas inte.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Resume game if it was paused by us
              if (_engine.state == GameState.paused) {
                _engine.togglePause();
              }
            },
            child: const Text('Fortsätt spela'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _goToMenu();
            },
            child: const Text('Lämna', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    if (_savedResult == null) return;
    final result = _savedResult!;
    HapticFeedback.heavyImpact();
    final nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Game Over! 🐾', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${result.score}\nLines: ${result.lines}\nLevel: ${result.level}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Ditt namn (för topplistan):', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              maxLength: 16,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Anonymt...',
                hintStyle: const TextStyle(color: Colors.white30),
                counterStyle: const TextStyle(color: Colors.white30),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF533483)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final name = nameController.text.trim().isEmpty
                  ? 'Anonym'
                  : nameController.text.trim();
              _leaderboard.submitScore(result, name).then((_) {
                _loadGlobalLeaderboard();
              }).catchError((_) {});
              _goToMenu();
            },
            child: const Text('Menu'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim().isEmpty
                  ? 'Anonym'
                  : nameController.text.trim();
              Navigator.pop(ctx);
              try {
                await _leaderboard.submitScore(result, name);
                await _loadGlobalLeaderboard();
              } catch (_) {}
              _savedResult = null;
              _engine.startGame();
            },
            child: const Text('Skicka & Spela igen'),
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
    final topScores = _history.topScores;
    final recentGames = _history.recentGames;
    final hasHistory = topScores.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
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
            const SizedBox(height: 32),
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
            if (hasHistory) ...[
              const SizedBox(height: 32),
              _buildHistorySection('🏆 Dina bästa', topScores),
              const SizedBox(height: 16),
              _buildHistorySection('🕐 Senaste spel', recentGames),
            ],
            if (_topGlobal.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildGlobalLeaderboard(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF533483).withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🌍 Global Topplista',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ..._topGlobal.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}.', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                  Expanded(
                    child: Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                  ),
                  Text('${r.score} pts', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistorySection(String title, List<GameResult> results) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...results.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}.',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${r.score} pts',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    'L${r.level}  ×${r.lines}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _engine.state == GameState.paused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                    onPressed: _engine.togglePause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: _confirmLeaveGame,
                  ),
                ],
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
    const double btnSize = 64;
    const double gap = 4;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Hard drop centered
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: btnSize + gap),
              _controlButton(Icons.keyboard_double_arrow_down, _engine.hardDrop, btnSize),
              SizedBox(width: btnSize + gap),
            ],
          ),
          SizedBox(height: gap),
          // Row 2: Left | Rotate | Right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _controlButton(Icons.arrow_left, _engine.moveLeft, btnSize),
              SizedBox(width: gap),
              _controlButton(Icons.rotate_right, _engine.rotate, btnSize),
              SizedBox(width: gap),
              _controlButton(Icons.arrow_right, _engine.moveRight, btnSize),
            ],
          ),
          SizedBox(height: gap),
          // Row 3: Soft drop centered
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: btnSize + gap),
              _controlButton(Icons.arrow_drop_down, _engine.softDrop, btnSize),
              SizedBox(width: btnSize + gap),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed, double size) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
