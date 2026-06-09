part of '../new_girvi_screen.dart';

// =============================================================================
// HELPER WIDGETS (private to this file)
// =============================================================================

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
                      style: GirviStyles.caption.copyWith(fontSize: 10.5),
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
                            fontSize: 10.5,
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
            fontSize: 11,
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
                style: GirviStyles.caption.copyWith(fontSize: 11),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 4),
                Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(
                    fontSize: 10,
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
                fontSize: 11,
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
                Text(label, style: GirviStyles.caption.copyWith(fontSize: 10)),
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
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _InvoiceCustomerCard extends StatelessWidget {
  final String name;
  final String mobile;
  final bool ready;

  const _InvoiceCustomerCard({
    required this.name,
    required this.mobile,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = ready && words.isNotEmpty
        ? words.take(2).map((word) => word[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: ready
            ? GirviColors.info.withValues(alpha: 0.055)
            : GirviColors.warning.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready
              ? GirviColors.info.withValues(alpha: 0.18)
              : GirviColors.warning.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ready
                  ? GirviColors.info.withValues(alpha: 0.13)
                  : GirviColors.warning.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                color: ready ? GirviColors.info : GirviColors.warning,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'BORROWER' : 'BORROWER REQUIRED',
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mobile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ready
                  ? GirviColors.success.withValues(alpha: 0.09)
                  : GirviColors.inputBgLocked,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ready
                    ? GirviColors.success.withValues(alpha: 0.20)
                    : GirviColors.cardBorder,
              ),
            ),
            child: Icon(
              ready ? Icons.lock_rounded : Icons.person_search_outlined,
              color: ready ? GirviColors.success : GirviColors.textHint,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceAmountHero extends StatelessWidget {
  final String loanAmount;
  final String maturityAmount;
  final String duration;

  const _InvoiceAmountHero({
    required this.loanAmount,
    required this.maturityAmount,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GirviColors.brandGold.withValues(alpha: 0.14),
            GirviColors.brandGold.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GirviColors.brandGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  GirviIcons.cash,
                  color: GirviColors.brandDeep,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'LOAN TO DISBURSE',
                style: GoogleFonts.inter(
                  color: GirviColors.brandDeep,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GirviColors.cardBg.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: GirviColors.brandGold.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  duration,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            loanAmount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: GirviColors.brandGoldGlow),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                'TOTAL AT MATURITY',
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  maturityAmount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.manrope(
                    color: GirviColors.brandDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InvoiceMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GirviStyles.caption.copyWith(
              fontSize: 8.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InvoiceDetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 8),
            child: Row(
              children: [
                Icon(icon, color: GirviColors.brandGold, size: 15),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.75,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: GirviColors.divider),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 11),
                child: Divider(height: 1, color: GirviColors.divider),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InvoiceDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InvoiceDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GirviColors.textHint, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                color: valueColor ?? GirviColors.textDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePaymentPart {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InvoicePaymentPart({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _InvoicePaymentBreakdown extends StatelessWidget {
  final List<_InvoicePaymentPart> parts;
  final String totalPaid;
  final String loanAmount;
  final String differenceLabel;
  final bool ready;

  const _InvoicePaymentBreakdown({
    required this.parts,
    required this.totalPaid,
    required this.loanAmount,
    required this.differenceLabel,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final mixed = parts.length > 1;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: ready
              ? GirviColors.success.withValues(alpha: 0.24)
              : GirviColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GirviColors.info.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: GirviColors.info,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mixed ? 'MIXED PAYMENT' : 'PAYMENT BREAKDOWN',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.65,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automatically detected from entered amounts',
                      style: GirviStyles.caption.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: GirviColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GirviColors.info.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  'AUTO',
                  style: GoogleFonts.inter(
                    color: GirviColors.info,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (parts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: GirviColors.cardBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: GirviColors.cardBorder),
              ),
              child: Text(
                'Enter Cash, UPI, Bank or Cheque amount above.',
                textAlign: TextAlign.center,
                style: GirviStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final part in parts) _InvoicePaymentChip(part: part),
              ],
            ),
          const SizedBox(height: 10),
          Container(height: 1, color: GirviColors.divider),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _InvoicePaymentTotal(
                  label: 'Disbursed',
                  value: totalPaid,
                  color: ready ? GirviColors.success : GirviColors.textDark,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: GirviColors.divider,
              ),
              Expanded(
                child: _InvoicePaymentTotal(
                  label: 'Loan Amount',
                  value: loanAmount,
                  color: GirviColors.brandDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: ready
                  ? GirviColors.success.withValues(alpha: 0.08)
                  : GirviColors.warning.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: ready ? GirviColors.success : GirviColors.warning,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    ready ? 'Payment total matched' : differenceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: ready ? GirviColors.success : GirviColors.warning,
                      fontSize: 9.5,
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

class _InvoicePaymentChip extends StatelessWidget {
  final _InvoicePaymentPart part;

  const _InvoicePaymentChip({required this.part});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: part.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: part.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(part.icon, color: part.color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.label,
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                part.value,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoicePaymentTotal extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InvoicePaymentTotal({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GirviStyles.caption.copyWith(fontSize: 8.5)),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InvoiceReadinessCard extends StatelessWidget {
  final bool customerReady;
  final bool itemsReady;
  final bool amountReady;
  final bool paymentReady;
  final bool kycAttached;

  const _InvoiceReadinessCard({
    required this.customerReady,
    required this.itemsReady,
    required this.amountReady,
    required this.paymentReady,
    required this.kycAttached,
  });

  @override
  Widget build(BuildContext context) {
    final allReady = customerReady && itemsReady && amountReady && paymentReady;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: allReady
            ? GirviColors.success.withValues(alpha: 0.055)
            : GirviColors.warning.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: allReady
              ? GirviColors.success.withValues(alpha: 0.20)
              : GirviColors.warning.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allReady ? Icons.verified_rounded : Icons.fact_check_outlined,
                color: allReady ? GirviColors.success : GirviColors.warning,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  allReady ? 'READY TO CREATE INVOICE' : 'INVOICE CHECKLIST',
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
              _InvoiceOptionalBadge(
                label: kycAttached ? 'KYC ATTACHED' : 'KYC OPTIONAL',
                active: kycAttached,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InvoiceCheckChip(label: 'Customer', complete: customerReady),
              _InvoiceCheckChip(label: 'Items', complete: itemsReady),
              _InvoiceCheckChip(label: 'Loan', complete: amountReady),
              _InvoiceCheckChip(label: 'Payment', complete: paymentReady),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceCheckChip extends StatelessWidget {
  final String label;
  final bool complete;

  const _InvoiceCheckChip({
    required this.label,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete ? GirviColors.success : GirviColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: complete
            ? GirviColors.success.withValues(alpha: 0.09)
            : GirviColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: complete ? GirviColors.textDark : GirviColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceOptionalBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _InvoiceOptionalBadge({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? GirviColors.success : GirviColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 7.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _TicketActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback? onTap;

  const _TicketActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.busy = false,
    this.onTap,
  });

  @override
  State<_TicketActionButton> createState() => _TicketActionButtonState();
}

class _TicketActionButtonState extends State<_TicketActionButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hovered == value) return;
      setState(() => _hovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bg = widget.filled
        ? GirviColors.brandGold
        : (_hovered && enabled ? GirviColors.brandGoldLight : Colors.white);
    final fg = widget.filled ? GirviColors.shellBg : GirviColors.brandDeep;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? bg : GirviColors.inputBgLocked,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.filled
                  ? GirviColors.brandGold
                  : GirviColors.brandGold.withValues(alpha: 0.55),
            ),
            boxShadow: widget.filled && enabled
                ? [
                    BoxShadow(
                      color: GirviColors.brandGold.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: GirviColors.shellBg,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: fg, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
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

class _SelectCustomerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SelectCustomerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GirviColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GirviColors.brandGold.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(GirviIcons.search, color: GirviColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Text(GirviStrings.selectCustomerHint,
              style: GoogleFonts.inter(
                  color: GirviColors.brandGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ItemCountStepper extends StatelessWidget {
  final int count;
  final void Function(int) onChanged;

  const _ItemCountStepper({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GirviStyles.inputHeight,
      decoration: GirviStyles.inputNormal,
      child: Row(children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: () => onChanged(count - 1),
          enabled: count > 1,
        ),
        Expanded(
          child: Center(
            child: Text('$count',
                style: GirviStyles.fieldInput.copyWith(fontSize: 18)),
          ),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: () => onChanged(count + 1),
          enabled: count < 99,
        ),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: GirviStyles.inputHeight,
          alignment: Alignment.center,
          child: Icon(icon,
              color: enabled ? GirviColors.brandGold : GirviColors.textHint,
              size: 20),
        ),
      );
}

class _LoanTermsGroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  const _LoanTermsGroupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.brandGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: GirviColors.brandGold.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(icon, color: GirviColors.brandGold, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GirviStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GirviColors.textBody,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GirviColors.bodyBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Text(
              trailing!,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LtvSuggestionRow extends StatelessWidget {
  final double totalValue;
  final void Function(double ltv) onSuggestionTap;

  const _LtvSuggestionRow({
    required this.totalValue,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    const ltvs = [50.0, 60.0, 70.0, 75.0, 80.0];
    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick LTV Suggestions:',
            style: GirviStyles.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ltvs.map((ltv) {
              final amt = totalValue * (ltv / 100);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSuggestionTap(ltv),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: GirviColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: GirviColors.brandGold.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      Text('${ltv.toInt()}% LTV',
                          style: GoogleFonts.inter(
                              color: GirviColors.brandDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text('Rs ${fmt.format(amt)}',
                          style: GoogleFonts.manrope(
                              color: GirviColors.textDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LtvIndicator extends StatelessWidget {
  final double ltv;
  final bool enabled;
  final void Function(double) onChanged;

  const _LtvIndicator({
    required this.ltv,
    required this.enabled,
    required this.onChanged,
  });

  Color get _color {
    if (ltv <= 60) return GirviColors.success;
    if (ltv <= 75) return GirviColors.warning;
    return GirviColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _color : GirviColors.brandGold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Loan-to-Value (LTV)', style: GirviStyles.fieldLabel),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: GirviStyles.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.06)
                : GirviColors.inputBgLocked,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.25)
                  : GirviColors.cardBorder,
            ),
          ),
          child: Row(children: [
            Icon(GirviIcons.loanTerms, color: color, size: 18),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: GirviColors.cardBorder),
            const SizedBox(width: 10),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  thumbColor: color,
                  inactiveTrackColor: GirviColors.divider,
                  disabledActiveTrackColor: color.withValues(alpha: 0.35),
                  disabledThumbColor: color.withValues(alpha: 0.70),
                  overlayColor: color.withValues(alpha: 0.15),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: ltv.clamp(0, 100),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              child: Text(
                '${ltv.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _InterestPreviewCard extends StatelessWidget {
  final double principal;
  final double monthly;
  final double total;
  final double totalDue;
  final double annualRate;
  final int durationMonths;

  const _InterestPreviewCard({
    required this.principal,
    required this.monthly,
    required this.total,
    required this.totalDue,
    required this.annualRate,
    required this.durationMonths,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.22)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GirviColors.brandGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: GirviColors.brandGold.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              GirviIcons.interestRate,
              color: GirviColors.brandGold,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repayment Preview',
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Simple interest estimate for $durationMonths months.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: GirviColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Text('${annualRate.toStringAsFixed(0)}% p.a.',
                style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final tiles = [
              _PreviewStat(
                label: 'Monthly Interest',
                value: 'Rs ${fmt.format(monthly)}',
                color: GirviColors.info,
                icon: Icons.calendar_month_outlined,
              ),
              _PreviewStat(
                label: 'Total Interest',
                value: 'Rs ${fmt.format(total)}',
                color: GirviColors.warning,
                icon: Icons.trending_up_rounded,
              ),
              _PreviewStat(
                label: 'Total Amount Due',
                value: 'Rs ${fmt.format(totalDue)}',
                color: GirviColors.brandGold,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  for (int i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    tiles[i],
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (int i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: tiles[i]),
                ],
              ],
            );
          },
        ),
      ]),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _PreviewStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
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
                      color: GirviColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: color,
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

class _DisbursementSplitEditor extends StatelessWidget {
  final List<GirviPaymentMode> modes;
  final GirviPaymentMode selected;
  final double loanAmount;
  final double totalAmount;
  final double remainingAmount;
  final TextEditingController Function(GirviPaymentMode mode) controllerFor;
  final double Function(GirviPaymentMode mode) amountFor;
  final String Function(GirviPaymentMode mode) modeLabel;
  final void Function(GirviPaymentMode mode) onModeTap;

  const _DisbursementSplitEditor({
    required this.modes,
    required this.selected,
    required this.loanAmount,
    required this.totalAmount,
    required this.remainingAmount,
    required this.controllerFor,
    required this.amountFor,
    required this.modeLabel,
    required this.onModeTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 920
            ? 4
            : width >= 640
                ? 2
                : 1;
        final spacing = columns == 1 ? 0.0 : 10.0;
        final tileWidth = (width - (spacing * (columns - 1))) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: [
                for (final mode in modes)
                  SizedBox(
                    width: tileWidth,
                    child: _DisbursementAmountTile(
                      mode: mode,
                      label: modeLabel(mode),
                      controller: controllerFor(mode),
                      active: selected == mode || amountFor(mode) > 0,
                      amount: amountFor(mode),
                      onTap: () => onModeTap(mode),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DisbursementTotalStrip(
              loanAmount: loanAmount,
              totalAmount: totalAmount,
              remainingAmount: remainingAmount,
              formatter: fmt,
            ),
          ],
        );
      },
    );
  }
}

class _DisbursementAmountTile extends StatelessWidget {
  final GirviPaymentMode mode;
  final String label;
  final TextEditingController controller;
  final bool active;
  final double amount;
  final VoidCallback onTap;

  const _DisbursementAmountTile({
    required this.mode,
    required this.label,
    required this.controller,
    required this.active,
    required this.amount,
    required this.onTap,
  });

  Color get _color {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviColors.success;
      case GirviPaymentMode.upi:
        return GirviColors.info;
      case GirviPaymentMode.bankTransfer:
        return GirviColors.brandGold;
      case GirviPaymentMode.cheque:
        return GirviColors.textMuted;
      case GirviPaymentMode.neft:
        return GirviColors.brandGold;
    }
  }

  IconData get _icon {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      case GirviPaymentMode.bankTransfer:
      case GirviPaymentMode.neft:
        return GirviIcons.bank;
      case GirviPaymentMode.cheque:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.07) : GirviColors.inputBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color:
                active ? color.withValues(alpha: 0.35) : GirviColors.cardBorder,
            width: active ? 1.3 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: color, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (amount > 0)
                Icon(Icons.check_circle_rounded, color: color, size: 16),
            ]),
            const SizedBox(height: 9),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: GirviColors.cardBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active
                      ? color.withValues(alpha: 0.28)
                      : GirviColors.cardBorder,
                ),
              ),
              child: Row(children: [
                Text(
                  'Rs',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'girvi-disbursement-${mode.dbValue.toLowerCase().replaceAll(' ', '-')}',
                    ),
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    textAlign: TextAlign.right,
                    style: GoogleFonts.manrope(
                      color: GirviColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: GirviStyles.fieldHint.copyWith(fontSize: 13),
                      isDense: true,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisbursementTotalStrip extends StatelessWidget {
  final double loanAmount;
  final double totalAmount;
  final double remainingAmount;
  final NumberFormat formatter;

  const _DisbursementTotalStrip({
    required this.loanAmount,
    required this.totalAmount,
    required this.remainingAmount,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final balanced = loanAmount > 0 && remainingAmount.abs() <= 0.50;
    final remainingColor = balanced ? GirviColors.success : GirviColors.warning;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final tiles = [
          _MiniAmountPanel(
            label: 'Loan Amount',
            value: 'Rs ${formatter.format(loanAmount)}',
            color: GirviColors.brandGold,
          ),
          _MiniAmountPanel(
            label: 'Disbursed',
            value: 'Rs ${formatter.format(totalAmount)}',
            color: GirviColors.info,
          ),
          _MiniAmountPanel(
            label: remainingAmount < 0 ? 'Over Limit' : 'Remaining',
            value: 'Rs ${formatter.format(remainingAmount.abs())}',
            color: remainingColor,
          ),
        ];
        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                tiles[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MiniAmountPanel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniAmountPanel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentModeSelector extends StatelessWidget {
  final GirviPaymentMode selected;
  final void Function(GirviPaymentMode) onChanged;

  const _PaymentModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GirviPaymentMode.values
          .where((mode) => mode != GirviPaymentMode.neft)
          .map((mode) {
        final isSelected = mode == selected;
        return GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? GirviColors.brandGold.withValues(alpha: 0.12)
                  : GirviColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? GirviColors.brandGold : GirviColors.cardBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isSelected)
                const Icon(GirviIcons.markDone,
                    color: GirviColors.brandGold, size: 14)
              else
                Icon(_modeIcon(mode), color: GirviColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(mode.displayName,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? GirviColors.brandGold
                        : GirviColors.textBody,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  IconData _modeIcon(GirviPaymentMode m) {
    switch (m) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      default:
        return GirviIcons.bank;
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.fieldLabel),
          const SizedBox(height: 6),
          Container(
            height: GirviStyles.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: GirviStyles.inputNormal,
            child: Row(children: [
              const Icon(GirviIcons.dates,
                  color: GirviColors.accentDates, size: 18),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: GirviColors.cardBorder),
              const SizedBox(width: 10),
              Text(DateFormat('dd MMM yyyy').format(date),
                  style: GirviStyles.fieldInput),
              const Spacer(),
              const Icon(Icons.edit_calendar_rounded,
                  color: GirviColors.textHint, size: 16),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DateDisplayField extends StatelessWidget {
  final String label;
  final DateTime date;

  const _DateDisplayField({
    required this.label,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GirviStyles.fieldLabel),
        const SizedBox(height: 6),
        Container(
          height: GirviStyles.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: GirviStyles.inputNormal,
          child: Row(children: [
            const Icon(GirviIcons.dates,
                color: GirviColors.accentDates, size: 18),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: GirviColors.cardBorder),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: GirviStyles.fieldInput,
            ),
          ]),
        ),
      ],
    );
  }
}
