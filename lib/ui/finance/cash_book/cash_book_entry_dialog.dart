import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'cash_book_entry_fields.dart';
part 'cash_book_entry_payment.dart';
part 'cash_book_entry_shared.dart';

class CashBookEntryDialog extends StatefulWidget {
  final CashBookController ctrl;
  const CashBookEntryDialog({super.key, required this.ctrl});

  @override
  State<CashBookEntryDialog> createState() => _CashBookEntryDialogState();
}

class _CashBookEntryDialogState extends State<CashBookEntryDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    widget.ctrl.resetEntryForm();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: CashBookColors.bodyPanel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CashBookColors.cardBorderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: widget.ctrl,
              builder: (_, __) => _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ctrl = widget.ctrl;
    final isIncome = ctrl.entryType == CashTransactionType.income;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isIncome
                    ? CashBookColors.incomeBg
                    : CashBookColors.expenseBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? CashBookIcons.income : CashBookIcons.expense,
                size: 18,
                color: isIncome
                    ? CashBookColors.incomeAccent
                    : CashBookColors.expenseAccent,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isIncome ? CashBookStrings.addIncome : CashBookStrings.addExpense,
              style: CashBookStyles.labelPrimary.copyWith(fontSize: 16),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: CashBookColors.summaryChipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: CashBookColors.textSecondary),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // â”€â”€ Type Toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _TypeToggle(ctrl: ctrl),

          const SizedBox(height: 16),

          // â”€â”€ Amount â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _FieldLabel(CashBookStrings.amount),
          const SizedBox(height: 6),
          _InputField(
            controller: ctrl.amountCtrl,
            hint: CashBookStrings.amountHint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: Text('Rs ', style: CashBookStyles.amountMedium),
            autofocus: true,
          ),

          const SizedBox(height: 14),

          // â”€â”€ Category â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _FieldLabel(CashBookStrings.category),
          const SizedBox(height: 6),
          _CategoryDropdown(ctrl: ctrl),

          // â”€â”€ Custom Label (shown only when 'Other' is selected) â”€â”€â”€â”€â”€â”€â”€â”€
          if (ctrl.entryNeedsCustomLabel) ...[
            const SizedBox(height: 10),
            _OtherLabelField(ctrl: ctrl),
          ],

          const SizedBox(height: 14),

          // â”€â”€ Payment Mode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _FieldLabel(CashBookStrings.paymentMode),
          const SizedBox(height: 6),
          _PaymentModeRow(ctrl: ctrl),

          const SizedBox(height: 14),

          // â”€â”€ Date â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _FieldLabel(CashBookStrings.date),
          const SizedBox(height: 6),
          _DateSelector(ctrl: ctrl),

          const SizedBox(height: 14),

          // â”€â”€ Party Name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _FieldLabel(CashBookStrings.partyName),
          const SizedBox(height: 6),
          _InputField(
            controller: ctrl.partyNameCtrl,
            hint: CashBookStrings.partyHint,
          ),

          const SizedBox(height: 14),

          // â”€â”€ Description â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _FieldLabel(CashBookStrings.description),
          const SizedBox(height: 6),
          _InputField(
            controller: ctrl.descriptionCtrl,
            hint: CashBookStrings.descriptionHint,
            maxLines: 2,
          ),

          const SizedBox(height: 24),

          // â”€â”€ Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: CashBookColors.bodyBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  foregroundColor: CashBookColors.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(CashBookStrings.cancel,
                    style: CashBookStyles.labelSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _SaveButton(ctrl: ctrl, context: context),
            ),
          ]),
        ],
      ),
    );
  }
}

// â”€â”€ Other Label Field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
