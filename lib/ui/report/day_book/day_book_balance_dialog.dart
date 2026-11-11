import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/reports/day_book/day_book_balance_verification.dart';
import '../../../models/reports/day_book/day_book_expense_record.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_balance_attention.dart';
import 'day_book_balance_difference_fields.dart';
import 'day_book_balance_expense_summary.dart';
import 'day_book_balance_sections.dart';
import 'day_book_balance_summary.dart';
import 'day_book_form_visuals.dart';

typedef SaveDayBookBalance = Future<DayBookBalanceVerification> Function({
  required double actualCash,
  required double actualBank,
  ExpenseCategory? cashExpenseCategory,
  String? cashReason,
  String? bankReason,
});

class DayBookBalanceDialogResult {
  const DayBookBalanceDialogResult.verified() : mismatchExpenseAmount = null;
  const DayBookBalanceDialogResult.mismatchExpense(this.mismatchExpenseAmount);

  final double? mismatchExpenseAmount;
}

class DayBookBalanceDialog extends StatefulWidget {
  const DayBookBalanceDialog({
    super.key,
    required this.date,
    required this.expectedCash,
    required this.expectedBank,
    required this.onSave,
    this.existing,
    this.expenseRecords = const [],
    this.bankAccountConfigured = true,
  });

  final DateTime date;
  final double expectedCash;
  final double expectedBank;
  final DayBookBalanceVerification? existing;
  final List<DayBookExpenseRecord> expenseRecords;
  final SaveDayBookBalance onSave;
  final bool bankAccountConfigured;

  @override
  State<DayBookBalanceDialog> createState() => _DayBookBalanceDialogState();
}

