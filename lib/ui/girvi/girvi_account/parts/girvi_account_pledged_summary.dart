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
                          fontSize: 12.5,
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
                      fontSize: 12.5,
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
