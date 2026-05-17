import 'package:flutter/material.dart';

import '../../games/beastblocks/screens/game_screen.dart';
import '../../games/yatzy/screens/yatzy_setup_screen.dart';

class PortalScreen extends StatelessWidget {
  const PortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BeastGames',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Välj ett spel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withAlpha(153),
                ),
              ),
              const SizedBox(height: 40),
              _GameCard(
                title: 'BeastBlocks',
                description: 'Klassiskt blockspel med highscore och leaderboard.',
                imagePath: 'assets/icon/app_icon.png',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _GameCard(
                title: 'Yatzy',
                description: '1–4 spelare. Kasta tärningar och fyll i poängblocket.',
                icon: Icons.casino_rounded,
                accentColor: const Color(0xFF1976D2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const YatzySetupScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.description,
    required this.onTap,
    this.imagePath,
    this.icon,
    this.accentColor,
  });

  final String title;
  final String description;
  final String? imagePath;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath != null
                    ? Image.asset(imagePath!, width: 56, height: 56, fit: BoxFit.cover)
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: accentColor ?? const Color(0xFF533483),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon ?? Icons.games_rounded,
                            color: Colors.white, size: 30),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
