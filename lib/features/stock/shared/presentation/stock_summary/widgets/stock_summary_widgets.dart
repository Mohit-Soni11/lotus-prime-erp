part of '../stock_summary_screen.dart';

final _summaryWeightFormat = NumberFormat('##,##0.000', 'en_IN');
final _summaryDateFormat = DateFormat('dd MMM yyyy, hh:mm a');

class _StockSummaryHero extends StatelessWidget {
  final StockSummaryOverview overview;

  const _StockSummaryHero({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF2B8), Color(0xFFD8B12E)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: InvColors.brandGold.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Color(0xFF7A5400),
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Summary',
                  style: GoogleFonts.manrope(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2B1F05),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Opening, inward, outward and closing stock in one owner-level inventory dashboard.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4C3A12),
                  ),
                ),
              ],
            ),
          ),
          _HeroSummaryTile(
            label: 'Closing Stock',
            value: '${overview.closingUnits} pcs',
          ),
          const SizedBox(width: 12),
          _HeroSummaryTile(
            label: 'Total Weight',
            value: '${_summaryWeight(overview.totalWeight)} g',
          ),
          const SizedBox(width: 12),
          _HeroSummaryTile(
            label: 'Actual Fine',
            value: '${_summaryWeight(overview.closingFine)} g',
          ),
        ],
      ),
    );
  }
}

class _StockSummaryMetricGrid extends StatelessWidget {
  final StockSummaryOverview overview;

  const _StockSummaryMetricGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _SummaryMetricCard(
          title: 'Opening Stock',
          value: '${overview.openingUnits} pcs',
          subtitle: '${_summaryWeight(overview.openingWeight)} g',
          icon: Icons.lock_open_rounded,
          accent: const Color(0xFF64748B),
          background: const Color(0xFFEFF3F8),
        ),
        _SummaryMetricCard(
          title: 'Stock Added Today',
          value: '${overview.inwardUnits} pcs',
          subtitle: '${_summaryWeight(overview.inwardWeight)} g inward',
          icon: Icons.add_business_rounded,
          accent: InvColors.success,
          background: InvColors.successBg,
        ),
        _SummaryMetricCard(
          title: 'Stock Sold Today',
          value: '${overview.outwardUnits} pcs',
          subtitle: '${_summaryWeight(overview.outwardWeight)} g outward',
          icon: Icons.point_of_sale_rounded,
          accent: InvColors.danger,
          background: InvColors.dangerBg,
        ),
        _SummaryMetricCard(
          title: 'Stock Restored Today',
          value: '${overview.restoredUnits} pcs',
          subtitle: '${_summaryWeight(overview.restoredWeight)} g restored',
          icon: Icons.restore_rounded,
          accent: const Color(0xFF2563EB),
          background: const Color(0x142563EB),
        ),
        _SummaryMetricCard(
          title: 'Closing Stock',
          value: '${overview.closingUnits} pcs',
          subtitle: '${_summaryWeight(overview.closingWeight)} g available',
          icon: Icons.inventory_2_rounded,
          accent: InvColors.brandGold,
          background: InvColors.brandGoldLight,
        ),
        _SummaryMetricCard(
          title: 'Sold Inventory',
          value: '${overview.soldUnits} pcs',
          subtitle: '${_summaryWeight(overview.soldWeight)} g sold',
          icon: Icons.receipt_long_rounded,
          accent: const Color(0xFFF59E0B),
          background: const Color(0xFFFFF7E6),
        ),
      ],
    );
  }
}

