// =============================================================================
// FILE        : Gold_batch_config_panel.dart
// MODULE      : Stock & Inventory (Gold)
// LAYER       : UI / Components
// DESCRIPTION : Premium Batch Configuration Panel.
//               âœ… Tax Status Toggle (Normal / GST).
//               âœ… Supplier Invoice ID & System Batch ID.
//               âœ… 100% Isolated Gold Theme.
// =============================================================================

import 'package:flutter/material.dart';

// Importing strictly from the isolated Gold theme
import '../../../../theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

class GoldBatchConfigPanel extends StatefulWidget {
  final String systemBatchId;

  const GoldBatchConfigPanel({
    super.key,
    required this.systemBatchId,
  });

  @override
  State<GoldBatchConfigPanel> createState() => _GoldBatchConfigPanelState();
}

class _GoldBatchConfigPanelState extends State<GoldBatchConfigPanel> {
  bool _isGstEnabled = false;
  late final TextEditingController _supplierInvoiceCtrl;

  @override
  void initState() {
    super.initState();
    _supplierInvoiceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _supplierInvoiceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GoldStockColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GoldStockColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: GoldStockColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ HEADER â”€â”€
          Row(
            children: [
              const Icon(
                GoldStockIcons.taxNormal,
                color: GoldStockColors.goldAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                GoldStockStrings.configPanelTitle,
                style: GoldStockStyles.panelHeader,
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: GoldStockColors.divider, height: 1),
          const SizedBox(height: 20),

          // â”€â”€ CONTENT ROW â”€â”€
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Tax Status Toggle
              Expanded(
                flex: 4,
                child: _buildTaxStatusToggle(),
              ),

              const SizedBox(width: 32),

              // RIGHT: Invoice Details
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(child: _buildSystemInvoiceBox()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSupplierInvoiceInput()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // â”€â”€ TAX STATUS TOGGLE â”€â”€
  Widget _buildTaxStatusToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TAX STATUS",
          style: GoldStockStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: GoldStockColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GoldStockColors.borderLight),
          ),
          child: Row(
            children: [
              _buildToggleOption(
                title: "NORMAL",
                isActive: !_isGstEnabled,
                onTap: () => setState(() => _isGstEnabled = false),
              ),
              _buildToggleOption(
                title: "GST",
                isActive: _isGstEnabled,
                onTap: () => setState(() => _isGstEnabled = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: GoldStockColors.shadowLight,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            title,
            style: GoldStockStyles.inputText.copyWith(
              color: isActive
                  ? GoldStockColors.textDark
                  : GoldStockColors.textMuted,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€ SYSTEM INVOICE BOX (READ-ONLY) â”€â”€
  Widget _buildSystemInvoiceBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GoldStockStrings.systemInvoiceId,
          style: GoldStockStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: GoldStockColors.brandGoldLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: GoldStockColors.brandGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                GoldStockIcons.invoiceSystem,
                size: 16,
                color: GoldStockColors.brandGold,
              ),
              const SizedBox(width: 10),
              Text(
                widget.systemBatchId,
                style: GoldStockStyles.inputText.copyWith(
                  color: GoldStockColors.brandGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // â”€â”€ SUPPLIER INVOICE INPUT â”€â”€
  Widget _buildSupplierInvoiceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GoldStockStrings.supplierInvoiceId,
          style: GoldStockStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _supplierInvoiceCtrl,
            style: GoldStockStyles.inputText,
            decoration: InputDecoration(
              hintText: "Enter ID...",
              hintStyle: GoldStockStyles.inputText.copyWith(
                color: GoldStockColors.textHint,
              ),
              prefixIcon: const Icon(
                GoldStockIcons.invoiceSupplier,
                size: 18,
                color: GoldStockColors.textMuted,
              ),
              filled: true,
              fillColor: GoldStockColors.inputBg,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: GoldStockColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: GoldStockColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: GoldStockColors.brandGold,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
