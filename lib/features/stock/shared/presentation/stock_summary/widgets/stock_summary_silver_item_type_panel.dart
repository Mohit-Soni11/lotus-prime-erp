part of '../stock_summary_screen.dart';

class _SilverItemTypeSummaryPanel extends StatelessWidget {
  final List<StockSummaryItem> items;
  final VoidCallback? onBack;
  final ValueChanged<String> onOpen;

  const _SilverItemTypeSummaryPanel({
    required this.items,
    this.onBack,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final summaries = _SilverItemTypeSummary.buildFromItems(items)
        .where((summary) => summary.hasStock)
        .toList(growable: false);

    return _SummaryPanel(
      title: 'Silver Item Type Summary',
      subtitle: 'Available, sold and total stock arranged by silver item type.',
      icon: Icons.category_rounded,
      action: onBack == null
          ? null
          : _PanelActionButton(
              label: 'Back to Metals',
              icon: Icons.arrow_back_rounded,
              onTap: onBack!,
            ),
      child: summaries.isEmpty
          ? const _SummaryEmptyState(
              message: 'No silver item type stock found yet.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 960
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final summary in summaries)
                      SizedBox(
                        width: cardWidth,
                        child: _SilverItemTypeSummaryCard(
                          summary: summary,
                          onTap: () => onOpen(summary.itemType),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _SilverItemTypeSummaryCard extends StatelessWidget {
  final _SilverItemTypeSummary summary;
  final VoidCallback onTap;

  const _SilverItemTypeSummaryCard({
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.silver);

    return InventoryMetalSummaryCard(
      title: '${summary.itemType} Silver Stock',
      subtitle:
          '${summary.gradeCount} grades | ${summary.companyGroupCount} company groups | ${summary.itemNameCount} item names',
      primaryLabel: 'Closing Stock',
      primaryValue:
          '${summary.availablePieces} pcs | ${_summaryWeight(summary.availableWeight)} g',
      weightLabel: 'Total Stock',
      weightValue:
          '${summary.totalPieces} pcs | ${_summaryWeight(summary.totalWeight)} g',
      actionLabel: 'Open ${summary.itemType} Summary',
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

class _SilverItemTypeDetailPanel extends StatelessWidget {
  final String itemType;
  final List<StockSummaryItem> items;
  final VoidCallback onBack;

  const _SilverItemTypeDetailPanel({
    required this.itemType,
    required this.items,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final summaries = _SilverItemTypeGradeSummary.buildFromItems(items)
        .where((summary) => summary.hasStock)
        .toList(growable: false);

    return _SummaryPanel(
      title: '$itemType Silver Details',
      subtitle: 'Grade, company and movement status for this silver item type.',
      icon: Icons.account_tree_rounded,
      action: _PanelActionButton(
        label: 'Back to Item Types',
        icon: Icons.arrow_back_rounded,
        onTap: onBack,
      ),
      child: summaries.isEmpty
          ? const _SummaryEmptyState(
              message: 'No stock found for this silver item type.')
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
                    for (final summary in summaries)
                      SizedBox(
                        width: width,
                        child: _SilverItemTypeGradeCard(summary: summary),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _SilverItemTypeGradeCard extends StatelessWidget {
  final _SilverItemTypeGradeSummary summary;

  const _SilverItemTypeGradeCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF64748B);
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
              const _SummaryIconBox(
                icon: Icons.verified_rounded,
                accent: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.gradeLabel} Silver',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _summaryStrongStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.subtitle,
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
                    label: 'Available',
                    value:
                        '${summary.availablePieces} pcs | ${_summaryWeight(summary.availableWeight)} g',
                    icon: Icons.inventory_2_rounded,
                    accent: InvColors.success,
                    background: InvColors.successBg,
                  ),
                  _BlockMetric(
                    width: width,
                    label: 'Sold',
                    value:
                        '${summary.soldPieces} pcs | ${_summaryWeight(summary.soldWeight)} g',
                    icon: Icons.point_of_sale_rounded,
                    accent: InvColors.danger,
                    background: InvColors.dangerBg,
                  ),
                  _BlockMetric(
                    width: width,
                    label: 'Total Stock',
                    value:
                        '${summary.totalPieces} pcs | ${_summaryWeight(summary.totalWeight)} g',
                    icon: Icons.scale_rounded,
                    accent: accent,
                    background: const Color(0xFFEFF3F8),
                  ),
                  _BlockMetric(
                    width: width,
                    label: 'Actual Fine',
                    value: '${_summaryWeight(summary.actualFine)} g',
                    icon: Icons.workspace_premium_rounded,
                    accent: InvColors.brandGold,
                    background: InvColors.brandGoldLight,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _SilverCompanyStrip(companies: summary.companyNames),
        ],
      ),
    );
  }
}

class _SilverCompanyStrip extends StatelessWidget {
  final Set<String> companies;

  const _SilverCompanyStrip({required this.companies});

  @override
  Widget build(BuildContext context) {
    final visibleCompanies = companies.take(5).toList(growable: false);
    final extraCount = companies.length - visibleCompanies.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: companies.isEmpty
          ? Text('Company not tagged', style: _summaryMutedStyle(fontSize: 11))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final company in visibleCompanies)
                  _SilverCompanyChip(label: company),
                if (extraCount > 0) _SilverCompanyChip(label: '+$extraCount'),
              ],
            ),
    );
  }
}

class _SilverCompanyChip extends StatelessWidget {
  final String label;

  const _SilverCompanyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD4DEE9)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _summaryStrongStyle(fontSize: 11).copyWith(
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}

class _SilverItemTypeSummary {
  final String itemType;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final int companyGroupCount;
  final double availableWeight;
  final double soldWeight;
  final double totalWeight;
  final Set<String> gradeLabels;
  final Set<String> itemNames;
  final Set<String> companyNames;

  const _SilverItemTypeSummary({
    required this.itemType,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.companyGroupCount,
    required this.availableWeight,
    required this.soldWeight,
    required this.totalWeight,
    required this.gradeLabels,
    required this.itemNames,
    required this.companyNames,
  });

  bool get hasStock =>
      totalPieces > 0 ||
      availablePieces > 0 ||
      soldPieces > 0 ||
      totalWeight > 0;

  int get gradeCount => gradeLabels.length;
  int get itemNameCount => itemNames.length;

  static List<_SilverItemTypeSummary> buildFromItems(
    List<StockSummaryItem> items,
  ) {
    final accumulators = <String, _SilverItemTypeAccumulator>{};
    for (final item in items) {
      final itemType = _silverSummaryItemType(item);
      accumulators
          .putIfAbsent(
            itemType.toLowerCase(),
            () => _SilverItemTypeAccumulator(itemType),
          )
          .add(item);
    }

    final summaries =
        accumulators.values.map((entry) => entry.toSummary()).toList()
          ..sort((a, b) {
            final available = b.availablePieces.compareTo(a.availablePieces);
            if (available != 0) return available;
            return a.itemType.compareTo(b.itemType);
          });
    return summaries;
  }
}

class _SilverItemTypeAccumulator {
  final String itemType;
  final Set<String> gradeLabels = <String>{};
  final Set<String> itemNames = <String>{};
  final Set<String> companyNames = <String>{};
  int totalPieces = 0;
  int availablePieces = 0;
  int soldPieces = 0;
  int fallbackCompanyGroupCount = 0;
  double availableWeight = 0;
  double soldWeight = 0;
  double totalWeight = 0;

  _SilverItemTypeAccumulator(this.itemType);

  void add(StockSummaryItem item) {
    final gradeLabel = item.gradeLabel.trim();
    if (gradeLabel.isNotEmpty) gradeLabels.add(gradeLabel);

    final itemName = item.itemName.trim();
    if (itemName.isNotEmpty) itemNames.add(_titleCase(itemName));
    for (final company in item.companyNames) {
      final name = company.trim();
      if (name.isNotEmpty) companyNames.add(_titleCase(name));
    }

    totalPieces += item.totalPieces;
    availablePieces += item.availablePieces;
    soldPieces += item.soldPieces;
    fallbackCompanyGroupCount += item.companyCount;
    availableWeight += item.availableWeight;
    soldWeight += item.soldWeight;
    totalWeight += item.totalWeight;
  }

  _SilverItemTypeSummary toSummary() {
    return _SilverItemTypeSummary(
      itemType: itemType,
      totalPieces: totalPieces,
      availablePieces: availablePieces,
      soldPieces: soldPieces,
      companyGroupCount: companyNames.isEmpty
          ? fallbackCompanyGroupCount
          : companyNames.length,
      availableWeight: availableWeight,
      soldWeight: soldWeight,
      totalWeight: totalWeight,
      gradeLabels: gradeLabels,
      itemNames: itemNames,
      companyNames: companyNames,
    );
  }
}

class _SilverItemTypeGradeSummary {
  final String gradeLabel;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final double availableWeight;
  final double soldWeight;
  final double totalWeight;
  final double actualFine;
  final Set<String> companyNames;
  final Set<String> itemNames;
  final Set<String> segments;
  final int fallbackCompanyGroupCount;

  const _SilverItemTypeGradeSummary({
    required this.gradeLabel,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.availableWeight,
    required this.soldWeight,
    required this.totalWeight,
    required this.actualFine,
    required this.companyNames,
    required this.itemNames,
    required this.segments,
    required this.fallbackCompanyGroupCount,
  });

  bool get hasStock =>
      totalPieces > 0 ||
      availablePieces > 0 ||
      soldPieces > 0 ||
      totalWeight > 0;

  int get companyCount =>
      companyNames.isEmpty ? fallbackCompanyGroupCount : companyNames.length;

  String get subtitle {
    final companyText = companyCount <= 0
        ? 'company not tagged'
        : companyCount == 1
            ? '1 company'
            : '$companyCount companies';
    final itemText = itemNames.isEmpty
        ? 'item name not tagged'
        : itemNames.length == 1
            ? '1 item name'
            : '${itemNames.length} item names';
    final segmentText = segments.isEmpty
        ? 'segment not tagged'
        : segments.length == 1
            ? '1 segment'
            : '${segments.length} segments';
    return '$companyText | $itemText | $segmentText';
  }

  static List<_SilverItemTypeGradeSummary> buildFromItems(
    List<StockSummaryItem> items,
  ) {
    final accumulators = <String, _SilverItemTypeGradeAccumulator>{};
    for (final item in items) {
      final grade = _fallback(item.gradeLabel, 'Unknown Grade');
      accumulators
          .putIfAbsent(
            grade.toLowerCase(),
            () => _SilverItemTypeGradeAccumulator(grade),
          )
          .add(item);
    }

    return accumulators.values.map((entry) => entry.toSummary()).toList()
      ..sort((a, b) {
        final available = b.availablePieces.compareTo(a.availablePieces);
        if (available != 0) return available;
        return a.gradeLabel.compareTo(b.gradeLabel);
      });
  }
}

class _SilverItemTypeGradeAccumulator {
  final String gradeLabel;
  final Set<String> companyNames = <String>{};
  final Set<String> itemNames = <String>{};
  final Set<String> segments = <String>{};
  int totalPieces = 0;
  int availablePieces = 0;
  int soldPieces = 0;
  int fallbackCompanyGroupCount = 0;
  double availableWeight = 0;
  double soldWeight = 0;
  double totalWeight = 0;
  double actualFine = 0;

  _SilverItemTypeGradeAccumulator(this.gradeLabel);

  void add(StockSummaryItem item) {
    for (final company in item.companyNames) {
      final name = company.trim();
      if (name.isNotEmpty) companyNames.add(_titleCase(name));
    }
    final itemName = item.itemName.trim();
    if (itemName.isNotEmpty) itemNames.add(_titleCase(itemName));
    final segment = item.segment.trim();
    if (segment.isNotEmpty) segments.add(_titleCase(segment));

    totalPieces += item.totalPieces;
    availablePieces += item.availablePieces;
    soldPieces += item.soldPieces;
    fallbackCompanyGroupCount += item.companyCount;
    availableWeight += item.availableWeight;
    soldWeight += item.soldWeight;
    totalWeight += item.totalWeight;
    actualFine += item.actualFine;
  }

  _SilverItemTypeGradeSummary toSummary() {
    return _SilverItemTypeGradeSummary(
      gradeLabel: gradeLabel,
      totalPieces: totalPieces,
      availablePieces: availablePieces,
      soldPieces: soldPieces,
      availableWeight: availableWeight,
      soldWeight: soldWeight,
      totalWeight: totalWeight,
      actualFine: actualFine,
      companyNames: companyNames,
      itemNames: itemNames,
      segments: segments,
      fallbackCompanyGroupCount: fallbackCompanyGroupCount,
    );
  }
}

String _silverSummaryItemType(StockSummaryItem item) {
  final itemType = item.itemType.trim();
  if (itemType.isNotEmpty) return _titleCase(itemType);
  final itemName = item.itemName.trim();
  if (itemName.isNotEmpty) return _titleCase(itemName);
  return 'Silver Item';
}
