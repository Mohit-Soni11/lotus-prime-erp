part of '../stock_search_screen.dart';

class _SearchLensPanel extends StatelessWidget {
  final StockSearchController controller;

  const _SearchLensPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final lens = _SearchLensSnapshot.fromResults(
      controller.results,
      controller.summary,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: InvStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _SectionIcon(icon: Icons.auto_awesome_motion_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Search Lens',
                      style: InvStyles.sectionTitle.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'One-click stock focus by lifecycle, metal and tracking type.',
                      style: InvStyles.pageSubtitle.copyWith(
                        color: InvColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              _ResultCount(count: controller.results.length),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 1080
                  ? (constraints.maxWidth - 42) / 4
                  : constraints.maxWidth >= 760
                      ? (constraints.maxWidth - 28) / 3
                      : constraints.maxWidth >= 520
                          ? (constraints.maxWidth - 14) / 2
                          : constraints.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _LensMetricCard(
                    width: width,
                    title: 'Listed Stock',
                    value: '${lens.totalUnits} pcs',
                    subtitle: _grams(lens.totalWeight),
                    icon: Icons.inventory_2_rounded,
                    accent: InvColors.brandGold,
                  ),
                  _LensMetricCard(
                    width: width,
                    title: 'Available',
                    value: '${lens.availableUnits} pcs',
                    subtitle: _grams(lens.availableWeight),
                    icon: Icons.task_alt_rounded,
                    accent: InvColors.success,
                    onTap: () => controller.setStatusFilter('Available'),
                  ),
                  _LensMetricCard(
                    width: width,
                    title: 'Sold',
                    value: '${lens.soldUnits} pcs',
                    subtitle: _grams(lens.soldWeight),
                    icon: Icons.point_of_sale_rounded,
                    accent: InvColors.danger,
                    onTap: () => controller.setStatusFilter('Sold'),
                  ),
                  _LensMetricCard(
                    width: width,
                    title: 'HUID Linked',
                    value: '${lens.huidUnits} pcs',
                    subtitle: '${lens.weightTrackedUnits} weight tracked',
                    icon: Icons.verified_user_rounded,
                    accent: const Color(0xFF2563EB),
                    onTap: () => controller.setTrackingFilter('HUID Linked'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LensQuickChip(
                label: 'Gold',
                count: lens.metalCount('Gold'),
                selected: controller.metalFilter == 'Gold',
                accent: InvColors.brandGold,
                onTap: () => controller.setMetalFilter('Gold'),
              ),
              _LensQuickChip(
                label: 'Silver',
                count: lens.metalCount('Silver'),
                selected: controller.metalFilter == 'Silver',
                accent: const Color(0xFF64748B),
                onTap: () => controller.setMetalFilter('Silver'),
              ),
              _LensQuickChip(
                label: 'Reserved',
                count: lens.statusCount('Reserved'),
                selected: controller.statusFilter == 'Reserved',
                accent: const Color(0xFFF59E0B),
                onTap: () => controller.setStatusFilter('Reserved'),
              ),
              _LensQuickChip(
                label: 'On Hold',
                count: lens.statusCount('On Hold'),
                selected: controller.statusFilter == 'On Hold',
                accent: const Color(0xFFF59E0B),
                onTap: () => controller.setStatusFilter('On Hold'),
              ),
              _LensQuickChip(
                label: 'Damaged',
                count: lens.statusCount('Damaged'),
                selected: controller.statusFilter == 'Damaged',
                accent: const Color(0xFF64748B),
                onTap: () => controller.setStatusFilter('Damaged'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LensMetricCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _LensMetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: InvStyles.itemFieldLabel),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: InvStyles.itemFieldValue.copyWith(
                    color: InvColors.textDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: InvStyles.pageSubtitle.copyWith(
                    color: InvColors.textBody,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

class _LensQuickChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _LensQuickChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: selected ? Colors.white : accent,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : InvColors.textDark,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.20)
                      : accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : accent,
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

class _SearchLensSnapshot {
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final int huidUnits;
  final int weightTrackedUnits;
  final double totalWeight;
  final double availableWeight;
  final double soldWeight;
  final Map<String, int> metals;
  final Map<String, int> statuses;

  const _SearchLensSnapshot({
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.huidUnits,
    required this.weightTrackedUnits,
    required this.totalWeight,
    required this.availableWeight,
    required this.soldWeight,
    required this.metals,
    required this.statuses,
  });

  int metalCount(String metal) => metals[metal.toLowerCase()] ?? 0;

  int statusCount(String status) => statuses[status.toLowerCase()] ?? 0;

  static _SearchLensSnapshot fromResults(
    List<StockSearchResult> results,
    StockSearchSummary summary,
  ) {
    final metals = <String, int>{};
    final statuses = <String, int>{};
    var huidUnits = 0;
    for (final item in results) {
      metals.update(
        item.metalType.trim().toLowerCase(),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      statuses.update(
        item.status.trim().toLowerCase(),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (item.hasHuid) huidUnits += 1;
    }

    return _SearchLensSnapshot(
      totalUnits: summary.totalUnits,
      availableUnits: summary.availableUnits,
      soldUnits: summary.soldUnits,
      huidUnits: huidUnits,
      weightTrackedUnits: results.length - huidUnits,
      totalWeight: summary.netWeight,
      availableWeight: summary.availableWeight,
      soldWeight: summary.soldWeight,
      metals: metals,
      statuses: statuses,
    );
  }
}
