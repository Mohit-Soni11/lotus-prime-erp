import 'package:flutter/material.dart';

import '../../../../database/db/app_database.dart';
import '../../../../features/sales_pos/domain/services/pos_number_formatter.dart';
import '../../../../features/sales_pos/domain/services/pos_number_parser.dart';
import '../../../../features/stock/shared/domain/models/supplier/supplier_model.dart';
import '../../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../repositories/supplier/supplier_repository.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'pos_advance_quick_stock_fields.dart';

class PosAdvanceQuickStockDialog extends StatefulWidget {
  final PosBillingController controller;
  final int rowIndex;

  const PosAdvanceQuickStockDialog({
    super.key,
    required this.controller,
    required this.rowIndex,
  });

  static Future<bool> show({
    required BuildContext context,
    required PosBillingController controller,
    required int rowIndex,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PosAdvanceQuickStockDialog(
        controller: controller,
        rowIndex: rowIndex,
      ),
    );
    return result ?? false;
  }

  @override
  State<PosAdvanceQuickStockDialog> createState() =>
      _PosAdvanceQuickStockDialogState();
}

class _PosAdvanceQuickStockDialogState
    extends State<PosAdvanceQuickStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supplierCtrl = TextEditingController();
  late final TextEditingController _purityCtrl;
  late final TextEditingController _wastageCtrl;
  late final TextEditingController _purchaseRateCtrl;
  late final TextEditingController _huidCtrl;
  late final Future<List<SupplierListItemModel>> _suppliersFuture;

  SupplierListItemModel? _selectedSupplier;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.controller.saleItems[widget.rowIndex];
    _purityCtrl = TextEditingController(text: item.purityCtrl.text.trim());
    _wastageCtrl = TextEditingController();
    _purchaseRateCtrl = TextEditingController(text: item.rateCtrl.text.trim());
    _huidCtrl = TextEditingController(text: item.primaryHuidText.trim());
    _supplierCtrl.addListener(_clearSupplierSelectionWhenEdited);
    _suppliersFuture =
        SupplierRepository(AppDatabase()).getAllSuppliers().catchError(
              (_) => const <SupplierListItemModel>[],
            );
  }

  @override
  void dispose() {
    _supplierCtrl.removeListener(_clearSupplierSelectionWhenEdited);
    _supplierCtrl.dispose();
    _purityCtrl.dispose();
    _wastageCtrl.dispose();
    _purchaseRateCtrl.dispose();
    _huidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.controller.saleItems[widget.rowIndex];
    final rowLabel = item.descCtrl.text.trim().isEmpty
        ? 'Jewellery Item'
        : item.descCtrl.text.trim();
    final weightLabel =
        PosNumberFormatter.weight(item.netWt, blankWhenZero: false);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuickStockDialogHeader(
                  title: 'Stock Required Before Sale',
                  subtitle:
                      'This advance booking item is not linked with inventory.',
                  onClose:
                      _isSaving ? null : () => Navigator.of(context).pop(false),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                  child: QuickStockItemSnapshot(
                    title: rowLabel,
                    details:
                        '${item.metal.displayName}  |  ${_purityCtrl.text.trim()}  |  Net $weightLabel g',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: QuickStockInputField(
                              controller: _purityCtrl,
                              label: 'Purity',
                              hint: '22KT',
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickStockInputField(
                              controller: _wastageCtrl,
                              label: 'Wastage %',
                              hint: '0',
                              number: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: QuickStockInputField(
                              controller: _purchaseRateCtrl,
                              label: 'Purchase Rate / g',
                              hint: 'Rate',
                              number: true,
                              validator: _positiveNumber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickStockInputField(
                              controller: _huidCtrl,
                              label: 'HUID',
                              hint: 'Optional',
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<SupplierListItemModel>>(
                        future: _suppliersFuture,
                        builder: (context, snapshot) {
                          return QuickStockSupplierAutocomplete(
                            controller: _supplierCtrl,
                            suppliers: snapshot.data ??
                                const <SupplierListItemModel>[],
                            onSelected: (supplier) {
                              setState(() {
                                _selectedSupplier = supplier;
                                _supplierCtrl.text = supplier.displayName;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: SalesPosColors.textDark,
                          disabledForegroundColor:
                              SalesPosColors.textDark.withValues(alpha: 0.38),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: const Text('Use Full Add Stock Later'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveQuickStock,
                        style: FilledButton.styleFrom(
                          backgroundColor: SalesPosColors.brandGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_task_rounded, size: 19),
                        label: Text(
                          _isSaving ? 'Adding Stock' : 'Quick Add & Continue',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuickStock() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final intake = widget.controller.quickStockDraftForRow(
        rowIndex: widget.rowIndex,
        wastagePercent: PosNumberParser.parseNonNegative(_wastageCtrl.text),
        purchaseRate: PosNumberParser.parseNonNegative(_purchaseRateCtrl.text),
        huid: _huidCtrl.text.trim(),
        supplierId: _selectedSupplier?.id,
        supplierName: _supplierCtrl.text.trim(),
        purityLabel: _purityCtrl.text.trim(),
      );
      await widget.controller.quickAddStockForSaleRow(intake);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock could not be added. Please review details.'),
          ),
        );
      }
    }
  }

  void _clearSupplierSelectionWhenEdited() {
    final supplier = _selectedSupplier;
    if (supplier == null) {
      return;
    }
    if (_supplierCtrl.text.trim() != supplier.displayName) {
      setState(() => _selectedSupplier = null);
    }
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'Required' : null;
  }

  String? _positiveNumber(String? value) {
    final parsed = PosNumberParser.parseNonNegative(value ?? '');
    if (parsed <= 0) return 'Enter valid rate';
    return null;
  }
}
