// =============================================================================
// FILE        : silver_batch_config_panel.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Components
// DESCRIPTION : Premium Batch Configuration Panel.
//               âœ… Tax Status Toggle (Normal / GST).
//               âœ… Supplier Invoice ID & System Batch ID.
//               âœ… 100% Isolated Silver Theme.
// =============================================================================

import 'package:flutter/material.dart';

// Importing strictly from the isolated Silver theme
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverBatchConfigPanel extends StatefulWidget {
  final String systemBatchId;

  const SilverBatchConfigPanel({
    super.key,
    required this.systemBatchId,
  });

  @override
  State<SilverBatchConfigPanel> createState() => _SilverBatchConfigPanelState();
}

class _SilverBatchConfigPanelState extends State<SilverBatchConfigPanel> {
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
        color: SilverStockColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilverStockColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: SilverStockColors.shadowLight,
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
                SilverStockIcons.taxNormal,
                color: SilverStockColors.silverAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                SilverStockStrings.configPanelTitle,
                style: SilverStockStyles.panelHeader,
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: SilverStockColors.divider, height: 1),
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
          style: SilverStockStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: SilverStockColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SilverStockColors.borderLight),
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
                      color: SilverStockColors.shadowLight,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            title,
            style: SilverStockStyles.inputText.copyWith(
              color: isActive
                  ? SilverStockColors.textDark
                  : SilverStockColors.textMuted,
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
          SilverStockStrings.systemInvoiceId,
          style: SilverStockStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: SilverStockColors.brandSilverLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: SilverStockColors.brandSilver.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                SilverStockIcons.invoiceSystem,
                size: 16,
                color: SilverStockColors.brandSilver,
              ),
              const SizedBox(width: 10),
              Text(
                widget.systemBatchId,
                style: SilverStockStyles.inputText.copyWith(
                  color: SilverStockColors.brandSilver,
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
          SilverStockStrings.supplierInvoiceId,
          style: SilverStockStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _supplierInvoiceCtrl,
            style: SilverStockStyles.inputText,
            decoration: InputDecoration(
              hintText: "Enter ID...",
              hintStyle: SilverStockStyles.inputText.copyWith(
                color: SilverStockColors.textHint,
              ),
              prefixIcon: const Icon(
                SilverStockIcons.invoiceSupplier,
                size: 18,
                color: SilverStockColors.textMuted,
              ),
              filled: true,
              fillColor: SilverStockColors.inputBg,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: SilverStockColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: SilverStockColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: SilverStockColors.brandSilver,
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
