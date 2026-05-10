import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'add_stock_supplier_autocomplete.dart';

class AddStockItemRowCard extends StatefulWidget {
  final int index;
  final StockRowEntry row;
  final AddStockController ctrl;

  const AddStockItemRowCard({
    super.key,
    required this.index,
    required this.row,
    required this.ctrl,
  });

  @override
  State<AddStockItemRowCard> createState() => _AddStockItemRowCardState();
}

class _AddStockItemRowCardState extends State<AddStockItemRowCard> {
  bool _expanded = true;

  late final TextEditingController _itemNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _huidCtrl;
  late final TextEditingController _grossCtrl;
  late final TextEditingController _stoneWeightCtrl;
  late final TextEditingController _stoneValueCtrl;
  late final TextEditingController _caratCtrl;
  late final TextEditingController _piecesCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _makingCtrl;
  late final TextEditingController _mrpCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _hsnCtrl;

  @override
  void initState() {
    super.initState();
    _itemNameCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _huidCtrl = TextEditingController();
    _grossCtrl = TextEditingController();
    _stoneWeightCtrl = TextEditingController();
    _stoneValueCtrl = TextEditingController();
    _caratCtrl = TextEditingController();
    _piecesCtrl = TextEditingController();
    _rateCtrl = TextEditingController();
    _makingCtrl = TextEditingController();
    _mrpCtrl = TextEditingController();
    _gstCtrl = TextEditingController();
    _qtyCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _hsnCtrl = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant AddStockItemRowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _huidCtrl.dispose();
    _grossCtrl.dispose();
    _stoneWeightCtrl.dispose();
    _stoneValueCtrl.dispose();
    _caratCtrl.dispose();
    _piecesCtrl.dispose();
    _rateCtrl.dispose();
    _makingCtrl.dispose();
    _mrpCtrl.dispose();
    _gstCtrl.dispose();
    _qtyCtrl.dispose();
    _locationCtrl.dispose();
    _hsnCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final row = widget.row;
    _setIfNeeded(_itemNameCtrl, row.itemName);
    _setIfNeeded(_descriptionCtrl, row.description);
    _setIfNeeded(_huidCtrl, row.huid);
    _setIfNeeded(_grossCtrl, _decimalText(row.grossWeight));
    _setIfNeeded(_stoneWeightCtrl, _decimalText(row.stoneWeight));
    _setIfNeeded(_stoneValueCtrl, _decimalText(row.stoneValue));
    _setIfNeeded(_caratCtrl, _decimalText(row.stoneCarats));
    _setIfNeeded(_piecesCtrl, row.stonePieces == 0 ? '' : '${row.stonePieces}');
    _setIfNeeded(_rateCtrl, _decimalText(row.purchaseRate));
    _setIfNeeded(_makingCtrl, _decimalText(row.makingCharges));
    _setIfNeeded(_mrpCtrl, _decimalText(row.mrp));
    _setIfNeeded(_gstCtrl, _decimalText(row.gstRate));
    _setIfNeeded(_qtyCtrl, row.quantity == 1 ? '1' : '${row.quantity}');
    _setIfNeeded(_locationCtrl, row.location);
    _setIfNeeded(_hsnCtrl, row.hsnCode);
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
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  JewelleryHsn? _selectedHsn(StockRowEntry row) {
    for (final hsn in JewelleryHsn.values) {
      if (hsn.code == row.hsnCode) {
        return hsn;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final ctrl = widget.ctrl;
    final error = ctrl.validateRow(row);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: error != null
              ? AddStockColors.danger.withOpacity(0.45)
              : AddStockColors.cardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(row, ctrl, error),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildBody(row, ctrl, error),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    StockRowEntry row,
    AddStockController ctrl,
    String? error,
  ) {
    return InkWell(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AddStockColors.brandGoldLight,
                  child: Text(
                    '${widget.index}',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AddStockColors.brandGold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.itemName.trim().isEmpty
                            ? 'New Item'
                            : row.itemName.trim(),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AddStockColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _summaryChip(
                            '${row.quantity} ${AddStockStrings.overviewPieces}',
                          ),
                          _summaryChip(
                            '${row.grossWeight.toStringAsFixed(3)}g',
                          ),
                          _summaryChip(
                            '${row.netWeight.toStringAsFixed(3)}g net',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (ctrl.rowCount > 1)
                  IconButton(
                    tooltip: 'Remove row',
                    onPressed: () => ctrl.removeRow(row.id),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AddStockColors.danger,
                    ),
                  ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AddStockColors.textMuted,
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AddStockColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AddStockColors.danger.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AddStockColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AddStockColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(StockRowEntry row, AddStockController ctrl, String? error) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              _section(
                title: AddStockStrings.secBasicInfo,
                subtitle: AddStockStrings.descBasicInfo,
                icon: AddStockIcons.basicInfo,
                accent: AddStockColors.brandGold,
                width: constraints.maxWidth,
                children: [
                  _textField(
                    label: AddStockStrings.lblItemName,
                    controller: _itemNameCtrl,
                    onChanged: (value) => ctrl.updateItemName(row.id, value),
                    hintText: AddStockStrings.hintItemName,
                  ),
                  _dropdownField<StockSubCategory>(
                    label: AddStockStrings.lblSubCategory,
                    value: row.subCategory,
                    items: StockSubCategory.values,
                    labelBuilder: (value) => value.label,
                    onChanged: (value) {
                      if (value != null) {
                        ctrl.updateSubCategory(row.id, value);
                      }
                    },
                  ),
                  _textField(
                    label: AddStockStrings.lblDescription,
                    controller: _descriptionCtrl,
                    onChanged: (value) => ctrl.updateDescription(row.id, value),
                    hintText: AddStockStrings.hintDescription,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                title: AddStockStrings.secCompliance,
                subtitle: AddStockStrings.descCompliance,
                icon: AddStockIcons.compliance,
                accent: AddStockColors.warning,
                width: constraints.maxWidth,
                children: [
                  _textField(
                    label: AddStockStrings.lblHuid,
                    controller: _huidCtrl,
                    onChanged: (value) => ctrl.updateHuid(row.id, value),
                    hintText: AddStockStrings.hintHuid,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textCapitalization: TextCapitalization.characters,
                  ),
                  _dropdownField<JewelleryHsn>(
                    label: AddStockStrings.lblHsnPreset,
                    value: _selectedHsn(row),
                    items: JewelleryHsn.values,
                    labelBuilder: (value) => value.label,
                    onChanged: (value) => ctrl.applyPresetHsn(row.id, value),
                  ),
                  _textField(
                    label: AddStockStrings.lblHsnCode,
                    controller: _hsnCtrl,
                    onChanged: (value) => ctrl.updateHsnCode(row.id, value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                title: AddStockStrings.secMetalDetails,
                subtitle: AddStockStrings.descMetal,
                icon: AddStockIcons.metalDetails,
                accent: AddStockColors.accentPricing,
                width: constraints.maxWidth,
                children: [
                  _numberField(
                    label: AddStockStrings.lblGrossWeight,
                    controller: _grossCtrl,
                    onChanged: (value) => ctrl.updateGrossWeight(row.id, value),
                  ),
                  _numberField(
                    label: AddStockStrings.lblStoneWeight,
                    controller: _stoneWeightCtrl,
                    onChanged: (value) => ctrl.updateStoneWeight(row.id, value),
                  ),
                  _readOnlyField(
                    label: AddStockStrings.lblNetWeight,
                    value: '${row.netWeight.toStringAsFixed(3)} g',
                    note: AddStockStrings.netWeightNote,
                    accent: AddStockColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                title: AddStockStrings.secStoneDetails,
                subtitle: AddStockStrings.descStone,
                icon: AddStockIcons.stoneDetails,
                accent: AddStockColors.accentStone,
                width: constraints.maxWidth,
                children: [
                  _dropdownField<StoneType>(
                    label: AddStockStrings.lblStoneType,
                    value: row.stoneType,
                    items: StoneType.values,
                    labelBuilder: (value) => value.label,
                    onChanged: (value) {
                      if (value != null) {
                        ctrl.updateStoneType(row.id, value);
                      }
                    },
                  ),
                  _numberField(
                    label: AddStockStrings.lblCarats,
                    controller: _caratCtrl,
                    onChanged: (value) => ctrl.updateStoneCarats(row.id, value),
                  ),
                  _numberField(
                    label: AddStockStrings.lblPieces,
                    controller: _piecesCtrl,
                    onChanged: (value) => ctrl.updateStonePieces(row.id, value),
                    decimals: false,
                  ),
                  _numberField(
                    label: AddStockStrings.lblStoneValue,
                    controller: _stoneValueCtrl,
                    onChanged: (value) => ctrl.updateStoneValue(row.id, value),
                    prefixText: 'Rs ',
                  ),
                ],
                footer: row.stoneType == StoneType.none
                    ? _infoStrip(
                        AddStockStrings.noteNoStone,
                        AddStockColors.accentStone,
                      )
                    : _infoStrip(
                        AddStockStrings.stoneValueNote,
                        AddStockColors.accentStone,
                      ),
              ),
              const SizedBox(height: 14),
              _section(
                title: AddStockStrings.secPricing,
                subtitle: AddStockStrings.descPricing,
                icon: AddStockIcons.pricing,
                accent: AddStockColors.warning,
                width: constraints.maxWidth,
                children: [
                  _numberField(
                    label: AddStockStrings.lblPurchaseRate,
                    controller: _rateCtrl,
                    onChanged: (value) =>
                        ctrl.updatePurchaseRate(row.id, value),
                    prefixText: 'Rs ',
                  ),
                  _numberField(
                    label: AddStockStrings.lblMakingCharges,
                    controller: _makingCtrl,
                    onChanged: (value) =>
                        ctrl.updateMakingCharges(row.id, value),
                    prefixText: 'Rs ',
                  ),
                  _dropdownField<MakingChargesType>(
                    label: AddStockStrings.lblMakingType,
                    value: row.makingChargesType,
                    items: MakingChargesType.values,
                    labelBuilder: (value) => value.label,
                    onChanged: (value) {
                      if (value != null) {
                        ctrl.updateMakingType(row.id, value);
                      }
                    },
                  ),
                  _numberField(
                    label: AddStockStrings.lblMrp,
                    controller: _mrpCtrl,
                    onChanged: (value) => ctrl.updateMrp(row.id, value),
                    prefixText: 'Rs ',
                  ),
                  _numberField(
                    label: AddStockStrings.lblGstRate,
                    controller: _gstCtrl,
                    onChanged: (value) => ctrl.updateGstRate(row.id, value),
                  ),
                ],
                footer: _pricingSummary(row),
              ),
              const SizedBox(height: 14),
              _section(
                title: AddStockStrings.secInventory,
                subtitle: AddStockStrings.descInventory,
                icon: AddStockIcons.inventoryMgmt,
                accent: const Color(0xFF2F7F75),
                width: constraints.maxWidth,
                children: [
                  _numberField(
                    label: AddStockStrings.lblQuantity,
                    controller: _qtyCtrl,
                    onChanged: (value) => ctrl.updateQuantity(row.id, value),
                    decimals: false,
                  ),
                  _textField(
                    label: AddStockStrings.lblRackLocation,
                    controller: _locationCtrl,
                    onChanged: (value) => ctrl.updateLocation(row.id, value),
                    hintText: AddStockStrings.hintRack,
                  ),
                  if (!ctrl.sameForAll)
                    AddStockSupplierAutocomplete(
                      label: AddStockStrings.lblSupplierRow,
                      suppliers: ctrl.suppliers,
                      initialName: row.supplierName,
                      onSelected: (supplier) =>
                          ctrl.setRowSupplier(row.id, supplier),
                      onTextChanged: (value) =>
                          ctrl.setRowSupplierText(row.id, value),
                    )
                  else
                    _readOnlyField(
                      label: AddStockStrings.lblSupplier,
                      value: ctrl.sessionSupplierName.trim().isEmpty
                          ? 'Using batch-level supplier'
                          : ctrl.sessionSupplierName,
                      note:
                          'Toggle off "Same for all items" to override per row.',
                      accent: const Color(0xFF2F7F75),
                    ),
                ],
              ),
              if (error == null &&
                  row.mrp > 0 &&
                  row.costPrice > 0 &&
                  row.mrp < row.costPrice) ...[
                const SizedBox(height: 12),
                _infoStrip(
                  'MRP estimated cost se kam hai. Pricing ko recheck kar lena.',
                  AddStockColors.warning,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required double width,
    required List<Widget> children,
    Widget? footer,
  }) {
    final columns = width >= 1100
        ? 3
        : width >= 760
            ? 2
            : 1;
    final fieldWidth = (width - ((columns - 1) * 12)) / columns;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AddStockStyles.sectionTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AddStockStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map((child) => SizedBox(width: fieldWidth, child: child))
                .toList(),
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer],
        ],
      ),
    );
  }

  Widget _pricingSummary(StockRowEntry row) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _summaryTile(
          label: AddStockStrings.costPriceLabel,
          value: 'Rs ${row.costPrice.toStringAsFixed(2)}',
          accent: AddStockColors.warning,
        ),
        _summaryTile(
          label: AddStockStrings.lblMrp,
          value: row.mrp > 0 ? 'Rs ${row.mrp.toStringAsFixed(2)}' : 'Not set',
          accent: AddStockColors.accentPricing,
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AddStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AddStockColors.textBody,
        ),
      ),
    );
  }

  Widget _infoStrip(String text, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.5,
                color: AddStockColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? hintText,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: AddStockStyles.fieldInput,
      decoration: _inputDecoration(
        label: label,
        hintText: hintText,
        prefixText: prefixText,
      ),
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? prefixText,
    bool decimals = true,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimals ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      style: AddStockStyles.fieldInput,
      decoration: _inputDecoration(
        label: label,
        hintText:
            decimals ? AddStockStrings.hintPrice : AddStockStrings.hintQuantity,
        prefixText: prefixText,
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required String note,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AddStockStyles.fieldLabel),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(note, style: AddStockStyles.caption),
        ],
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      onChanged: onChanged,
      style: AddStockStyles.fieldInput,
      decoration: _inputDecoration(label: label),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixText: prefixText,
      labelStyle: AddStockStyles.fieldLabel,
      hintStyle: AddStockStyles.fieldHint,
      filled: true,
      fillColor: AddStockColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AddStockColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AddStockColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AddStockColors.brandGold,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }
}
