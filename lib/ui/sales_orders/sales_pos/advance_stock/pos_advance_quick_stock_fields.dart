import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../features/stock/shared/domain/models/supplier/supplier_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class QuickStockDialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  const QuickStockDialogHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 17),
      decoration: const BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SalesPosColors.brandGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class QuickStockItemSnapshot extends StatelessWidget {
  final String title;
  final String details;

  const QuickStockItemSnapshot({
    super.key,
    required this.title,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: const TextStyle(
              color: SalesPosColors.goldHoverDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickStockSupplierAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final List<SupplierListItemModel> suppliers;
  final ValueChanged<SupplierListItemModel> onSelected;

  const QuickStockSupplierAutocomplete({
    super.key,
    required this.controller,
    required this.suppliers,
    required this.onSelected,
  });

  @override
  State<QuickStockSupplierAutocomplete> createState() =>
      _QuickStockSupplierAutocompleteState();
}

class _QuickStockSupplierAutocompleteState
    extends State<QuickStockSupplierAutocomplete> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'PosQuickStockSupplier');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<SupplierListItemModel>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (supplier) => supplier.displayName,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return widget.suppliers.take(8);
        return widget.suppliers.where((supplier) {
          return supplier.displayName.toLowerCase().contains(query) ||
              supplier.mobile.contains(query);
        }).take(8);
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return QuickStockInputField(
          controller: textController,
          focusNode: focusNode,
          label: 'Supplier',
          hint: widget.suppliers.isEmpty ? 'Supplier name' : 'Search supplier',
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final supplier = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      supplier.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(supplier.mobile),
                    onTap: () => onSelectedOption(supplier),
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

class QuickStockInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final bool number;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const QuickStockInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.focusNode,
    this.number = false,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textCapitalization: textCapitalization,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      style: const TextStyle(
        color: SalesPosColors.textDark,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: SalesPosColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        floatingLabelStyle: const TextStyle(
          color: SalesPosColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
        hintStyle: TextStyle(
          color: SalesPosColors.textDark.withValues(alpha: 0.56),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: SalesPosColors.formInputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: SalesPosColors.brandGold, width: 1.4),
        ),
      ),
    );
  }
}
