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
  late final Future<List<_InventoryBatchGroup>> _batchesFuture;

  @override
  void initState() {
    super.initState();
    _batchesFuture = _loadBatchGroups();
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
        u.valuation_fine_weight AS valuation_fine,
        u.unit_cost AS unit_cost,
        COALESCE(NULLIF(TRIM(u.supplier_name), ''), pv.party_name, '') AS supplier_name,
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
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverList.separated(
                    itemCount: batches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return _InventoryBatchCard(
                        batch: batch,
                        ui: ui,
                        onTap: () => _openBatchDossier(batch),
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

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }

  void _openBatchDossier(_InventoryBatchGroup batch) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
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
  }
}

class _InventoryBatchGroup {
  final String batchCode;
  final String supplierName;
  final String taxType;
  final String supplierInvoiceNo;
  final int createdAt;
  final List<_InventoryGradeUnit> units;
  final int totalItems;
  final int availableItems;
  final double grossWeight;
  final double netWeight;
  final double actualFine;
  final double valuationFine;
  final _InventoryPaymentSummary payment;

  const _InventoryBatchGroup({
    required this.batchCode,
    required this.supplierName,
    required this.taxType,
    required this.supplierInvoiceNo,
    required this.createdAt,
    required this.units,
    required this.totalItems,
    required this.availableItems,
    required this.grossWeight,
    required this.netWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.payment,
  });

  bool get isGst => taxType.toUpperCase().contains('GST');

  factory _InventoryBatchGroup.fromUnits(
    String batchCode,
    List<_InventoryGradeUnit> units,
  ) {
    final first = units.first;
    return _InventoryBatchGroup(
      batchCode: batchCode,
      supplierName: first.supplierName,
      taxType: first.taxType,
      supplierInvoiceNo: first.supplierInvoiceNo,
      createdAt: first.batchCreatedAt,
      units: units,
      totalItems: units.length,
      availableItems: units
          .where((unit) => unit.status.toLowerCase() == 'available')
          .length,
      grossWeight: units.fold(0.0, (sum, unit) => sum + unit.grossWeight),
      netWeight: units.fold(0.0, (sum, unit) => sum + unit.netWeight),
      actualFine: units.fold(0.0, (sum, unit) => sum + unit.actualFine),
      valuationFine: units.fold(0.0, (sum, unit) => sum + unit.valuationFine),
      payment: _InventoryPaymentSummary.fromUnit(first),
    );
  }
}

class _InventoryPaymentSummary {
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final double metalPaidFine;
  final double metalPaidValue;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double fineDueWeight;
  final double fineDueValue;
  final double fineReturnWeight;
  final double fineReturnValue;
  final double supplierCreditValue;
  final String paymentStatus;
  final String dueMode;
  final String excessMode;
  final String attachmentPath;
  final String paymentMode;
  final String balanceLabel;

  const _InventoryPaymentSummary({
    required this.grandTotal,
    required this.totalPaid,
    required this.balanceDue,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankPaid,
    required this.cardPaid,
    required this.metalPaidFine,
    required this.metalPaidValue,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.fineDueWeight,
    required this.fineDueValue,
    required this.fineReturnWeight,
    required this.fineReturnValue,
    required this.supplierCreditValue,
    required this.paymentStatus,
    required this.dueMode,
    required this.excessMode,
    required this.attachmentPath,
    required this.paymentMode,
    required this.balanceLabel,
  });

  factory _InventoryPaymentSummary.fromUnit(_InventoryGradeUnit unit) {
    final meta = _decodePaymentMeta(unit.paymentMeta);
    return _InventoryPaymentSummary(
      grandTotal: unit.grandTotal,
      totalPaid: unit.totalPaid,
      balanceDue: unit.balanceDue,
      cashPaid: unit.cashPaid,
      upiPaid: unit.upiPaid,
      bankPaid: unit.bankPaid,
      cardPaid: unit.cardPaid,
      metalPaidFine: unit.metalPaidFine,
      metalPaidValue: unit.metalPaidValue,
      gstAmount: unit.gstAmount,
      cgstAmount: unit.cgstAmount,
      sgstAmount: unit.sgstAmount,
      fineDueWeight: _metaDouble(meta, 'fineDueWeight'),
      fineDueValue: _metaDouble(meta, 'fineDueValue'),
      fineReturnWeight: _metaDouble(meta, 'fineReturnWeight'),
      fineReturnValue: _metaDouble(meta, 'fineReturnValue'),
      supplierCreditValue: _metaDouble(meta, 'supplierCreditValue'),
      paymentStatus: unit.paymentStatus,
      dueMode: unit.dueMode,
      excessMode: unit.excessMode,
      attachmentPath: _metaString(meta, 'supplierBillAttachmentPath'),
      paymentMode: _metaString(meta, 'mode'),
      balanceLabel: _metaString(meta, 'balanceLabel'),
    );
  }

