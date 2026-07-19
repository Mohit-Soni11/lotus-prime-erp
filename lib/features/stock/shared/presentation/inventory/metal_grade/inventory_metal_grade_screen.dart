part of '../inventory_screen.dart';

const String _inventoryLotUnitExpression = '''
lower(COALESCE(u.unit_code, '')) LIKE '%lot%'
  AND TRIM(COALESCE(u.huid, '')) = ''
''';

const String _inventoryAvailableGrossWeightExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(s.gross_weight, u.gross_weight, 0.0)
      ELSE COALESCE(u.gross_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableNetWeightExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(s.net_weight, u.net_weight, 0.0)
      ELSE COALESCE(u.net_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableActualFineExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(u.actual_fine_weight, 0.0)
      ELSE COALESCE(u.actual_fine_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableValuationFineExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(u.valuation_fine_weight, 0.0)
      ELSE COALESCE(u.valuation_fine_weight, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventoryAvailableStockValueExpression = '''
CASE
  WHEN lower(u.status) = 'available' THEN
    CASE
      WHEN $_inventoryLotUnitExpression THEN
        COALESCE(u.unit_cost, 0.0)
      ELSE COALESCE(u.unit_cost, 0.0)
    END
  ELSE 0.0
END
''';

const String _inventorySoldWeightExpression = '''
CASE
  WHEN u.id = (
    SELECT MIN(first_unit.id)
    FROM stock_item_units first_unit
    WHERE first_unit.stock_item_id = s.id
  ) THEN
    CASE
      WHEN COALESCE(sm.sold_net_weight, 0) > 0
        THEN COALESCE(sm.sold_net_weight, 0)
      ELSE 0
    END
  ELSE 0
END
''';

const String _inventorySoldWeightJoin = '''
LEFT JOIN (
  SELECT
    source.stock_item_id,
    COALESCE(bill_weight.sold_net_weight, movement_weight.sold_net_weight, 0.0) AS sold_net_weight
  FROM (
    SELECT stock_item_id
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    UNION
    SELECT linked_stock_item_id AS stock_item_id
    FROM bill_items
    WHERE linked_stock_item_id IS NOT NULL
  ) source
  LEFT JOIN (
    SELECT
      bi.linked_stock_item_id AS stock_item_id,
      SUM(COALESCE(bi.net_weight, 0.0)) AS sold_net_weight
    FROM bill_items bi
    INNER JOIN bills b ON b.id = bi.bill_id
    WHERE bi.linked_stock_item_id IS NOT NULL
      AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
    GROUP BY bi.linked_stock_item_id
  ) bill_weight ON bill_weight.stock_item_id = source.stock_item_id
  LEFT JOIN (
    SELECT
      stock_item_id,
      SUM(
        CASE
          WHEN movement_type = 'SALE' THEN ABS(net_weight_delta)
          WHEN movement_type = 'SALE_RESTORE' THEN -ABS(net_weight_delta)
          ELSE 0
        END
      ) AS sold_net_weight
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    GROUP BY stock_item_id
  ) movement_weight ON movement_weight.stock_item_id = source.stock_item_id
) sm ON sm.stock_item_id = s.id
''';

class _InventoryMetalGradeScreen extends StatefulWidget {
  final StockCategory metal;
  final String? initialBatchCode;

  const _InventoryMetalGradeScreen({
    required this.metal,
    this.initialBatchCode,
  });

  @override
  State<_InventoryMetalGradeScreen> createState() =>
      _InventoryMetalGradeScreenState();
}

class _InventoryMetalGradeScreenState
    extends State<_InventoryMetalGradeScreen> {
  final AppDatabase _db = AppDatabase();
  late final Future<List<_InventoryGradeSummary>> _gradeFuture;
  String? _selectedGrade;
  String _stockViewFilter = 'Live Stock';
  bool _openedInitialBatch = false;
  Future<void>? _schemaFuture;

  @override
  void initState() {
    super.initState();
    _gradeFuture = _loadGradeSummary();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _openInitialBatchIfNeeded());
  }

  Future<void> _openInitialBatchIfNeeded() async {
    if (_openedInitialBatch || !mounted) return;
    final batchCode = widget.initialBatchCode?.trim();
    if (batchCode == null || batchCode.isEmpty) return;
    _openedInitialBatch = true;
    final grade = await _loadGradeForBatch(batchCode);
    if (!mounted || grade == null) return;
    _openGradeLedger(grade, initialBatchCode: batchCode);
  }

  Future<_InventoryGradeSummary?> _loadGradeForBatch(String batchCode) async {
    await _ensureInventoryGroupingSchema();
    final groupExpression = _inventoryPrimaryGroupExpression(widget.metal);
    final fallbackLabel = _inventoryFallbackGroupLabel(widget.metal);
    final rows = await _db.customSelect(
      '''
      SELECT
        $groupExpression AS grade_label,
        COUNT(*) AS total_units,
        SUM(CASE WHEN lower(u.status) = 'available' THEN 1 ELSE 0 END) AS available_units,
        SUM(CASE WHEN lower(u.status) = 'sold' THEN 1 ELSE 0 END) AS sold_units,
        SUM(CASE WHEN lower(COALESCE(u.unit_code, '')) LIKE '%lot%' AND TRIM(COALESCE(u.huid, '')) = '' THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) ELSE 1 END) AS total_pieces,
        SUM(CASE WHEN lower(u.status) = 'available' THEN CASE WHEN lower(COALESCE(u.unit_code, '')) LIKE '%lot%' AND TRIM(COALESCE(u.huid, '')) = '' THEN COALESCE(NULLIF(s.quantity, 0), 0) ELSE 1 END ELSE 0 END) AS available_pieces,
        SUM(CASE WHEN lower(COALESCE(u.unit_code, '')) LIKE '%lot%' AND TRIM(COALESCE(u.huid, '')) = '' THEN CASE WHEN lower(u.status) = 'sold' THEN COALESCE(NULLIF(pvi.quantity, 0), 1) WHEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) > 0 THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) ELSE 0 END WHEN lower(u.status) = 'sold' THEN 1 ELSE 0 END) AS sold_pieces,
        SUM(CASE WHEN lower(COALESCE(s.quantity_mode, '')) IN ('packet', 'pack') THEN COALESCE(NULLIF(s.packet_count, 0), 0) ELSE 0 END) AS total_sets,
        SUM(CASE WHEN lower(u.status) = 'available' AND lower(COALESCE(s.quantity_mode, '')) IN ('packet', 'pack') THEN COALESCE(NULLIF(s.packet_count, 0), 0) ELSE 0 END) AS available_sets,
        COUNT(DISTINCT NULLIF(TRIM(COALESCE(s.company_name, '')), '')) AS company_count,
        COUNT(DISTINCT CASE WHEN u.purity_percent > 0 THEN printf('%.2f', u.purity_percent) ELSE NULL END) AS purity_group_count,
        COALESCE(SUM($_inventoryAvailableGrossWeightExpression), 0.0) AS gross_weight,
        COALESCE(SUM($_inventoryAvailableNetWeightExpression), 0.0) AS net_weight,
        COALESCE(SUM($_inventorySoldWeightExpression), 0.0) AS sold_weight,
        COALESCE(SUM($_inventoryAvailableActualFineExpression), 0.0) AS actual_fine,
        COALESCE(SUM($_inventoryAvailableValuationFineExpression), 0.0) AS valuation_fine,
        COALESCE(SUM($_inventoryAvailableStockValueExpression), 0.0) AS stock_value
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
      $_inventorySoldWeightJoin
      WHERE lower(u.metal_type) = ?
        AND lower(COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no, 'Unbatched Stock')) = lower(?)
      GROUP BY grade_label
      LIMIT 1
      ''',
      variables: [
        Variable.withString(widget.metal.label.toLowerCase()),
        Variable.withString(batchCode),
      ],
    ).get();

    if (rows.isEmpty) return null;
    final row = rows.first;
    return _InventoryGradeSummary(
      gradeLabel: _readString(row, 'grade_label', fallbackLabel),
      totalUnits: _readInt(row, 'total_units'),
      availableUnits: _readInt(row, 'available_units'),
      soldUnits: _readInt(row, 'sold_units'),
      totalPieces: _readInt(row, 'total_pieces'),
      availablePieces: _readInt(row, 'available_pieces'),
      soldPieces: _readInt(row, 'sold_pieces'),
      totalSets: _readInt(row, 'total_sets'),
      availableSets: _readInt(row, 'available_sets'),
      companyCount: _readInt(row, 'company_count'),
      purityGroupCount: _readInt(row, 'purity_group_count'),
      grossWeight: _readDouble(row, 'gross_weight'),
      netWeight: _readDouble(row, 'net_weight'),
      soldWeight: _readDouble(row, 'sold_weight'),
      actualFine: _readDouble(row, 'actual_fine'),
      valuationFine: _readDouble(row, 'valuation_fine'),
      stockValue: _readDouble(row, 'stock_value'),
      availableInfo: const <_InventoryGradeAvailableInfo>[],
    );
  }

  Future<List<_InventoryGradeSummary>> _loadGradeSummary() async {
    await _ensureInventoryGroupingSchema();
    final groupExpression = _inventoryPrimaryGroupExpression(widget.metal);
    final fallbackLabel = _inventoryFallbackGroupLabel(widget.metal);
    final availableInfoByGrade =
        await _loadAvailableInfoByGrade(groupExpression);
    final rows = await _db.customSelect(
      '''
      SELECT
        $groupExpression AS grade_label,
        COUNT(*) AS total_units,
        SUM(CASE WHEN lower(u.status) = 'available' THEN 1 ELSE 0 END) AS available_units,
        SUM(CASE WHEN lower(u.status) = 'sold' THEN 1 ELSE 0 END) AS sold_units,
        SUM(CASE WHEN lower(COALESCE(u.unit_code, '')) LIKE '%lot%' AND TRIM(COALESCE(u.huid, '')) = '' THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) ELSE 1 END) AS total_pieces,
        SUM(CASE WHEN lower(u.status) = 'available' THEN CASE WHEN lower(COALESCE(u.unit_code, '')) LIKE '%lot%' AND TRIM(COALESCE(u.huid, '')) = '' THEN COALESCE(NULLIF(s.quantity, 0), 0) ELSE 1 END ELSE 0 END) AS available_pieces,
        SUM(CASE WHEN lower(COALESCE(u.unit_code, '')) LIKE '%lot%' AND TRIM(COALESCE(u.huid, '')) = '' THEN CASE WHEN lower(u.status) = 'sold' THEN COALESCE(NULLIF(pvi.quantity, 0), 1) WHEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) > 0 THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) ELSE 0 END WHEN lower(u.status) = 'sold' THEN 1 ELSE 0 END) AS sold_pieces,
        SUM(CASE WHEN lower(COALESCE(s.quantity_mode, '')) IN ('packet', 'pack') THEN COALESCE(NULLIF(s.packet_count, 0), 0) ELSE 0 END) AS total_sets,
        SUM(CASE WHEN lower(u.status) = 'available' AND lower(COALESCE(s.quantity_mode, '')) IN ('packet', 'pack') THEN COALESCE(NULLIF(s.packet_count, 0), 0) ELSE 0 END) AS available_sets,
        COUNT(DISTINCT NULLIF(TRIM(COALESCE(s.company_name, '')), '')) AS company_count,
        COUNT(DISTINCT CASE WHEN u.purity_percent > 0 THEN printf('%.2f', u.purity_percent) ELSE NULL END) AS purity_group_count,
        COALESCE(SUM($_inventoryAvailableGrossWeightExpression), 0.0) AS gross_weight,
        COALESCE(SUM($_inventoryAvailableNetWeightExpression), 0.0) AS net_weight,
        COALESCE(SUM($_inventorySoldWeightExpression), 0.0) AS sold_weight,
        COALESCE(SUM($_inventoryAvailableActualFineExpression), 0.0) AS actual_fine,
        COALESCE(SUM($_inventoryAvailableValuationFineExpression), 0.0) AS valuation_fine,
        COALESCE(SUM($_inventoryAvailableStockValueExpression), 0.0) AS stock_value
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      $_inventorySoldWeightJoin
      WHERE lower(u.metal_type) = ?
      GROUP BY grade_label
      ORDER BY available_units DESC, total_units DESC, grade_label ASC
      ''',
      variables: [Variable.withString(widget.metal.label.toLowerCase())],
    ).get();

    return rows.map(
      (row) {
        final gradeLabel = _readString(row, 'grade_label', fallbackLabel);
        return _InventoryGradeSummary(
          gradeLabel: gradeLabel,
          totalUnits: _readInt(row, 'total_units'),
          availableUnits: _readInt(row, 'available_units'),
          soldUnits: _readInt(row, 'sold_units'),
          totalPieces: _readInt(row, 'total_pieces'),
          availablePieces: _readInt(row, 'available_pieces'),
          soldPieces: _readInt(row, 'sold_pieces'),
          totalSets: _readInt(row, 'total_sets'),
          availableSets: _readInt(row, 'available_sets'),
          companyCount: _readInt(row, 'company_count'),
          purityGroupCount: _readInt(row, 'purity_group_count'),
          grossWeight: _readDouble(row, 'gross_weight'),
          netWeight: _readDouble(row, 'net_weight'),
          soldWeight: _readDouble(row, 'sold_weight'),
          actualFine: _readDouble(row, 'actual_fine'),
          valuationFine: _readDouble(row, 'valuation_fine'),
          stockValue: _readDouble(row, 'stock_value'),
          availableInfo: availableInfoByGrade[gradeLabel] ??
              const <_InventoryGradeAvailableInfo>[],
        );
      },
    ).toList(growable: false);
  }

  Future<Map<String, List<_InventoryGradeAvailableInfo>>>
      _loadAvailableInfoByGrade(String groupExpression) async {
    final rows = await _db.customSelect(
      '''
      SELECT
        $groupExpression AS grade_label,
        COALESCE(
          NULLIF(TRIM(u.item_type), ''),
          NULLIF(TRIM(s.sub_category), ''),
          'Stock Item'
        ) AS item_type,
        COALESCE(NULLIF(TRIM(u.segment), ''), 'General') AS segment,
        COALESCE(
          NULLIF(TRIM(u.item_name), ''),
          NULLIF(TRIM(s.item_name), ''),
          'Unnamed Item'
        ) AS item_name,
        SUM(CASE WHEN lower(COALESCE(u.unit_code, '')) LIKE '%lot%' AND TRIM(COALESCE(u.huid, '')) = '' THEN COALESCE(NULLIF(s.quantity, 0), 0) ELSE 1 END) AS pieces,
        COALESCE(SUM($_inventoryAvailableGrossWeightExpression), 0.0) AS gross_weight,
        COALESCE(SUM($_inventoryAvailableNetWeightExpression), 0.0) AS net_weight
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      WHERE lower(u.metal_type) = ?
        AND lower(u.status) = 'available'
      GROUP BY 1, 2, 3, 4
      ORDER BY 1 ASC, 2 ASC, 3 ASC, 7 DESC
      ''',
      variables: [Variable.withString(widget.metal.label.toLowerCase())],
    ).get();

    final mapped = <String, List<_InventoryGradeAvailableInfo>>{};
    for (final row in rows) {
      final gradeLabel = _readString(
        row,
        'grade_label',
        _inventoryFallbackGroupLabel(widget.metal),
      );
      mapped
          .putIfAbsent(gradeLabel, () => <_InventoryGradeAvailableInfo>[])
          .add(
            _InventoryGradeAvailableInfo(
              itemType: _titleCase(_readString(row, 'item_type', 'Stock Item')),
              segment: _titleCase(_readString(row, 'segment', 'General')),
              itemName:
                  _titleCase(_readString(row, 'item_name', 'Unnamed Item')),
              pieces: _readInt(row, 'pieces'),
              grossWeight: _readDouble(row, 'gross_weight'),
              netWeight: _readDouble(row, 'net_weight'),
            ),
          );
    }
    return mapped;
  }

  Future<void> _ensureInventoryGroupingSchema() async {
    _schemaFuture ??= _ensureInventoryGroupingSchemaInternal();
    return _schemaFuture;
  }

  Future<void> _ensureInventoryGroupingSchemaInternal() async {
    final columns = await _tableColumns('stock_items');
    if (!columns.contains('company_name')) {
      await _db.customStatement(
          'ALTER TABLE stock_items ADD COLUMN company_name TEXT');
    }
    if (!columns.contains('quantity_mode')) {
      await _db.customStatement(
        "ALTER TABLE stock_items ADD COLUMN quantity_mode TEXT NOT NULL DEFAULT 'PIECES'",
      );
    }
    if (!columns.contains('packet_count')) {
      await _db.customStatement(
        'ALTER TABLE stock_items ADD COLUMN packet_count INTEGER NOT NULL DEFAULT 0',
      );
    }
    final unitColumns = await _tableColumns('stock_item_units');
    if (!unitColumns.contains('item_type')) {
      await _db.customStatement(
        'ALTER TABLE stock_item_units ADD COLUMN item_type TEXT',
      );
    }
    if (!unitColumns.contains('segment')) {
      await _db.customStatement(
        'ALTER TABLE stock_item_units ADD COLUMN segment TEXT',
      );
    }
    if (!unitColumns.contains('item_name')) {
      await _db.customStatement(
        'ALTER TABLE stock_item_units ADD COLUMN item_name TEXT',
      );
    }
    await StockLotSaleReconciliationService(_db).reconcile();
  }

  Future<Set<String>> _tableColumns(String tableName) async {
    final rows = await _db.customSelect('PRAGMA table_info($tableName)').get();
    return rows
        .map((row) => row.data['name'])
        .whereType<String>()
        .map((name) => name.toLowerCase())
        .toSet();
  }

  String _readString(QueryRow row, String column, String fallback) {
    final value = row.data[column];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  int _readInt(QueryRow row, String column) {
    final value = row.data[column];
    if (value is num) return value.toInt();
    return 0;
  }

  double _readDouble(QueryRow row, String column) {
    final value = row.data[column];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(widget.metal);

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: FutureBuilder<List<_InventoryGradeSummary>>(
        future: _gradeFuture,
        builder: (context, snapshot) {
          final grades = snapshot.data ?? const <_InventoryGradeSummary>[];
          final visibleGrades = _filterGradeSummaries(grades);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildHeader(ui, grades),
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
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildMessageCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable To Load ${ui.title} Grades',
                    message:
                        'Inventory records could not be grouped right now. Please try again after refreshing the inventory.',
                    accent: const Color(0xFFEF4444),
                  ),
                )
              else if (grades.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildMessageCard(
                    icon: ui.icon,
                    title: 'No ${ui.title} Stock Found',
                    message:
                        'Add ${ui.title.toLowerCase()} stock first. Grade cards will appear here automatically after stock is saved.',
                    accent: ui.accent,
                  ),
                )
              else if (visibleGrades.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _buildStockViewToolbar(ui, grades, visibleGrades),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildMessageCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'No $_stockViewFilter Records',
                    message:
                        'Change the stock view to Live Stock, All Stock or Sold Out to review the required inventory records.',
                    accent: ui.accent,
                  ),
                ),
              ] else
                SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: _buildStockViewToolbar(
                          ui,
                          grades,
                          visibleGrades,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      sliver: SliverToBoxAdapter(
                        child: _buildGradeGrid(ui, visibleGrades),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStockViewToolbar(
    StockMetalUiData ui,
    List<_InventoryGradeSummary> grades,
    List<_InventoryGradeSummary> visibleGrades,
  ) {
    final soldOutCount = grades.where((grade) => grade.isSoldOut).length;
    final liveCount = grades.where((grade) => !grade.isSoldOut).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InvColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in const [
                  'Live Stock',
                  'All Stock',
                  'Sold Out',
                ])
                  _BatchFilterChip(
                    label: filter,
                    selected: _stockViewFilter == filter,
                    accent: ui.accent,
                    onTap: () => setState(() => _stockViewFilter = filter),
                  ),
              ],
            ),
          ),
          Text(
            '${visibleGrades.length}/${grades.length} groups',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$liveCount live • $soldOutCount sold out',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: InvColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  List<_InventoryGradeSummary> _filterGradeSummaries(
    List<_InventoryGradeSummary> grades,
  ) {
    return grades.where((grade) {
      switch (_stockViewFilter) {
        case 'All Stock':
          return true;
        case 'Sold Out':
          return grade.isSoldOut;
        default:
          return !grade.isSoldOut;
      }
    }).toList(growable: false);
  }

  Widget _buildHeader(
    StockMetalUiData ui,
    List<_InventoryGradeSummary> grades,
  ) {
    final totalAvailable = grades.fold<int>(
      0,
      (sum, grade) => sum + grade.availablePieces,
    );
    final availableWeight = grades.fold<double>(
      0,
      (sum, grade) => sum + grade.netWeight,
    );
    final totalWeight = grades.fold<double>(
      0,
      (sum, grade) => sum + grade.netWeight + grade.soldWeight,
    );

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
                  widget.metal == StockCategory.silver
                      ? '${ui.title} Inventory Items'
                      : '${ui.title} Inventory Grades',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: ui.textOnGradient,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.metal == StockCategory.silver
                      ? 'Select an item to review available stock, company split, purity groups and batch movement.'
                      : widget.metal == StockCategory.gold
                          ? 'Select a gold purity grade to review item-wise stock, HUID status and batch movement.'
                          : 'Select a grade to review available stock, HUID status, fine weight and movement readiness.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ui.textOnGradient.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          _HeaderMetric(
            label: 'Available Items',
            value: '$totalAvailable pcs',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Available Weight',
            value: '${_weight(availableWeight)} g',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Total Weight',
            value: '${_weight(totalWeight)} g',
            textColor: ui.textOnGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeGrid(
    StockMetalUiData ui,
    List<_InventoryGradeSummary> grades,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1260
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 820
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final grade in grades)
              SizedBox(
                width: width,
                child: _InventoryGradeSummaryCard(
                  grade: grade,
                  ui: ui,
                  selected: _selectedGrade == grade.gradeLabel,
                  onTap: () {
                    setState(() {
                      _selectedGrade = grade.gradeLabel;
                    });
                    _openGradeLedger(grade);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: InvColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: InvColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: InvColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }

  void _openGradeLedger(
    _InventoryGradeSummary grade, {
    String? initialBatchCode,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => _InventoryGradeDetailScreen(
          metal: widget.metal,
          grade: grade,
          initialBatchCode: initialBatchCode,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _InventoryGradeSummary {
  final String gradeLabel;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final int totalSets;
  final int availableSets;
  final int companyCount;
  final int purityGroupCount;
  final double grossWeight;
  final double netWeight;
  final double soldWeight;
  final double actualFine;
  final double valuationFine;
  final double stockValue;
  final List<_InventoryGradeAvailableInfo> availableInfo;

  const _InventoryGradeSummary({
    required this.gradeLabel,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.totalSets,
    required this.availableSets,
    required this.companyCount,
    required this.purityGroupCount,
    required this.grossWeight,
    required this.netWeight,
    required this.soldWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.stockValue,
    required this.availableInfo,
  });

  bool get isSoldOut => totalPieces > 0 && availablePieces <= 0;
}

class _InventoryGradeAvailableInfo {
  final String itemType;
  final String segment;
  final String itemName;
  final int pieces;
  final double grossWeight;
  final double netWeight;

  const _InventoryGradeAvailableInfo({
    required this.itemType,
    required this.segment,
    required this.itemName,
    required this.pieces,
    required this.grossWeight,
    required this.netWeight,
  });
}

String _inventoryPrimaryGroupExpression(StockCategory metal) {
  if (metal == StockCategory.gold) {
    return '''
      CASE
        WHEN u.purity_percent > 0 THEN
          CASE CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER)
            WHEN 24 THEN '24KT (99.9%)'
            WHEN 22 THEN '22KT (91.6%)'
            WHEN 18 THEN '18KT (75%)'
            WHEN 14 THEN '14KT (58.5%)'
            WHEN 9 THEN '9KT (37.5%)'
            ELSE CAST(CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER) AS TEXT) || 'KT (' || printf('%.1f', u.purity_percent) || '%)'
          END
        ELSE COALESCE(NULLIF(TRIM(s.purity), ''), 'Custom Grade')
      END
    ''';
  }

  if (metal == StockCategory.silver) {
    return '''
      lower(COALESCE(
        NULLIF(TRIM(u.item_name), ''),
        NULLIF(TRIM(s.item_name), ''),
        NULLIF(TRIM(u.item_type), ''),
        NULLIF(TRIM(s.sub_category), ''),
        'Silver Item'
      ))
    ''';
  }

  return '''
    COALESCE(
      NULLIF(TRIM(s.purity), ''),
      CASE
        WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
        ELSE 'Custom Grade'
      END
    )
  ''';
}

String _inventoryFallbackGroupLabel(StockCategory metal) {
  if (metal == StockCategory.gold) return 'Custom Gold Grade';
  if (metal == StockCategory.silver) return 'Silver Item';
  return 'Custom Grade';
}

String _inventoryGradeTitle(StockCategory metal, String gradeLabel) {
  final ui = stockMetalUiFor(metal);
  final parts = _inventoryGroupParts(gradeLabel);
  final label = parts.itemLabel.trim();
  if (label.isEmpty || label.toLowerCase() == 'custom grade') {
    return 'Custom ${ui.title} Stock';
  }
  if (metal == StockCategory.gold) {
    return '${_inventoryGoldGradeText(parts.gradeLabel)} Gold Stock';
  }
  if (metal == StockCategory.silver) {
    return '${_titleCase(label)} Silver Stock';
  }
  return '$label ${ui.title} Stock';
}

String _inventoryGradeSubtitle(
  StockCategory metal,
  String gradeLabel,
  int availableUnits,
  int totalUnits,
  int companyCount,
  int purityGroupCount,
) {
  final ui = stockMetalUiFor(metal);
  final parts = _inventoryGroupParts(gradeLabel);
  if (metal == StockCategory.gold) {
    final gradeText = _inventoryGoldGradeText(parts.gradeLabel);
    return '$gradeText gold • $availableUnits available pcs';
  }
  if (metal == StockCategory.silver) {
    final companyText =
        companyCount <= 1 ? '1 company' : '$companyCount companies';
    final purityText = purityGroupCount <= 1
        ? '1 purity group'
        : '$purityGroupCount purity groups';
    return '$availableUnits available pcs • $companyText • $purityText';
  }
  final purity = _inventoryGradePurityPercent(parts.gradeLabel);
  final purityText = purity == null
      ? parts.gradeLabel
      : '${_formatInventoryPercent(purity)}% ${ui.title.toLowerCase()} purity';
  return '$purityText • $availableUnits available items';
}

({String itemLabel, String gradeLabel}) _inventoryGroupParts(String value) {
  final parts = value.split('|GRADE|');
  if (parts.length < 2) {
    final label = value.trim();
    return (itemLabel: label, gradeLabel: label);
  }
  return (
    itemLabel: parts.first.trim(),
    gradeLabel: parts.sublist(1).join('|GRADE|').trim(),
  );
}

String _inventoryGoldGradeText(String gradeLabel) {
  final raw = gradeLabel.trim();
  if (raw.isEmpty) return 'Custom Gold Grade';
  if (RegExp(r'\b\d+(?:\.\d+)?\s*KT\b', caseSensitive: false).hasMatch(raw)) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').replaceAllMapped(
          RegExp(r'\bkt\b', caseSensitive: false),
          (_) => 'KT',
        );
  }
  final purity = _inventoryGradePurityPercent(raw);
  if (purity == null) return _titleCase(raw);
  final karat = (purity * 24 / 100).round();
  return '${karat}KT (${_formatInventoryPercent(_standardGoldPurity(karat, purity))}%)';
}

double _standardGoldPurity(int karat, double fallback) {
  switch (karat) {
    case 24:
      return 99.9;
    case 22:
      return 91.6;
    case 18:
      return 75;
    case 14:
      return 58.5;
    case 9:
      return 37.5;
    default:
      return fallback;
  }
}

double? _inventoryGradePurityPercent(String gradeLabel) {
  final raw = gradeLabel.trim();
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
  if (match == null) return null;
  final value = double.tryParse(match.group(1) ?? '');
  if (value == null || value <= 0) return null;
  if (value > 100 && value <= 1000) return value / 10;
  return value;
}

String _formatInventoryPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.001) return rounded.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _titleCase(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
    final lower = part.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: textColor.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