class _ItemSummaryPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<StockSummaryItem> items;
  final VoidCallback? onBack;

  const _ItemSummaryPanel({
    this.title = 'Item-wise Stock Summary',
    this.subtitle =
        'Available stock, sold movement and weight status grouped by item.',
    required this.items,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _SummaryPanel(
      title: title,
      subtitle: subtitle,
      icon: Icons.inventory_2_rounded,
      action: onBack == null
          ? null
          : _PanelActionButton(
              label: 'Back to Grades',
              icon: Icons.arrow_back_rounded,
              onTap: onBack!,
            ),
      child: items.isEmpty
          ? const _SummaryEmptyState(message: 'No item stock found yet.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1480
                    ? 3
                    : constraints.maxWidth >= 980
                        ? 2
                        : 1;
                const spacing = 14.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: width,
                        child: _ItemSummaryCard(item: item),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _MetalSummaryPanel extends StatelessWidget {
  final List<StockSummaryMetal> metals;
  final ValueChanged<String>? onOpen;

  const _MetalSummaryPanel({required this.metals, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final smartMetals = metals.where(_hasMetalInventory).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (smartMetals.isEmpty) {
          return const _SummaryPanel(
            title: 'Metal-wise Stock Summary',
            subtitle: 'Stock summary will appear once inventory is available.',
            icon: Icons.category_rounded,
            child: _SummaryEmptyState(message: 'No metal stock found yet.'),
          );
        }

        final cardWidth = constraints.maxWidth >= 960
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final metal in smartMetals)
              SizedBox(
                width: cardWidth,
                child: _StockSummaryMetalCard(
                  metal: metal,
                  onTap: () => onOpen?.call(metal.metal),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StockSummaryMetalCard extends StatelessWidget {
  final StockSummaryMetal metal;
  final VoidCallback onTap;

  const _StockSummaryMetalCard({
    required this.metal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = _stockCategoryFromMetal(metal.metal);
    final ui = stockMetalUiFor(category);

    return InventoryMetalSummaryCard(
      title: '${ui.title} Stock Summary',
      subtitle: _metalSummarySubtitle(category),
      primaryLabel: 'Opening Stock',
      primaryValue:
          '${metal.openingUnits} pcs | ${_summaryWeight(metal.openingWeight)} g',
      weightLabel: 'Closing Stock',
      weightValue:
          '${metal.closingUnits} pcs | ${_summaryWeight(metal.closingWeight)} g',
      actionLabel: 'Open ${ui.title} Summary',
      icon: ui.icon,
      logoAsset: ui.logoAsset,
      accent: ui.accent,
      surface: ui.softSurface,
      tint: ui.softTint,
      gradient: ui.gradient,
      textOnGradient: ui.textOnGradient,
      selected: false,
      onTap: onTap,
    );
  }
}

bool _hasMetalInventory(StockSummaryMetal metal) {
  return metal.openingUnits > 0 ||
      metal.inwardUnits > 0 ||
      metal.outwardUnits > 0 ||
      metal.restoredUnits > 0 ||
      metal.closingUnits > 0 ||
      metal.totalWeight > 0 ||
      metal.soldWeight > 0;
}

String _metalSummarySubtitle(StockCategory category) {
  switch (category) {
    case StockCategory.gold:
      return 'Opening, inward, outward and closing stock by gold purity grade.';
    case StockCategory.silver:
      return 'Opening, inward, outward and closing stock by silver item and grade.';
    case StockCategory.diamond:
      return 'Diamond inventory summary with item movement and closing stock.';
    case StockCategory.platinum:
      return 'Platinum stock summary with premium item movement and closing stock.';
    case StockCategory.antique:
    case StockCategory.other:
      return 'Custom stock summary with item movement and closing stock.';
  }
}

class _GradeSummaryPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<StockSummaryGrade> grades;
  final VoidCallback? onBack;
  final ValueChanged<String>? onOpen;

  const _GradeSummaryPanel({
    this.title = 'Purity Breakdown',
    this.subtitle = 'Purity-wise available stock snapshot.',
    required this.grades,
    this.onBack,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final visibleGrades = grades.where(_hasGradeInventory).toList();
    return _SummaryPanel(
      title: title,
      subtitle: subtitle,
      icon: Icons.verified_rounded,
      action: onBack == null
          ? null
          : _PanelActionButton(
              label: 'Back to Metals',
              icon: Icons.arrow_back_rounded,
              onTap: onBack!,
            ),
      child: visibleGrades.isEmpty
          ? const _SummaryEmptyState(message: 'No purity stock found yet.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 960
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final grade in visibleGrades)
                      SizedBox(
                        width: cardWidth,
                        child: _StockSummaryGradeCard(
                          grade: grade,
                          onTap: () => onOpen?.call(grade.gradeLabel),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _StockSummaryGradeCard extends StatelessWidget {
  final StockSummaryGrade grade;
  final VoidCallback onTap;

  const _StockSummaryGradeCard({required this.grade, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = _stockCategoryFromMetal(grade.metal);
    final ui = stockMetalUiFor(category);

    return InventoryMetalSummaryCard(
      title: '${grade.gradeLabel} ${ui.title} Stock',
      subtitle:
          '${grade.closingUnits} available pcs | ${grade.soldUnits} sold pcs | grade-wise summary',
      primaryLabel: 'Opening Stock',
      primaryValue:
          '${grade.openingUnits} pcs | ${_summaryWeight(grade.openingWeight)} g',
      weightLabel: 'Closing Stock',
      weightValue:
          '${grade.closingUnits} pcs | ${_summaryWeight(grade.closingWeight)} g',
      actionLabel: 'Open Item Summary',
      icon: Icons.verified_rounded,
      logoAsset: ui.logoAsset,
      accent: ui.accent,
      surface: ui.softSurface,
      tint: ui.softTint,
      gradient: ui.gradient,
      textOnGradient: ui.textOnGradient,
      selected: false,
      onTap: onTap,
    );
  }
}

bool _hasGradeInventory(StockSummaryGrade grade) {
  return grade.openingUnits > 0 ||
      grade.inwardUnits > 0 ||
      grade.outwardUnits > 0 ||
      grade.restoredUnits > 0 ||
      grade.closingUnits > 0 ||
      grade.totalWeight > 0 ||
      grade.soldWeight > 0;
}

class _ItemSummaryCard extends StatelessWidget {
  final StockSummaryItem item;

  const _ItemSummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(item.metal);
    final statusAccent = item.stockStatus == 'Sold Out'
        ? InvColors.danger
        : item.stockStatus == 'Partially Sold'
            ? const Color(0xFFF59E0B)
            : InvColors.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryIconBox(icon: _metalIcon(item.metal), accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCase(item.stockTitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _summaryStrongStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _itemSubtitle(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _summaryMutedStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _BlockMetric(
                    width: width,
                    label: 'Available Weight',
                    value: '${_summaryWeight(item.availableWeight)} g',
                    icon: Icons.scale_rounded,
                    accent: InvColors.success,
                    background: InvColors.successBg,
                  ),
                  _BlockMetric(
                    width: width,
                    label: 'Sold Weight',
                    value: '${_summaryWeight(item.soldWeight)} g',
                    icon: Icons.point_of_sale_rounded,
                    accent: InvColors.danger,
                    background: InvColors.dangerBg,
                  ),
                  _BlockMetric(
                    width: width,
                    label: 'Total Weight',
                    value: '${_summaryWeight(item.totalWeight)} g',
                    icon: Icons.inventory_rounded,
                    accent: const Color(0xFF64748B),
                    background: const Color(0xFFEFF3F8),
                  ),
                  _BlockMetric(
                    width: width,
                    label: 'Actual Fine',
                    value: '${_summaryWeight(item.actualFine)} g',
                    icon: Icons.verified_rounded,
                    accent: InvColors.success,
                    background: InvColors.successBg,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEADCC5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FooterMetric(
                    label: 'Total Pcs',
                    value: '${item.totalPieces} pcs',
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _FooterMetric(
                    label: 'Available',
                    value: '${item.availablePieces} pcs',
                    accent: InvColors.success,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _FooterMetric(
                    label: 'Sold',
                    value: '${item.soldPieces} pcs',
                    accent: item.soldPieces > 0
                        ? InvColors.danger
                        : InvColors.textDark,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _FooterMetric(
                    label: 'Status',
                    value: item.stockStatus,
                    accent: statusAccent,
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

class _SummaryPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  final Widget child;

  const _SummaryPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryIconBox(icon: icon, accent: InvColors.brandGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PanelActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8DDC9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: InvColors.textDark),
              const SizedBox(width: 8),
              Text(label, style: _summaryStrongStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;

  const _SummaryMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 292,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          _SummaryIconBox(icon: icon, accent: accent),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _summaryMutedStyle()),
                const SizedBox(height: 4),
                Text(value, style: _summaryStrongStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryMutedStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _HeroSummaryTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _summaryMutedStyle(fontSize: 10)),
          const SizedBox(height: 5),
          Text(value, style: _summaryStrongStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _BlockMetric extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;

  const _BlockMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _summaryMutedStyle(fontSize: 10.5)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryStrongStyle(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InlineMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _summaryMutedStyle(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _summaryStrongStyle(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _FooterMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _FooterMetric({
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _summaryMutedStyle(fontSize: 10.5)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _summaryStrongStyle(fontSize: 12.5).copyWith(
            color: accent ?? InvColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFEADCC5),
    );
  }
}

class _SummaryIconBox extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _SummaryIconBox({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: accent, size: 21),
    );
  }
}

class _SummaryEmptyState extends StatelessWidget {
  final String message;

  const _SummaryEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: _summaryMutedStyle(),
      ),
    );
  }
}

class _SummaryErrorBanner extends StatelessWidget {
  final String message;

  const _SummaryErrorBanner({required this.message});

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

TextStyle _summaryStrongStyle({double fontSize = 14}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w900,
    color: InvColors.textDark,
  );
}

TextStyle _summaryMutedStyle({double fontSize = 12}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: InvColors.textMuted,
  );
}

String _summaryWeight(double value) => _summaryWeightFormat.format(value);

String _summaryDate(DateTime? value) {
  if (value == null) return 'Not recorded';
  return _summaryDateFormat.format(value);
}

String _fallback(String value, String fallback) {
  return value.trim().isEmpty ? fallback : value.trim();
}

String _itemSubtitle(StockSummaryItem item) {
  final companyCount =
      item.companyNames.isEmpty ? item.companyCount : item.companyNames.length;
  final companyText = companyCount <= 0
      ? 'company not tagged'
      : companyCount == 1
          ? '1 company'
          : '$companyCount companies';
  final purityText = item.purityGroupCount <= 0
      ? 'purity not tagged'
      : item.purityGroupCount == 1
          ? '1 purity group'
          : '${item.purityGroupCount} purity groups';
  final sets = item.totalSets > 0
      ? ' | ${item.availableSets}/${item.totalSets} set'
      : '';
  return '${_fallback(item.itemType, 'General')} | ${_fallback(item.segment, 'General')} | $companyText | $purityText$sets';
}

String _titleCase(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Stock Item';
  return text.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return word;
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

StockCategory _stockCategoryFromMetal(String metal) {
  switch (metal.trim().toLowerCase()) {
    case 'gold':
      return StockCategory.gold;
    case 'silver':
      return StockCategory.silver;
    case 'diamond':
      return StockCategory.diamond;
    case 'platinum':
      return StockCategory.platinum;
    default:
      return StockCategory.other;
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