  bool get hasAttachment => attachmentPath.trim().isNotEmpty;
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
  final String taxType;
  final String supplierInvoiceNo;
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final double metalPaidFine;
  final double metalPaidValue;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final String paymentStatus;
  final String dueMode;
  final String excessMode;
  final String paymentMeta;
  final int batchCreatedAt;
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
    required this.taxType,
    required this.supplierInvoiceNo,
    required this.grandTotal,
    required this.totalPaid,
    required this.balanceDue,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankPaid,
    required this.cardPaid,
    required this.metalPaidFine,
    required this.metalPaidValue,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.paymentStatus,
    required this.dueMode,
    required this.excessMode,
    required this.paymentMeta,
    required this.batchCreatedAt,
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
      taxType: text('tax_type'),
      supplierInvoiceNo: text('supplier_invoice_no'),
      grandTotal: number('grand_total'),
      totalPaid: number('total_paid'),
      balanceDue: number('balance_due'),
      cashPaid: number('cash_paid'),
      upiPaid: number('upi_paid'),
      bankPaid: number('bank_paid'),
      cardPaid: number('card_paid'),
      metalPaidFine: number('metal_paid_fine'),
      metalPaidValue: number('metal_paid_value'),
      gstAmount: number('gst_amount'),
      cgstAmount: number('cgst_amount'),
      sgstAmount: number('sgst_amount'),
      paymentStatus: text('payment_status'),
      dueMode: text('due_mode'),
      excessMode: text('excess_mode'),
      paymentMeta: text('payment_meta'),
      batchCreatedAt: integer('batch_created_at'),
      status: text('status'),
    );
  }
}

