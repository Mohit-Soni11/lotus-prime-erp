import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

class AddStockSupplierAutocomplete extends StatefulWidget {
  final String label;
  final List<SupplierListItemModel> suppliers;
  final String initialName;
  final void Function(SupplierListItemModel?) onSelected;
  final void Function(String) onTextChanged;

  const AddStockSupplierAutocomplete({
    super.key,
    required this.label,
    required this.suppliers,
    required this.initialName,
    required this.onSelected,
    required this.onTextChanged,
  });

  @override
  State<AddStockSupplierAutocomplete> createState() =>
      _AddStockSupplierAutocompleteState();
}

class _AddStockSupplierAutocompleteState
    extends State<AddStockSupplierAutocomplete> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant AddStockSupplierAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _textController.text != widget.initialName) {
      _textController.text = widget.initialName;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<SupplierListItemModel>(
      textEditingController: _textController,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.displayName,
      optionsBuilder: (value) {
        if (widget.suppliers.isEmpty) {
          return const Iterable<SupplierListItemModel>.empty();
        }
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return widget.suppliers.take(6);
        }
        return widget.suppliers.where((supplier) {
          return supplier.businessName.toLowerCase().contains(query) ||
              supplier.mobile.contains(query) ||
              (supplier.contactPersonName ?? '').toLowerCase().contains(query);
        });
      },
      onSelected: (option) {
        _textController.text = option.displayName;
        widget.onSelected(option);
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: widget.onTextChanged,
          style: AddStockStyles.fieldInput,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: AddStockStrings.supplierHint,
            hintStyle: AddStockStyles.fieldHint,
            labelStyle: AddStockStyles.fieldLabel,
            prefixIcon: const Icon(
              AddStockIcons.supplier,
              color: AddStockColors.brandGold,
              size: 18,
            ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: true,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      controller.clear();
                      widget.onSelected(null);
                      widget.onTextChanged('');
                    },
                  )
                : null,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AddStockColors.cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AddStockColors.divider),
                itemBuilder: (context, index) {
                  final supplier = list[index];
                  return InkWell(
                    onTap: () => onSelected(supplier),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.businessName,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AddStockColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              supplier.mobile,
                              if ((supplier.contactPersonName ?? '').isNotEmpty)
                                supplier.contactPersonName!,
                            ].join(' • '),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AddStockColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
