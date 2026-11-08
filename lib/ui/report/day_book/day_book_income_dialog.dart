import 'package:flutter/material.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../repositories/reports/day_book_manual_income_repository.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_form_visuals.dart';
import 'day_book_income_category_field.dart';
import 'day_book_income_dialog_chrome.dart';

typedef SaveDayBookIncome = Future<bool> Function({
  required double amount,
  required String category,
  required PaymentMode paymentMode,
  int? bankAccountId,
  String? customLabel,
});

class DayBookIncomeDialog extends StatefulWidget {
  const DayBookIncomeDialog({
    super.key,
    required this.date,
    required this.bankAccounts,
    required this.onSave,
  });

  final DateTime date;
  final List<ManualIncomeBankAccount> bankAccounts;
  final SaveDayBookIncome onSave;

  @override
  State<DayBookIncomeDialog> createState() => _DayBookIncomeDialogState();
}

class _DayBookIncomeDialogState extends State<DayBookIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _categoryText = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.cash;
  int? _bankAccountId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _categoryText.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final enteredCategory = _categoryText.text.trim();
    final category = switch (enteredCategory.toLowerCase()) {
      'gold repair' => IncomeCategory.goldRepairIncome,
      'silver repair' => IncomeCategory.silverRepairIncome,
      _ => IncomeCategory.otherIncome,
    };
    if (_paymentMode == PaymentMode.bank && _bankAccountId == null) {
      setState(() => _error = 'Select an active bank account.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave(
        amount: double.parse(_amount.text.trim().replaceAll(',', '')),
        category: category.dbValue,
        paymentMode: _paymentMode,
        bankAccountId: _paymentMode == PaymentMode.bank ? _bankAccountId : null,
        customLabel: category.requiresCustomLabel ? enteredCategory : null,
      );
      if (!mounted) return;
      if (saved) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error =
            'Income could not be saved. Check the selected day and bank account.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Income could not be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => DayBookFormVisuals.themed(
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
              maxWidth: 620,
              maxHeight: MediaQuery.sizeOf(context).height - 36,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DayBookIncomeHeader(
                onClose:
                    _saving ? null : () => Navigator.of(context).pop(false),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DayBookIncomeSection(
                          icon: Icons.receipt_long_outlined,
                          title: 'Income Details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _amount,
                                autofocus: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: DayBookStyles.valueLarge
                                    .copyWith(color: DayBookColors.textPrimary),
                                decoration: DayBookFormVisuals.field(
                                    'Amount', Icons.currency_rupee_rounded),
                                validator: _validateAmount,
                              ),
                              const SizedBox(height: 11),
                              DayBookIncomeCategoryField(
                                controller: _categoryText,
                                enabled: !_saving,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        DayBookIncomeSection(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Payment Method',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<PaymentMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: PaymentMode.cash,
                                    icon: Icon(Icons.payments_outlined),
                                    label: Text('Cash'),
                                  ),
                                  ButtonSegment(
                                    value: PaymentMode.bank,
                                    icon: Icon(Icons.account_balance_outlined),
                                    label: Text('Bank'),
                                  ),
                                ],
                                selected: {_paymentMode},
                                onSelectionChanged: _saving
                                    ? null
                                    : (selection) => setState(() {
                                          _paymentMode = selection.first;
                                          _bankAccountId = null;
                                        }),
                              ),
                              if (_paymentMode == PaymentMode.bank) ...[
                                const SizedBox(height: 11),
                                if (widget.bankAccounts.isEmpty)
                                  Text(
                                    'Add an active bank account in Bank Book before recording bank income.',
                                    style: DayBookStyles.labelStrong.copyWith(
                                        color: DayBookColors.negative),
                                  )
                                else
                                  DropdownButtonFormField<int>(
                                    initialValue: _bankAccountId,
                                    decoration: DayBookFormVisuals.field(
                                        'Bank account',
                                        Icons.account_balance_outlined),
                                    items: widget.bankAccounts
                                        .map((account) => DropdownMenuItem(
                                              value: account.id,
                                              child: Text(account.label,
                                                  style: DayBookStyles
                                                      .labelStrong),
                                            ))
                                        .toList(),
                                    onChanged: _saving
                                        ? null
                                        : (accountId) => setState(
                                            () => _bankAccountId = accountId),
                                    validator: (value) => value == null
                                        ? 'Select a bank account.'
                                        : null,
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        DayBookFormVisuals.contextStrip(date: widget.date),
                        const SizedBox(height: 10),
                        DayBookFormVisuals.note(
                          'For income without an invoice. Invoice sales, dues, advances and Girvi receipts are recorded automatically. This entry records money only; it does not change stock.',
                        ),
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
              DayBookIncomeFooter(
                saving: _saving,
                onCancel:
                    _saving ? null : () => Navigator.of(context).pop(false),
                onSave: _saving ? null : _save,
              ),
            ]),
          ),
        ),
      );

  String? _validateAmount(String? value) {
    final amount = double.tryParse((value ?? '').trim().replaceAll(',', ''));
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
      return 'Enter a valid amount with up to two decimals.';
    }
    return null;
  }
}
