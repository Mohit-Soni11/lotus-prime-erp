import 'package:flutter/material.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_form_visuals.dart';

typedef SaveDayBookCashIncome = Future<bool> Function({
  required double amount,
  required String category,
  required String description,
  String? customLabel,
  String? partyName,
});

class DayBookCashIncomeDialog extends StatefulWidget {
  const DayBookCashIncomeDialog({
    super.key,
    required this.date,
    required this.onSave,
  });

  final DateTime date;
  final SaveDayBookCashIncome onSave;

  @override
  State<DayBookCashIncomeDialog> createState() =>
      _DayBookCashIncomeDialogState();
}

class _DayBookCashIncomeDialogState extends State<DayBookCashIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _customLabel = TextEditingController();
  final _partyName = TextEditingController();
  final _description = TextEditingController();
  IncomeCategory _category = IncomeCategory.miscIncome;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _customLabel.dispose();
    _partyName.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final amount = double.parse(_amount.text.trim().replaceAll(',', ''));
    try {
      final saved = await widget.onSave(
        amount: amount,
        category: _category.dbValue,
        description: _description.text.trim(),
        customLabel:
            _category.requiresCustomLabel ? _customLabel.text.trim() : null,
        partyName:
            _partyName.text.trim().isEmpty ? null : _partyName.text.trim(),
      );
      if (!mounted) return;
      if (saved) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error =
            'Cash income could not be saved. Check whether this day is closed.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Cash income could not be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => DayBookFormVisuals.themed(
          child: AlertDialog(
        backgroundColor: DayBookColors.bodyPanel,
        surfaceTintColor: Colors.transparent,
        shape: DayBookFormVisuals.dialogShape,
        title: DayBookFormVisuals.heading(
          title: 'Add Cash Income',
          subtitle: 'Extra cash received today',
          icon: Icons.account_balance_wallet_outlined,
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DayBookFormVisuals.contextStrip(
                    date: widget.date,
                    mode: 'Cash',
                  ),
                  const SizedBox(height: 12),
                  DayBookFormVisuals.note(
                    'Use this for extra income only. Sales, dues, advances and Girvi receipts appear automatically.',
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _amount,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: DayBookStyles.valueLarge,
                    decoration: DayBookFormVisuals.field(
                      'Amount',
                      Icons.currency_rupee_rounded,
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                          (value ?? '').trim().replaceAll(',', ''));
                      if (amount == null ||
                          !amount.isFinite ||
                          amount <= 0 ||
                          (amount * 100 - (amount * 100).round()).abs() >
                              0.000001) {
                        return 'Enter a valid amount with up to two decimals.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<IncomeCategory>(
                    initialValue: _category,
                    style: DayBookStyles.labelStrong,
                    decoration: DayBookFormVisuals.field(
                      'Income category',
                      Icons.category_outlined,
                    ),
                    items: const [
                      IncomeCategory.miscIncome,
                      IncomeCategory.otherIncome,
                    ]
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.displayLabel,
                                  style: DayBookStyles.labelStrong),
                            ))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (category) => setState(() {
                              _category = category ?? IncomeCategory.miscIncome;
                            }),
                  ),
                  if (_category.requiresCustomLabel) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customLabel,
                      style: DayBookStyles.labelStrong,
                      decoration: DayBookFormVisuals.field(
                        'Category name',
                        Icons.label_outline_rounded,
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Enter a category name.'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _partyName,
                    style: DayBookStyles.labelStrong,
                    decoration: DayBookFormVisuals.field(
                      'Received from (optional)',
                      Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 2,
                    style: DayBookStyles.labelStrong,
                    decoration: DayBookFormVisuals.field(
                      'Reason',
                      Icons.notes_rounded,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter the reason for this receipt.'
                        : null,
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
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save Income'),
          ),
        ],
      ));
}
