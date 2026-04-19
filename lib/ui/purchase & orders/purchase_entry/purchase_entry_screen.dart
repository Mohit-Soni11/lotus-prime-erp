// =============================================================================
// FILE        : purchase_entry_screen.dart
// MODULE      : Purchase Entry
// LAYER       : UI — Main Screen Assembly
// DESCRIPTION : Master shell connecting all Purchase Entry components.
//               Matches PosMasterSaleScreen pattern exactly.
//               ✅ Dark AppBar + Cream body
//               ✅ Left 70% scroll zone | Right 30% fixed panel
//               ✅ Global tap-to-unfocus
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import 'purchase_entry_app_bar.dart';
import 'purchase_top_control_bar.dart';
import 'purchase_invoice_status_bar.dart';
import 'purchase_customer_panel.dart';
import 'purchase_items_table.dart';
import 'purchase_right_panel.dart';

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  late final PurchaseEntryController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PurchaseEntryController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: PurchaseEntryColors.bodyBg,

        // ── DARK APP BAR ──────────────────────────────────────────────────
        appBar: PurchaseEntryAppBar(
          onBack: () => Navigator.pop(context),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── LEFT COLUMN 70% ───────────────────────────────────────
                Expanded(
                  flex: 70,
                  child: SingleChildScrollView(
                    controller: _ctrl.tableScrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // Top control bar + Invoice status bar side by side
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool sideBySide = constraints.maxWidth > 720;
                            if (sideBySide) {
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    PurchaseTopControlBar(ctrl: _ctrl),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: PurchaseInvoiceStatusBar(ctrl: _ctrl),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PurchaseTopControlBar(ctrl: _ctrl),
                                const SizedBox(height: 12),
                                PurchaseInvoiceStatusBar(ctrl: _ctrl),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // Customer / Supplier panel
                        PurchaseCustomerPanel(ctrl: _ctrl),
                        const SizedBox(height: 16),

                        // Purchase items table
                        PurchaseItemsTable(ctrl: _ctrl),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                // ── RIGHT COLUMN 30% ──────────────────────────────────────
                Expanded(
                  flex: 30,
                  child: PurchaseRightPanel(ctrl: _ctrl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
