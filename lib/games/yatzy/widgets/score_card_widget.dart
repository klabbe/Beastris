import 'package:flutter/material.dart';

import '../models/score_card.dart';

class ScoreCardWidget extends StatelessWidget {
  const ScoreCardWidget({
    super.key,
    required this.scoreCard,
    required this.previews,
    required this.onSelectCategory,
    this.canScore = false,
  });

  final ScoreCard scoreCard;
  final Map<ScoreCategory, int> previews;
  final void Function(ScoreCategory) onSelectCategory;
  final bool canScore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(label: 'Övre sektion (bonus +50 vid ≥63)'),
        ...ScoreCategory.values
            .where((c) => c.isUpperSection)
            .map((c) => _ScoreRow(
                  category: c,
                  scored: scoreCard[c],
                  preview: previews[c],
                  onTap: canScore && !scoreCard.isScored(c)
                      ? () => onSelectCategory(c)
                      : null,
                )),
        _BonusRow(
          upperSum: scoreCard.upperSum,
          bonus: scoreCard.upperBonus,
        ),
        const SizedBox(height: 4),
        _SectionHeader(label: 'Nedre sektion'),
        ...ScoreCategory.values
            .where((c) => !c.isUpperSection)
            .map((c) => _ScoreRow(
                  category: c,
                  scored: scoreCard[c],
                  preview: previews[c],
                  onTap: canScore && !scoreCard.isScored(c)
                      ? () => onSelectCategory(c)
                      : null,
                )),
        const Divider(height: 12),
        _TotalRow(total: scoreCard.total),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: const Color(0xFF533483).withAlpha(80),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD1B3FF))),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.category,
    required this.scored,
    required this.preview,
    this.onTap,
  });

  final ScoreCategory category;
  final int? scored;
  final int? preview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isScored = scored != null;
    final showPreview = !isScored && preview != null && onTap != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: Colors.white.withAlpha(15), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: isScored
                      ? Colors.white.withAlpha(180)
                      : onTap != null
                          ? Colors.white
                          : Colors.white.withAlpha(100),
                ),
              ),
            ),
            if (isScored)
              Text(
                '$scored',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              )
            else if (showPreview)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: preview! > 0
                      ? const Color(0xFF533483).withAlpha(160)
                      : Colors.red.withAlpha(80),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  preview! > 0 ? '+$preview' : '0',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: preview! > 0
                        ? const Color(0xFFD1B3FF)
                        : Colors.redAccent,
                  ),
                ),
              )
            else
              Text(
                '—',
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withAlpha(60)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  const _BonusRow({required this.upperSum, required this.bonus});
  final int upperSum;
  final int bonus;

  @override
  Widget build(BuildContext context) {
    final remaining = (63 - upperSum).clamp(0, 63);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: Colors.white.withAlpha(8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bonus > 0
                  ? 'Bonus uppnådd! 🎉'
                  : 'Kvar till bonus: $remaining',
              style: TextStyle(
                  fontSize: 12,
                  color: bonus > 0
                      ? const Color(0xFF4CAF50)
                      : Colors.white.withAlpha(150)),
            ),
          ),
          Text(
            bonus > 0 ? '+50' : '$upperSum / 63',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: bonus > 0
                    ? const Color(0xFF4CAF50)
                    : Colors.white.withAlpha(150)),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Expanded(
            child: Text('Totalt',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          Text('$total',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
