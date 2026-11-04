import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookMetalPositionPanel extends StatelessWidget {
  const DayBookMetalPositionPanel({super.key, required this.summary});

  final DayBookSummary summary;

  @override
  Widget build(BuildContext context) {
    final verified = summary.metalPositionVerified;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DayBookStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(DayBookIcons.vault,
                  size: 21, color: DayBookColors.goldMetal),
              const SizedBox(width: 9),
              Expanded(
                child:
                    Text('Metal Position', style: DayBookStyles.sectionTitle),
              ),
              if (!verified)
                const Tooltip(
                  message:
                      'Historical owned-stock baseline needs verification.',
                  child: _VerificationBadge(),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Owned gold and silver opening and closing stock. Girvi custody is tracked separately.',
            style: DayBookStyles.sectionSubtitle,
          ),
          const SizedBox(height: 14),
          _MetalLine(
            label: 'Gold',
            icon: DayBookIcons.gold,
            color: DayBookColors.goldMetal,
            opening: verified ? _weight(summary.openingGoldGrams) : '—',
            closing: verified
                ? _weight(
                    _ownedClosing(summary, 'gold', summary.openingGoldGrams))
                : '—',
          ),
          const SizedBox(height: 8),
          _MetalLine(
            label: 'Silver',
            icon: DayBookIcons.silver,
            color: DayBookColors.silverMetal,
            opening: verified ? _weight(summary.openingSilverGrams) : '—',
            closing: verified
                ? _weight(_ownedClosing(
                    summary, 'silver', summary.openingSilverGrams))
                : '—',
          ),
        ],
      ),
    );
  }
}

String _weight(double grams) =>
    '${NumberFormat.decimalPatternDigits(locale: 'en_IN', decimalDigits: 3).format(grams)} g';

double _ownedClosing(DayBookSummary summary, String metal, double opening) =>
    opening +
    summary.stockMovements
        .where((movement) => movement.metal.trim().toLowerCase() == metal)
        .fold<double>(0, (total, movement) => total + movement.netWeightDelta);

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.warningSoft,
          borderColor: DayBookColors.warningBorder,
        ),
        child: Text(
          'Unverified',
          style: DayBookStyles.labelStrong.copyWith(
            fontSize: 11,
            color: DayBookColors.warning,
          ),
        ),
      );
}

class _MetalLine extends StatelessWidget {
  const _MetalLine({
    required this.label,
    required this.icon,
    required this.color,
    required this.opening,
    required this.closing,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String opening;
  final String closing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.bodySubtle,
          borderColor: DayBookColors.bodyBorder,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text(label, style: DayBookStyles.labelStrong),
            ),
            Expanded(child: _PositionValue(label: 'Opening', value: opening)),
            const SizedBox(width: 8),
            Expanded(child: _PositionValue(label: 'Closing', value: closing)),
          ],
        ),
      );
}

class _PositionValue extends StatelessWidget {
  const _PositionValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: DayBookStyles.label.copyWith(fontSize: 11)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DayBookStyles.value,
          ),
        ],
      );
}
