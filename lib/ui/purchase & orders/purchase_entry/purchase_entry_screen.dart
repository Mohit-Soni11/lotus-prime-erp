import 'package:flutter/material.dart';

import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'purchase_customer_panel.dart';
import 'purchase_entry_app_bar.dart';
import 'purchase_invoice_status_bar.dart';
import 'purchase_items_table.dart';
import 'purchase_right_panel.dart';
import 'purchase_top_control_bar.dart';

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
        appBar: PurchaseEntryAppBar(
          onBack: () => Navigator.pop(context),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1240;
              final rightPanelHeight =
                  constraints.maxWidth < 720 ? 680.0 : 760.0;
              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 68,
                        child: SingleChildScrollView(
                          controller: _ctrl.tableScrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          child: _buildPrimaryColumn(),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 32,
                        child: PurchaseRightPanel(ctrl: _ctrl),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrimaryColumn(),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: rightPanelHeight,
                      child: PurchaseRightPanel(ctrl: _ctrl),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth > 760;
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
        PurchaseCustomerPanel(ctrl: _ctrl),
        const SizedBox(height: 16),
        PurchaseItemsTable(ctrl: _ctrl),
        const SizedBox(height: 24),
      ],
    );
  }
}
