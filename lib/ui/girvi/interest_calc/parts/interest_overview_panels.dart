part of '../interest_calc_screen.dart';

class _OverviewMoneyPanel extends StatelessWidget {
  final String title;
  final String primaryLabel;
  final String primaryValue;
  final String? secondaryLabel;
  final String? secondaryValue;
  final String? tertiaryLabel;
  final String? tertiaryValue;
  final IconData icon;
  final Color color;
  final double? progress;

  const _OverviewMoneyPanel({
    required this.title,
    required this.primaryLabel,
    required this.primaryValue,
    this.secondaryLabel,
    this.secondaryValue,
    this.tertiaryLabel,
    this.tertiaryValue,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final supporting = <_OverviewMiniValue>[
      if (secondaryLabel != null && secondaryValue != null)
        _OverviewMiniValue(
          label: secondaryLabel!,
          value: secondaryValue!,
          color: color,
        ),
      if (tertiaryLabel != null && tertiaryValue != null)
        _OverviewMiniValue(
          label: tertiaryLabel!,
          value: tertiaryValue!,
          color: color,
        ),
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color, dark: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            primaryLabel,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                primaryValue,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            _ProgressTrack(value: progress!, color: color),
          ],
          if (supporting.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < supporting.length; i++) ...[
                  Expanded(child: supporting[i]),
                  if (i != supporting.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewTermsPanel extends StatelessWidget {
  final String tenure;
  final String startDate;
  final String maturityDate;
  final String paidTill;
  final String totalCollected;

  const _OverviewTermsPanel({
    required this.tenure,
    required this.startDate,
    required this.maturityDate,
    required this.paidTill,
    required this.totalCollected,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _OverviewInfoTile(
        label: 'Tenure',
        value: tenure,
        icon: GirviIcons.dates,
        color: GirviColors.info,
      ),
      _OverviewInfoTile(
        label: 'Start Date',
        value: startDate,
        icon: GirviIcons.dates,
        color: GirviColors.brandGold,
      ),
      _OverviewInfoTile(
        label: 'Maturity',
        value: maturityDate,
        icon: GirviIcons.dates,
        color: GirviColors.purple,
      ),
      _OverviewInfoTile(
        label: 'Interest Paid',
        value: paidTill,
        icon: GirviIcons.markDone,
        color: GirviColors.success,
      ),
      _OverviewInfoTile(
        label: 'Total Collected',
        value: totalCollected,
        icon: GirviIcons.cash,
        color: GirviColors.info,
        wide: true,
      ),
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: GirviColors.info.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.info,
                color: GirviColors.info,
                dark: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terms & Timeline',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 320;
              if (!twoColumns) {
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i != tiles.length - 1) const SizedBox(height: 9),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 9),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(child: tiles[2]),
                      const SizedBox(width: 9),
                      Expanded(child: tiles[3]),
                    ],
                  ),
                  const SizedBox(height: 9),
                  tiles[4],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewMiniValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewMiniValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _OverviewInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: wide ? 58 : 64),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressTrack({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: safeValue,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(safeValue * 100).toStringAsFixed(0)}% principal recovered',
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MiniMoney extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMoney({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 12,
                color: GirviColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
