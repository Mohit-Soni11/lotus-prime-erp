import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart'
    show AddStockStep;
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/add_silver_stock_items_step.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_app_bar.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_purity_step.dart';

class SilverStockScreen extends StatefulWidget {
  const SilverStockScreen({super.key});

  @override
  State<SilverStockScreen> createState() => _SilverStockScreenState();
}

class _SilverStockScreenState extends State<SilverStockScreen> {
  late final SilverStockController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SilverStockController();
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
            backgroundColor: AddStockColors.bodyBg,
            appBar: AddStockAppBar(
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
                  : AddSilverStockItemsStep(
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

  Future<void> _handleBackPressed() async {
    final canLeave = await _handleExitAttempt();
    if (!mounted || !canLeave) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool> _handleExitAttempt() async {
    if (!_ctrl.hasAnyInput || _ctrl.isSaving) {
      return !_ctrl.isSaving;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            AddStockStrings.confirmExitTitle,
            style: AddStockStyles.sectionTitle,
          ),
          content: Text(
            AddStockStrings.confirmExitBody,
            style: AddStockStyles.caption,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                AddStockStrings.btnKeepEditing,
                style: GoogleFonts.inter(
                  color: AddStockColors.textBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AddStockColors.danger,
                foregroundColor: Colors.white,
              ),
              child: Text(
                AddStockStrings.btnDiscard,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  Future<void> _showResetDialog() async {
    if (_ctrl.isSaving) {
      return;
    }

    if (!_ctrl.hasAnyInput) {
      _ctrl.resetForNewBatch();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            AddStockStrings.confirmResetTitle,
            style: AddStockStyles.sectionTitle,
          ),
          content: Text(
            AddStockStrings.confirmResetBody,
            style: AddStockStyles.caption,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                AddStockStrings.btnCancel,
                style: GoogleFonts.inter(
                  color: AddStockColors.textBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF748A98),
                foregroundColor: Colors.white,
              ),
              child: Text(
                AddStockStrings.btnResetBatch,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _ctrl.resetForNewBatch();
    }
  }

  Future<void> _onSave() async {
    final success = await _ctrl.saveAll();
    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ctrl.errorMessage ?? AddStockStrings.errSaveFailed),
          backgroundColor: AddStockColors.danger,
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
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFDDE7ED), Color(0xFF8BA1AF)],
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
                  AddStockStrings.savedTitle,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AddStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _ctrl.successMessage ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.6,
                    color: AddStockColors.textBody,
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
                AddStockStrings.btnAddMore,
                style: GoogleFonts.inter(
                  color: const Color(0xFF748A98),
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
                side: const BorderSide(color: Color(0xFF8BA1AF)),
              ),
              child: Text(
                AddStockStrings.btnNewBatch,
                style: GoogleFonts.inter(
                  color: const Color(0xFF748A98),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF748A98),
                foregroundColor: Colors.white,
              ),
              child: Text(
                AddStockStrings.btnDone,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}
