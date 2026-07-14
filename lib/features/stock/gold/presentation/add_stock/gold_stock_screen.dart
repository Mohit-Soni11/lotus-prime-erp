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

enum _GoldSaveAction { addMoreOnly, newBatch, exit }

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
                    onDoneExit: _doneAndExit,
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
    final action = await _showSaveActionDialog();
    if (!mounted || action == null) {
      return;
    }

    if (action == _GoldSaveAction.addMoreOnly) {
      _ctrl.addRow(requestFocus: true);
      return;
    }

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

    final message =
        _ctrl.successMessage ?? 'Gold stock batch has been saved successfully.';

    switch (action) {
      case _GoldSaveAction.addMoreOnly:
        break;
      case _GoldSaveAction.newBatch:
        AppFeedback.success(context, message: message);
        _ctrl.resetForNewBatch();
      case _GoldSaveAction.exit:
        AppFeedback.success(context, message: message);
        Navigator.of(context).pop();
    }
  }

  void _doneAndExit() {
    Navigator.of(context).pop();
  }

  Future<_GoldSaveAction?> _showSaveActionDialog() async {
    return showDialog<_GoldSaveAction>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              color: GoldStockColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GoldStockColors.brandGoldBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF8E1),
                        Color(0xFFFFFFFF),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(color: GoldStockColors.cardBorder),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: GoldStockColors.successBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: GoldStockColors.successBorder,
                          ),
                        ),
                        child: const Icon(
                          Icons.save_alt_rounded,
                          color: GoldStockColors.paymentPrimary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Save Gold Batch',
                              style: GoogleFonts.manrope(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: GoldStockColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose what should happen after this batch is saved. The stock will be posted only after you select one option.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                                color: GoldStockColors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(
                            _GoldSaveAction.addMoreOnly,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: GoldStockColors.paymentPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                        ),
                        child: Text(
                          AddStockStrings.btnAddMore,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(
                            _GoldSaveAction.newBatch,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GoldStockColors.textDark,
                          side: const BorderSide(
                            color: GoldStockColors.brandGoldBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          'Save & New Batch',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(
                            _GoldSaveAction.exit,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: GoldStockColors.paymentPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text(
                          'Save & Exit',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
