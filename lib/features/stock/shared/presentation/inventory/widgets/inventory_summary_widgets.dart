part of '../inventory_screen.dart';

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String note;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final String bigNumber;
  final String bigUnit;
  final String row1Label;
  final String row1Value;
  final String row2Label;
  final String row2Value;
  final Widget? deltaWidget;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.note,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.bigNumber,
    required this.bigUnit,
    required this.row1Label,
    required this.row1Value,
    required this.row2Label,
    required this.row2Value,
    this.deltaWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InvStyles.summaryCard(accentColor, bgColor, borderColor),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: InvStyles.cardLabel.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      note,
                      style: InvStyles.cardNote,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bigNumber,
                style: InvStyles.cardBigNumber.copyWith(color: accentColor),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  bigUnit,
                  style: InvStyles.cardNote.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stats rows
          _StatRow(label: row1Label, value: row1Value),
          const SizedBox(height: 4),
          _StatRow(label: row2Label, value: row2Value),

          if (deltaWidget != null) ...[
            const SizedBox(height: 10),
            deltaWidget!,
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: InvStyles.cardNote),
        Text(
          value,
          style: InvStyles.cardSubValue.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// =============================================================================
// MOVEMENT CHIP (today's +/- on closing card)
// =============================================================================

class _MovementChip extends StatelessWidget {
  final int added;
  final int sold;
  const _MovementChip({required this.added, required this.sold});

  @override
  Widget build(BuildContext context) {
    if (added == 0 && sold == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (added > 0)
          _chip('+$added added today', InvColors.success, InvColors.successBg),
        if (added > 0 && sold > 0) const SizedBox(width: 6),
        if (sold > 0)
          _chip('-$sold sold today', InvColors.danger, InvColors.dangerBg),
      ],
    );
  }

  Widget _chip(String text, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

// =============================================================================
// METAL HOLDING CHIP
// =============================================================================

class _MetalHoldingChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final double weight;
  final double value;
  final Color bg;
  final Color textColor;
  final Color border;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;
  final bool showWeight;
  final bool showValue;

  const _MetalHoldingChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.weight,
    required this.value,
    required this.bg,
    required this.textColor,
    required this.border,
    required this.rupeeFormat,
    required this.wtFormat,
    this.showWeight = true,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: InvStyles.metalChip(bg, border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: InvStyles.metalChipText(
                  textColor,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count pcs',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (showWeight && weight > 0)
            Text(
              '${wtFormat.format(weight)} g',
              style: InvStyles.metalChipText(
                textColor,
              ).copyWith(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          if (showValue && value > 0)
            Text(
              rupeeFormat.format(value),
              style: InvStyles.metalChipText(
                textColor,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// STOCK ITEM CARD
// =============================================================================
