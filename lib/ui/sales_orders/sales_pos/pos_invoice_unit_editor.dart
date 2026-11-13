import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/sales_pos/domain/services/pos_item_unit_profile.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

/// Edits the invoice label without changing the linked stock unit.
class PosInvoiceUnitEditor extends StatelessWidget {
  const PosInvoiceUnitEditor({
    super.key,
    required this.item,
    required this.color,
  });

  final SaleItemModel item;
  final Color color;

  Future<void> _openEditor(BuildContext context) async {
    final selection = await showDialog<_InvoiceUnitSelection>(
      context: context,
      builder: (_) => _InvoiceUnitDialog(item: item),
    );
    if (selection == null) return;
    if (item.linkedStockItemId == null) {
      item.setUnitProfile(selection.actualUnit);
    }
    item.setInvoiceUnitLabel(selection.displayName);
  }

  @override
  Widget build(BuildContext context) => Tooltip(
        message: '${item.invoiceUnitLabel} · Edit invoice name',
        child: InkWell(
          onTap: () => _openEditor(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 26,
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Text(
              item.invoiceUnitLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
}

class _InvoiceUnitSelection {
  const _InvoiceUnitSelection(this.actualUnit, this.displayName);

  final PosItemUnitProfile actualUnit;
  final String displayName;
}

class _InvoiceUnitDialog extends StatefulWidget {
  const _InvoiceUnitDialog({required this.item});

  final SaleItemModel item;

  @override
  State<_InvoiceUnitDialog> createState() => _InvoiceUnitDialogState();
}

class _InvoiceUnitDialogState extends State<_InvoiceUnitDialog> {
  static const _textColor = SalesPosColors.textDark;
  static const _fieldLabelStyle = TextStyle(
    color: _textColor,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
  static const _fieldBorder = OutlineInputBorder(
    borderSide: BorderSide(color: SalesPosColors.bodyBorder),
  );
  static const _focusedFieldBorder = OutlineInputBorder(
    borderSide: BorderSide(color: SalesPosColors.goldHoverDark, width: 1.5),
  );

  late final TextEditingController _labelController;
  late PosItemUnitProfile _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.item.unitProfile;
    _labelController =
        TextEditingController(text: widget.item.invoiceUnitLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Invoice unit',
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.item.linkedStockItemId == null)
                DropdownButtonFormField<PosItemUnitProfile>(
                  initialValue: _selectedUnit,
                  dropdownColor: Colors.white,
                  iconEnabledColor: _textColor,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Actual unit',
                    border: _fieldBorder,
                    enabledBorder: _fieldBorder,
                    focusedBorder: _focusedFieldBorder,
                    labelStyle: _fieldLabelStyle,
                    floatingLabelStyle: _fieldLabelStyle,
                  ),
                  items: [
                    for (final profile in widget.item.availableUnitProfiles)
                      DropdownMenuItem(
                        value: profile,
                        child: Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    final oldDefault = _selectedUnit.shortName;
                    setState(() => _selectedUnit = value);
                    if (_labelController.text.trim() == oldDefault) {
                      _labelController.text = value.shortName;
                    }
                  },
                )
              else
                Text(
                  'Stock unit: ${widget.item.unitProfile.displayName}',
                  style: SalesPosStyles.caption.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelController,
                autofocus: true,
                maxLength: 32,
                style: SalesPosStyles.inputText.copyWith(
                  color: _textColor,
                  fontWeight: FontWeight.w800,
                ),
                cursorColor: SalesPosColors.goldHoverDark,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[\r\n\t]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Name shown on invoice',
                  hintText: 'e.g. Jodi',
                  border: _fieldBorder,
                  enabledBorder: _fieldBorder,
                  focusedBorder: _focusedFieldBorder,
                  helperText: 'Only this invoice; stock unit stays unchanged.',
                  helperMaxLines: 2,
                  labelStyle: _fieldLabelStyle,
                  floatingLabelStyle: _fieldLabelStyle,
                  hintStyle: _fieldLabelStyle,
                  helperStyle: TextStyle(
                    color: _textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  counterStyle: TextStyle(
                    color: _textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _textColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _textColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () => _labelController.text = _selectedUnit.shortName,
            child: const Text('Use default name'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SalesPosColors.brandGold,
              foregroundColor: _textColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: () => Navigator.pop(
              context,
              _InvoiceUnitSelection(_selectedUnit, _labelController.text),
            ),
            child: const Text('Save'),
          ),
        ],
      );
}
