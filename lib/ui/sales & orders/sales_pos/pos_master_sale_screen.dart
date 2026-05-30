// ==========================================
// FILE: pos_master_sale_screen.dart
// TYPE: Main Screen Assembly (Motherboard)
// AUTHOR: Senior System Architect
// DESCRIPTION: Main shell connecting the POS workspace components.
//               Parent NEVER rebuilds (True Zero-Lag).
//               Global tap-to-unfocus added for premium UX.
// Removed deprecated login badge parameters.
// ==========================================

import 'package:flutter/material.dart';

import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

import 'pos_app_bar.dart';
import 'pos_top_control_bar.dart';
import 'pos_invoice_status_bar.dart';
import 'pos_customer_details_panel.dart';
import 'pos_sale_items_table.dart';
import 'pos_old_gold_table.dart';
import 'pos_right_billing_panel.dart';

class PosMasterSaleScreen extends StatefulWidget {
  const PosMasterSaleScreen({super.key});

  @override
  State<PosMasterSaleScreen> createState() => _PosMasterSaleScreenState();
}

class _PosMasterSaleScreenState extends State<PosMasterSaleScreen> {
  //  The master controller driving the entire screen
  late final PosBillingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PosBillingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //  Global Unfocus: Tapping anywhere outside a text field hides the keyboard
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: SalesPosColors.bodyBg,

        //  Top app bar 
        appBar: PosAppBar(
          title: "${_ctrl.shopName} - POS TERMINAL",
          // Removed userName, userRole, and userInitials from here
          onBack: () => Navigator.pop(context),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // LEFT COLUMN (70%) - SMART SCROLL ZONE
                // ==========================================
                Expanded(
                  flex: 70,
                  child: SingleChildScrollView(
                    controller: _ctrl.tableScrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        //  HEADER COMPONENT ROW 
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool sideBySide = constraints.maxWidth > 720;
                            if (sideBySide) {
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    PosTopControlBar(ctrl: _ctrl),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child:
                                            PosInvoiceStatusBar(ctrl: _ctrl)),
                                  ],
                                ),
                              );
                            }
                            // Responsive fallback for smaller screens
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PosTopControlBar(ctrl: _ctrl),
                                const SizedBox(height: 12),
                                PosInvoiceStatusBar(ctrl: _ctrl),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        //  CUSTOMER INFO 
                        PosCustomerDetailsPanel(ctrl: _ctrl),
                        const SizedBox(height: 16),

                        //  MAIN CART TABLE 
                        PosSaleItemsTable(ctrl: _ctrl),
                        const SizedBox(height: 16),

                        //  OLD GOLD / EXCHANGE TABLE 
                        PosOldGoldTable(ctrl: _ctrl),

                        // Extra bottom padding for scroll comfort
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                // ==========================================
                // Right billing column
                // ==========================================
                Expanded(
                  flex: 30,
                  child: PosRightBillingPanel(ctrl: _ctrl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
