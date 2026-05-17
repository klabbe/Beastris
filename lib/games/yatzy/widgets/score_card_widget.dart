import 'package:flutter/material.dart';

import '../engine.dart';
import '../models/score_card.dart';

/// Multi-player scorecard: one column per player.
class ScoreCardWidget extends StatelessWidget {
  const ScoreCardWidget({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.previews,
    required this.onSelectCategory,
    this.canScore = false,
  });

  final List<YatzyPlayer> players;
  final int currentPlayerIndex;
  final Map<ScoreCategory, int> previews;
  final void Function(ScoreCategory) onSelectCategory;
  final bool canScore;

  static const int _labelFlex = 3;
  static const int _playerFlex = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeaderRow(
          players: players,
          currentIndex: currentPlayerIndex,
          labelFlex: _labelFlex,
          playerFlex: _playerFlex,
        ),
        _SectionBar(label: 'Övre sektion  ·  bonus +50 vid ≥63'),
        ...ScoreCategory.values.where((c) => c.isUpperSection).map(
              (c) => _CategoryRow(
                category: c,
                players: players,
                currentIndex: currentPlayerIndex,
                previews: previews,
                canScore: canScore,
                onTap: canScore &&
                        !players[currentPlayerIndex].scoreCard.isScored(c)
                    ? () => onSelectCategory(c)
                    : null,
                labelFlex: _labelFlex,
                playerFlex: _playerFlex,
              ),
            ),
        _BonusRow(
            players: players,
            labelFlex: _labelFlex,
            playerFlex: _playerFlex),
        _SectionBar(label: 'Nedre sektion'),
        ...ScoreCategory.values.where((c) => !c.isUpperSection).map(
              (c) => _CategoryRow(
                category: c,
                players: players,
                currentIndex: currentPlayerIndex,
                previews: previews,
                canScore: canScore,
                onTap: canScore &&
                        !players[currentPlayerIndex].scoreCard.isScored(c)
                    ? () => onSelectCategory(c)
                    : null,
                labelFlex: _labelFlex,
                playerFlex: _playerFlex,
              ),
            ),
        const Divider(height: 8, thickness: 1),
        _TotalRow(
          players: players,
          currentIndex: currentPlayerIndex,
          labelFlex: _labelFlex,
          playerFlex: _playerFlex,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Header row ──────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.players,
    required this.currentIndex,
    required this.labelFlex,
    required this.playerFlex,
  });
  final List<YatzyPlayer> players;
  final int currentIndex;
  final int labelFlex;
  final int playerFlex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0f0f1e),
      child: Row(
        children: [
          Expanded(flex: labelFlex, child: const SizedBox.shrink()),
          ...players.asMap().entries.map((e) {
            final isActive = e.key == currentIndex;
            return Expanded(
              flex: playerFlex,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFF8B5CF6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  e.value.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withAlpha(120),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Section bar ─────────────────────────────────────────────────────────────

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: const Color(0xFF533483).withAlpha(80),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD1B3FF),
        ),
      ),
    );
  }
}

// ─── Category row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.players,
    required this.currentIndex,
    required this.previews,
    required this.canScore,
    required this.onTap,
    required this.labelFlex,
    required this.playerFlex,
  });

  final ScoreCategory category;
  final List<YatzyPlayer> players;
  final int currentIndex;
  final Map<ScoreCategory, int> previews;
  final bool canScore;
  final VoidCallback? onTap;
  final int labelFlex;
  final int playerFlex;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: Colors.white.withAlpha(12), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: labelFlex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                child: Text(
                  category.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: onTap != null
                        ? Colors.white
                        : Colors.white.withAlpha(130),
                  ),
                ),
              ),
            ),
            ...players.asMap().entries.map((e) {
              final pIdx = e.key;
              final sc = e.value.scoreCard;
              final isCurrentPlayer = pIdx == currentIndex;
              final scored = sc[category];
              final preview = isCurrentPlayer ? previews[category] : null;
              final showPreview =
                  scored == null && preview != null && canScore;

              return Expanded(
                flex: playerFlex,
                child: Container(
                  color: isCurrentPlayer
                      ? Colors.white.withAlpha(6)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      vertical: 7, horizontal: 2),
                  alignment: Alignment.center,
                  child: _CellValue(
                    scored: scored,
                    preview: showPreview ? preview : null,
                    isCurrentPlayer: isCurrentPlayer,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CellValue extends StatelessWidget {
  const _CellValue({
    required this.scored,
    required this.preview,
    required this.isCurrentPlayer,
  });
  final int? scored;
  final int? preview;
  final bool isCurrentPlayer;

  @override
  Widget build(BuildContext context) {
    if (scored != null) {
      return Text(
        '$scored',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isCurrentPlayer
              ? Colors.white
              : Colors.white.withAlpha(160),
        ),
      );
    }
    if (preview != null) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: preview! > 0
              ? const Color(0xFF533483).withAlpha(180)
              : Colors.red.withAlpha(70),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          preview! > 0 ? '+$preview' : '0',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: preview! > 0
                ? const Color(0xFFD1B3FF)
                : Colors.redAccent,
          ),
        ),
      );
    }
    return Text(
      '—',
      style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(50)),
    );
  }
}

// ─── Bonus row ────────────────────────────────────────────────────────────────

class _BonusRow extends StatelessWidget {
  const _BonusRow({
    required this.players,
    required this.labelFlex,
    required this.playerFlex,
  });
  final List<YatzyPlayer> players;
  final int labelFlex;
  final int playerFlex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(8),
      child: Row(
        children: [
          Expanded(
            flex: labelFlex,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                'Bonus',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withAlpha(150)),
              ),
            ),
          ),
          ...players.map((p) {
            final bonus = p.scoreCard.upperBonus;
            final sum = p.scoreCard.upperSum;
            final hasBonus = bonus > 0;
            return Expanded(
              flex: playerFlex,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 5, horizontal: 2),
                alignment: Alignment.center,
                child: Text(
                  hasBonus ? '+50✓' : '$sum/63',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasBonus
                        ? const Color(0xFF4CAF50)
                        : Colors.white.withAlpha(130),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Total row ────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.players,
    required this.currentIndex,
    required this.labelFlex,
    required this.playerFlex,
  });
  final List<YatzyPlayer> players;
  final int currentIndex;
  final int labelFlex;
  final int playerFlex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: labelFlex,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              'Totalt',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...players.asMap().entries.map((e) {
          final isActive = e.key == currentIndex;
          return Expanded(
            flex: playerFlex,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              alignment: Alignment.center,
              child: Text(
                '${e.value.scoreCard.total}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? const Color(0xFFD1B3FF)
                      : Colors.white,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
