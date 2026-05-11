// =============================================================================
// FILE        : silver_stock_screen.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Screen
// DESCRIPTION : Dedicated Silver Stock entry screen.
//               ✅ 100% Isolated Silver Theme & App Bar.
//               ✅ Step 1 → Purity Selection (SilverPurityStep).
//               ✅ Step 2 → SilverBatchOverviewCard + SilverInvoiceCard
//                          + Supplier Panel + Items Table (wired in next phase).
//               ✅ No generic gold/purity stepper used.
// UPDATED     : SilverBatchConfigPanel replaced by two focused cards:
//               1. SilverBatchOverviewCard — compact stats + GST toggle.
//               2. SilverInvoiceCard       — batch ID + supplier invoice + date/time.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

// ── ISOLATED SILVER THEME ──────────────────────────────────────
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

// ── SILVER UI COMPONENTS ───────────────────────────────────────
import 'silver_app_bar.dart';
import 'silver_purity_step.dart';
import 'silver_batch_overview_card.dart';
import 'silver_invoice_card.dart';

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

  // ── BACK INTERCEPT ───────────────────────────────────────────
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

  // ── EXIT DIALOG ──────────────────────────────────────────────
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
            child: Text(SilverStockStrings.btnDiscard,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── RESET DIALOG ─────────────────────────────────────────────
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

  // ── SAVE ─────────────────────────────────────────────────────
  Future<void> _onSave() async {
    await _ctrl.saveAll();
    if (_ctrl.successMessage != null && mounted) _showSuccessDialog();
  }

  // ── SUCCESS DIALOG ───────────────────────────────────────────
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

  // ── BUILD ────────────────────────────────────────────────────
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

                // ── STEP 1 : PURITY SELECTION ─────────────────────
                ? SilverPurityStep(
                    key: const ValueKey('silver-purity'),
                    ctrl: _ctrl,
                  )

                // ── STEP 2 : OVERVIEW + INVOICE + ITEMS ───────────
                : _buildItemsBody(),
          ),
        ),
      ),
    );
  }

  // ── ITEMS BODY (STEP 2) ──────────────────────────────────────
  Widget _buildItemsBody() {
    return Padding(
      key: const ValueKey('silver-items'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── CARD 1 : BATCH OVERVIEW ──────────────────────────
          // Compact stats — purity, pieces, weights, cost/sale,
          // and the animated GST / NORMAL toggle pill.
          SilverBatchOverviewCard(ctrl: _ctrl),

          const SizedBox(height: 16),

          // ── CARD 2 : INVOICE NUMBER ──────────────────────────
          // System batch ID (auto), supplier invoice (manual B2B),
          // and live date / time chips.
          SilverInvoiceCard(ctrl: _ctrl),

          const SizedBox(height: 20),

          // ── UPCOMING: Supplier Panel ─────────────────────────
          // SilverSupplierPanel(ctrl: _ctrl),

          // ── UPCOMING: Items Entry Table ──────────────────────
          // SilverEntryTable(ctrl: _ctrl),

          // ── UPCOMING: Payment & Save Panel ──────────────────
          // SilverPaymentPanel(ctrl: _ctrl, onSave: _onSave),
        ],
      ),
    );
  }
}
