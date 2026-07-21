part of '../market_refill_report_screen.dart';

final _refillNumberFormat = NumberFormat.decimalPattern('en_IN');
final _refillWeightFormat = NumberFormat('##,##0.000', 'en_IN');
final _refillDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
final _refillRangeDateFormat = DateFormat('dd MMM yyyy');

class _MarketRefillAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _MarketRefillAppBar({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<_MarketRefillAppBar> createState() => _MarketRefillAppBarState();
}

class _MarketRefillAppBarState extends State<_MarketRefillAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: InvColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: InvColors.shellBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _RefillShellButton(
              icon: Icons.arrow_back_rounded,
              onTap: widget.onBack,
            ),
            const SizedBox(width: 18),
            _RefillDivider(),
            const SizedBox(width: 18),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD76A), InvColors.brandGold],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'MARKET REFILL REPORT',
              style: InvStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            _RefillShellButton(
              icon: Icons.refresh_rounded,
              onTap: widget.onRefresh,
            ),
            const SizedBox(width: 14),
            _RefillOnlineBadge(pulse: _pulse),
          ],
        ),
      ),
    );
  }
}

class _MarketRefillHero extends StatelessWidget {
  final MarketRefillReport report;
  final bool isExportEnabled;
  final VoidCallback onExport;

