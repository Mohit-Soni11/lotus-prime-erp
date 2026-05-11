// =============================================================================
// FILE        : silver_stock_screen.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Screen
// DESCRIPTION : Dedicated Silver Stock entry screen.
//               ✅ 100% Isolated Silver Theme & App Bar.
//               ✅ Step 1 → Purity Selection (SilverPurityStep)
//               ✅ Step 2 → Batch Config + Items Entry
//               ✅ No generic gold/purity stepper used.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

// ── ISOLATED SILVER THEME & COMPONENTS ──
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';
import 'silver_app_bar.dart';
import 'silver_purity_step.dart';
import 'silver_batch_config_panel.dart';

class SilverStockScreen extends StatefulWidget {
  const SilverStockScreen({super.key});

  @override
  State<SilverStockScreen> createState() => _SilverStockScreenState();
}

class _SilverStockScreenState extends State<SilverStockScreen> {
  late final AddStockController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AddStockController(initialMetal: StockCategory.silver);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_ctrl.step == AddStockStep.items) {
      _ctrl.prevStep();
      return false;
    }
    if (_ctrl.hasAnyInput) {
      return await _showExitDialog() ?? false;
    }
    return true;
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilverStockColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(SilverStockStrings.confirmExitTitle,
            style: SilverStockStyles.panelHeader),
        content: Text(SilverStockStrings.confirmExitBody,
            style: SilverStockStyles.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(SilverStockStrings.btnKeepEditing,
                style: TextStyle(color: SilverStockColors.brandSilver)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SilverStockColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilverStockColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(SilverStockStrings.confirmResetTitle,
            style: SilverStockStyles.panelHeader),
        content: Text(SilverStockStrings.confirmResetBody,
            style: SilverStockStyles.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(SilverStockStrings.btnCancel,
                style: TextStyle(color: SilverStockColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SilverStockColors.brandSilver,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(SilverStockStrings.btnResetBatch,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) _ctrl.resetForNewBatch();
  }

  Future<void> _onSave() async {
    await _ctrl.saveAll();
    if (_ctrl.successMessage != null && mounted) _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SilverStockColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: SilverStockColors.success, size: 22),
          const SizedBox(width: 8),
          Text(SilverStockStrings.savedTitle,
              style: SilverStockStyles.panelHeader),
        ]),
        content:
            Text(_ctrl.successMessage ?? '', style: SilverStockStyles.caption),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _ctrl.resetAllRows();
            },
            child: Text(SilverStockStrings.btnAddMore,
                style: TextStyle(color: SilverStockColors.brandSilver)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _ctrl.resetForNewBatch();
            },
            child: Text(SilverStockStrings.btnNewBatch,
                style: TextStyle(color: SilverStockColors.brandSilver)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SilverStockColors.brandSilver,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(SilverStockStrings.btnDone,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: SilverStockColors.bodyBg,
        appBar: SilverAppBar(
          ctrl: _ctrl,
          onBack: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) Navigator.of(context).pop();
          },
        ),
        body: ListenableBuilder(
          listenable: _ctrl,
          builder: (_, __) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _ctrl.step == AddStockStep.purity

                // ── STEP 1 : PURITY SELECTION ──────────────────────
                ? SilverPurityStep(
                    key: const ValueKey('silver-purity'),
                    ctrl: _ctrl,
                  )

                // ── STEP 2 : BATCH CONFIG + ITEMS ──────────────────
                : _buildItemsBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsBody() {
    return Padding(
      key: const ValueKey('silver-items'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── BATCH CONFIG PANEL ──────────────────────────────────
          SilverBatchConfigPanel(
            systemBatchId: _ctrl.batchCode,
          ),
          const SizedBox(height: 20),
          // ── TODO: Supplier Panel & Items Table ─────────────────
          // SilverSupplierPanel(ctrl: _ctrl),
          // SilverEntryTable(ctrl: _ctrl),
          // SilverPaymentPanel(ctrl: _ctrl, onSave: _onSave),
        ],
      ),
    );
  }
}
