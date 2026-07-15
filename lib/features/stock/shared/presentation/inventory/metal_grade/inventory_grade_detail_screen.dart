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
  final TextEditingController _batchSearchCtrl = TextEditingController();
  String _batchSearch = '';
  String _batchFilter = 'All';
  late Future<List<_InventoryBatchGroup>> _batchesFuture;

  @override
  void initState() {
    super.initState();
    _batchesFuture = _loadBatchGroups();
  }

  @override
  void dispose() {
    _batchSearchCtrl.dispose();
    super.dispose();
  }

  Future<List<_InventoryBatchGroup>> _loadBatchGroups() async {
    final rows = await _db.customSelect(
      '''
      SELECT
        u.id AS unit_id,
        u.unit_code AS unit_code,
        COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no, 'Unbatched Stock') AS batch_code,
        u.item_type AS item_type,
        u.segment AS segment,
        u.item_name AS item_name,
        u.huid AS huid,
        u.gross_weight AS gross_weight,
        u.less_weight AS less_weight,
        u.net_weight AS net_weight,
        u.purity_percent AS purity_percent,
        u.actual_fine_weight AS actual_fine,
        u.wastage_fine_weight AS wastage_fine,
        u.valuation_fine_weight AS valuation_fine,
        u.rate_per_gram AS rate_per_gram,
        u.making_amount AS making_amount,
        u.unit_cost AS unit_cost,
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
        COALESCE(
          NULLIF(TRIM(s.purity), ''),
          CASE
            WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
            ELSE 'Custom Grade'
          END
        ) AS grade_label
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
      WHERE lower(u.metal_type) = ?
        AND COALESCE(
          NULLIF(TRIM(s.purity), ''),
          CASE
            WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
            ELSE 'Custom Grade'
          END
        ) = ?
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
        Variable.withString(widget.grade.gradeLabel),
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
      widget.grade.availableUnits,
      widget.grade.totalUnits,
    );

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: FutureBuilder<List<_InventoryBatchGroup>>(
        future: _batchesFuture,
        builder: (context, snapshot) {
          final batches = snapshot.data ?? const <_InventoryBatchGroup>[];
          final visibleBatches = _filterBatches(batches);
          return CustomScrollView(
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
                    child: _buildBatchToolbar(ui, batches),
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
                        child: _buildBatchToolbar(ui, batches),
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
              'No Matching Batch Found',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Change the search text or filter to view more stock batches.',
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

  Widget _buildBatchToolbar(
    StockMetalUiData ui,
    List<_InventoryBatchGroup> batches,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
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
                hintText: 'Search batch, supplier, invoice or item',
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
                'All',
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
          const SizedBox(width: 12),
          Text(
            '${_filterBatches(batches).length}/${batches.length} batches',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
        ],
      ),
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

  Future<void> _openBatchDossier(_InventoryBatchGroup batch) async {
    final cleaned = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        pageBuilder: (_, animation, __) => _InventoryBatchDossierScreen(
          metal: widget.metal,
          grade: widget.grade,
          batch: batch,
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
