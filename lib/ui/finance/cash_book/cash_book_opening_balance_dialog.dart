import 'package:flutter/material.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

Future<void> showCashBookOpeningBalanceDialog(
  BuildContext context,
  CashBookController ctrl,
) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _OpeningBalanceDialog(ctrl: ctrl),
  );
  if (saved == true && context.mounted) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.success,
      message: CashBookStrings.openingBalanceSaved,
    );
  }
}

class _OpeningBalanceDialog extends StatefulWidget {
  const _OpeningBalanceDialog({required this.ctrl});

  final CashBookController ctrl;

  @override
  State<_OpeningBalanceDialog> createState() => _OpeningBalanceDialogState();
}

class _OpeningBalanceDialogState extends State<_OpeningBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl = TextEditingController(
    text: widget.ctrl.summary.openingBalance.toStringAsFixed(2),
  );
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', ''));
    final saved = await widget.ctrl.updateOpeningBalance(amount);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _saveError = 'Opening balance could not be saved. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CashBookColors.bodyPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        CashBookStrings.editOpeningBalance,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CashBookColors.textDark),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: CashBookStyles.inputText,
              decoration: InputDecoration(
                labelText: CashBookStrings.openingBalance,
                prefixText: 'Rs ',
                filled: true,
                fillColor: CashBookColors.summaryChipBg,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (value) {
                final amount =
                    double.tryParse((value ?? '').trim().replaceAll(',', ''));
                if (amount == null || !amount.isFinite || amount < 0) {
                  return 'Enter a valid amount of zero or more.';
                }
                return null;
              },
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 10),
              Text(
                _saveError!,
                style: const TextStyle(
                  color: CashBookColors.expenseChip,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text(CashBookStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: CashBookColors.brandGold,
            foregroundColor: CashBookColors.textDark,
          ),
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
