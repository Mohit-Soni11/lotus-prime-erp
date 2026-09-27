part of '../girvi_account_detail_screen.dart';

class _PledgedFinancialSummary extends StatelessWidget {
  final String principal;
  final String interest;
  final String totalAmount;
  final String itemCount;
  final String netWeight;

  const _PledgedFinancialSummary({
    required this.principal,
    required this.interest,
    required this.totalAmount,
    required this.itemCount,
    required this.netWeight,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _PledgedSummaryMetric(
        label: 'Total Principal',
        value: principal,
        icon: Icons.account_balance_wallet_rounded,
        color: GirviColors.textDark,
      ),
      _PledgedSummaryMetric(
        label: 'Total Interest',
        value: interest,
        icon: Icons.percent_rounded,
        color: GirviColors.warning,
      ),
      _PledgedSummaryMetric(
        label: 'Total Amount',
        value: totalAmount,
        icon: Icons.summarize_rounded,
        color: GirviColors.success,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _AccountIconBox(
                icon: Icons.inventory_2_rounded,
                color: GirviColors.brandGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pledged Value Snapshot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _AccountStatusBadge(
                label: '$itemCount | $netWeight',
                color: GirviColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final safeWidth = constraints.maxWidth <= 0
                  ? MediaQuery.sizeOf(context).width
                  : constraints.maxWidth;
              final columns = safeWidth >= 760
                  ? 3
                  : safeWidth >= 460
                      ? 2
                      : 1;
              const spacing = 10.0;
              final width = (safeWidth - ((columns - 1) * spacing)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: width,
                        child: _PledgedSummaryMetricTile(metric: metric),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PledgedSummaryMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PledgedSummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _PledgedSummaryMetricTile extends StatelessWidget {
  final _PledgedSummaryMetric metric;

  const _PledgedSummaryMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: metric.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          _AccountIconBox(icon: metric.icon, color: metric.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    style: GoogleFonts.manrope(
                      color: metric.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PledgedItemDetailRow extends StatelessWidget {
  final int serialNo;
  final String itemName;
  final String metal;
  final String purity;
  final int pieces;
  final String grossWeight;
  final String? lessWeight;
  final String netWeight;
  final String rate;
  final String value;
  final String? huid;
  final List<String> photoPaths;
  final Color color;

  const _PledgedItemDetailRow({
    required this.serialNo,
    required this.itemName,
    required this.metal,
    required this.purity,
    required this.pieces,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.rate,
    required this.value,
    required this.huid,
    required this.photoPaths,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final huidText = huid?.trim();
    final hasHuid = huidText != null && huidText.isNotEmpty;
    final pieceLabel = pieces == 1 ? '1 piece' : '$pieces pieces';
    final metalLabel = metal.trim().isEmpty ? 'Metal not set' : metal.trim();
    final purityLabel =
        purity.trim().isEmpty ? 'Purity not set' : purity.trim();
    final hasPhotos = photoPaths.any((path) => path.trim().isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Text(
                  serialNo.toString().padLeft(2, '0'),
                  style: GoogleFonts.manrope(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item ${serialNo.toString().padLeft(2, '0')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Text(
                            itemName.trim().isEmpty ? 'Unnamed item' : itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: GirviColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _AccountStatusBadge(label: metalLabel, color: color),
                        _AccountStatusBadge(
                          label: purityLabel,
                          color: GirviColors.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PledgedValuePill(value: value, color: color),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = hasPhotos && constraints.maxWidth >= 700;
              final specs = _PledgedItemSpecs(
                pieceLabel: pieceLabel,
                grossWeight: grossWeight,
                lessWeight: lessWeight,
                netWeight: netWeight,
                rate: rate,
                huid: hasHuid ? huidText : null,
                color: color,
              );
              final photos = _PledgedPhotoStrip(
                photoPaths: photoPaths,
                color: color,
              );

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    specs,
                    photos,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: specs),
                  const SizedBox(width: 14),
                  SizedBox(width: 266, child: photos),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PledgedValuePill extends StatelessWidget {
  final String value;
  final Color color;

  const _PledgedValuePill({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Valuation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
