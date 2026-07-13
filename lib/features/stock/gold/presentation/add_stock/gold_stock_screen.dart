import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_controller.dart'
    show AddStockStep;
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/add_gold_stock_items_step.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_app_bar.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_batch_action_bar.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_purity_step.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class GoldStockScreen extends StatefulWidget {
  const GoldStockScreen({super.key});

  @override
  State<GoldStockScreen> createState() => _GoldStockScreenState();
}

class _GoldStockScreenState extends State<GoldStockScreen> {
  late final GoldStockController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = GoldStockController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handleBackPressed();
      },
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: AddStockColors.bodyBg,
            appBar: GoldAppBar(
              ctrl: _ctrl,
              onBack: _handleBackPressed,
            ),
            bottomNavigationBar: _ctrl.step == AddStockStep.items
                ? GoldBatchActionBar(
                    ctrl: _ctrl,
                    onSave: _onSave,
                    onResetBatch: _showResetDialog,
                  )
                : null,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              child: _ctrl.step == AddStockStep.purity
                  ? GoldPurityStep(
                      key: const ValueKey('Gold-purity-step'),
                      ctrl: _ctrl,
                    )
                  : AddGoldStockItemsStep(
                      key: const ValueKey('Gold-items-step'),
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
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return _GoldConfirmDialog(
          icon: Icons.warning_amber_rounded,
          iconColor: GoldStockColors.danger,
          title: AddStockStrings.confirmExitTitle,
          message: AddStockStrings.confirmExitBody,
          primaryLabel: AddStockStrings.btnKeepEditing,
          secondaryLabel: AddStockStrings.btnDiscard,
          secondaryColor: GoldStockColors.danger,
          onPrimary: () => Navigator.of(dialogContext).pop(false),
          onSecondary: () => Navigator.of(dialogContext).pop(true),
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
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return _GoldConfirmDialog(
          icon: Icons.restart_alt_rounded,
          iconColor: GoldStockColors.paymentPrimary,
          title: AddStockStrings.confirmResetTitle,
          message: AddStockStrings.confirmResetBody,
          primaryLabel: AddStockStrings.btnCancel,
          secondaryLabel: AddStockStrings.btnResetBatch,
          secondaryColor: GoldStockColors.paymentPrimary,
          onPrimary: () => Navigator.of(dialogContext).pop(false),
          onSecondary: () => Navigator.of(dialogContext).pop(true),
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
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: _ctrl.errorMessage ?? AddStockStrings.errSaveFailed,
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

class _GoldConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final Color secondaryColor;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _GoldConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.secondaryColor,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GoldStockColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GoldStockColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: GoldStockColors.shadowMedium,
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: iconColor.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: GoldStockColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: GoldStockColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrimary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GoldStockColors.textBody,
                      side: const BorderSide(color: GoldStockColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      primaryLabel,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSecondary,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
