part of '../new_girvi_screen.dart';

// =============================================================================
// HELPER WIDGETS (private to this file)
// =============================================================================

String _formatSmartNumber(
  double value, {
  int decimalPlaces = 3,
  bool dashWhenZero = false,
}) {
  if (!value.isFinite) return dashWhenZero ? '-' : '0';
  if (value.abs() < 0.000001) return dashWhenZero ? '-' : '0';
  if ((value - value.roundToDouble()).abs() < 0.000001) {
    return NumberFormat('#,##,##0', 'en_IN').format(value);
  }
  final pattern = '#,##,##0.${'0' * decimalPlaces}';
  return NumberFormat(pattern, 'en_IN').format(value);
}

String _formatSmartMoney(double value, {bool dashWhenZero = false}) {
  final formatted =
      _formatSmartNumber(value, decimalPlaces: 3, dashWhenZero: dashWhenZero);
  return formatted == '-' ? '-' : 'Rs $formatted';
}

String _formatSmartWeight(double value, {bool dashWhenZero = false}) {
  final formatted =
      _formatSmartNumber(value, decimalPlaces: 3, dashWhenZero: dashWhenZero);
  return formatted == '-' ? '-' : '$formatted g';
}

String _formatSmartPercent(double value, {bool dashWhenZero = false}) {
  final formatted =
      _formatSmartNumber(value, decimalPlaces: 3, dashWhenZero: dashWhenZero);
  return formatted == '-' ? '-' : '$formatted%';
}

class _KycPhotoCard extends StatelessWidget {
  final bool enabled;
  final String? documentName;
  final String? photoPath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  const _KycPhotoCard({
    required this.enabled,
    required this.documentName,
    required this.photoPath,
    required this.onCamera,
    required this.onGallery,
    required this.onPreview,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final hasPhoto = path != null && path.isNotEmpty && File(path).existsSync();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? GirviColors.inputBg : GirviColors.inputBgLocked,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPhoto
              ? GirviColors.success.withValues(alpha: 0.45)
              : GirviColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled
                      ? GirviColors.brandGoldLight
                      : GirviColors.cardBorder.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  hasPhoto
                      ? Icons.verified_rounded
                      : Icons.document_scanner_outlined,
                  color: hasPhoto
                      ? GirviColors.success
                      : enabled
                          ? GirviColors.brandGold
                          : GirviColors.textHint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Photo',
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      !enabled
                          ? 'Available after selecting an ID'
                          : hasPhoto
                              ? '${documentName ?? 'KYC'} attached'
                              : 'Camera or gallery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GirviStyles.caption.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (hasPhoto)
                IconButton(
                  tooltip: 'Remove photo',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: GirviColors.danger,
                    size: 19,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: hasPhoto ? onPreview : null,
            child: Container(
              height: 104,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: GirviColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GirviColors.cardBorder),
              ),
              child: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(path), fit: BoxFit.cover),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(7),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  GirviColors.shellBg.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          enabled
                              ? Icons.add_a_photo_outlined
                              : Icons.lock_outline_rounded,
                          color: enabled
                              ? GirviColors.brandGold
                              : GirviColors.textHint,
                          size: 25,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          enabled
                              ? 'Attach a clear photo of the card'
                              : 'Select an identity document first',
                          style: GirviStyles.caption.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _KycPhotoButton(
                  icon: Icons.camera_alt_outlined,
                  label: hasPhoto ? 'Retake' : 'Camera',
                  enabled: enabled,
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KycPhotoButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  enabled: enabled,
                  onTap: onGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KycPhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _KycPhotoButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: GirviColors.brandDeep,
          side: BorderSide(
            color: enabled
                ? GirviColors.brandGold.withValues(alpha: 0.5)
                : GirviColors.cardBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PledgedItemHeader extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  const _PledgedItemHeader({
    required this.photoPath,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final hasPhoto = path != null && path.isNotEmpty && File(path).existsSync();
    final file = hasPhoto ? File(path) : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final preview = Container(
            width: compact ? 78 : 92,
            height: compact ? 66 : 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasPhoto
                    ? GirviColors.brandGold.withValues(alpha: 0.35)
                    : GirviColors.cardBorder,
              ),
            ),
            child: hasPhoto && file != null
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: GirviColors.textHint,
                      size: 26,
                    ),
                  )
                : const Icon(
                    Icons.add_a_photo_outlined,
                    color: GirviColors.brandGold,
                    size: 26,
                  ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pledged Item Photo',
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPhoto
                    ? 'Photo attached for this ticket audit trail.'
                    : 'Attach a clear image of the pledged item.',
                style: GirviStyles.caption.copyWith(fontSize: 12.5),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 4),
                Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(
                    fontSize: 12.5,
                    color: GirviColors.textHint,
                  ),
                ),
              ],
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PhotoActionButton(
                icon: hasPhoto ? Icons.sync_rounded : Icons.upload_rounded,
                label: hasPhoto ? 'Change' : 'Upload',
                filled: true,
                onTap: onPickPhoto,
              ),
              if (hasPhoto)
                _PhotoActionButton(
                  icon: Icons.close_rounded,
                  label: 'Remove',
                  filled: false,
                  onTap: onRemovePhoto,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  preview,
                  const SizedBox(width: 12),
                  Expanded(child: details),
                ]),
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              preview,
              const SizedBox(width: 12),
              Expanded(child: details),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? GirviColors.brandGold : GirviColors.textBody;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: filled ? GirviColors.brandGoldLight : GirviColors.cardBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: filled
                ? GirviColors.brandGold.withValues(alpha: 0.35)
                : GirviColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeskMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DeskMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GirviStyles.caption.copyWith(fontSize: 12.5)),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
