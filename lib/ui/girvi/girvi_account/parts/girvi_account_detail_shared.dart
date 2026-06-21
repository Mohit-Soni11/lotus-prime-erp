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
  final EdgeInsetsGeometry padding;

  const _AccountSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
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
      height: 126,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AccountIconBox(icon: data.icon, color: data.color),
              const Spacer(),
            ],
          ),
          const Spacer(),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: GoogleFonts.manrope(
                color: data.color,
                fontSize: 21,
                fontWeight: FontWeight.w900,
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
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GirviColors.brandGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: GirviColors.brandGold.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            initials,
            style: GoogleFonts.manrope(
              color: GirviColors.brandGold,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(8),
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
                  fontSize: 12.8,
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
      width: 190,
      child: Row(
        children: [
          _AccountIconBox(icon: icon, color: color),
          const SizedBox(width: 9),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.8,
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

class _AccountStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AccountStatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
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
    );
  }
}

class _PledgedMetalSummaryCard extends StatelessWidget {
  final String metal;
  final int itemCount;
  final int pieces;
  final String grossWeight;
  final String netWeight;
  final String value;
  final Color color;

  const _PledgedMetalSummaryCard({
    required this.metal,
    required this.itemCount,
    required this.pieces,
    required this.grossWeight,
    required this.netWeight,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel = itemCount == 1 ? '1 item' : '$itemCount items';
    final pieceLabel = pieces == 1 ? '1 piece' : '$pieces pieces';

    return SizedBox(
      width: 236,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AccountIconBox(
                  icon: Icons.workspace_premium_rounded,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: GirviColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$countLabel | $pieceLabel',
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
              ],
            ),
            const SizedBox(height: 12),
            _PledgedSpecLine(label: 'Gross Weight', value: grossWeight),
            const SizedBox(height: 6),
            _PledgedSpecLine(label: 'Net Weight', value: netWeight),
            const SizedBox(height: 6),
            _PledgedSpecLine(label: 'Valuation', value: value, color: color),
          ],
        ),
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
  final String lessWeight;
  final String netWeight;
  final String rate;
  final String value;
  final String? huid;
  final int photoCount;
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
    required this.photoCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final huidText = huid?.trim();
    final hasHuid = huidText != null && huidText.isNotEmpty;
    final pieceLabel = pieces == 1 ? '1 piece' : '$pieces pieces';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: GirviColors.textDark,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _AccountStatusBadge(label: metal, color: color),
                    _AccountStatusBadge(
                      label: purity.trim().isEmpty ? 'Purity not set' : purity,
                      color: GirviColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PledgedSpecTile(label: 'Pieces', value: pieceLabel),
                    _PledgedSpecTile(label: 'Gross', value: grossWeight),
                    _PledgedSpecTile(label: 'Less', value: lessWeight),
                    _PledgedSpecTile(label: 'Net', value: netWeight),
                    _PledgedSpecTile(label: 'Rate / Gram', value: rate),
                    _PledgedSpecTile(
                      label: 'Valuation',
                      value: value,
                      color: color,
                    ),
                    if (hasHuid)
                      _PledgedSpecTile(label: 'HUID', value: huidText),
                    _PledgedSpecTile(
                      label: 'Photos',
                      value: photoCount == 1 ? '1 photo' : '$photoCount photos',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      width: 142,
      child: Container(
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

class _PledgedSpecLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PledgedSpecLine({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: color ?? GirviColors.textDark,
            fontSize: 12.6,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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

class _AccountClosureHero extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AccountClosureHero({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            GirviColors.cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _AccountIconBox(icon: icon, color: color, large: true),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w800,
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

class _AccountClosureStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AccountClosureStep({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textDark,
                      fontSize: 12.5,
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

class _FlippablePdfPreviewDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String frontTitle;
  final String backTitle;
  final String frontFileName;
  final String backFileName;
  final Uint8List frontBytes;
  final Uint8List backBytes;
  final VoidCallback onClose;

  const _FlippablePdfPreviewDialog({
    required this.title,
    required this.subtitle,
    required this.frontTitle,
    required this.backTitle,
    required this.frontFileName,
    required this.backFileName,
    required this.frontBytes,
    required this.backBytes,
    required this.onClose,
  });

  @override
  State<_FlippablePdfPreviewDialog> createState() =>
      _FlippablePdfPreviewDialogState();
}

class _FlippablePdfPreviewDialogState
    extends State<_FlippablePdfPreviewDialog> {
  bool _showBack = false;

  void _flipReceiptSide() {
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final activeTitle = _showBack ? widget.backTitle : widget.frontTitle;
    final activeBytes = _showBack ? widget.backBytes : widget.frontBytes;
    final activeFileName =
        _showBack ? widget.backFileName : widget.frontFileName;

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF111827),
      child: Column(
        children: [
          _FlippablePdfPreviewHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            activeTitle: activeTitle,
            isBackSide: _showBack,
            onFlip: _flipReceiptSide,
            onClose: widget.onClose,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _flipReceiptSide,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: PdfPreview(
                  key: ValueKey<bool>(_showBack),
                  build: (_) async => activeBytes,
                  initialPageFormat: PdfPageFormat.a4,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  maxPageWidth: 860,
                  pdfFileName: activeFileName,
                  scrollViewDecoration: const BoxDecoration(
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlippablePdfPreviewHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String activeTitle;
  final bool isBackSide;
  final VoidCallback onFlip;
  final VoidCallback onClose;

  const _FlippablePdfPreviewHeader({
    required this.title,
    required this.subtitle,
    required this.activeTitle,
    required this.isBackSide,
    required this.onFlip,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: GirviColors.brandGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GirviColors.brandGold.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              GirviIcons.print,
              color: GirviColors.brandGold,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle | $activeTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Double-click preview to flip side',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onFlip,
            icon: Icon(
              isBackSide
                  ? Icons.flip_to_front_rounded
                  : Icons.flip_to_back_rounded,
              size: 18,
            ),
            label: Text(isBackSide ? 'Show Front' : 'Show Ledger'),
            style: FilledButton.styleFrom(
              backgroundColor: GirviColors.brandGold,
              foregroundColor: GirviColors.shellBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Close preview',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
