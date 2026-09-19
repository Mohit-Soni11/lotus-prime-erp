part of '../new_girvi_screen.dart';

class _LedgerPhotoCell extends StatelessWidget {
  const _LedgerPhotoCell({
    required this.width,
    required this.hasPhoto,
    required this.photoCount,
    required this.onTap,
    required this.onRemove,
  });

  final double width;
  final bool hasPhoto;
  final int photoCount;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: hasPhoto
              ? GirviColors.success.withValues(alpha: 0.08)
              : GirviColors.brandGoldLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasPhoto
                ? GirviColors.success.withValues(alpha: 0.24)
                : GirviColors.brandGold.withValues(alpha: 0.24),
          ),
        ),
        child: hasPhoto
            ? Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$photoCount',
                          style: GoogleFonts.manrope(
                            color: GirviColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: GirviColors.success.withValues(alpha: 0.18),
                  ),
                  InkWell(
                    onTap: onRemove,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 38,
                      child: Icon(
                        Icons.close_rounded,
                        color: GirviColors.danger,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              )
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: const Center(
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: GirviColors.brandGold,
                    size: 18,
                  ),
                ),
              ),
      ),
    );
  }
}

class _PledgedPhotoThumbnail extends StatelessWidget {
  const _PledgedPhotoThumbnail({
    required this.serialNo,
    required this.title,
    required this.path,
    required this.onPreview,
    required this.onRemove,
  });

  final int serialNo;
  final String title;
  final String path;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        decoration: BoxDecoration(
          color: GirviColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onPreview,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: SizedBox(
                  height: 88,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: GirviColors.inputBgLocked,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: GirviColors.textMuted,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      serialNo.toString().padLeft(2, '0'),
                      style: GoogleFonts.manrope(
                        color: GirviColors.brandDeep,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GirviColors.dangerBg,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: GirviColors.dangerBorder),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: GirviColors.danger,
                        size: 14,
                      ),
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

class _LedgerActionCell extends StatelessWidget {
  const _LedgerActionCell({
    required this.width,
    required this.enabled,
    required this.onDelete,
  });

  final double width;
  final bool enabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: InkWell(
          onTap: enabled ? onDelete : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? GirviColors.dangerBg : GirviColors.inputBgLocked,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    enabled ? GirviColors.dangerBorder : GirviColors.cardBorder,
              ),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: enabled ? GirviColors.danger : GirviColors.textHint,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalWeightSummary {
  const _MetalWeightSummary({
    required this.metal,
    required this.pieces,
    required this.gross,
    required this.less,
    required this.net,
  });

  final MetalType metal;
  final int pieces;
  final double gross;
  final double less;
  final double net;
}

class _PledgedLedgerBottomBar extends StatelessWidget {
  const _PledgedLedgerBottomBar({
    required this.totalItems,
    required this.totalPieces,
    required this.summaries,
    required this.onAdd,
  });

  final int totalItems;
  final int totalPieces;
  final List<_MetalWeightSummary> summaries;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final addButton = _LedgerAddButton(onTap: onAdd);
          final totals = _PledgedLedgerMetric(
            label: 'ITEMS / PCS',
            value: '$totalItems / $totalPieces',
            color: GirviColors.success,
          );
          final summaryChips = summaries
              .map((summary) => _MetalWeightSummaryChip(summary: summary))
              .toList();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    addButton,
                    const SizedBox(width: 10),
                    Expanded(child: totals),
                  ],
                ),
                if (summaryChips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summaryChips,
                  ),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              addButton,
              const SizedBox(width: 10),
              SizedBox(width: 208, child: totals),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: summaryChips,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PledgedLedgerMetric extends StatelessWidget {
  const _PledgedLedgerMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: color,
                  size: 13,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.manrope(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _WeightMiniText(
                  label: 'Items',
                  value: value.split('/').first.trim(),
                ),
              ),
              Expanded(
                child: _WeightMiniText(
                  label: 'Pieces',
                  value: value.split('/').last.trim(),
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetalWeightSummaryChip extends StatelessWidget {
  const _MetalWeightSummaryChip({required this.summary});

  final _MetalWeightSummary summary;

  @override
  Widget build(BuildContext context) {
    final accent = _pledgedMetalAccent(summary.metal);
    return Container(
      width: 208,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  GirviIcons.itemDetails,
                  color: accent,
                  size: 13,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${summary.metal.displayName.toUpperCase()} TOTAL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                summary.pieces == 1 ? '1 piece' : '${summary.pieces} pieces',
                style: GoogleFonts.manrope(
                  color: accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _WeightMiniText(
                  label: 'Gross',
                  value: _formatSmartWeight(summary.gross),
                ),
              ),
              Expanded(
                child: _WeightMiniText(
                  label: 'Less',
                  value: _formatSmartWeight(summary.less),
                ),
              ),
              Expanded(
                child: _WeightMiniText(
                  label: 'Net',
                  value: _formatSmartWeight(summary.net),
                  color: GirviColors.brandGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightMiniText extends StatelessWidget {
  const _WeightMiniText({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GirviStyles.caption.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: color ?? GirviColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
