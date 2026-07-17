import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_controller.dart'
    show AddStockStep;
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/add_silver_stock_items_step.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_app_bar.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_batch_action_bar.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_purity_step.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

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
            appBar: SilverAppBar(
              ctrl: _ctrl,
              onBack: _handleBackPressed,
            ),
            bottomNavigationBar: _ctrl.step == AddStockStep.items
                ? SilverBatchActionBar(
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
                  ? SilverPurityStep(
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
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return _SilverConfirmDialog(
          icon: Icons.warning_amber_rounded,
          iconColor: SilverStockColors.danger,
          title: AddStockStrings.confirmExitTitle,
          message: AddStockStrings.confirmExitBody,
          primaryLabel: AddStockStrings.btnKeepEditing,
          secondaryLabel: AddStockStrings.btnDiscard,
          secondaryColor: SilverStockColors.danger,
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
        return _SilverConfirmDialog(
          icon: Icons.restart_alt_rounded,
          iconColor: SilverStockColors.paymentPrimary,
          title: AddStockStrings.confirmResetTitle,
          message: AddStockStrings.confirmResetBody,
          primaryLabel: AddStockStrings.btnCancel,
          secondaryLabel: AddStockStrings.btnResetBatch,
          secondaryColor: SilverStockColors.paymentPrimary,
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

  void _doneAndExit() {
    Navigator.of(context).pop();
  }

  Future<void> _showSavedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              color: SilverStockColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: SilverStockColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 34,
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
                        Color(0xFFF8FBFC),
                        Color(0xFFE7EEF2),
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color:
                              SilverStockColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: SilverStockColors.success
                                .withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: SilverStockColors.success,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AddStockStrings.savedTitle,
                              style: GoogleFonts.manrope(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: SilverStockColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _ctrl.successMessage ??
                                  'Silver stock batch has been saved successfully.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                                color: SilverStockColors.textBody,
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
                          Navigator.of(dialogContext).pop();
                          _ctrl.resetAllRows();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: SilverStockColors.brandSilver,
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
                          Navigator.of(dialogContext).pop();
                          _ctrl.resetForNewBatch();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SilverStockColors.textDark,
                          side: const BorderSide(
                            color: SilverStockColors.cardBorder,
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
                          AddStockStrings.btnNewBatch,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: SilverStockColors.brandSilver,
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
                          AddStockStrings.btnDone,
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

class _SilverConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final Color secondaryColor;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _SilverConfirmDialog({
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
          color: SilverStockColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SilverStockColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: SilverStockColors.shadowMedium,
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
                          color: SilverStockColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: SilverStockColors.textBody,
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
                      foregroundColor: SilverStockColors.textBody,
                      side:
                          const BorderSide(color: SilverStockColors.cardBorder),
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
