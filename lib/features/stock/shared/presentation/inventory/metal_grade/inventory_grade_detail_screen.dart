part of '../inventory_screen.dart';

class _InventoryGradeDetailScreen extends StatefulWidget {
  final StockCategory metal;
  final _InventoryGradeSummary grade;
  final String? initialBatchCode;

  const _InventoryGradeDetailScreen({
    required this.metal,
    required this.grade,
    this.initialBatchCode,
  });

  @override
  State<_InventoryGradeDetailScreen> createState() =>
      _InventoryGradeDetailScreenState();
}

class _InventoryGradeDetailScreenState
    extends State<_InventoryGradeDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _batchSearchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _silverProfileKey = GlobalKey();
  String _batchSearch = '';
  String _batchFilter = 'Live Stock';
  String _itemSummaryFilter = 'Live Stock';
  late Future<List<_InventoryBatchGroup>> _batchesFuture;
  bool _openedInitialBatchDossier = false;

  @override
  void initState() {
    super.initState();
    final batchCode = widget.initialBatchCode?.trim();
    if (batchCode != null && batchCode.isNotEmpty) {
      _batchSearch = batchCode;
      _batchSearchCtrl.text = batchCode;
      _batchFilter = 'All Stock';
      _itemSummaryFilter = 'All Stock';
    }
    _batchesFuture = _loadBatchGroups();
  }

  @override
  void dispose() {
    _batchSearchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<_InventoryBatchGroup>> _loadBatchGroups({
    String? sourceBatchCode,
    bool includeAllInvoiceItems = false,
  }) async {
    final groupExpression = _inventoryPrimaryGroupExpression(widget.metal);
    final rows = await _db.customSelect(
      '''
      SELECT
        u.id AS unit_id,
        u.unit_code AS unit_code,
        COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no, 'Unbatched Stock') AS batch_code,
        u.item_type AS item_type,
        COALESCE(NULLIF(TRIM(s.quantity_mode), ''), 'PIECES') AS quantity_mode,
        COALESCE(NULLIF(pvi.packet_count, 0), NULLIF(s.packet_count, 0), 0) AS packet_count,
        COALESCE(NULLIF(s.pieces_per_packet, 0), 1) AS pieces_per_packet,
        COALESCE(NULLIF(TRIM(u.company_name), ''), NULLIF(TRIM(s.company_name), ''), '') AS company_name,
        u.segment AS segment,
        u.item_name AS item_name,
        u.huid AS huid,
        u.gross_weight AS gross_weight,
        u.less_weight AS less_weight,
        u.net_weight AS net_weight,
        u.purity_percent AS purity_percent,
        CASE
          WHEN $_inventoryLotUnitExpression
            AND COALESCE(u.net_weight, 0.0) > 0
            AND COALESCE(u.purity_percent, 0.0) > 0
          THEN ROUND(COALESCE(u.net_weight, 0.0) * COALESCE(u.purity_percent, 0.0) / 100.0, 6)
          ELSE COALESCE(u.actual_fine_weight, 0.0)
        END AS actual_fine,
        u.wastage_fine_weight AS wastage_fine,
        CASE
          WHEN $_inventoryLotUnitExpression
            AND COALESCE(u.net_weight, 0.0) > 0
            AND COALESCE(u.purity_percent, 0.0) > 0
          THEN ROUND(
            (COALESCE(u.net_weight, 0.0) * COALESCE(u.purity_percent, 0.0) / 100.0)
            + COALESCE(u.wastage_fine_weight, 0.0),
            6
          )
          ELSE COALESCE(u.valuation_fine_weight, 0.0)
        END AS valuation_fine,
        u.rate_per_gram AS rate_per_gram,
        u.making_amount AS making_amount,
        u.unit_cost AS unit_cost,
        CASE
          WHEN $_inventoryLotUnitExpression THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1)
          ELSE 1
        END AS total_pieces,
        CASE
          WHEN lower(u.status) = 'available' THEN
            CASE
              WHEN $_inventoryLotUnitExpression THEN COALESCE(NULLIF(s.quantity, 0), 0)
              ELSE 1
            END
          ELSE 0
        END AS available_pieces,
        CASE
          WHEN $_inventoryLotUnitExpression THEN
            CASE
              WHEN lower(u.status) = 'sold' THEN COALESCE(NULLIF(pvi.quantity, 0), 1)
              WHEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) > 0
                THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0)
              ELSE 0
            END
          WHEN lower(u.status) = 'sold' THEN 1
          ELSE 0
        END AS sold_pieces,
        CASE
          WHEN $_inventoryLotUnitExpression THEN COALESCE(NULLIF(pvi.gross_weight, 0), NULLIF(s.gross_weight, 0), u.gross_weight, 0.0)
          ELSE COALESCE(u.gross_weight, 0.0)
        END AS total_gross_weight,
        CASE
          WHEN $_inventoryLotUnitExpression THEN COALESCE(NULLIF(pvi.net_weight, 0), COALESCE(s.net_weight, 0.0) + COALESCE(sm.sold_net_weight, 0.0), u.net_weight, 0.0)
          ELSE COALESCE(u.net_weight, 0.0)
        END AS total_net_weight,
        $_inventoryAvailableGrossWeightExpression AS available_gross_weight,
        $_inventoryAvailableNetWeightExpression AS available_net_weight,
        $_inventorySoldWeightExpression AS sold_net_weight,
        COALESCE(sm.sold_quantity, 0) AS sold_quantity,
        COALESCE(NULLIF(TRIM(u.supplier_name), ''), pv.party_name, '') AS supplier_name,
        COALESCE(pv.mobile, '') AS supplier_mobile,
        COALESCE(pv.gst_number, '') AS supplier_gst_number,
        COALESCE(pv.tax_type, 'NORMAL') AS tax_type,
        COALESCE(pv.supplier_invoice_no, '') AS supplier_invoice_no,
        COALESCE(pv.grand_total, 0.0) AS grand_total,
        COALESCE(pv.total_paid, 0.0) AS total_paid,
        COALESCE(pv.balance_due, 0.0) AS balance_due,
        COALESCE(pv.cash_paid, 0.0) AS cash_paid,
        COALESCE(pv.upi_paid, 0.0) AS upi_paid,
        COALESCE(pv.bank_paid, 0.0) AS bank_paid,
        COALESCE(pv.card_paid, 0.0) AS card_paid,
        COALESCE(pv.metal_paid_fine, 0.0) AS metal_paid_fine,
        COALESCE(pv.metal_paid_value, 0.0) AS metal_paid_value,
        COALESCE(pv.gst_amount, 0.0) AS gst_amount,
        COALESCE(pv.cgst_amount, 0.0) AS cgst_amount,
        COALESCE(pv.sgst_amount, 0.0) AS sgst_amount,
        COALESCE(pv.payment_status, '') AS payment_status,
        COALESCE(pv.due_mode, '') AS due_mode,
        COALESCE(pv.excess_mode, '') AS excess_mode,
        COALESCE(pv.payment_meta, '') AS payment_meta,
        COALESCE(pv.created_at, u.created_at) AS batch_created_at,
        u.status AS status,
        COALESCE((
          SELECT GROUP_CONCAT(DISTINCT NULLIF(TRIM(source_unit.item_name), ''))
          FROM stock_item_units source_unit
          LEFT JOIN purchase_vouchers source_pv
            ON source_pv.id = source_unit.purchase_voucher_id
          WHERE lower(source_unit.metal_type) = lower(u.metal_type)
            AND lower(
              COALESCE(
                NULLIF(TRIM(source_unit.batch_code), ''),
                source_pv.voucher_no,
                'Unbatched Stock'
              )
            ) = lower(
              COALESCE(
                NULLIF(TRIM(u.batch_code), ''),
                pv.voucher_no,
                'Unbatched Stock'
              )
            )
        ), '') AS source_item_names,
        $groupExpression AS grade_label
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
      $_inventorySoldWeightJoin
      WHERE lower(u.metal_type) = ?
        AND (? = 1 OR $groupExpression = ?)
        AND (
          ? = ''
          OR lower(COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no, 'Unbatched Stock')) = lower(?)
        )
      ORDER BY
        batch_created_at DESC,
        batch_code DESC,
        CASE WHEN lower(u.status) = 'available' THEN 0 ELSE 1 END,
        lower(u.item_type) ASC,
        lower(u.segment) ASC,
        lower(u.item_name) ASC,
        u.id DESC
      ''',
      variables: [
        Variable.withString(widget.metal.label.toLowerCase()),
        Variable.withInt(includeAllInvoiceItems ? 1 : 0),
        Variable.withString(widget.grade.gradeLabel),
        Variable.withString(sourceBatchCode?.trim() ?? ''),
        Variable.withString(sourceBatchCode?.trim() ?? ''),
      ],
    ).get();

    final groups = <String, List<_InventoryGradeUnit>>{};
    for (final row in rows) {
      final unit = _InventoryGradeUnit.fromRow(row);
      groups
          .putIfAbsent(unit.batchCode, () => <_InventoryGradeUnit>[])
          .add(unit);
    }

    return groups.entries
        .map((entry) => _InventoryBatchGroup.fromUnits(entry.key, entry.value))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(widget.metal);
    final title = _inventoryGradeTitle(widget.metal, widget.grade.gradeLabel);
    final subtitle = _inventoryGradeSubtitle(
      widget.metal,
      widget.grade.gradeLabel,
      widget.grade.availablePieces,
      widget.grade.totalPieces,
      widget.grade.companyCount,
      widget.grade.purityGroupCount,
    );

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: FutureBuilder<List<_InventoryBatchGroup>>(
        future: _batchesFuture,
        builder: (context, snapshot) {
          final batches = snapshot.data ?? const <_InventoryBatchGroup>[];
          _openInitialBatchDossierWhenReady(batches);
          final visibleBatches = _filterBatches(batches);
          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                  child: _buildHeader(ui, title, subtitle, batches.length),
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
              else if (batches.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(ui),
                )
              else if (visibleBatches.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: _buildSourceInvoiceToolbar(ui, batches, title),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildNoResultState(ui),
                ),
              ] else
                SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: widget.metal == StockCategory.silver
                            ? KeyedSubtree(
                                key: _silverProfileKey,
                                child: _SilverBreakdownSection(
                                  batches: batches,
                                  ui: ui,
                                  weightFormatter: _weight,
                                ),
                              )
                            : _buildItemSummarySection(ui, batches),
                      ),
                    ),
                    if (widget.metal == StockCategory.silver)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: _buildItemSummarySection(
                            ui,
                            batches,
                            onValuationProfileRequested:
                                _scrollToSilverValuationProfile,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: _buildSourceInvoiceToolbar(ui, batches, title),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      sliver: SliverList.separated(
                        itemCount: visibleBatches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final batch = visibleBatches[index];
                          return _InventoryBatchCard(
                            batch: batch,
                            ui: ui,
                            onTap: () => _openBatchDossier(batch),
                          );
                        },
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

  Widget _buildHeader(
    StockMetalUiData ui,
    String title,
    String subtitle,
    int batchCount,
  ) {
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
                  '$subtitle - Batch-wise stock ledger',
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
            label: 'Batches',
            value: '$batchCount',
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
              'No Batch Records Found',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This grade summary exists, but batch-level item records could not be found.',
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

  Widget _buildNoResultState(StockMetalUiData ui) {
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
            Icon(Icons.manage_search_rounded, color: ui.accent, size: 36),
            const SizedBox(height: 12),
            Text(
              'No Matching Source Invoice Found',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Change the search text or filter to view more source invoices.',
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

  Widget _buildSourceInvoiceToolbar(
    StockMetalUiData ui,
    List<_InventoryBatchGroup> batches,
    String title,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ui.softTint.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: ui.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Source Purchase Invoices',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Showing invoice sources that contain $title stock. Open a card to view the full source dossier.',
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
              const SizedBox(width: 12),
              Text(
                '${_filterBatches(batches).length}/${batches.length} invoices',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: InvColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _batchSearchCtrl,
                  onChanged: (value) => setState(() => _batchSearch = value),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: InvColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search source invoice, supplier, batch or item',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: InvColors.textHint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: ui.accent,
                      size: 20,
                    ),
                    suffixIcon: _batchSearch.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _batchSearchCtrl.clear();
                              setState(() => _batchSearch = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFFBF8F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFEADCC5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFEADCC5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: ui.accent, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final filter in const [
                    'Live Stock',
                    'All Stock',
                    'Available',
                    'Partially Sold',
                    'Sold Out',
                    'GST',
                    'Due',
                    'Attachment',
                  ])
                    _BatchFilterChip(
                      label: filter,
                      selected: _batchFilter == filter,
                      accent: ui.accent,
                      onTap: () => setState(() => _batchFilter = filter),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemSummarySection(
      StockMetalUiData ui, List<_InventoryBatchGroup> batches,
      {VoidCallback? onValuationProfileRequested}) {
    final allItems = _buildItemSummaries(batches);
    final items = _filterItemSummaries(allItems);
    if (allItems.isEmpty) return const SizedBox.shrink();

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
                child: Icon(Icons.inventory_2_rounded, color: ui.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade Item Summary',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Item-wise available, sold and total weight for this selected grade.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
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
                      selected: _itemSummaryFilter == filter,
                      accent: ui.accent,
                      onTap: () => setState(() => _itemSummaryFilter = filter),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ui.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ui.accent.withValues(alpha: 0.24)),
                ),
                child: Text(
                  '${items.length}/${allItems.length} items',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ui.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: ui.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ui.accent.withValues(alpha: 0.16)),
              ),
              child: Text(
                'No $_itemSummaryFilter item summary available in this grade.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: InvColors.textMuted,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 1160
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth >= 760
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: width,
                        child: _GradeItemSummaryCard(
                          item: item,
                          ui: ui,
                          weightFormatter: _weight,
                          onValuationProfileRequested:
                              onValuationProfileRequested,
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

  List<_InventoryItemSummary> _buildItemSummaries(
    List<_InventoryBatchGroup> batches,
  ) {
    final summaries = <String, _InventoryItemSummaryAccumulator>{};
    for (final batch in batches) {
      for (final unit in batch.units) {
        final name = _itemSummaryGroupName(unit);
        final key = name.toLowerCase();
        summaries.putIfAbsent(
          key,
          () => _InventoryItemSummaryAccumulator(name),
        );
        summaries[key]!.add(unit);
      }
    }

    final items = summaries.values.map((entry) => entry.toSummary()).toList();
    items.sort((a, b) {
      final status = a.statusRank.compareTo(b.statusRank);
      if (status != 0) return status;
      return a.itemType.compareTo(b.itemType);
    });
    return items;
  }

  List<_InventoryItemSummary> _filterItemSummaries(
    List<_InventoryItemSummary> items,
  ) {
    return items.where((item) {
      switch (_itemSummaryFilter) {
        case 'All Stock':
          return true;
        case 'Sold Out':
          return item.isSoldOut;
        default:
          return !item.isSoldOut;
      }
    }).toList(growable: false);
  }

  String _itemSummaryGroupName(_InventoryGradeUnit unit) {
    final itemType = unit.itemType.trim();
    if (itemType.isNotEmpty) return _titleCase(itemType);
    final itemName = unit.itemName.trim();
    if (itemName.isNotEmpty) return _titleCase(itemName);
    return 'Unnamed Stock Item';
  }

  void _scrollToSilverValuationProfile() {
    final context = _silverProfileKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  List<_InventoryBatchGroup> _filterBatches(
      List<_InventoryBatchGroup> batches) {
    final query = _batchSearch.trim().toLowerCase();
    return batches.where((batch) {
      final textMatch = query.isEmpty || batch.searchText.contains(query);
      return textMatch && _matchesBatchFilter(batch);
    }).toList(growable: false);
  }

  bool _matchesBatchFilter(_InventoryBatchGroup batch) {
    switch (_batchFilter) {
      case 'Live Stock':
        return !batch.isSoldOut;
      case 'All Stock':
        return true;
      case 'Available':
        return batch.hasAvailableStock;
      case 'Partially Sold':
        return batch.isPartiallySold;
      case 'Sold Out':
        return batch.isSoldOut;
      case 'GST':
        return batch.isGst;
      case 'Due':
        return batch.payment.balanceDue > 0 || batch.payment.fineDueWeight > 0;
      case 'Attachment':
        return batch.payment.hasAttachment;
      default:
        return true;
    }
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }

  void _openInitialBatchDossierWhenReady(List<_InventoryBatchGroup> batches) {
    if (_openedInitialBatchDossier || batches.isEmpty || !mounted) return;
    final targetBatch = widget.initialBatchCode?.trim();
    if (targetBatch == null || targetBatch.isEmpty) return;
    _InventoryBatchGroup? matchedBatch;
    for (final batch in batches) {
      if (batch.batchCode.toLowerCase() == targetBatch.toLowerCase()) {
        matchedBatch = batch;
        break;
      }
    }
    if (matchedBatch == null) return;
    _openedInitialBatchDossier = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openBatchDossier(matchedBatch!);
    });
  }

  Future<void> _openBatchDossier(_InventoryBatchGroup batch) async {
    var dossierBatch = batch;
    final sourceBatchCode = batch.batchCode.trim();
    if (sourceBatchCode.isNotEmpty) {
      final sourceBatches = await _loadBatchGroups(
        sourceBatchCode: sourceBatchCode,
        includeAllInvoiceItems: true,
      );
      for (final sourceBatch in sourceBatches) {
        if (sourceBatch.batchCode.toLowerCase() ==
            sourceBatchCode.toLowerCase()) {
          dossierBatch = sourceBatch;
          break;
        }
      }
    }

    if (!mounted) return;
    final cleaned = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (_, animation, __) => _InventoryBatchDossierScreen(
          metal: widget.metal,
          grade: widget.grade,
          batch: dossierBatch,
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
    if (cleaned == true && mounted) {
      setState(() {
        _batchesFuture = _loadBatchGroups();
      });
    }
  }
}
