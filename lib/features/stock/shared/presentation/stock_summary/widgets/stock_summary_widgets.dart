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
            label: 'Net Weight',
            value: '${_summaryWeight(overview.closingWeight)} g',
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
          subtitle: 'Historical sold units',
          icon: Icons.receipt_long_rounded,
          accent: const Color(0xFFF59E0B),
          background: const Color(0xFFFFF7E6),
        ),
      ],
    );
  }
}

class _MetalSummaryPanel extends StatelessWidget {
  final List<StockSummaryMetal> metals;

  const _MetalSummaryPanel({required this.metals});

  @override
  Widget build(BuildContext context) {
    return _SummaryPanel(
      title: 'Metal-wise Closing Stock',
      subtitle: 'Available and sold stock grouped by metal.',
      icon: Icons.category_rounded,
      child: metals.isEmpty
          ? const _SummaryEmptyState(message: 'No metal stock found yet.')
          : Column(
              children: [
                for (final metal in metals) ...[
                  _MetalSummaryRow(metal: metal),
                  if (metal != metals.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _GradeSummaryPanel extends StatelessWidget {
  final List<StockSummaryGrade> grades;

  const _GradeSummaryPanel({required this.grades});

  @override
  Widget build(BuildContext context) {
    return _SummaryPanel(
      title: 'Grade Breakdown',
      subtitle: 'Purity-wise available stock snapshot.',
      icon: Icons.verified_rounded,
      child: grades.isEmpty
          ? const _SummaryEmptyState(message: 'No grade stock found yet.')
          : Column(
              children: [
                for (final grade in grades.take(10)) ...[
                  _GradeSummaryRow(grade: grade),
                  if (grade != grades.take(10).last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _RecentMovementPanel extends StatelessWidget {
  final List<StockSummaryMovement> records;

  const _RecentMovementPanel({required this.records});

  @override
  Widget build(BuildContext context) {
    return _SummaryPanel(
      title: 'Recent Stock Movement',
      subtitle: 'Latest inward, sold and restored inventory activity.',
      icon: Icons.timeline_rounded,
      child: records.isEmpty
          ? const _SummaryEmptyState(message: 'No stock movement recorded yet.')
          : Column(
              children: [
                for (final record in records) ...[
                  _MovementSummaryRow(record: record),
                  if (record != records.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SummaryPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
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
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetalSummaryRow extends StatelessWidget {
  final StockSummaryMetal metal;

  const _MetalSummaryRow({required this.metal});

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(metal.metal);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _SummaryIconBox(icon: _metalIcon(metal.metal), accent: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metal.metal} Stock',
                  style: _summaryStrongStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${metal.availableUnits} available • ${metal.soldUnits} sold',
                  style: _summaryMutedStyle(),
                ),
              ],
            ),
          ),
          _InlineMetric(
              label: 'Net', value: '${_summaryWeight(metal.netWeight)} g'),
          const SizedBox(width: 10),
          _InlineMetric(
              label: 'Fine', value: '${_summaryWeight(metal.actualFine)} g'),
        ],
      ),
    );
  }
}

class _GradeSummaryRow extends StatelessWidget {
  final StockSummaryGrade grade;

  const _GradeSummaryRow({required this.grade});

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(grade.metal);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Row(
        children: [
          _SummaryIconBox(icon: Icons.verified_rounded, accent: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${grade.metal} • ${grade.gradeLabel}',
                  style: _summaryStrongStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '${grade.availableUnits} available • ${grade.soldUnits} sold',
                  style: _summaryMutedStyle(),
                ),
              ],
            ),
          ),
          _InlineMetric(
              label: 'Net', value: '${_summaryWeight(grade.netWeight)} g'),
          const SizedBox(width: 10),
          _InlineMetric(
              label: 'Fine', value: '${_summaryWeight(grade.actualFine)} g'),
        ],
      ),
    );
  }
}

class _MovementSummaryRow extends StatelessWidget {
  final StockSummaryMovement record;

  const _MovementSummaryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final accent = record.isSold
        ? InvColors.danger
        : record.isRestore
            ? const Color(0xFF2563EB)
            : InvColors.success;
    final label = record.isSold
        ? 'Sold'
        : record.isRestore
            ? 'Restored'
            : 'Added';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Row(
        children: [
          _SummaryIconBox(
            icon: record.isSold
                ? Icons.point_of_sale_rounded
                : record.isRestore
                    ? Icons.restore_rounded
                    : Icons.add_business_rounded,
            accent: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label • ${_fallback(record.itemName, 'Stock Item')}',
                  style: _summaryStrongStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    _fallback(record.metal, 'Metal'),
                    if (record.sourceNumber.trim().isNotEmpty)
                      record.sourceNumber,
                    _summaryDate(record.occurredAt),
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryMutedStyle(),
                ),
              ],
            ),
          ),
          _InlineMetric(label: 'PCS', value: record.quantity.toString()),
          const SizedBox(width: 10),
          _InlineMetric(
              label: 'Net', value: '${_summaryWeight(record.netWeight)} g'),
        ],
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
          Text(value, style: _summaryStrongStyle(fontSize: 12.5)),
        ],
      ),
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
