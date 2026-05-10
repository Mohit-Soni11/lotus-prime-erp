// =============================================================================
// FILE        : silver_stock_screen.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Screen
// DESCRIPTION : Dedicated Silver Stock entry screen.
//               Uses 100% isolated SilverAppBar + Silver theme.
//               Gold/Diamond/Platinum ka AddStockScreen alag rehta hai.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

// ✅ Silver isolated theme — sirf EK baar import (duplicate hata diya)
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

// ✅ Silver App Bar
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_app_bar.dart';

// ✅ Steps reuse karte hain — same controller, alag screen
import 'package:lotus_erp/ui/stock/add_stock/add_stock_purity_step.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_items_step.dart';

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
    // Silver fixed — controller always gets StockCategory.silver
    _ctrl = AddStockController(initialMetal: StockCategory.silver);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleExitAttempt,
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Scaffold(
            // ✅ Silver body background — cool blue-grey, not warm cream (gold)
            backgroundColor: SilverStockColors.bodyBg,

            // ✅ SilverAppBar — no more Gold header
            appBar: SilverAppBar(
              ctrl: _ctrl,
              onBack: _handleBackPressed,
            ),

            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              child: _ctrl.step == AddStockStep.purity
                  ? AddStockPurityStep(
                      key: const ValueKey('silver-purity-step'),
                      ctrl: _ctrl,
                    )
                  : AddStockItemsStep(
                      key: const ValueKey('silver-items-step'),
                      ctrl: _ctrl,
                      onSave: _onSave,
                      onResetBatch: _showResetDialog,
                    ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BACK / EXIT
  // ─────────────────────────────────────────────────────────────

  Future<void> _handleBackPressed() async {
    final canLeave = await _handleExitAttempt();
    if (!mounted || !canLeave) return;
    Navigator.of(context).pop();
  }

  Future<bool> _handleExitAttempt() async {
    if (!_ctrl.hasAnyInput || _ctrl.isSaving) {
      return !_ctrl.isSaving;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          SilverStockStrings.confirmExitTitle,
          style: SilverStockStyles.sectionTitle,
        ),
        content: Text(
          SilverStockStrings.confirmExitBody,
          style: SilverStockStyles.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              SilverStockStrings.btnKeepEditing,
              style: GoogleFonts.inter(
                color: SilverStockColors.textBody,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SilverStockColors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(
              SilverStockStrings.btnDiscard,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  // ─────────────────────────────────────────────────────────────
  // RESET DIALOG
  // ─────────────────────────────────────────────────────────────

  Future<void> _showResetDialog() async {
    if (_ctrl.isSaving) return;

    if (!_ctrl.hasAnyInput) {
      _ctrl.resetForNewBatch();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          SilverStockStrings.confirmResetTitle,
          style: SilverStockStyles.sectionTitle,
        ),
        content: Text(
          SilverStockStrings.confirmResetBody,
          style: SilverStockStyles.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              SilverStockStrings.btnCancel,
              style: GoogleFonts.inter(
                color: SilverStockColors.textBody,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            // ✅ Silver accent — brandSilver, not brandGold
            style: ElevatedButton.styleFrom(
              backgroundColor: SilverStockColors.brandSilver,
              foregroundColor: Colors.white,
            ),
            child: Text(
              SilverStockStrings.btnResetBatch,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) _ctrl.resetForNewBatch();
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    final success = await _ctrl.saveAll();
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ctrl.errorMessage ?? SilverStockStrings.errSaveFailed),
          backgroundColor: SilverStockColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _showSavedDialog();
  }

  Future<void> _showSavedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Silver gradient icon box
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SilverStockColors.gradientStart,
                      SilverStockColors.brandSilver,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                SilverStockStrings.savedTitle,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: SilverStockColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _ctrl.successMessage ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: SilverStockColors.textBody,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _ctrl.resetAllRows();
            },
            child: Text(
              SilverStockStrings.btnAddMore,
              style: GoogleFonts.inter(
                color: SilverStockColors.brandSilver,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _ctrl.resetForNewBatch();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: SilverStockColors.brandSilver.withOpacity(0.32),
              ),
            ),
            child: Text(
              SilverStockStrings.btnNewBatch,
              style: GoogleFonts.inter(
                color: SilverStockColors.brandSilver,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SilverStockColors.brandSilver,
              foregroundColor: Colors.white,
            ),
            child: Text(
              SilverStockStrings.btnDone,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