class _DayBookBalanceDialogState extends State<DayBookBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _cash = TextEditingController(
      text: widget.existing?.actualCash.toStringAsFixed(2) ?? '');
  late final _bank = TextEditingController(
      text: widget.existing?.actualBank.toStringAsFixed(2) ?? '');
  late final _note = TextEditingController(
      text: widget.existing?.cashReason ?? widget.existing?.bankReason ?? '');
  late ExpenseCategory? _expenseCategory = widget.existing?.cashCategory == null
      ? null
      : ExpenseCategory.fromDb(widget.existing!.cashCategory!);
  late DayBookExpenseScope? _expenseScope = _expenseCategory == null
      ? null
      : _expenseCategory!.isPersonal
          ? DayBookExpenseScope.personal
          : DayBookExpenseScope.shop;
  bool _saving = false;
  String? _error;

  double? _amount(TextEditingController controller) {
    final amount = double.tryParse(controller.text.trim().replaceAll(',', ''));
    return amount != null && amount.isFinite ? amount : null;
  }

  double get _netShortage =>
      widget.expectedCash +
      widget.expectedBank -
      (_amount(_cash) ?? 0) -
      (_amount(_bank) ?? 0);

  @override
  void initState() {
    super.initState();
    _cash.addListener(_refresh);
    _bank.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _cash.removeListener(_refresh);
    _bank.removeListener(_refresh);
    _cash.dispose();
    _bank.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_netShortage >= 0.01 &&
        (_expenseScope == null || _expenseCategory == null)) {
      setState(
          () => _error = 'Choose Shop or Personal expense and its category.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        actualCash: _amount(_cash)!,
        actualBank: _amount(_bank)!,
        cashExpenseCategory: _netShortage >= 0.01 ? _expenseCategory : null,
        cashReason: _netShortage.abs() >= 0.01 ? _note.text.trim() : null,
        bankReason: _netShortage < -0.005 ? _note.text.trim() : null,
      );
      if (mounted) {
        Navigator.of(context).pop(const DayBookBalanceDialogResult.verified());
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Invalid argument(s): ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openMismatchExpense(double amount) {
    Navigator.of(context)
        .pop(DayBookBalanceDialogResult.mismatchExpense(amount));
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final readOnly = existing != null;
    final expectedCash = existing?.expectedCash ?? widget.expectedCash;
    final expectedBank = existing?.expectedBank ?? widget.expectedBank;
    final actualCash = readOnly ? existing.actualCash : _amount(_cash);
    final actualBank = readOnly ? existing.actualBank : _amount(_bank);
    final cashVariance = actualCash == null ? 0 : actualCash - expectedCash;
    final bankVariance = actualBank == null ? 0 : actualBank - expectedBank;
    final netDifference = actualCash == null || actualBank == null
        ? 0.0
        : expectedCash + expectedBank - actualCash - actualBank;
    final allocationConflict = actualCash != null &&
        actualBank != null &&
        ((cashVariance < -0.005 && bankVariance > 0.005) ||
            (cashVariance > 0.005 && bankVariance < -0.005));
    final hasMismatch = actualCash != null &&
        actualBank != null &&
        (cashVariance.abs() >= 0.01 || bankVariance.abs() >= 0.01);

    return DayBookFormVisuals.themed(
      child: Dialog(
        insetPadding: const EdgeInsets.all(18),
        backgroundColor: const Color(0xFFFFFEFC),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DayBookColors.brandGoldBorder),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height - 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _header(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DayBookPreviousClosing(
                        date: widget.date,
                        cash: expectedCash,
                        bank: expectedBank,
                      ),
                      const SizedBox(height: 10),
                      DayBookOpeningInputs(
                        date: widget.date,
                        cash: _cash,
                        bank: _bank,
                        readOnly: readOnly,
                        bankAccountConfigured: widget.bankAccountConfigured,
                      ),
                      const SizedBox(height: 10),
                      DayBookBalanceSummary(
                        expectedCash: expectedCash,
                        expectedBank: expectedBank,
                        actualCash: actualCash,
                        actualBank: actualBank,
                      ),
                      const SizedBox(height: 10),
                      DayBookBalanceExpenseSummary(
                          records: widget.expenseRecords),
                      if (allocationConflict) ...[
                        const SizedBox(height: 10),
                        DayBookBalanceAttention(
                            hasNetShortage: netDifference > 0.005),
                      ] else if (actualCash != null && actualBank != null) ...[
                        const SizedBox(height: 10),
                        DayBookBalanceDifferenceFields(
                          netDifference: netDifference,
                          scope: _expenseScope,
                          onScopeChanged: (scope) => setState(() {
                            _expenseScope = scope;
                            _expenseCategory = null;
                          }),
                          category: _expenseCategory,
                          onCategoryChanged: (value) =>
                              setState(() => _expenseCategory = value),
                          note: _note,
                          readOnly: readOnly,
                        ),
                      ],
                      if (readOnly) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Saved ${DateFormat('d MMM yyyy, h:mm a').format(existing.verifiedAt)}',
                          style: DayBookStyles.labelStrong,
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: DayBookStyles.labelStrong
                                .copyWith(color: DayBookColors.negative)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _footer(
              readOnly: readOnly,
              allocationConflict: allocationConflict,
              showMismatchAction: hasMismatch,
              mismatchExpenseAmount: netDifference > 0.005
                  ? (netDifference * 100).roundToDouble() / 100
                  : null,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 17, 13, 14),
        child: Stack(children: [
          Positioned(
            right: 53,
            top: -9,
            child: IgnorePointer(
              child: Icon(Icons.spa_outlined,
                  size: 71,
                  color: DayBookColors.brandGold.withValues(alpha: 0.13)),
            ),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: DayBookColors.brandGoldSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DayBookColors.brandGoldBorder),
              ),
              child: const Icon(Icons.fact_check_outlined,
                  color: DayBookColors.goldMetal, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Balance Verification',
                        style: DayBookStyles.pageTitle.copyWith(
                            fontSize: 22, color: DayBookColors.goldMetal)),
                    const SizedBox(height: 2),
                    Text(
                      'Compare previous day closing with today’s opening before starting the day.',
                      style: DayBookStyles.labelStrong.copyWith(
                          fontSize: 13, color: DayBookColors.textPrimary),
                    ),
                  ]),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: DayBookColors.bodySubtle,
                side: const BorderSide(color: DayBookColors.bodyBorder),
              ),
            ),
          ]),
        ]),
      );

  Widget _footer({
    required bool readOnly,
    required bool allocationConflict,
    required bool showMismatchAction,
    required double? mismatchExpenseAmount,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DayBookColors.bodyBorder)),
        ),
        child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 9,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  foregroundColor: DayBookColors.textPrimary,
                  side: const BorderSide(color: DayBookColors.bodyBorder),
                  textStyle: DayBookStyles.button.copyWith(fontSize: 14),
                ),
                child: Text(readOnly ? 'Close' : 'Cancel'),
              ),
              if (!readOnly) ...[
                if (showMismatchAction) ...[
                  OutlinedButton.icon(
                    onPressed: mismatchExpenseAmount == null || _saving
                        ? null
                        : () => _openMismatchExpense(mismatchExpenseAmount),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      foregroundColor: DayBookColors.goldMetal,
                      disabledForegroundColor: DayBookColors.goldMetal,
                      side: const BorderSide(
                          color: DayBookColors.brandGoldBorder),
                      textStyle: DayBookStyles.button.copyWith(fontSize: 14),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Mismatch Transfer'),
                  ),
                ],
                FilledButton.icon(
                  onPressed: _saving || allocationConflict ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    backgroundColor: DayBookColors.brandGold,
                    foregroundColor: DayBookColors.textPrimary,
                    disabledBackgroundColor: DayBookColors.brandGoldSoft,
                    disabledForegroundColor: DayBookColors.goldMetal,
                    side:
                        const BorderSide(color: DayBookColors.brandGoldBorder),
                    elevation: 2,
                    textStyle: DayBookStyles.button.copyWith(fontSize: 14),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Save & Verify'),
                ),
              ],
            ]),
      );
}
