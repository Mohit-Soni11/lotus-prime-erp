import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_gold_stock_supplier_panel.dart';
import 'stock_metal_ui.dart';

class AddGoldStockItemsStep extends StatelessWidget {
  final AddStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;

  const AddGoldStockItemsStep({
    super.key,
    required this.ctrl,
    required this.onSave,
    required this.onResetBatch,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(ctrl.selectedMetal);

    return Column(
      children: [
        _buildOverview(ui),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              AddGoldStockSupplierPanel(ctrl: ctrl),
              const SizedBox(height: 16),
              _GoldRateReferenceCard(ctrl: ctrl),
              const SizedBox(height: 16),
              _GoldEntryTable(ctrl: ctrl),
            ],
          ),
        ),
        _buildFooter(ui),
      ],
    );
  }

  Widget _buildOverview(StockMetalUiData ui) {
    final purityLabel = ctrl.selectedPurityShortLabel.isEmpty
        ? ctrl.purityDisplay
        : ctrl.selectedPurityShortLabel;

    return Container(
      color: AddStockColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ui.softSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ui.accent.withOpacity(0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AddStockStrings.batchOverview,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AddStockColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selected purity stays fixed for this batch while each row can carry its own actual touch percentage.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AddStockColors.textBody,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ctrl.gstEnabled
                        ? AddStockColors.success.withOpacity(0.12)
                        : AddStockColors.bodyBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ctrl.gstEnabled
                          ? AddStockColors.success.withOpacity(0.25)
                          : AddStockColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    ctrl.gstEnabled ? 'GST ACTIVE' : 'NON GST',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ctrl.gstEnabled
                          ? AddStockColors.success
                          : AddStockColors.textBody,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pill('Gold Batch', ui.accent),
                _pill(purityLabel, AddStockColors.accentPricing),
                _pill(ctrl.batchCode, AddStockColors.textBody),
                if (ctrl.supplierDisplayName.trim().isNotEmpty)
                  _pill(ctrl.supplierDisplayName, AddStockColors.success),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard(
                  'Total $purityLabel Weight',
                  '${_wt(ctrl.totalNetWeight)} g',
                ),
                _metricCard('Total Fine Gold', '${_wt(ctrl.totalFineGold)} g'),
                _metricCard('Taxable Amount', _money(ctrl.totalTaxableAmount)),
                _metricCard('Batch Total', _money(ctrl.totalBatchAmount)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(StockMetalUiData ui) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: AddStockColors.shadowMedium,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ctrl.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AddStockColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AddStockColors.danger.withOpacity(0.2),
                ),
              ),
              child: Text(
                ctrl.errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AddStockColors.danger,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 960;

              final gstCard = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: ctrl.gstEnabled
                      ? AddStockColors.success.withOpacity(0.08)
                      : AddStockColors.bodyBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ctrl.gstEnabled
                        ? AddStockColors.success.withOpacity(0.24)
                        : AddStockColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GST Billing',
                            style: AddStockStyles.sectionTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctrl.gstEnabled
                                ? 'CGST ${_money(ctrl.cgstAmount)}  •  SGST ${_money(ctrl.sgstAmount)}'
                                : 'Turn on to add 3% GST breakup to this batch.',
                            style: AddStockStyles.caption.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: ctrl.gstEnabled,
                      onChanged: ctrl.toggleGst,
                      activeColor: ui.accent,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              );

              final statusCard = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: ui.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ui.accent.withOpacity(0.18)),
                ),
                child: Text(
                  ctrl.rowsWithErrorsCount == 0
                      ? 'Ready to save • ${ctrl.enteredRowCount} entered row${ctrl.enteredRowCount == 1 ? '' : 's'}'
                      : '${ctrl.rowsWithErrorsCount} entered row${ctrl.rowsWithErrorsCount == 1 ? '' : 's'} need attention',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ui.accent,
                  ),
                ),
              );

              final actions = Row(
                children: [
                  Expanded(child: statusCard),
                  const SizedBox(width: 12),
                  Expanded(child: gstCard),
                ],
              );

              if (stack) {
                return Column(
                  children: [statusCard, const SizedBox(height: 10), gstCard],
                );
              }

              return actions;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: ctrl.prevStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ui.accent.withOpacity(0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  AddStockStrings.btnBackPurity,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: ui.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onResetBatch,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AddStockColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  AddStockStrings.btnResetBatch,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textBody,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: ctrl.isSaving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ui.accent,
                      disabledBackgroundColor: AddStockColors.inputBgLocked,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: ctrl.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.save_alt_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      ctrl.isSaving
                          ? AddStockStrings.btnSaving
                          : 'Save ${ctrl.enteredRowCount} gold row${ctrl.enteredRowCount == 1 ? '' : 's'}',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AddStockColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AddStockColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

class _GoldRateReferenceCard extends StatelessWidget {
  final AddStockController ctrl;

  const _GoldRateReferenceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final rateDate = ctrl.goldRateDate == null
        ? 'No rate snapshot'
        : DateFormat('d MMM yyyy').format(ctrl.goldRateDate!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AddStockColors.brandGold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ctrl.isLoadingGoldRates
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AddStockColors.brandGold,
                    ),
                  )
                : const Icon(
                    Icons.candlestick_chart_rounded,
                    color: AddStockColors.brandGold,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Gold Rate Reference',
                  style: AddStockStyles.sectionTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  ctrl.hasActiveRateSnapshot
                      ? 'Row metal value is derived from fine gold using the latest gold rate snapshot.'
                      : 'No gold rate snapshot was found in Daily Rates. Save will stay blocked until today\'s rate is available.',
                  style: AddStockStyles.caption.copyWith(
                    fontSize: 12,
                    height: 1.45,
                    color: ctrl.hasActiveRateSnapshot
                        ? AddStockColors.textBody
                        : AddStockColors.danger,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _rateChip('24K', _money(ctrl.gold24kRatePer10g), rateDate),
                    _rateChip(
                      ctrl.selectedPurityShortLabel.isEmpty
                          ? ctrl.purityDisplay
                          : ctrl.selectedPurityShortLabel,
                      _money(ctrl.selectedPurityRatePer10g),
                      'per 10g',
                    ),
                    _rateChip(
                      'Pure / gm',
                      _money(ctrl.pureGoldRatePerGram),
                      'fine gold',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateChip(String label, String value, String note) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AddStockColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AddStockStyles.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 3),
          Text(
            value,
            style: AddStockStyles.sectionTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(note, style: AddStockStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _GoldEntryTable extends StatelessWidget {
  final AddStockController ctrl;

  const _GoldEntryTable({required this.ctrl});

  static const double _tableWidth = 1538;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final needsScroll = constraints.maxWidth < _tableWidth;

            return Container(
              decoration: BoxDecoration(
                color: AddStockColors.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AddStockColors.cardBorder,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AddStockColors.shadowLight,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(needsScroll),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: needsScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: _tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildColumnHeaders(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ctrl.rows.length,
                            itemBuilder: (context, index) => _GoldStockTableRow(
                              index: index,
                              row: ctrl.rows[index],
                              ctrl: ctrl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(bool needsScroll) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AddStockColors.brandGold.withOpacity(0.04),
        border: const Border(
          bottom: BorderSide(color: AddStockColors.cardBorder, width: 1.5),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AddStockColors.brandGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AddStockColors.brandGold.withOpacity(0.40),
              ),
            ),
            child: const Icon(
              Icons.table_rows_rounded,
              color: AddStockColors.brandGold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FAST GOLD ENTRY TABLE',
                  style: AddStockStyles.pageTitle.copyWith(
                    fontSize: 18,
                    color: AddStockColors.brandGold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Press Enter in the labour field to jump into the next blank row without breaking the typing flow.',
                  style: AddStockStyles.caption.copyWith(fontSize: 12),
                ),
                if (needsScroll) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Scroll horizontally to review every gold-entry column.',
                    style: AddStockStyles.caption.copyWith(
                      color: AddStockColors.brandGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AddStockColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AddStockColors.cardBorder, width: 1.5),
            ),
            child: Text(
              'ROWS : ${ctrl.enteredRowCount > 0 ? ctrl.enteredRowCount : ctrl.rows.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AddStockColors.brandGold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AddStockColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: AddStockColors.cardBorder, width: 1.5),
        ),
      ),
      child: const Row(
        children: [
          _GoldHeaderCell('S.NO', width: 62, center: true),
          SizedBox(width: 8),
          _GoldHeaderCell('SUB CATEGORY', width: 170),
          SizedBox(width: 8),
          _GoldHeaderCell('ITEM NAME', width: 220),
          SizedBox(width: 8),
          _GoldHeaderCell('HUID', width: 120),
          SizedBox(width: 8),
          _GoldHeaderCell('GROSS', width: 96, right: true),
          SizedBox(width: 8),
          _GoldHeaderCell('LESS', width: 96, right: true),
          SizedBox(width: 8),
          _GoldHeaderCell('NET WT', width: 96, right: true),
          SizedBox(width: 8),
          _GoldHeaderCell('TOUCH %', width: 96, right: true),
          SizedBox(width: 8),
          _GoldHeaderCell('FINE GOLD', width: 110, right: true),
          SizedBox(width: 8),
          _GoldHeaderCell('LABOUR TYPE', width: 156),
          SizedBox(width: 8),
          _GoldHeaderCell('LABOUR', width: 110, right: true),
          SizedBox(width: 8),
          _GoldHeaderCell('ROW TOTAL', width: 150, right: true),
          SizedBox(width: 8),
          _GoldHeaderCell('ACT', width: 56, center: true),
        ],
      ),
    );
  }
}

class _GoldHeaderCell extends StatelessWidget {
  final String title;
  final double width;
  final bool right;
  final bool center;

  const _GoldHeaderCell(
    this.title, {
    required this.width,
    this.right = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        textAlign: center
            ? TextAlign.center
            : (right ? TextAlign.right : TextAlign.left),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AddStockColors.textMuted,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _GoldStockTableRow extends StatefulWidget {
  final int index;
  final StockRowEntry row;
  final AddStockController ctrl;

  const _GoldStockTableRow({
    required this.index,
    required this.row,
    required this.ctrl,
  });

  @override
  State<_GoldStockTableRow> createState() => _GoldStockTableRowState();
}

class _GoldStockTableRowState extends State<_GoldStockTableRow> {
  bool _isHovered = false;

  late final TextEditingController _itemCtrl;
  late final TextEditingController _huidCtrl;
  late final TextEditingController _grossCtrl;
  late final TextEditingController _lessCtrl;
  late final TextEditingController _touchCtrl;
  late final TextEditingController _labourCtrl;
  late final FocusNode _itemFocus;

  @override
  void initState() {
    super.initState();
    _itemCtrl = TextEditingController();
    _huidCtrl = TextEditingController();
    _grossCtrl = TextEditingController();
    _lessCtrl = TextEditingController();
    _touchCtrl = TextEditingController();
    _labourCtrl = TextEditingController();
    _itemFocus = FocusNode();
    _syncControllers();
    _handlePendingFocus();
  }

  @override
  void didUpdateWidget(covariant _GoldStockTableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
    _handlePendingFocus();
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _huidCtrl.dispose();
    _grossCtrl.dispose();
    _lessCtrl.dispose();
    _touchCtrl.dispose();
    _labourCtrl.dispose();
    _itemFocus.dispose();
    super.dispose();
  }

  void _handlePendingFocus() {
    if (!widget.ctrl.shouldRequestFocus(widget.row.id)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _itemFocus.requestFocus();
      widget.ctrl.clearFocusRequest(widget.row.id);
    });
  }

  void _syncControllers() {
    _setIfNeeded(_itemCtrl, widget.row.itemName);
    _setIfNeeded(_huidCtrl, widget.row.huid);
    _setIfNeeded(_grossCtrl, _decimalText(widget.row.grossWeight));
    _setIfNeeded(_lessCtrl, _decimalText(widget.row.lessWeight));
    _setIfNeeded(_touchCtrl, _decimalText(widget.ctrl.touchOf(widget.row)));
    _setIfNeeded(_labourCtrl, _decimalText(widget.row.makingCharges));
  }

  void _setIfNeeded(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  String _decimalText(double value) {
    if (value == 0) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value
            .toStringAsFixed(3)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final ctrl = widget.ctrl;
    final isEven = widget.index.isEven;
    final error = ctrl.validateRow(row);
    final background = error != null
        ? AddStockColors.danger.withOpacity(0.04)
        : _isHovered
            ? AddStockColors.cardHoverBg
            : (isEven ? AddStockColors.cardBg : AddStockColors.bodyBg);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            bottom: BorderSide(
              color: error != null
                  ? AddStockColors.danger.withOpacity(0.18)
                  : AddStockColors.cardBorder,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _sNoCell(),
            const SizedBox(width: 8),
            _subCategoryCell(row, ctrl),
            const SizedBox(width: 8),
            _textField(
              width: 220,
              controller: _itemCtrl,
              hint: 'e.g. Maharaja',
              focusNode: _itemFocus,
              onChanged: (value) => ctrl.updateItemName(row.id, value),
            ),
            const SizedBox(width: 8),
            _textField(
              width: 120,
              controller: _huidCtrl,
              hint: 'AB1234',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => ctrl.updateHuid(row.id, value),
            ),
            const SizedBox(width: 8),
            _numberField(
              width: 96,
              controller: _grossCtrl,
              hint: '0.000',
              onChanged: (value) => ctrl.updateGrossWeight(row.id, value),
            ),
            const SizedBox(width: 8),
            _numberField(
              width: 96,
              controller: _lessCtrl,
              hint: '0.000',
              onChanged: (value) => ctrl.updateLessWeight(row.id, value),
            ),
            const SizedBox(width: 8),
            _autoCell(
              width: 96,
              value: _wt(row.netWeight).toStringAsFixed(3),
              color: AddStockColors.success,
            ),
            const SizedBox(width: 8),
            _numberField(
              width: 96,
              controller: _touchCtrl,
              hint: _decimalText(ctrl.selectedPurityBasePercent),
              onChanged: (value) => ctrl.updateTouchPercent(row.id, value),
            ),
            const SizedBox(width: 8),
            _autoCell(
              width: 110,
              value: '${_wt(ctrl.fineWeightOf(row))} g',
              color: AddStockColors.brandGold,
              isBold: true,
            ),
            const SizedBox(width: 8),
            _makingTypeCell(row, ctrl),
            const SizedBox(width: 8),
            _numberField(
              width: 110,
              controller: _labourCtrl,
              hint: '0.00',
              onChanged: (value) => ctrl.updateMakingCharges(row.id, value),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => ctrl.completeRowAndAdvance(row.id),
            ),
            const SizedBox(width: 8),
            _autoCell(
              width: 150,
              value: _money(ctrl.rowTotalAmount(row)),
              color: AddStockColors.textDark,
              alignRight: true,
              isBold: true,
            ),
            const SizedBox(width: 8),
            _deleteCell(ctrl, row),
          ],
        ),
      ),
    );
  }

  Widget _sNoCell() {
    return SizedBox(
      width: 62,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AddStockColors.brandGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AddStockColors.brandGold.withOpacity(0.32),
            ),
          ),
          child: Text(
            '${widget.index + 1}',
            style: AddStockStyles.fieldInput.copyWith(
              color: AddStockColors.brandGold,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subCategoryCell(StockRowEntry row, AddStockController ctrl) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<StockSubCategory>(
        value: row.subCategory,
        decoration: _inputDecoration(),
        style: AddStockStyles.fieldInput.copyWith(fontSize: 13),
        items: StockSubCategory.values
            .map(
              (value) => DropdownMenuItem<StockSubCategory>(
                value: value,
                child: Text(value.label, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            ctrl.updateSubCategory(row.id, value);
          }
        },
      ),
    );
  }

  Widget _makingTypeCell(StockRowEntry row, AddStockController ctrl) {
    return SizedBox(
      width: 156,
      child: DropdownButtonFormField<MakingChargesType>(
        value: row.makingChargesType,
        decoration: _inputDecoration(),
        style: AddStockStyles.fieldInput.copyWith(fontSize: 13),
        items: MakingChargesType.values
            .map(
              (value) => DropdownMenuItem<MakingChargesType>(
                value: value,
                child: Text(value.label, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            ctrl.updateMakingType(row.id, value);
          }
        },
      ),
    );
  }

  Widget _textField({
    required double width,
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        style: AddStockStyles.fieldInput.copyWith(fontSize: 14),
        onChanged: onChanged,
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  Widget _numberField({
    required double width,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        textInputAction: textInputAction,
        style: AddStockStyles.fieldInput.copyWith(
          fontSize: 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  Widget _autoCell({
    required double width,
    required String value,
    required Color color,
    bool alignRight = false,
    bool isBold = false,
  }) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        value,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: AddStockStyles.fieldInput.copyWith(
          color: color,
          fontSize: isBold ? 15 : 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _deleteCell(AddStockController ctrl, StockRowEntry row) {
    return SizedBox(
      width: 56,
      child: Center(
        child: Tooltip(
          message: 'Remove row',
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: ctrl.rows.length <= 1 ? null : () => ctrl.removeRow(row.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AddStockColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AddStockColors.danger.withOpacity(0.35),
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AddStockColors.danger,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AddStockColors.inputBg,
      hintStyle: TextStyle(
        color: AddStockColors.textMuted.withOpacity(0.52),
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AddStockColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AddStockColors.brandGold,
          width: 1.6,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AddStockColors.cardBorder),
      ),
    );
  }
}

double _wt(double value) => double.parse(value.toStringAsFixed(3));

String _money(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
