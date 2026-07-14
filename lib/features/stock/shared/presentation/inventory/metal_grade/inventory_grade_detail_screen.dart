part of '../inventory_screen.dart';

class _InventoryGradeDetailScreen extends StatefulWidget {
  final StockCategory metal;
  final _InventoryGradeSummary grade;

  const _InventoryGradeDetailScreen({
    required this.metal,
    required this.grade,
  });

  @override
  State<_InventoryGradeDetailScreen> createState() =>
      _InventoryGradeDetailScreenState();
}

class _InventoryGradeDetailScreenState
    extends State<_InventoryGradeDetailScreen> {
  final AppDatabase _db = AppDatabase();
  late final Future<List<_InventoryGradeUnit>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _unitsFuture = _loadGradeUnits();
  }

  Future<List<_InventoryGradeUnit>> _loadGradeUnits() async {
    final rows = await _db.customSelect(
      '''
      SELECT
        u.id AS unit_id,
        u.unit_code AS unit_code,
        u.batch_code AS batch_code,
        u.item_type AS item_type,
        u.segment AS segment,
        u.item_name AS item_name,
        u.huid AS huid,
        u.gross_weight AS gross_weight,
        u.less_weight AS less_weight,
        u.net_weight AS net_weight,
        u.purity_percent AS purity_percent,
        u.actual_fine_weight AS actual_fine,
        u.valuation_fine_weight AS valuation_fine,
        u.unit_cost AS unit_cost,
        u.supplier_name AS supplier_name,
        u.status AS status,
        COALESCE(
          NULLIF(TRIM(s.purity), ''),
          CASE
            WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
            ELSE 'Custom Grade'
          END
        ) AS grade_label
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      WHERE lower(u.metal_type) = ?
        AND COALESCE(
          NULLIF(TRIM(s.purity), ''),
          CASE
            WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
            ELSE 'Custom Grade'
          END
        ) = ?
      ORDER BY
        CASE WHEN lower(u.status) = 'available' THEN 0 ELSE 1 END,
        lower(u.item_type) ASC,
        lower(u.segment) ASC,
        lower(u.item_name) ASC,
        u.id DESC
      ''',
      variables: [
        Variable.withString(widget.metal.label.toLowerCase()),
        Variable.withString(widget.grade.gradeLabel),
      ],
    ).get();

    return rows.map(_InventoryGradeUnit.fromRow).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(widget.metal);
    final title = _inventoryGradeTitle(widget.metal, widget.grade.gradeLabel);
    final subtitle = _inventoryGradeSubtitle(
      widget.metal,
      widget.grade.gradeLabel,
      widget.grade.availableUnits,
      widget.grade.totalUnits,
    );

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: FutureBuilder<List<_InventoryGradeUnit>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          final units = snapshot.data ?? const <_InventoryGradeUnit>[];
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                  child: _buildHeader(ui, title, subtitle),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ui.accent,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (units.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(ui),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverList.separated(
                    itemCount: units.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _InventoryGradeUnitCard(
                        unit: units[index],
                        ui: ui,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(StockMetalUiData ui, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: ui.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
            child: Icon(ui.icon, color: ui.textOnGradient, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: ui.textOnGradient,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ui.textOnGradient.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          _HeaderMetric(
            label: 'Available',
            value: '${widget.grade.availableUnits} pcs',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Actual Fine',
            value: '${_weight(widget.grade.actualFine)} g',
            textColor: ui.textOnGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(StockMetalUiData ui) {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: InvColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ui.icon, color: ui.accent, size: 34),
            const SizedBox(height: 12),
            Text(
              'No Stock Units Found',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This grade summary is available, but item-level records could not be found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: InvColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }
}

class _InventoryGradeUnit {
  final int unitId;
  final String unitCode;
  final String batchCode;
  final String itemType;
  final String segment;
  final String itemName;
  final String huid;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purityPercent;
  final double actualFine;
  final double valuationFine;
  final double unitCost;
  final String supplierName;
  final String status;

  const _InventoryGradeUnit({
    required this.unitId,
    required this.unitCode,
    required this.batchCode,
    required this.itemType,
    required this.segment,
    required this.itemName,
    required this.huid,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purityPercent,
    required this.actualFine,
    required this.valuationFine,
    required this.unitCost,
    required this.supplierName,
    required this.status,
  });

  factory _InventoryGradeUnit.fromRow(QueryRow row) {
    String text(String column) {
      final value = row.data[column];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return '';
    }

    double number(String column) {
      final value = row.data[column];
      if (value is num) return value.toDouble();
      return 0.0;
    }

    int integer(String column) {
      final value = row.data[column];
      if (value is num) return value.toInt();
      return 0;
    }

    return _InventoryGradeUnit(
      unitId: integer('unit_id'),
      unitCode: text('unit_code'),
      batchCode: text('batch_code'),
      itemType: text('item_type'),
      segment: text('segment'),
      itemName: text('item_name'),
      huid: text('huid'),
      grossWeight: number('gross_weight'),
      lessWeight: number('less_weight'),
      netWeight: number('net_weight'),
      purityPercent: number('purity_percent'),
      actualFine: number('actual_fine'),
      valuationFine: number('valuation_fine'),
      unitCost: number('unit_cost'),
      supplierName: text('supplier_name'),
      status: text('status'),
    );
  }
}

class _InventoryGradeUnitCard extends StatelessWidget {
  final _InventoryGradeUnit unit;
  final StockMetalUiData ui;

  const _InventoryGradeUnitCard({
    required this.unit,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final available = unit.status.toLowerCase() == 'available';
    final statusColor = available ? InvColors.success : InvColors.danger;
    final statusBg = available ? InvColors.successBg : InvColors.dangerBg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InvColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ui.softTint.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(ui.icon, color: ui.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.itemName.isEmpty ? 'Unnamed Stock Item' : unit.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _itemSubtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _UnitMetric(
            label: 'HUID',
            value: unit.huid.isEmpty ? 'No HUID' : unit.huid,
          ),
          _UnitMetric(label: 'Gross', value: '${_weight(unit.grossWeight)} g'),
          _UnitMetric(label: 'Net', value: '${_weight(unit.netWeight)} g'),
          _UnitMetric(
            label: 'Actual Fine',
            value: '${_weight(unit.actualFine)} g',
          ),
          _UnitMetric(
            label: 'Valuation Fine',
            value: '${_weight(unit.valuationFine)} g',
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              unit.status.isEmpty ? 'Available' : unit.status,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _itemSubtitle() {
    final parts = [
      unit.itemType,
      unit.segment,
      unit.batchCode,
      unit.supplierName,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return unit.unitCode;
    return parts.join(' - ');
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }
}

class _UnitMetric extends StatelessWidget {
  final String label;
  final String value;

  const _UnitMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
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
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
