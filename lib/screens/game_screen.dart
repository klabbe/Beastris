import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/engine.dart';
import '../models/countries.dart';
import '../models/game_history.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../widgets/score_panel.dart';
import 'privacy_policy_screen.dart';

enum _LeaderboardTab { allTime, thisWeek }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameEngine _engine = GameEngine();
  final GameHistory _history = GameHistory();
  final LeaderboardService _leaderboard = LeaderboardService();
  final AuthService _auth = AuthService();

  List<LeaderboardEntry> _topAllTime = [];
  List<LeaderboardEntry> _topWeekly = [];
  (int, LeaderboardEntry)? _userAllTimeRank;
  (int, LeaderboardEntry)? _userWeeklyRank;
  _LeaderboardTab _activeTab = _LeaderboardTab.allTime;
  GameResult? _savedResult;

  // Explosion animation
  late AnimationController _explosionController;
  late Animation<double> _explosionScale;
  late Animation<double> _explosionFade;

  @override
  void initState() {
    super.initState();
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _explosionScale = Tween<double>(begin: 0.3, end: 1.8).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );
    _explosionFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeIn),
    );
    _engine.addListener(_onEngineUpdate);
    _auth.addListener(_onAuthChanged);
    _history.load().then((_) {
      if (mounted) setState(() {});
    });
    _loadLeaderboards();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
    // Trigger explosion animation when cells explode
    if (_engine.explosionCells.isNotEmpty) {
      _explosionController.forward(from: 0);
    }
    if (_engine.state == GameState.gameOver && _savedResult == null) {
      _savedResult = GameResult(
        score: _engine.score,
        lines: _engine.lines,
        level: _engine.level,
        date: DateTime.now(),
      );
      _history.addResult(_savedResult!);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        String? congrats;
        if (_auth.isLoggedIn && _auth.profile != null) {
          congrats = await _autoSubmitIfQualified(_savedResult!);
          if (mounted) await _loadLeaderboards();
        }
        if (mounted) _showGameOverDialog(congrats: congrats);
      });
    }
  }

  Future<String?> _autoSubmitIfQualified(GameResult result) async {
    final uid = _auth.currentUser!.uid;
    final profile = _auth.profile!;
    final isTopTen = _topWeekly.length < 10 || result.score > _topWeekly.last.score;
    final prevBest = await _leaderboard.fetchUserBestScoreThisWeek(uid);
    final isPersonalBest = prevBest == null || result.score > prevBest;
    if (!isTopTen && !isPersonalBest) return null;
    await _leaderboard.submitScore(
      result,
      profile.alias,
      uid: uid,
      country: profile.country.isNotEmpty ? profile.country : null,
    );
    if (isTopTen) {
      final rank = _topWeekly.where((e) => e.score > result.score).length + 1;
      return '🏆 You made the weekly top 10!\nRank #$rank this week';
    }
    return '⭐ New personal best this week!';
  }

  void _goToMenu() {
    _savedResult = null;
    _engine.returnToMenu();
    _history.load().then((_) {
      if (mounted) setState(() {});
    });
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    final uid = _auth.currentUser?.uid;
    try {
      final data = await _leaderboard.fetchAllTimeData(uid: uid);
      if (mounted) setState(() {
        _topAllTime = data.top10;
        _userAllTimeRank = data.userRank;
      });
    } catch (_) {}
    try {
      final data = await _leaderboard.fetchWeeklyData(uid: uid);
      if (mounted) setState(() {
        _topWeekly = data.top10;
        _userWeeklyRank = data.userRank;
      });
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
        title: const Text('Leave game?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'The current game will end and the result will not be saved.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_engine.state == GameState.paused) {
                _engine.togglePause();
              }
            },
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _goToMenu();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog({String? congrats}) {
    if (_savedResult == null) return;
    final result = _savedResult!;
    HapticFeedback.heavyImpact();

    if (_auth.isLoggedIn && _auth.profile != null) {
      // Logged-in: score was auto-submitted if it qualified
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('Game Over! 🐾', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Score: ${result.score}\nLines: ${result.lines}  ·  Level: ${result.level}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (congrats != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF533483).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF533483)),
                  ),
                  child: Text(
                    congrats,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); _goToMenu(); },
              child: const Text('Menu'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _savedResult = null;
                _engine.startGame();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF533483)),
              child: const Text('Play Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Not logged in: offer to sign in to save online, or continue without
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('Game Over! 🐾', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Score: ${result.score}\nLines: ${result.lines}  ·  Level: ${result.level}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to save your score to the global leaderboard!',
                style: TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); _goToMenu(); },
              child: const Text('Menu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _savedResult = null;
                _engine.startGame();
              },
              child: const Text('Play Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showAuthDialogThenSubmit(result);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF533483)),
              child: const Text('Sign In', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _explosionController.dispose();
    _engine.removeListener(_onEngineUpdate);
    _auth.removeListener(_onAuthChanged);
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
    final profile = _auth.profile;
    final hasHistory = topScores.isNotEmpty;
    final hasGlobal = _topAllTime.isNotEmpty || _topWeekly.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Auth header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (profile != null)
                    GestureDetector(
                      onTap: _showProfileDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_circle, color: Colors.white70, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            profile.alias,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 16),
                        ],
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _showAuthDialog,
                      icon: const Icon(Icons.login, size: 16, color: Colors.white60),
                      label: const Text('Sign In', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '🐾 BEASTBLOCKS 🐾',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
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
              _buildHistorySection('🏆 Your Best', topScores),
              const SizedBox(height: 16),
              _buildHistorySection('🕐 Recent Games', recentGames),
            ],
            if (hasGlobal) ...[
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
    final entries = _activeTab == _LeaderboardTab.allTime ? _topAllTime : _topWeekly;
    final userRank = _activeTab == _LeaderboardTab.allTime ? _userAllTimeRank : _userWeeklyRank;
    final uid = _auth.currentUser?.uid;
    final userInTopTen = userRank != null && userRank.$1 <= 10;

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
            '🌍 Global Leaderboard',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton('All Time', _LeaderboardTab.allTime),
              const SizedBox(width: 8),
              _tabButton('This Week', _LeaderboardTab.thisWeek),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No entries yet', style: TextStyle(color: Colors.white38, fontSize: 12))
          else ...[
            ...entries.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final isMe = uid != null && r.uid == uid;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${i + 1}.', style: TextStyle(color: isMe ? const Color(0xFFFFD700) : Colors.white54, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(
                        isMe ? '${r.name} (you)' : r.name,
                        style: TextStyle(color: isMe ? const Color(0xFFFFD700) : Colors.white, fontSize: 13, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (r.country.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(right: 4), child: Text(countryCodeToFlag(r.country), style: const TextStyle(fontSize: 12))),
                    Text('${r.score} pts', style: TextStyle(color: isMe ? const Color(0xFFFFD700) : Colors.white70, fontSize: 13)),
                  ],
                ),
              );
            }),
            // Show user's rank if they're outside top 10
            if (uid != null && userRank != null && !userInTopTen) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(color: Colors.white12, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('#${userRank.$1}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12)),
                    ),
                    Expanded(
                      child: Text('${userRank.$2.name} (you)', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    Text('${userRank.$2.score} pts', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                  ],
                ),
              ),
            ],
            if (uid != null && userRank == null && _auth.isLoggedIn)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('You are not ranked yet', style: TextStyle(color: Colors.white24, fontSize: 11)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(String label, _LeaderboardTab tab) {
    final active = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF533483) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFF533483) : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 12),
        ),
      ),
    );
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AuthDialog(auth: _auth),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showAuthDialogThenSubmit(GameResult result) {
    showDialog(
      context: context,
      builder: (ctx) => _AuthDialog(auth: _auth),
    ).then((_) async {
      if (!mounted) return;
      setState(() {});
      if (_auth.isLoggedIn && _auth.profile != null) {
        final congrats = await _autoSubmitIfQualified(result);
        if (mounted) await _loadLeaderboards();
        if (mounted) _showGameOverDialog(congrats: congrats);
      }
    });
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ProfileDialog(auth: _auth),
    ).then((_) {
      if (mounted) setState(() {});
    });
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

  Widget _buildBoardWithExplosions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = constraints.maxWidth;
        final boardHeight = boardWidth * GameEngine.rows / GameEngine.cols;
        final cellW = boardWidth / GameEngine.cols;
        final cellH = boardHeight / GameEngine.rows;

        return SizedBox(
          width: boardWidth,
          height: boardHeight,
          child: Stack(
            children: [
              GameBoard(engine: _engine),
              // Explosion overlay
              if (_engine.explosionCells.isNotEmpty)
                ..._engine.explosionCells.map((cell) {
                  return Positioned(
                    left: cell.col * cellW,
                    top: cell.row * cellH,
                    width: cellW,
                    height: cellH,
                    child: AnimatedBuilder(
                      animation: _explosionController,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _explosionFade.value,
                          child: Transform.scale(
                            scale: _explosionScale.value,
                            child: const Center(
                              child: Text('\ud83d\udca5', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      },
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
                '🐾 BEASTBLOCKS',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
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
                  child: _buildBoardWithExplosions(),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // D-pad: 3 rows
          Column(
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
          // Gap between d-pad and bomb buttons
          const SizedBox(width: 32),
          // Bomb column: grenade on top, bomb below
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bombButton('💣', _engine.grenadeAvailable, _engine.activateGrenade, btnSize),
              SizedBox(height: gap * 2),
              _bombButton('💥', _engine.bombAvailable, _engine.activateBomb, btnSize),
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

  Widget _bombButton(String emoji, bool available, VoidCallback onPressed, double size) {
    return GestureDetector(
      onTap: available
          ? () {
              HapticFeedback.mediumImpact();
              onPressed();
            }
          : null,
      child: Opacity(
        opacity: available ? 1.0 : 0.35,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: available
                ? Colors.orange.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: available ? Colors.orangeAccent.withValues(alpha: 0.6) : Colors.white24,
            ),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Dialog (Sign In / Register)
// ---------------------------------------------------------------------------

class _AuthDialog extends StatefulWidget {
  final AuthService auth;
  const _AuthDialog({required this.auth});

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  bool _isRegister = false;
  bool _loading = false;
  String? _error;
  String? _selectedCountryCode;
  bool _acceptedPolicy = false;
  bool _ageConfirmed = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _aliasCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address first.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await widget.auth.sendPasswordReset(email);
    if (!mounted) return;
    setState(() { _loading = false; });
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (_isRegister && _aliasCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Alias is required for registration.');
      return;
    }
    if (_isRegister && !_acceptedPolicy) {
      setState(() => _error = 'You must accept the privacy policy to register.');
      return;
    }
    if (_isRegister && !_ageConfirmed) {
      setState(() => _error = 'You must confirm your age to register.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    String? err;
    if (_isRegister) {
      final profile = UserProfile(
        uid: '',
        alias: _aliasCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        country: _selectedCountryCode ?? '',
      );
      err = await widget.auth.register(email, password, profile);
    } else {
      err = await widget.auth.signIn(email, password);
    }
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      title: Text(
        _isRegister ? 'Create Account' : 'Sign In',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_emailCtrl, 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            _field(_passwordCtrl, 'Password', obscure: true),
            if (_isRegister) ...[
              const SizedBox(height: 8),
              _labelledField(
                label: 'Alias',
                hint: 'Shown on the leaderboard',
                ctrl: _aliasCtrl,
                maxLength: 16,
              ),
              const SizedBox(height: 8),
              _labelledField(
                label: 'Name (optional)',
                hint: 'Your real name — not shown publicly',
                ctrl: _nameCtrl,
              ),
              const SizedBox(height: 8),
              _countryDropdown(
                value: _selectedCountryCode,
                onChanged: (v) => setState(() => _selectedCountryCode = v),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptedPolicy,
                    activeColor: const Color(0xFF533483),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    onChanged: _loading ? null : (v) => setState(() => _acceptedPolicy = v ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(text: 'I have read and accept the ', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFF7B68EE), fontSize: 12, decoration: TextDecoration.underline)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _ageConfirmed,
                    activeColor: const Color(0xFF533483),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    onChanged: _loading ? null : (v) => setState(() => _ageConfirmed = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I am 13 years or older, or have parental consent',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _loading ? null : () => setState(() { _isRegister = !_isRegister; _error = null; _ageConfirmed = false; _acceptedPolicy = false; }),
                  child: Text(
                    _isRegister ? 'Already have an account?' : 'Create account',
                    style: const TextStyle(color: Color(0xFF7B68EE), fontSize: 13),
                  ),
                ),
                if (!_isRegister)
                  GestureDetector(
                    onTap: _loading ? null : _forgotPassword,
                    child: const Text('Forgot password?', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF533483)),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isRegister ? 'Register' : 'Sign In', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _labelledField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    bool obscure = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        _field(ctrl, hint, obscure: obscure, keyboardType: keyboardType, maxLength: maxLength),
      ],
    );
  }

  Widget _countryDropdown({String? value, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Country (optional)', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white54,
          decoration: InputDecoration(
            hintText: 'Select country...',
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF533483)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('— None —', style: TextStyle(color: Colors.white38)),
            ),
            ...kCountries.map((c) => DropdownMenuItem<String>(
              value: c.code,
              child: Text('${countryCodeToFlag(c.code)}  ${c.name}',
                  style: const TextStyle(color: Colors.white)),
            )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Dialog (Edit profile + Sign Out)
// ---------------------------------------------------------------------------

class _ProfileDialog extends StatefulWidget {
  final AuthService auth;
  const _ProfileDialog({required this.auth});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  bool _loading = false;
  String? _error;
  String? _selectedCountryCode;
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.auth.profile;
    _aliasCtrl = TextEditingController(text: p?.alias ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    // Pre-select country if it matches a known code
    final savedCode = p?.country ?? '';
    _selectedCountryCode = kCountries.any((c) => c.code == savedCode) ? savedCode : null;
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_aliasCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Alias cannot be empty.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final uid = widget.auth.currentUser!.uid;
    final err = await widget.auth.updateProfile(UserProfile(
      uid: uid,
      alias: _aliasCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      country: _selectedCountryCode ?? '',
    ));
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _signOut() async {
    await widget.auth.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Delete account?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This permanently deletes your account, profile, and all leaderboard entries. '
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete forever', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final err = await widget.auth.deleteAccount();
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: const Text('Your Profile', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelledField(
              label: 'Alias',
              hint: 'Shown on the leaderboard',
              ctrl: _aliasCtrl,
              maxLength: 16,
            ),
            const SizedBox(height: 10),
            _labelledField(
              label: 'Name (optional)',
              hint: 'Your real name — not shown publicly',
              ctrl: _nameCtrl,
            ),
            const SizedBox(height: 10),
            _countryDropdown(
              value: _selectedCountryCode,
              onChanged: (v) => setState(() => _selectedCountryCode = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(color: Color(0xFF7B68EE), fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : _deleteAccount,
          child: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ),
        TextButton(
          onPressed: _loading ? null : _signOut,
          child: const Text('Sign Out', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF533483)),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int? maxLength}) {
    return TextField(
      controller: ctrl,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _labelledField({required String label, required String hint, required TextEditingController ctrl, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        _field(ctrl, hint, maxLength: maxLength),
      ],
    );
  }

  Widget _countryDropdown({String? value, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Country (optional)', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white54,
          decoration: InputDecoration(
            hintText: 'Select country...',
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF533483)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('— None —', style: TextStyle(color: Colors.white38)),
            ),
            ...kCountries.map((c) => DropdownMenuItem<String>(
              value: c.code,
              child: Text('${countryCodeToFlag(c.code)}  ${c.name}',
                  style: const TextStyle(color: Colors.white)),
            )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
