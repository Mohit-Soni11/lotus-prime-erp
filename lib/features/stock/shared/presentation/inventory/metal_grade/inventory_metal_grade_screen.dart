part of '../inventory_screen.dart';

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
  bool _openedInitialBatch = false;

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
    final rows = await _db.customSelect(
      '''
      SELECT
        COALESCE(
          NULLIF(TRIM(s.purity), ''),
          CASE
            WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
            ELSE 'Custom Grade'
          END
        ) AS grade_label,
        COUNT(*) AS total_units,
        SUM(CASE WHEN lower(u.status) = 'available' THEN 1 ELSE 0 END) AS available_units,
        SUM(CASE WHEN lower(u.status) = 'sold' THEN 1 ELSE 0 END) AS sold_units,
        COALESCE(SUM(u.gross_weight), 0.0) AS gross_weight,
        COALESCE(SUM(u.net_weight), 0.0) AS net_weight,
        COALESCE(SUM(u.actual_fine_weight), 0.0) AS actual_fine,
        COALESCE(SUM(u.valuation_fine_weight), 0.0) AS valuation_fine,
        COALESCE(SUM(u.unit_cost), 0.0) AS stock_value
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
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
      gradeLabel: _readString(row, 'grade_label', 'Custom Grade'),
      totalUnits: _readInt(row, 'total_units'),
      availableUnits: _readInt(row, 'available_units'),
      soldUnits: _readInt(row, 'sold_units'),
      grossWeight: _readDouble(row, 'gross_weight'),
      netWeight: _readDouble(row, 'net_weight'),
      actualFine: _readDouble(row, 'actual_fine'),
      valuationFine: _readDouble(row, 'valuation_fine'),
      stockValue: _readDouble(row, 'stock_value'),
    );
  }

  Future<List<_InventoryGradeSummary>> _loadGradeSummary() async {
    final rows = await _db.customSelect(
      '''
      SELECT
        COALESCE(
          NULLIF(TRIM(s.purity), ''),
          CASE
            WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
            ELSE 'Custom Grade'
          END
        ) AS grade_label,
        COUNT(*) AS total_units,
        SUM(CASE WHEN lower(u.status) = 'available' THEN 1 ELSE 0 END) AS available_units,
        SUM(CASE WHEN lower(u.status) = 'sold' THEN 1 ELSE 0 END) AS sold_units,
        COALESCE(SUM(u.gross_weight), 0.0) AS gross_weight,
        COALESCE(SUM(u.net_weight), 0.0) AS net_weight,
        COALESCE(SUM(u.actual_fine_weight), 0.0) AS actual_fine,
        COALESCE(SUM(u.valuation_fine_weight), 0.0) AS valuation_fine,
        COALESCE(SUM(u.unit_cost), 0.0) AS stock_value
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      WHERE lower(u.metal_type) = ?
      GROUP BY grade_label
      ORDER BY available_units DESC, total_units DESC, grade_label ASC
      ''',
      variables: [Variable.withString(widget.metal.label.toLowerCase())],
    ).get();

    return rows
        .map(
          (row) => _InventoryGradeSummary(
            gradeLabel: _readString(row, 'grade_label', 'Custom Grade'),
            totalUnits: _readInt(row, 'total_units'),
            availableUnits: _readInt(row, 'available_units'),
            soldUnits: _readInt(row, 'sold_units'),
            grossWeight: _readDouble(row, 'gross_weight'),
            netWeight: _readDouble(row, 'net_weight'),
            actualFine: _readDouble(row, 'actual_fine'),
            valuationFine: _readDouble(row, 'valuation_fine'),
            stockValue: _readDouble(row, 'stock_value'),
          ),
        )
        .toList(growable: false);
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
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  sliver:
                      SliverToBoxAdapter(child: _buildGradeGrid(ui, grades)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    StockMetalUiData ui,
    List<_InventoryGradeSummary> grades,
  ) {
    final totalAvailable = grades.fold<int>(
      0,
      (sum, grade) => sum + grade.availableUnits,
    );
    final totalFine = grades.fold<double>(
      0,
      (sum, grade) => sum + grade.actualFine,
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
                  '${ui.title} Inventory Grades',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: ui.textOnGradient,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a grade to review available stock, HUID status, fine weight and movement readiness.',
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
            label: 'Actual Fine',
            value: '${_weight(totalFine)} g',
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
  final double grossWeight;
  final double netWeight;
  final double actualFine;
  final double valuationFine;
  final double stockValue;

  const _InventoryGradeSummary({
    required this.gradeLabel,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.grossWeight,
    required this.netWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.stockValue,
  });
}

String _inventoryGradeTitle(StockCategory metal, String gradeLabel) {
  final ui = stockMetalUiFor(metal);
  final purity = _inventoryGradePurityPercent(gradeLabel);
  if (metal == StockCategory.gold && purity != null) {
    final karat = (purity * 24 / 100).round();
    return '${karat}KT (${_formatInventoryPercent(purity)}%) HUID Hallmark Stock';
  }
  final label = gradeLabel.trim();
  if (label.isEmpty || label.toLowerCase() == 'custom grade') {
    return 'Custom ${ui.title} Stock';
  }
  return '$label ${ui.title} Stock';
}

String _inventoryGradeSubtitle(
  StockCategory metal,
  String gradeLabel,
  int availableUnits,
  int totalUnits,
) {
  final ui = stockMetalUiFor(metal);
  final purity = _inventoryGradePurityPercent(gradeLabel);
  final purityText = purity == null
      ? gradeLabel
      : '${_formatInventoryPercent(purity)}% ${ui.title.toLowerCase()} purity';
  return '$purityText - $availableUnits available of $totalUnits total items';
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
