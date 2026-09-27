part of '../girvi_account_detail_screen.dart';

class _PledgedItemSpecs extends StatelessWidget {
  final String pieceLabel;
  final String grossWeight;
  final String? lessWeight;
  final String netWeight;
  final String rate;
  final String? huid;
  final Color color;

  const _PledgedItemSpecs({
    required this.pieceLabel,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.rate,
    required this.huid,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth =
            constraints.maxWidth <= 0 ? 300.0 : constraints.maxWidth;
        final columns = safeWidth >= 560
            ? 3
            : safeWidth >= 360
                ? 2
                : 1;
        const spacing = 10.0;
        final tileWidth = (safeWidth - ((columns - 1) * spacing)) / columns;
        final rows = [
          _PledgedSpecData('Pieces', pieceLabel),
          _PledgedSpecData('Gross Weight', grossWeight),
          if (lessWeight != null) _PledgedSpecData('Less Weight', lessWeight!),
          _PledgedSpecData('Net Weight', netWeight, color: color),
          _PledgedSpecData('Rate / Gram', rate),
          if (huid != null) _PledgedSpecData('HUID', huid!),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: rows
              .map(
                (row) => SizedBox(
                  width: tileWidth,
                  child: _PledgedSpecTile(
                    label: row.label,
                    value: row.value,
                    color: row.color,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PledgedSpecData {
  final String label;
  final String value;
  final Color? color;

  const _PledgedSpecData(this.label, this.value, {this.color});
}

class _PledgedSpecTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PledgedSpecTile({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = color ?? GirviColors.textDark;
    return SizedBox(
      width: double.infinity,
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: valueColor,
                fontSize: 12.7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
