// =============================================================================
// FILE        : silver_stock_screen.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Screen
// DESCRIPTION : Dedicated Silver Stock entry screen.
//               ✅ 100% Isolated Silver Theme & App Bar.
//               ✅ Removed old Gold/Purity Stepper.
//               ✅ Added Premium Batch Config Panel with Auto-Batch ID.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

// ── ISOLATED SILVER THEME & COMPONENTS ──
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';
import 'silver_app_bar.dart';
import 'silver_batch_config_panel.dart';

class SilverStockScreen extends StatefulWidget {
  const SilverStockScreen({super.key});

  @override
  State<SilverStockScreen> createState() => _SilverStockScreenState();
}

class _SilverStockScreenState extends State<SilverStockScreen> {
  late final AddStockController _ctrl;
  late final String _systemBatchId; // Smart auto-generated ID

  @override
  void initState() {
    super.initState();
    // Temporary fallback to old controller until SilverController is built
    _ctrl = AddStockController(initialMetal: StockCategory.silver);

    // Auto-generate a premium batch ID (e.g., SLV-98473)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _systemBatchId = "SLV-${timestamp.substring(timestamp.length - 6)}";
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SilverStockColors.bodyBg,

      // ── TOP HEADER (WITHOUT STEPPER) ──
      appBar: SilverAppBar(
        ctrl: _ctrl,
        onBack: () => Navigator.of(context).pop(),
      ),

      // ── MAIN CONTENT AREA ──
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // STEP 1: Naya Top-Brand Batch Configuration Panel
            SilverBatchConfigPanel(
              systemBatchId: _systemBatchId, // Fixed Error Here!
            ),

            const SizedBox(height: 20),

            // Note: Agla step (Supplier Details aur Items Table) hum yahan add karenge
          ],
        ),
      ),
    );
  }
}
