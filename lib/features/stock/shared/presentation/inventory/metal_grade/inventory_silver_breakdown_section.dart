part of '../inventory_screen.dart';

class _SilverBreakdownSection extends StatelessWidget {
  final List<_InventoryBatchGroup> batches;
  final StockMetalUiData ui;
  final String Function(double value) weightFormatter;

  const _SilverBreakdownSection({
    required this.batches,
    required this.ui,
    required this.weightFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final companies = _SilverCompanySummary.buildFromBatches(batches);
    if (companies.isEmpty) return const SizedBox.shrink();

    final gradeCount = companies
        .expand((company) => company.grades.map((grade) => grade.gradeLabel))
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: InvColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ui.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.business_rounded, color: ui.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company & Grade Breakup',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Company-wise stock with grade, item-name and weight details.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _SilverBreakdownPill(
                label: companies.length == 1
                    ? '1 company'
                    : '${companies.length} companies',
                accent: ui.accent,
              ),
              const SizedBox(width: 8),
              _SilverBreakdownPill(
                label: gradeCount == 1 ? '1 grade' : '$gradeCount grades',
                accent: const Color(0xFF0F766E),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 1080
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth >= 720
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final company in companies)
                    SizedBox(
                      width: width,
                      child: _SilverCompanyBreakdownCard(
                        company: company,
                        ui: ui,
                        weightFormatter: weightFormatter,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SilverCompanyBreakdownCard extends StatefulWidget {
  final _SilverCompanySummary company;
  final StockMetalUiData ui;
  final String Function(double value) weightFormatter;

  const _SilverCompanyBreakdownCard({
    required this.company,
    required this.ui,
    required this.weightFormatter,
  });

  @override
  State<_SilverCompanyBreakdownCard> createState() =>
      _SilverCompanyBreakdownCardState();
}

class _SilverCompanyBreakdownCardState
    extends State<_SilverCompanyBreakdownCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final accent = widget.ui.accent;

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded ? accent : accent.withValues(alpha: 0.24),
            width: _expanded ? 1.4 : 1,
          ),
          boxShadow: [
            if (_expanded)
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                      Icon(Icons.storefront_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: InvColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        company.itemNamePreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: InvColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SilverBreakdownMetric(
                    label: 'Available',
                    value: '${company.availablePieces} pcs',
                    accent: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SilverBreakdownMetric(
                    label: 'Total',
                    value: '${company.totalPieces} pcs',
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SilverBreakdownMetric(
                    label: 'Grades',
                    value: '${company.grades.length}',
                    accent: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SilverBreakdownMetric(
                    label: 'Available Wt',
                    value:
                        '${widget.weightFormatter(company.availableWeight)} g',
                    accent: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SilverBreakdownMetric(
                    label: 'Total Wt',
                    value: '${widget.weightFormatter(company.totalWeight)} g',
                    accent: accent,
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _expanded
                  ? Padding(
                      key: const ValueKey('grades'),
                      padding: const EdgeInsets.only(top: 12),
                      child: _SilverGradeBreakdownList(
                        grades: company.grades,
                        accent: accent,
                        weightFormatter: widget.weightFormatter,
                      ),
                    )
                  : Padding(
                      key: const ValueKey('hint'),
                      padding: const EdgeInsets.only(top: 10),
                      child: _FlipHint(
                        accent: accent,
                        label: 'Click to view grade breakup',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SilverGradeBreakdownList extends StatelessWidget {
  final List<_SilverGradeSummary> grades;
  final Color accent;
  final String Function(double value) weightFormatter;

  const _SilverGradeBreakdownList({
    required this.grades,
    required this.accent,
    required this.weightFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final grade in grades) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        grade.gradeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: InvColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${grade.availablePieces}/${grade.totalPieces} pcs',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  grade.itemNamePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SilverBreakdownMetric(
                        label: 'Available',
                        value: '${weightFormatter(grade.availableWeight)} g',
                        accent: const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SilverBreakdownMetric(
                        label: 'Total',
                        value: '${weightFormatter(grade.totalWeight)} g',
                        accent: accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (grade != grades.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SilverBreakdownPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _SilverBreakdownPill({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      ),
    );
  }
}

class _SilverBreakdownMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SilverBreakdownMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SilverCompanySummary {
  final String companyName;
  final List<_SilverGradeSummary> grades;
  final int totalPieces;
  final int availablePieces;
  final double totalWeight;
  final double availableWeight;
  final Set<String> itemNames;

  const _SilverCompanySummary({
    required this.companyName,
    required this.grades,
    required this.totalPieces,
    required this.availablePieces,
    required this.totalWeight,
    required this.availableWeight,
    required this.itemNames,
  });

  String get itemNamePreview {
    if (itemNames.isEmpty) return 'No item names recorded';
    final preview = itemNames.take(3).join(', ');
    if (itemNames.length <= 3) return preview;
    return '$preview +${itemNames.length - 3} more';
  }

  static List<_SilverCompanySummary> buildFromBatches(
    List<_InventoryBatchGroup> batches,
  ) {
    final accumulators = <String, _SilverCompanyAccumulator>{};
    for (final batch in batches) {
      for (final unit in batch.units) {
        final companyName = _silverCompanyName(unit);
        final key = companyName.toLowerCase();
        accumulators
            .putIfAbsent(key, () => _SilverCompanyAccumulator(companyName))
            .add(unit);
      }
    }

    final companies =
        accumulators.values.map((entry) => entry.toSummary()).toList()
          ..sort((a, b) {
            final available = b.availablePieces.compareTo(a.availablePieces);
            if (available != 0) return available;
            return a.companyName.compareTo(b.companyName);
          });
    return companies;
  }
}

class _SilverCompanyAccumulator {
  final String companyName;
  final Map<String, _SilverGradeAccumulator> grades =
      <String, _SilverGradeAccumulator>{};
  final Set<String> itemNames = <String>{};
  int totalPieces = 0;
  int availablePieces = 0;
  double totalWeight = 0;
  double availableWeight = 0;

  _SilverCompanyAccumulator(this.companyName);

  void add(_InventoryGradeUnit unit) {
    final gradeLabel = _silverGradeLabel(unit);
    grades
        .putIfAbsent(
          gradeLabel.toLowerCase(),
          () => _SilverGradeAccumulator(gradeLabel),
        )
        .add(unit);

    final itemName = unit.itemName.trim();
    if (itemName.isNotEmpty) itemNames.add(_titleCase(itemName));
    totalPieces += unit.totalPieces;
    availablePieces += unit.availablePieces;
    totalWeight += unit.totalNetWeight;
    availableWeight += unit.availableNetWeight;
  }

  _SilverCompanySummary toSummary() {
    final gradeList = grades.values.map((entry) => entry.toSummary()).toList()
      ..sort((a, b) {
        final available = b.availablePieces.compareTo(a.availablePieces);
        if (available != 0) return available;
        return a.gradeLabel.compareTo(b.gradeLabel);
      });
    return _SilverCompanySummary(
      companyName: companyName,
      grades: gradeList,
      totalPieces: totalPieces,
      availablePieces: availablePieces,
      totalWeight: totalWeight,
      availableWeight: availableWeight,
      itemNames: itemNames,
    );
  }
}

class _SilverGradeSummary {
  final String gradeLabel;
  final int totalPieces;
  final int availablePieces;
  final double totalWeight;
  final double availableWeight;
  final Set<String> itemNames;

  const _SilverGradeSummary({
    required this.gradeLabel,
    required this.totalPieces,
    required this.availablePieces,
    required this.totalWeight,
    required this.availableWeight,
    required this.itemNames,
  });

  String get itemNamePreview {
    if (itemNames.isEmpty) return 'No item names recorded';
    final preview = itemNames.take(3).join(', ');
    if (itemNames.length <= 3) return preview;
    return '$preview +${itemNames.length - 3} more';
  }
}

class _SilverGradeAccumulator {
  final String gradeLabel;
  final Set<String> itemNames = <String>{};
  int totalPieces = 0;
  int availablePieces = 0;
  double totalWeight = 0;
  double availableWeight = 0;

  _SilverGradeAccumulator(this.gradeLabel);

  void add(_InventoryGradeUnit unit) {
    final itemName = unit.itemName.trim();
    if (itemName.isNotEmpty) itemNames.add(_titleCase(itemName));
    totalPieces += unit.totalPieces;
    availablePieces += unit.availablePieces;
    totalWeight += unit.totalNetWeight;
    availableWeight += unit.availableNetWeight;
  }

  _SilverGradeSummary toSummary() {
    return _SilverGradeSummary(
      gradeLabel: gradeLabel,
      totalPieces: totalPieces,
      availablePieces: availablePieces,
      totalWeight: totalWeight,
      availableWeight: availableWeight,
      itemNames: itemNames,
    );
  }
}

String _silverCompanyName(_InventoryGradeUnit unit) {
  final companyName = unit.companyName.trim();
  if (companyName.isNotEmpty) return _titleCase(companyName);
  return 'Unbranded Silver';
}

String _silverGradeLabel(_InventoryGradeUnit unit) {
  if (unit.purityPercent > 0) {
    return '${_formatInventoryPercent(unit.purityPercent)}%';
  }
  return 'Custom Grade';
}