class _InventoryBatchCard extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;
  final VoidCallback onTap;

  const _InventoryBatchCard({
    required this.batch,
    required this.ui,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: InvColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: ui.gradient,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(ui.icon, color: ui.textOnGradient, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            batch.batchCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: InvColors.textDark,
                            ),
                          ),
                        ),
                        if (batch.isGst) ...[
                          const SizedBox(width: 10),
                          _GstTag(accent: ui.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _batchSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _BatchMetric(
                label: 'Items',
                value: '${batch.availableItems}/${batch.totalItems}',
                accent: ui.accent,
              ),
              _BatchMetric(
                label: 'Gross Weight',
                value: '${_weight(batch.grossWeight)} g',
                accent: ui.accent,
              ),
              _BatchMetric(
                label: 'Actual Fine',
                value: '${_weight(batch.actualFine)} g',
                accent: const Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ui.softTint.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.open_in_full_rounded,
                  color: ui.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _batchSubtitle() {
    final parts = [
      batch.supplierName.isEmpty ? 'Supplier not linked' : batch.supplierName,
      if (batch.supplierInvoiceNo.isNotEmpty)
        'Invoice ${batch.supplierInvoiceNo}',
      if (batch.createdAt > 0) _date(batch.createdAt),
    ];
    return parts.join(' - ');
  }

  String _date(int millis) {
    return DateFormat('dd MMM yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unit.itemName.isEmpty ? 'Unnamed Stock Item' : unit.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  unit.status.isEmpty ? 'Available' : unit.status,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _UnitMetric(
                  label: 'HUID',
                  value: unit.huid.isEmpty ? 'No HUID' : unit.huid),
              _UnitMetric(
                  label: 'Gross', value: '${_weight(unit.grossWeight)} g'),
              _UnitMetric(label: 'Net', value: '${_weight(unit.netWeight)} g'),
              _UnitMetric(
                  label: 'Actual Fine', value: '${_weight(unit.actualFine)} g'),
              _UnitMetric(
                label: 'Valuation Fine',
                value: '${_weight(unit.valuationFine)} g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _itemSubtitle() {
    final parts = [
      unit.itemType,
      unit.segment,
      unit.unitCode,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Stock unit' : parts.join(' - ');
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }
}

class _BatchMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _BatchMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
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
      constraints: const BoxConstraints(minWidth: 106),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7DAC5)),
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
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GstTag extends StatelessWidget {
  final Color accent;

  const _GstTag({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        'GST',
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: accent,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InventoryBatchDossierScreen extends StatelessWidget {
  final StockCategory metal;
  final _InventoryGradeSummary grade;
  final _InventoryBatchGroup batch;

  const _InventoryBatchDossierScreen({
    required this.metal,
    required this.grade,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(metal);
    final title = _inventoryGradeTitle(metal, grade.gradeLabel);

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: _BatchDossierHeader(
                ui: ui,
                title: title,
                batch: batch,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BatchOverviewPanel(batch: batch, ui: ui),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BatchPaymentPanel(batch: batch, ui: ui),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BatchDocumentPanel(batch: batch, ui: ui),
                  const SizedBox(height: 16),
                  _BatchStockLedgerPanel(batch: batch, ui: ui),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchDossierHeader extends StatelessWidget {
  final StockMetalUiData ui;
  final String title;
  final _InventoryBatchGroup batch;

  const _BatchDossierHeader({
    required this.ui,
    required this.title,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
            ),
            child: Icon(ui.icon, color: ui.textOnGradient, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        batch.batchCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: ui.textOnGradient,
                        ),
                      ),
                    ),
                    if (batch.isGst) ...[
                      const SizedBox(width: 10),
                      _HeaderGstTag(textColor: ui.textOnGradient),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$title - complete batch dossier',
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
            label: 'Items',
            value: '${batch.availableItems}/${batch.totalItems}',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Actual Fine',
            value: '${_weight(batch.actualFine)} g',
            textColor: ui.textOnGradient,
          ),
        ],
      ),
    );
  }
}

class _BatchOverviewPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchOverviewPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    return _DossierPanel(
      icon: Icons.inventory_2_rounded,
      title: 'Batch Overview',
      subtitle: 'Supplier, invoice and stock status',
      accent: ui.accent,
      child: Column(
        children: [
          _DossierInfoRow(label: 'Supplier', value: _dash(batch.supplierName)),
          _DossierInfoRow(
            label: 'Supplier Invoice',
            value: _dash(batch.supplierInvoiceNo),
          ),
          _DossierInfoRow(
              label: 'Purchase Type',
              value: batch.isGst ? 'GST Purchase' : 'Non-GST Purchase'),
          _DossierInfoRow(
            label: 'Batch Date',
            value: batch.createdAt > 0
                ? DateFormat('dd MMM yyyy').format(
                    DateTime.fromMillisecondsSinceEpoch(batch.createdAt),
                  )
                : 'Not recorded',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DossierMetric(
                  label: 'Total Items',
                  value: '${batch.totalItems} pcs',
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Available',
                  value: '${batch.availableItems} pcs',
                  accent: InvColors.success),
              _DossierMetric(
                  label: 'Sold',
                  value: '${batch.totalItems - batch.availableItems} pcs',
                  accent: InvColors.danger),
              _DossierMetric(
                  label: 'Gross Wt',
                  value: '${_weight(batch.grossWeight)} g',
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Net Wt',
                  value: '${_weight(batch.netWeight)} g',
                  accent: const Color(0xFF0F766E)),
              _DossierMetric(
                  label: 'Valuation Fine',
                  value: '${_weight(batch.valuationFine)} g',
                  accent: InvColors.brandGold),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchPaymentPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchPaymentPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final payment = batch.payment;
    return _DossierPanel(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Payment Summary',
      subtitle: 'Cash, metal, GST, due and return snapshot',
      accent: ui.accent,
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DossierMetric(
                  label: 'Final Bill',
                  value: _money(payment.grandTotal),
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Total Paid',
                  value: _money(payment.totalPaid),
                  accent: InvColors.success),
              _DossierMetric(
                  label: 'Cash Due',
                  value: _money(payment.balanceDue),
                  accent: payment.balanceDue > 0
                      ? InvColors.danger
                      : InvColors.success),
              _DossierMetric(
                  label: 'Metal Paid',
                  value: '${_weight(payment.metalPaidFine)} g',
                  accent: InvColors.brandGold),
              _DossierMetric(
                  label: 'Fine Due',
                  value: '${_weight(payment.fineDueWeight)} g',
                  accent: payment.fineDueWeight > 0
                      ? InvColors.danger
                      : InvColors.success),
              _DossierMetric(
                  label: 'Fine Return',
                  value: '${_weight(payment.fineReturnWeight)} g',
                  accent: const Color(0xFF0F766E)),
            ],
          ),
          const SizedBox(height: 12),
          _DossierInfoRow(label: 'Cash', value: _money(payment.cashPaid)),
          _DossierInfoRow(label: 'UPI', value: _money(payment.upiPaid)),
          _DossierInfoRow(label: 'Bank', value: _money(payment.bankPaid)),
          _DossierInfoRow(label: 'Card', value: _money(payment.cardPaid)),
          if (batch.isGst) ...[
            _DossierInfoRow(
                label: 'GST Total', value: _money(payment.gstAmount)),
            _DossierInfoRow(
                label: 'CGST / SGST',
                value:
                    '${_money(payment.cgstAmount)} / ${_money(payment.sgstAmount)}'),
          ],
          _DossierInfoRow(label: 'Status', value: _dash(payment.paymentStatus)),
        ],
      ),
    );
  }
}

class _BatchDocumentPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchDocumentPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final path = batch.payment.attachmentPath.trim();
    return _DossierPanel(
      icon: Icons.attach_file_rounded,
      title: 'Supplier Bill Document',
      subtitle: 'View or locate the bill attached during stock intake',
      accent: ui.accent,
      child: Row(
        children: [
          Expanded(
            child: Text(
              path.isEmpty
                  ? 'No supplier bill attachment is linked with this batch.'
                  : path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: path.isEmpty ? InvColors.textMuted : InvColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _DossierActionButton(
            label: 'Open Bill',
            icon: Icons.open_in_new_rounded,
            accent: ui.accent,
            enabled: path.isNotEmpty,
            onTap: () => _openLocalPath(path),
          ),
          const SizedBox(width: 10),
          _DossierActionButton(
            label: 'Show File',
            icon: Icons.folder_open_rounded,
            accent: ui.accent,
            enabled: path.isNotEmpty,
            onTap: () => _showLocalFile(path),
          ),
        ],
      ),
    );
  }
}

class _BatchStockLedgerPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchStockLedgerPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    return _DossierPanel(
      icon: Icons.view_list_rounded,
      title: 'Batch Item Ledger',
      subtitle: 'Available and sold stock units from this batch',
      accent: ui.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 1180
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final unit in batch.units)
                SizedBox(
                  width: itemWidth,
                  child: _InventoryGradeUnitCard(unit: unit, ui: ui),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DossierPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  const _DossierPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: InvColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
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

class _DossierMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DossierMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DossierInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DossierInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: InvColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DossierActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  const _DossierActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? accent : InvColors.textHint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 17, color: enabled ? Colors.white : InvColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: enabled ? Colors.white : InvColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderGstTag extends StatelessWidget {
  final Color textColor;

  const _HeaderGstTag({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
      ),
      child: Text(
        'GST',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

Map<String, dynamic> _decodePaymentMeta(String raw) {
  if (raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } catch (_) {}
  return const {};
}

double _metaDouble(Map<String, dynamic> meta, String key) {
  final value = meta[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String _metaString(Map<String, dynamic> meta, String key) {
  final value = meta[key];
  if (value == null) return '';
  return '$value';
}

String _money(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  ).format(value);
}

String _weight(double value) {
  return NumberFormat('##,##0.000', 'en_IN').format(value);
}

String _dash(String value) {
  final text = value.trim();
  return text.isEmpty ? 'Not recorded' : text;
}

Future<void> _openLocalPath(String path) async {
  if (path.trim().isEmpty) return;
  final file = File(path);
  if (!file.existsSync()) return;
  await Process.start('explorer.exe', [path]);
}

Future<void> _showLocalFile(String path) async {
  if (path.trim().isEmpty) return;
  final file = File(path);
  if (!file.existsSync()) return;
  await Process.start('explorer.exe', ['/select,', path]);
}
