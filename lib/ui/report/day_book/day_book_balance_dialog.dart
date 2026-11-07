import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/reports/day_book/day_book_balance_verification.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_balance_summary.dart';
import 'day_book_form_visuals.dart';

typedef SaveDayBookBalance = Future<DayBookBalanceVerification> Function({
  required double actualCash,
  required double actualBank,
  ExpenseCategory? cashExpenseCategory,
  String? cashReason,
  String? bankReason,
});

class DayBookBalanceDialog extends StatefulWidget {
  const DayBookBalanceDialog({
    super.key,
    required this.date,
    required this.expectedCash,
    required this.expectedBank,
    required this.onSave,
    this.existing,
    this.bankAccountConfigured = true,
    this.onOpenBankBook,
  });

  final DateTime date;
  final double expectedCash;
  final double expectedBank;
  final DayBookBalanceVerification? existing;
  final SaveDayBookBalance onSave;
  final bool bankAccountConfigured;
  final VoidCallback? onOpenBankBook;

  @override
  State<DayBookBalanceDialog> createState() => _DayBookBalanceDialogState();
}

class _DayBookBalanceDialogState extends State<DayBookBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _cash = TextEditingController(
      text: widget.existing?.actualCash.toStringAsFixed(2) ?? '');
  late final _bank = TextEditingController(
      text: widget.existing?.actualBank.toStringAsFixed(2) ?? '');
  late final _cashReason =
      TextEditingController(text: widget.existing?.cashReason ?? '');
  late final _bankReason =
      TextEditingController(text: widget.existing?.bankReason ?? '');
  ExpenseCategory? _expenseCategory;
  bool _saving = false;
  String? _error;

  static const _expenseCategories = [
    ExpenseCategory.shopRent,
    ExpenseCategory.staffSalary,
    ExpenseCategory.electricity,
    ExpenseCategory.maintenance,
    ExpenseCategory.advertising,
    ExpenseCategory.transport,
    ExpenseCategory.governmentFees,
    ExpenseCategory.miscExpense,
    ExpenseCategory.otherExpense,
  ];

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
    _cashReason.dispose();
    _bankReason.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController input) =>
      double.tryParse(input.text.trim().replaceAll(',', ''));
  double? get _cashVariance =>
      _parse(_cash) == null ? null : _parse(_cash)! - widget.expectedCash;
  double? get _bankVariance =>
      _parse(_bank) == null ? null : _parse(_bank)! - widget.expectedBank;
  bool get _cashMismatch => (_cashVariance?.abs() ?? 0) >= 0.01;
  bool get _bankMismatch => (_bankVariance?.abs() ?? 0) >= 0.01;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        actualCash: _parse(_cash)!,
        actualBank: _parse(_bank)!,
        cashExpenseCategory: _cashVariance! < -0.005 ? _expenseCategory : null,
        cashReason: _cashMismatch ? _cashReason.text.trim() : null,
        bankReason: _bankMismatch ? _bankReason.text.trim() : null,
      );
      if (mounted) Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final readOnly = existing != null;
    return DayBookFormVisuals.themed(
        child: AlertDialog(
      backgroundColor: DayBookColors.bodyPanel,
      surfaceTintColor: Colors.transparent,
      shape: DayBookFormVisuals.dialogShape,
      title: DayBookFormVisuals.heading(
        title: readOnly ? 'Balance Verification' : 'Set Balance',
        subtitle: 'Check today’s opening cash and bank',
        icon: Icons.fact_check_outlined,
      ),
      content: SizedBox(
        width: 530,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DayBookFormVisuals.contextStrip(date: widget.date),
                if (readOnly) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Saved ${DateFormat('d MMM yyyy, h:mm a').format(existing.verifiedAt)}'
                    '${existing.bankNeedsReview ? ' · Bank reconciliation pending' : existing.cashAdjusted ? ' · Cash adjusted' : ' · Verified'}',
                    style: DayBookStyles.labelStrong.copyWith(
                      color: existing.bankNeedsReview
                          ? DayBookColors.warning
                          : DayBookColors.positive,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (!readOnly) ...[
                  DayBookFormVisuals.note(
                    'Enter the counted cash and current bank balance. Explain any difference before saving.',
                  ),
                  const SizedBox(height: 14),
                ],
                if (!widget.bankAccountConfigured) ...[
                  Text(
                    'No bank account is configured in Bank Book. Add one before verifying a non-zero bank balance.',
                    style: DayBookStyles.labelStrong
                        .copyWith(color: DayBookColors.warning),
                  ),
                  const SizedBox(height: 12),
                ],
                _BalanceLine(
                  label: 'Counter Cash',
                  expected:
                      readOnly ? existing.expectedCash : widget.expectedCash,
                  input: _cash,
                  readOnly: readOnly,
                  keyName: 'actual-cash',
                  difference: readOnly ? existing.cashVariance : _cashVariance,
                  allowNegative: false,
                  bankAccountConfigured: widget.bankAccountConfigured,
                ),
                const SizedBox(height: 14),
                _BalanceLine(
                  label: 'Bank Balance',
                  expected:
                      readOnly ? existing.expectedBank : widget.expectedBank,
                  input: _bank,
                  readOnly: readOnly,
                  keyName: 'actual-bank',
                  difference: readOnly ? existing.bankVariance : _bankVariance,
                  allowNegative: true,
                  bankAccountConfigured: widget.bankAccountConfigured,
                ),
                const SizedBox(height: 14),
                DayBookBalanceSummary(
                  expectedCash:
                      readOnly ? existing.expectedCash : widget.expectedCash,
                  expectedBank:
                      readOnly ? existing.expectedBank : widget.expectedBank,
                  actualCash: readOnly ? existing.actualCash : _parse(_cash),
                  actualBank: readOnly ? existing.actualBank : _parse(_bank),
                ),
                if (readOnly
                    ? existing.cashVariance.abs() >= 0.01
                    : _cashMismatch) ...[
                  const SizedBox(height: 16),
                  Text(
                    (readOnly ? existing.cashVariance : _cashVariance!) < 0
                        ? 'Cash shortage · record the expense type and reason'
                        : 'Cash surplus · record the reason',
                    style: DayBookStyles.labelStrong,
                  ),
                  if ((readOnly ? existing.cashVariance : _cashVariance!) < 0 &&
                      !readOnly) ...[
                    const SizedBox(height: 9),
                    DropdownButtonFormField<ExpenseCategory>(
                      key: const ValueKey('cash-variance-category'),
                      initialValue: _expenseCategory,
                      style: DayBookStyles.labelStrong,
                      decoration: DayBookFormVisuals.field(
                        'Expense type',
                        Icons.receipt_long_outlined,
                      ),
                      items: _expenseCategories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.displayLabel,
                                    style: DayBookStyles.labelStrong),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _expenseCategory = value),
                      validator: (value) =>
                          value == null ? 'Select the expense type.' : null,
                    ),
                  ],
                  if (readOnly && existing.cashCategory != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Expense type: ${resolveDisplayLabel(type: CashTransactionType.expense, categoryDbValue: existing.cashCategory!)}',
                      style: DayBookStyles.labelStrong,
                    ),
                  ],
                  const SizedBox(height: 9),
                  TextFormField(
                    key: const ValueKey('cash-variance-reason'),
                    controller: _cashReason,
                    readOnly: readOnly,
                    maxLines: 2,
                    style: DayBookStyles.labelStrong,
                    decoration: DayBookFormVisuals.field(
                      'Cash difference reason',
                      Icons.notes_rounded,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Explain the cash difference.'
                        : null,
                  ),
                ],
                if (readOnly ? existing.bankNeedsReview : _bankMismatch) ...[
                  const SizedBox(height: 16),
                  Text('Bank difference · reconciliation pending',
                      style: DayBookStyles.labelStrong
                          .copyWith(color: DayBookColors.warning)),
                  const SizedBox(height: 5),
                  Text(
                    'Record the reason. Bank charges or missing transactions should be posted from their source after confirmation.',
                    style: DayBookStyles.label,
                  ),
                  const SizedBox(height: 9),
                  TextFormField(
                    key: const ValueKey('bank-variance-reason'),
                    controller: _bankReason,
                    readOnly: readOnly,
                    maxLines: 2,
                    style: DayBookStyles.labelStrong,
                    decoration: DayBookFormVisuals.field(
                      'Bank difference reason',
                      Icons.notes_rounded,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Explain the bank difference.'
                        : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: DayBookStyles.labelStrong
                          .copyWith(color: DayBookColors.negative)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!readOnly &&
            !widget.bankAccountConfigured &&
            widget.onOpenBankBook != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(false);
              widget.onOpenBankBook!();
            },
            icon: const Icon(Icons.account_balance_outlined, size: 18),
            label: const Text('Open Bank Book'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(readOnly ? 'Close' : 'Cancel'),
        ),
        if (!readOnly)
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save Verification'),
          ),
      ],
    ));
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({
    required this.label,
    required this.expected,
    required this.input,
    required this.readOnly,
    required this.keyName,
    required this.difference,
    required this.allowNegative,
    required this.bankAccountConfigured,
  });

  final String label;
  final double expected;
  final TextEditingController input;
  final bool readOnly;
  final String keyName;
  final double? difference;
  final bool allowNegative;
  final bool bankAccountConfigured;

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DayBookStyles.softPanel(
        color: DayBookColors.bodySubtle,
        borderColor: DayBookColors.bodyBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(
                label == 'Counter Cash'
                    ? Icons.payments_outlined
                    : Icons.account_balance_outlined,
                color: DayBookColors.goldMetal,
                size: 19),
            const SizedBox(width: 8),
            Text(label,
                style: DayBookStyles.sectionTitle.copyWith(fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          Text('Expected opening', style: DayBookStyles.label),
          Text(money.format(expected), style: DayBookStyles.valueLarge),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey(keyName),
            controller: input,
            readOnly: readOnly,
            keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: true),
            style: DayBookStyles.value,
            decoration: DayBookFormVisuals.field(
              label == 'Counter Cash'
                  ? 'Physical cash counted'
                  : 'Actual bank balance',
              label == 'Counter Cash'
                  ? Icons.calculate_outlined
                  : Icons.account_balance_wallet_outlined,
              prefixText: '₹ ',
            ),
            validator: (value) {
              final amount =
                  double.tryParse((value ?? '').trim().replaceAll(',', ''));
              if (amount == null ||
                  !amount.isFinite ||
                  (!allowNegative && amount < 0) ||
                  (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
                return 'Enter a valid amount with up to two decimals.';
              }
              if (label == 'Bank Balance' &&
                  !bankAccountConfigured &&
                  amount.abs() >= 0.01) {
                return 'Add a bank account in Bank Book first.';
              }
              return null;
            },
          ),
          if (difference != null && difference!.abs() >= 0.01) ...[
            const SizedBox(height: 6),
            Text('Difference  ${money.format(difference)}',
                style: DayBookStyles.labelStrong.copyWith(
                  color: difference! < 0
                      ? DayBookColors.negative
                      : DayBookColors.warning,
                )),
          ] else if (difference != null) ...[
            const SizedBox(height: 6),
            Text('Matched',
                style: DayBookStyles.labelStrong
                    .copyWith(color: DayBookColors.positive)),
          ],
        ],
      ),
    );
  }
}