  const _MarketRefillHero({
    required this.report,
    required this.isExportEnabled,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final summary = report.summary;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DDC9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RefillIconBox(
                icon: Icons.storefront_rounded,
                accent: InvColors.brandGold,
                size: 58,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Refill Report',
                      style: GoogleFonts.manrope(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Sold stock converted into a purchase-ready metal and item list.',
                      style: _refillMutedStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              _RefillPrimaryButton(
                label: 'Export CSV',
                icon: Icons.download_rounded,
                enabled: isExportEnabled,
                onTap: onExport,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _RefillHeroMetric(
                label: 'Sold',
                value: _formatQty(summary.soldQuantity, 'unit'),
                icon: Icons.point_of_sale_rounded,
                accent: InvColors.danger,
              ),
              _RefillHeroMetric(
                label: 'Available',
                value: _formatQty(summary.availableQuantity, 'unit'),
                icon: Icons.inventory_2_rounded,
                accent: InvColors.success,
              ),
              _RefillHeroMetric(
                label: 'Refill',
                value: _formatQty(summary.refillQuantity, 'unit'),
                icon: Icons.add_shopping_cart_rounded,
                accent: InvColors.brandGold,
              ),
              _RefillHeroMetric(
                label: 'Sold Weight',
                value: '${_weight(summary.soldNetWeight)} g',
                icon: Icons.scale_rounded,
                accent: const Color(0xFF64748B),
              ),
              _RefillHeroMetric(
                label: 'Groups',
                value:
                    '${summary.itemGroups} item | ${summary.metalGroups} metal',
                icon: Icons.category_rounded,
                accent: const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketRefillToolbar extends StatelessWidget {
  final MarketRefillPreset selected;
  final ValueChanged<MarketRefillPreset> onChanged;

  const _MarketRefillToolbar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          const _RefillIconBox(
            icon: Icons.date_range_rounded,
            accent: InvColors.brandGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select sold period for market purchase planning.',
              style: _refillStrongStyle(fontSize: 14),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RangeChip(
                label: 'This Month',
                selected: selected == MarketRefillPreset.thisMonth,
                onTap: () => onChanged(MarketRefillPreset.thisMonth),
              ),
              _RangeChip(
                label: '7 Days',
                selected: selected == MarketRefillPreset.last7Days,
                onTap: () => onChanged(MarketRefillPreset.last7Days),
              ),
              _RangeChip(
                label: '30 Days',
                selected: selected == MarketRefillPreset.last30Days,
                onTap: () => onChanged(MarketRefillPreset.last30Days),
              ),
              _RangeChip(
                label: 'All Time',
                selected: selected == MarketRefillPreset.allTime,
                onTap: () => onChanged(MarketRefillPreset.allTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketRefillMetalSnapshot extends StatelessWidget {
  final List<MarketRefillMetalSummary> metals;

  const _MarketRefillMetalSnapshot({required this.metals});

  @override
  Widget build(BuildContext context) {
    if (metals.isEmpty) {
      return const _RefillPanel(
        title: 'Metal Refill Snapshot',
        subtitle: 'Metal cards appear after sold stock is found.',
        icon: Icons.auto_awesome_mosaic_rounded,
        child: _RefillEmptyState(
          message: 'No metal refill data for this period.',
        ),
      );
    }

    return _RefillPanel(
      title: 'Metal Refill Snapshot',
      subtitle: 'Quick view before opening the item purchase list.',
      icon: Icons.auto_awesome_mosaic_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1280
              ? 4
              : constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
          const spacing = 12.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final metal in metals)
                SizedBox(width: width, child: _MetalSnapshotCard(metal: metal)),
            ],
          );
        },
      ),
    );
  }
}

class _MarketRefillItemList extends StatelessWidget {
  final MarketRefillReport report;

  const _MarketRefillItemList({required this.report});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<MarketRefillItemRow>>{};
    for (final row in report.rows) {
      grouped.putIfAbsent(row.metal, () => []).add(row);
    }

    return _RefillPanel(
      title: 'Purchase Ready List',
      subtitle:
          '${report.range.label} | ${_refillRangeDateFormat.format(report.range.start)} to ${_refillRangeDateFormat.format(report.range.end.subtract(const Duration(days: 1)))}',
      icon: Icons.fact_check_rounded,
      child: report.rows.isEmpty
          ? const _RefillEmptyState(
              message: 'No sold items found in the selected period.',
            )
          : Column(
              children: [
                for (final entry in grouped.entries) ...[
                  _MetalItemSection(metal: entry.key, rows: entry.value),
                  if (entry.key != grouped.keys.last) const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

class _MetalItemSection extends StatelessWidget {
  final String metal;
  final List<MarketRefillItemRow> rows;

  const _MetalItemSection({
    required this.metal,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(metal);
    final grouped = <String, List<MarketRefillItemRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(_marketGroupTitle(row), () => []).add(row);
    }
    final entries = grouped.entries.toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RefillIconBox(icon: _metalIcon(metal), accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$metal ${_marketGroupMode(metal)} List',
                  style: _refillStrongStyle(fontSize: 16),
                ),
              ),
              _RefillBadge(
                label: '${rows.length} item groups',
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final entry in entries) ...[
            _MarketItemGroup(
              title: entry.key,
              rows: entry.value,
              accent: accent,
            ),
            if (entry != entries.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MarketItemGroup extends StatelessWidget {
  final String title;
  final List<MarketRefillItemRow> rows;
  final Color accent;

  const _MarketItemGroup({
    required this.title,
    required this.rows,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: _refillStrongStyle(fontSize: 14)),
              ),
              _RefillBadge(label: '${rows.length} item', accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1320
                  ? 3
                  : constraints.maxWidth >= 860
                      ? 2
                      : 1;
              const spacing = 12.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final row in rows)
                    SizedBox(width: width, child: _RefillItemCard(row: row)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RefillItemCard extends StatelessWidget {
  final MarketRefillItemRow row;

  const _RefillItemCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final accent = _statusAccent(row.statusLabel);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RefillIconBox(
                icon: _metalIcon(row.metal),
                accent: _metalAccent(row.metal),
                size: 46,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _refillStrongStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row.metal} | ${row.gradeLabel} | ${row.companyLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _refillMutedStyle(),
                    ),
                  ],
                ),
              ),
              _RefillBadge(label: row.statusLabel, accent: accent),
            ],
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _RefillMetricBlock(
                    width: width,
                    label: 'Sold',
                    value: _formatQty(row.soldQuantity, row.unitLabel),
                    accent: InvColors.danger,
                    icon: Icons.point_of_sale_rounded,
                  ),
                  _RefillMetricBlock(
                    width: width,
                    label: 'Available',
                    value: _formatQty(row.availableQuantity, row.unitLabel),
                    accent: InvColors.success,
                    icon: Icons.inventory_2_rounded,
                  ),
                  _RefillMetricBlock(
                    width: width,
                    label: 'Refill',
                    value: _formatQty(row.refillQuantity, row.unitLabel),
                    accent: InvColors.brandGold,
                    icon: Icons.add_shopping_cart_rounded,
                  ),
                  _RefillMetricBlock(
                    width: width,
                    label: 'Sold Net',
                    value: '${_weight(row.soldNetWeight)} g',
                    accent: const Color(0xFF64748B),
                    icon: Icons.scale_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FooterInfo(
                    label: 'Item Names',
                    value: row.itemNameLabel,
                  ),
                ),
                const _FooterDivider(),
                Expanded(
                  child: _FooterInfo(
                    label: 'Bills',
                    value: '${row.billCount}',
                  ),
                ),
                const _FooterDivider(),
                Expanded(
                  child: _FooterInfo(
                    label: 'Last Sold',
                    value: _date(row.lastSoldAt),
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

class _MetalSnapshotCard extends StatelessWidget {
  final MarketRefillMetalSummary metal;

  const _MetalSnapshotCard({required this.metal});

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(metal.metal);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RefillIconBox(icon: _metalIcon(metal.metal), accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metal.metal,
                  style: _refillStrongStyle(fontSize: 16),
                ),
              ),
              _RefillBadge(label: '${metal.itemGroups} groups', accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          _SnapshotLine(
            label: 'Sold',
            value: _formatQty(metal.soldQuantity, 'unit'),
          ),
          _SnapshotLine(
            label: 'Available',
            value: _formatQty(metal.availableQuantity, 'unit'),
          ),
          _SnapshotLine(
            label: 'Refill',
            value: _formatQty(metal.refillQuantity, 'unit'),
          ),
          _SnapshotLine(
            label: 'Sold Net',
            value: '${_weight(metal.soldNetWeight)} g',
          ),
        ],
      ),
    );
  }
}

class _RefillPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _RefillPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RefillIconBox(icon: icon, accent: InvColors.brandGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _refillStrongStyle(fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: _refillMutedStyle()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RefillHeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _RefillHeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          _RefillIconBox(icon: icon, accent: accent, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: _refillMutedStyle(fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _refillStrongStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillMetricBlock extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _RefillMetricBlock({
    required this.width,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: _refillMutedStyle(fontSize: 10)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _refillStrongStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? InvColors.brandGold : const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? InvColors.brandGold : const Color(0xFFE8DDC9),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : InvColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _RefillPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RefillPrimaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? InvColors.brandGold : const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? Colors.white : InvColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: enabled ? Colors.white : InvColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefillShellButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RefillShellButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_RefillShellButton> createState() => _RefillShellButtonState();
}

class _RefillShellButtonState extends State<_RefillShellButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? InvColors.shellBg
                : InvColors.shellBorder.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hovered ? InvColors.brandGold : InvColors.shellBorder,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? InvColors.brandGold : InvColors.shellTextTitle,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _RefillIconBox extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double size;

  const _RefillIconBox({
    required this.icon,
    required this.accent,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size >= 50 ? 16 : 13),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: accent, size: size >= 50 ? 28 : 21),
    );
  }
}

class _RefillBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _RefillBadge({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      ),
    );
  }
}

class _SnapshotLine extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _refillMutedStyle())),
          Text(value, style: _refillStrongStyle(fontSize: 13.5)),
        ],
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  final String label;
  final String value;

  const _FooterInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: _refillMutedStyle(fontSize: 9.5)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _refillStrongStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _FooterDivider extends StatelessWidget {
  const _FooterDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE2E8F0),
    );
  }
}

class _RefillEmptyState extends StatelessWidget {
  final String message;

  const _RefillEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: _refillMutedStyle(),
      ),
    );
  }
}

class _MarketRefillError extends StatelessWidget {
  final String message;

  const _MarketRefillError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: InvColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: InvColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            InvColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _RefillOnlineBadge extends StatelessWidget {
  final AnimationController pulse;

  const _RefillOnlineBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: InvColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: InvColors.onlineGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RefillPulseWave(animation: pulse, delay: 0),
                _RefillPulseWave(animation: pulse, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: InvColors.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SYSTEM ONLINE',
            style: GoogleFonts.inter(
              color: InvColors.onlineGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillPulseWave extends StatelessWidget {
  final AnimationController animation;
  final double delay;

  const _RefillPulseWave({
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final value = (animation.value + delay) % 1;
        return Opacity(
          opacity: 1 - value,
          child: Transform.scale(
            scale: 1 + value * 1.5,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: InvColors.onlineGreen.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE8DDC9)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.055),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

TextStyle _refillStrongStyle({double fontSize = 14}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w900,
    color: InvColors.textDark,
  );
}

TextStyle _refillMutedStyle({double fontSize = 12}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: InvColors.textMuted,
  );
}

String _formatQty(int value, String unitLabel) {
  final clean = unitLabel.trim().toLowerCase();
  final unit = clean.isEmpty || clean == 'unit' ? 'unit' : clean;
  return '${_refillNumberFormat.format(value)} $unit';
}

String _weight(double value) => _refillWeightFormat.format(value);

String _date(DateTime? value) {
  if (value == null) return 'Not recorded';
  return _refillDateFormat.format(value);
}

String _marketGroupMode(String metal) {
  switch (metal.trim().toLowerCase()) {
    case 'gold':
      return 'Grade Wise';
    case 'silver':
      return 'Company Wise';
    default:
      return 'Group Wise';
  }
}

String _marketGroupTitle(MarketRefillItemRow row) {
  switch (row.metal.trim().toLowerCase()) {
    case 'gold':
      return row.gradeLabel.trim().isEmpty ? 'Gold Grade Not Tagged' : row.gradeLabel;
    case 'silver':
      return row.companyLabel;
    default:
      return row.gradeLabel.trim().isEmpty ? row.metal : row.gradeLabel;
  }
}

Color _statusAccent(String status) {
  switch (status.toLowerCase()) {
    case 'refill now':
      return InvColors.danger;
    case 'plan refill':
      return const Color(0xFFF59E0B);
    default:
      return InvColors.success;
  }
}

Color _metalAccent(String metal) {
  switch (metal.toLowerCase()) {
    case 'silver':
      return const Color(0xFF64748B);
    case 'diamond':
      return const Color(0xFF0EA5E9);
    case 'platinum':
      return const Color(0xFF475569);
    case 'gold':
      return InvColors.brandGold;
    default:
      return const Color(0xFF64748B);
  }
}

IconData _metalIcon(String metal) {
  switch (metal.toLowerCase()) {
    case 'silver':
      return Icons.circle_outlined;
    case 'diamond':
      return Icons.diamond_rounded;
    case 'platinum':
      return Icons.radio_button_checked_rounded;
    case 'gold':
      return Icons.workspace_premium_rounded;
    default:
      return Icons.inventory_2_rounded;
  }
}
