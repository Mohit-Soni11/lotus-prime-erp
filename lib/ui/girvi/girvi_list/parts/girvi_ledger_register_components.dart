part of '../girvi_list_screen.dart';

class _RegisterStatusBadge extends StatelessWidget {
  const _RegisterStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _RegisterMetaBadge extends StatelessWidget {
  const _RegisterMetaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 11.6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _RegisterAmountPanel extends StatelessWidget {
  const _RegisterAmountPanel({required this.quote, required this.money});

  final GirviInterestQuote quote;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GirviColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RegisterAmountLine(
              label: 'Principal Due',
              value: money(quote.principalDue),
              color: quote.principalDue > 0.005
                  ? GirviColors.danger
                  : GirviColors.success,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: GirviColors.divider),
            const SizedBox(height: 8),
            _RegisterAmountLine(
              label: 'Interest Due',
              value: money(quote.interestOutstanding),
              color: quote.interestOutstanding > 0.005
                  ? GirviColors.danger
                  : GirviColors.success,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: GirviColors.divider),
            const SizedBox(height: 8),
            _RegisterAmountLine(
              label: 'Net Payable',
              value: money(quote.totalPayable),
              color: quote.totalPayable > 0.005
                  ? GirviColors.danger
                  : GirviColors.success,
            ),
          ],
        ),
      );
}

class _RegisterAmountLine extends StatelessWidget {
  const _RegisterAmountLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
}
