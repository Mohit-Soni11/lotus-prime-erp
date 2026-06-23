part of '../girvi_account_detail_screen.dart';

class _AccountMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? helper;

  const _AccountMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.helper,
  });
}

class _AccountInfoRowData {
  final String label;
  final String value;

  const _AccountInfoRowData(this.label, this.value);
}

class _AccountSurface extends StatelessWidget {
  final Widget child;

  const _AccountSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AccountMetricCard extends StatelessWidget {
  final _AccountMetricData data;

  const _AccountMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 158),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AccountIconBox(icon: data.icon, color: data.color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.value,
                  maxLines: 1,
                  style: GoogleFonts.manrope(
                    color: data.color,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          if (data.helper != null) ...[
            const SizedBox(height: 2),
            Text(
              data.helper!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _AccountSectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AccountIconBox(icon: icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GirviStyles.sectionTitle,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _AccountIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool large;

  const _AccountIconBox({
    required this.icon,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 46.0 : 34.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Icon(icon, color: color, size: large ? 22 : 17),
    );
  }
}

class _AccountCustomerAvatar extends StatelessWidget {
  final String initials;
  final Color statusColor;

  const _AccountCustomerAvatar({
    required this.initials,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: GirviColors.brandGold.withValues(alpha: 0.72),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GirviColors.brandGold.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                color: GirviColors.brandGold,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: GirviColors.cardBg, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: GirviColors.shadowMedium,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AccountMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountQuickFact extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AccountQuickFact({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: GirviColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textBody,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textDark,
                      fontSize: 12.7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountLifecycleItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _AccountLifecycleItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}

class _AccountLifecycleRail extends StatelessWidget {
  final List<_AccountLifecycleItem> items;

  const _AccountLifecycleRail({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: stacked
              ? Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _AccountLifecycleCell(item: items[index]),
                      if (index != items.length - 1)
                        const Divider(
                          height: 1,
                          color: GirviColors.cardBorder,
                        ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Expanded(
                        child: _AccountLifecycleCell(item: items[index]),
                      ),
                      if (index != items.length - 1)
                        Container(
                          width: 1,
                          height: 58,
                          color: GirviColors.cardBorder,
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _AccountLifecycleCell extends StatelessWidget {
  final _AccountLifecycleItem item;

  const _AccountLifecycleCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: item.color.withValues(alpha: 0.16)),
            ),
            child: Icon(item.icon, color: item.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: item.color,
                    fontSize: 14.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 11.1,
                    fontWeight: FontWeight.w700,
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

class _AccountStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AccountStatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                    fontSize: 11.5,
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
                        fontSize: 11.5,
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
              fontSize: 11,
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

class _PledgedPhotoStrip extends StatelessWidget {
  final List<String> photoPaths;
  final Color color;

  const _PledgedPhotoStrip({
    required this.photoPaths,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final paths = photoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (paths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          paths.length == 1 ? 'Photo' : 'Photos',
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _PledgedPhotoThumb(
              path: paths[index],
              index: index + 1,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _PledgedPhotoThumb extends StatelessWidget {
  final String path;
  final int index;
  final Color color;

  const _PledgedPhotoThumb({
    required this.path,
    required this.index,
    required this.color,
  });

  void _openPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.6,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.all(260),
                child: Center(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Image could not be opened',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close image',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scroll or pinch to zoom',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openPreview(context),
        child: Container(
          width: 122,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(path),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: color.withValues(alpha: 0.07),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                top: 7,
                left: 7,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 7,
                bottom: 7,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                fontSize: 11.5,
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

class _AccountDocumentButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _AccountDocumentButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.66,
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.075),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                _AccountIconBox(icon: icon, color: color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: GirviColors.textDark,
                          fontSize: 13.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountPrimaryCommandButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountPrimaryCommandButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: GirviColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _AccountActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        color == GirviColors.brandGold ? GirviColors.shellBg : Colors.white;
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: color.withValues(alpha: 0.45),
          disabledForegroundColor: foreground.withValues(alpha: 0.88),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _AccountHeaderButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _AccountHeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: GirviColors.shellBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GirviColors.shellBorder),
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(
            icon,
            color: GirviColors.shellTextTitle,
            size: 18,
          ),
          splashRadius: 20,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _AccountInfoGrid extends StatelessWidget {
  final List<_AccountInfoRowData> rows;
  final bool compact;

  const _AccountInfoGrid({
    required this.rows,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final safeWidth = maxWidth <= 0 ? 280.0 : maxWidth;
        final columns = compact
            ? 2
            : safeWidth >= 640
                ? 2
                : 1;
        const spacing = 10.0;
        final width = (safeWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: rows
              .map(
                (row) => SizedBox(
                  width: width > 0 ? width : safeWidth,
                  child: _AccountInfoTile(data: row),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  final _AccountInfoRowData data;

  const _AccountInfoTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInlineNotice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _AccountInlineNotice({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountEmptyBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _AccountEmptyBlock({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        children: [
          _AccountIconBox(icon: icon, color: GirviColors.textHint),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountLoadingState extends StatelessWidget {
  const _AccountLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: GirviColors.brandGold),
    );
  }
}

class _AccountErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onBack;

  const _AccountErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 420,
        child: _AccountSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _AccountIconBox(
                icon: Icons.error_outline_rounded,
                color: GirviColors.danger,
                large: true,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AccountActionButton(
                    icon: GirviIcons.backArrow,
                    label: 'Back to Ledger',
                    color: GirviColors.textDark,
                    onTap: onBack,
                  ),
                  _AccountActionButton(
                    icon: GirviIcons.refresh,
                    label: 'Retry',
                    color: GirviColors.brandGold,
                    onTap: onRetry,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GirviInvoiceFlipPreview extends StatefulWidget {
  const _GirviInvoiceFlipPreview({
    required this.sides,
    required this.onClose,
    this.singleSideLabel = 'Invoice preview',
  });

  final List<PdfRaster> sides;
  final VoidCallback onClose;
  final String singleSideLabel;

  @override
  State<_GirviInvoiceFlipPreview> createState() =>
      _GirviInvoiceFlipPreviewState();
}

class _GirviInvoiceFlipPreviewState extends State<_GirviInvoiceFlipPreview>
    with SingleTickerProviderStateMixin {
  static const double _minZoom = 0.70;
  static const double _maxZoom = 4.0;

  late final AnimationController _flipController;
  late final TransformationController _viewController;
  DateTime? _lastPointerDownAt;
  Offset? _lastPointerDownPosition;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _viewController = TransformationController();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _viewController.dispose();
    super.dispose();
  }

  void _toggleSide() {
    if (widget.sides.length < 2 || _flipController.isAnimating) return;
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final lastAt = _lastPointerDownAt;
    final lastPosition = _lastPointerDownPosition;
    final isDoubleClick = lastAt != null &&
        now.difference(lastAt) <= const Duration(milliseconds: 360) &&
        lastPosition != null &&
        (event.position - lastPosition).distance <= 16;

    _lastPointerDownAt = now;
    _lastPointerDownPosition = event.position;

    if (isDoubleClick) {
      _lastPointerDownAt = null;
      _lastPointerDownPosition = null;
      _toggleSide();
    }
  }

  void _zoomBy(double factor) {
    final currentScale = _viewController.value.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    final nextScale =
        (currentScale * factor).clamp(_minZoom, _maxZoom).toDouble();
    if ((nextScale - currentScale).abs() < 0.01) return;
    final scaleDelta = nextScale / currentScale;
    _viewController.value = _viewController.value.clone()
      ..scaleByDouble(scaleDelta, scaleDelta, scaleDelta, 1.0);
  }

  void _resetZoom() {
    _viewController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF111827)),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final firstSide = widget.sides.first;
                final aspectRatio = firstSide.width / firstSide.height;
                return Listener(
                  onPointerDown: _handlePointerDown,
                  child: InteractiveViewer(
                    transformationController: _viewController,
                    minScale: _minZoom,
                    maxScale: _maxZoom,
                    scaleFactor: 160,
                    trackpadScrollCausesScale: true,
                    boundaryMargin: const EdgeInsets.all(320),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              math.min(constraints.maxWidth * 0.94, 1180.0),
                          maxHeight: constraints.maxHeight * 0.94,
                        ),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: MouseRegion(
                            cursor: widget.sides.length > 1
                                ? SystemMouseCursors.click
                                : MouseCursor.defer,
                            child: AnimatedBuilder(
                              animation: _flipController,
                              builder: (context, _) {
                                final angle = _flipController.value * math.pi;
                                final showingBack = angle > math.pi / 2 &&
                                    widget.sides.length > 1;
                                final side = showingBack
                                    ? widget.sides[1]
                                    : widget.sides.first;

                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0012)
                                    ..rotateY(angle),
                                  child: showingBack
                                      ? Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(math.pi),
                                          child: _GirviInvoiceFlipSide(
                                            raster: side,
                                          ),
                                        )
                                      : _GirviInvoiceFlipSide(raster: side),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Material(
              color: Colors.black.withValues(alpha: 0.62),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close preview',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: _InvoiceFlipHint(
              canFlip: widget.sides.length > 1,
              singleSideLabel: widget.singleSideLabel,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: _InvoiceFlipPreviewToolbar(
              canFlip: widget.sides.length > 1,
              onFlip: _toggleSide,
              onZoomIn: () => _zoomBy(1.18),
              onZoomOut: () => _zoomBy(0.84),
              onReset: _resetZoom,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceFlipHint extends StatelessWidget {
  const _InvoiceFlipHint({
    required this.canFlip,
    required this.singleSideLabel,
  });

  final bool canFlip;
  final String singleSideLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canFlip ? Icons.touch_app_rounded : Icons.receipt_long_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              canFlip ? 'Double click to flip front/back' : singleSideLabel,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceFlipPreviewToolbar extends StatelessWidget {
  const _InvoiceFlipPreviewToolbar({
    required this.canFlip,
    required this.onFlip,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final bool canFlip;
  final VoidCallback onFlip;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InvoiceFlipPreviewToolButton(
              tooltip: 'Zoom out',
              icon: Icons.remove_rounded,
              onPressed: onZoomOut,
            ),
            _InvoiceFlipPreviewToolButton(
              tooltip: 'Reset zoom',
              icon: Icons.center_focus_strong_rounded,
              onPressed: onReset,
            ),
            _InvoiceFlipPreviewToolButton(
              tooltip: 'Zoom in',
              icon: Icons.add_rounded,
              onPressed: onZoomIn,
            ),
            if (canFlip)
              _InvoiceFlipPreviewToolButton(
                tooltip: 'Flip page',
                icon: Icons.flip_rounded,
                onPressed: onFlip,
              ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceFlipPreviewToolButton extends StatelessWidget {
  const _InvoiceFlipPreviewToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}

class _GirviInvoiceFlipSide extends StatelessWidget {
  const _GirviInvoiceFlipSide({required this.raster});

  final PdfRaster raster;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image(
          image: PdfRasterImage(raster),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
