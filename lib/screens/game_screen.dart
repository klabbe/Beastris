import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/engine.dart';
import '../models/game_history.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../widgets/score_panel.dart';

enum _LeaderboardTab { allTime, thisWeek }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameEngine _engine = GameEngine();
  final GameHistory _history = GameHistory();
  final LeaderboardService _leaderboard = LeaderboardService();
  final AuthService _auth = AuthService();

  List<LeaderboardEntry> _topAllTime = [];
  List<LeaderboardEntry> _topWeekly = [];
  _LeaderboardTab _activeTab = _LeaderboardTab.allTime;
  GameResult? _savedResult;

  @override
  void initState() {
    super.initState();
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
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    try {
      final all = await _leaderboard.fetchTopScores();
      if (mounted) setState(() => _topAllTime = all);
    } catch (_) {}
    try {
      final weekly = await _leaderboard.fetchWeeklyScores();
      if (mounted) setState(() => _topWeekly = weekly);
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

  void _showGameOverDialog() {
    if (_savedResult == null) return;
    final result = _savedResult!;
    HapticFeedback.heavyImpact();
    final profile = _auth.profile;
    final nameController = TextEditingController(text: profile?.alias ?? '');
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
            Text(
              profile != null
                  ? 'Name on leaderboard (your alias):'
                  : 'Your name for the leaderboard:',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              maxLength: 16,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Anonymous...',
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
              final name = nameController.text.trim().isEmpty ? 'Anonymous' : nameController.text.trim();
              _leaderboard.submitScore(result, name,
                uid: _auth.currentUser?.uid,
                country: profile?.country,
              ).then((_) => _loadLeaderboards()).catchError((_) {});
              _goToMenu();
            },
            child: const Text('Menu'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim().isEmpty ? 'Anonymous' : nameController.text.trim();
              Navigator.pop(ctx);
              try {
                await _leaderboard.submitScore(result, name,
                  uid: _auth.currentUser?.uid,
                  country: profile?.country,
                );
                await _loadLeaderboards();
              } catch (_) {}
              _savedResult = null;
              _engine.startGame();
            },
            child: const Text('Submit & Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
          else
            ...entries.asMap().entries.map((entry) {
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
                      child: Text(
                        r.name,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (r.country.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(r.country, style: const TextStyle(fontSize: 12)),
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

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _aliasCtrl.dispose();
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
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
    setState(() { _loading = true; _error = null; });
    String? err;
    if (_isRegister) {
      final profile = UserProfile(
        uid: '',
        alias: _aliasCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
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
      title: Text(
        _isRegister ? 'Create Account' : 'Sign In',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_emailCtrl, 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _field(_passwordCtrl, 'Password', obscure: true),
            if (_isRegister) ...[
              const SizedBox(height: 10),
              _field(_aliasCtrl, 'Alias (shown on leaderboard)', maxLength: 16),
              const SizedBox(height: 10),
              _field(_nameCtrl, 'Name (optional)'),
              const SizedBox(height: 10),
              _field(_countryCtrl, 'Country (optional, e.g. 🇸🇪)'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => setState(() { _isRegister = !_isRegister; _error = null; }),
          child: Text(_isRegister ? 'Already have an account?' : 'Create account'),
        ),
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
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _countryCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.auth.profile;
    _aliasCtrl = TextEditingController(text: p?.alias ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _countryCtrl = TextEditingController(text: p?.country ?? '');
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _nameCtrl.dispose();
    _countryCtrl.dispose();
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
      country: _countryCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: const Text('Your Profile', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_aliasCtrl, 'Alias', maxLength: 16),
            const SizedBox(height: 10),
            _field(_nameCtrl, 'Name (optional)'),
            const SizedBox(height: 10),
            _field(_countryCtrl, 'Country (optional, e.g. 🇸🇪)'),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : _signOut,
          child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
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
}
