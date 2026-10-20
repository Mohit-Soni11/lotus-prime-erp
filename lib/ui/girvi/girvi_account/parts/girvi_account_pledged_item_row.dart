part of '../girvi_account_detail_screen.dart';

class _PledgedItemDetailRow extends StatelessWidget {
  final bool showSerial;
  final int serialNo;
  final String itemName;
  final String metal;
  final String purity;
  final String? pieceLabel;
  final String? grossWeight;
  final String? lessWeight;
  final String netWeight;
  final String? huid;
  final List<String> photoPaths;
  final Color color;

  const _PledgedItemDetailRow({
    required this.showSerial,
    required this.serialNo,
    required this.itemName,
    required this.metal,
    required this.purity,
    required this.pieceLabel,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.huid,
    required this.photoPaths,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final huidText = huid?.trim();
    final hasHuid = huidText != null && huidText.isNotEmpty;
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
              if (showSerial) ...[
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
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  children: [specs, photos],
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
