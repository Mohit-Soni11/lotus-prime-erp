// =============================================================================
// FILE        : cash_book_entry_dialog.dart
// MODULE      : Accounts / Cash Book
// LAYER       : UI
// DESCRIPTION : Slide-up dialog for adding income/expense entry.
//               v2 â€” Custom label field shown when 'Other' is selected.
//               v2 â€” Girvi Given / Girvi Released categories supported.
//               v2 â€” Validation: 'Other' requires custom label before save.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

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

class _OtherLabelField extends StatelessWidget {
  final CashBookController ctrl;
  const _OtherLabelField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: CashBookColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('Specify Category *',
                style: CashBookStyles.labelSecondary.copyWith(
                  color: CashBookColors.brandGold,
                )),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl.customLabelCtrl,
            style: CashBookStyles.inputText,
            decoration: InputDecoration(
              hintText: 'e.g. Temple Donation, Tool Purchase, Medical',
              hintStyle: CashBookStyles.labelMuted,
              filled: true,
              fillColor: CashBookColors.brandGoldLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CashBookColors.brandGold),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: CashBookColors.brandGold.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: CashBookColors.brandGold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Type Toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TypeToggle extends StatelessWidget {
  final CashBookController ctrl;
  const _TypeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: CashBookColors.summaryChipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashBookColors.bodyBorder),
      ),
      child: Row(
        children: CashTransactionType.values.map((type) {
          final isActive = ctrl.entryType == type;
          final isIncome = type == CashTransactionType.income;
          final color = isIncome
              ? CashBookColors.incomeAccent
              : CashBookColors.expenseAccent;

          return Expanded(
            child: GestureDetector(
              onTap: () => ctrl.setEntryType(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: isActive
                      ? Border.all(color: color.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isIncome ? CashBookIcons.income : CashBookIcons.expense,
                      size: 14,
                      color: isActive ? color : CashBookColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isIncome ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? color : CashBookColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// â”€â”€ Category Dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CategoryDropdown extends StatelessWidget {
  final CashBookController ctrl;
  const _CategoryDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CashBookColors.searchBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashBookColors.searchBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ctrl.entryCategory,
          isExpanded: true,
          style: CashBookStyles.labelPrimary,
          dropdownColor: CashBookColors.bodyPanel,
          items: ctrl.availableCategories.map((dbVal) {
            final label = ctrl.categoryLabel(dbVal, ctrl.entryType);
            final isOther = dbVal == IncomeCategory.otherIncome.dbValue ||
                dbVal == ExpenseCategory.otherExpense.dbValue;

            return DropdownMenuItem(
              value: dbVal,
              child: Row(children: [
                if (isOther) ...[
                  const Icon(Icons.edit_note_rounded,
                      size: 14, color: CashBookColors.brandGold),
                  const SizedBox(width: 6),
                ],
                Text(label, style: CashBookStyles.labelPrimary),
              ]),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) ctrl.setEntryCategory(val);
          },
        ),
      ),
    );
  }
}

// â”€â”€ Payment Mode Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PaymentModeRow extends StatelessWidget {
  final CashBookController ctrl;
  const _PaymentModeRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMode.values.map((mode) {
        final isActive = ctrl.entryMode == mode;
        final icon = switch (mode) {
          PaymentMode.cash => CashBookIcons.cash,
          PaymentMode.upi => CashBookIcons.upi,
          PaymentMode.card => CashBookIcons.card,
          PaymentMode.bank => CashBookIcons.bank,
          PaymentMode.cheque => CashBookIcons.cheque,
        };
        return GestureDetector(
          onTap: () => ctrl.setEntryMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? CashBookColors.brandGoldLight
                  : CashBookColors.summaryChipBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? CashBookColors.brandGold.withValues(alpha: 0.5)
                    : CashBookColors.bodyBorder,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 14,
                  color: isActive
                      ? CashBookColors.brandGold
                      : CashBookColors.textSecondary),
              const SizedBox(width: 6),
              Text(mode.displayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? CashBookColors.brandGold
                        : CashBookColors.textSecondary,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// â”€â”€ Date Selector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DateSelector extends StatelessWidget {
  final CashBookController ctrl;
  const _DateSelector({required this.ctrl});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: ctrl.entryDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (_, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: CashBookColors.brandGold,
                onPrimary: Color(0xFF111827),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) ctrl.setEntryDate(picked);
      },
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: CashBookColors.searchBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CashBookColors.searchBorder),
        ),
        child: Row(children: [
          const Icon(CashBookIcons.calendar,
              size: 16, color: CashBookColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            DateFormat('d MMMM yyyy').format(ctrl.entryDate),
            style: CashBookStyles.labelPrimary,
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down_rounded,
              color: CashBookColors.textMuted),
        ]),
      ),
    );
  }
}

// â”€â”€ Save Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SaveButton extends StatelessWidget {
  final CashBookController ctrl;
  final BuildContext context;
  const _SaveButton({required this.ctrl, required this.context});

  @override
  Widget build(BuildContext ctx) {
    // Disable if 'Other' selected but no custom label typed
    final isDisabled =
        ctrl.entryNeedsCustomLabel && ctrl.customLabelCtrl.text.trim().isEmpty;

    return GestureDetector(
      onTap: (ctrl.isSaving || isDisabled)
          ? null
          : () async {
              final ok = await ctrl.saveEntry();
              if (ok && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: const Text('Entry saved successfully',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  backgroundColor: CashBookColors.incomeAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        decoration: BoxDecoration(
          color: (ctrl.isSaving || isDisabled)
              ? CashBookColors.brandGold.withValues(alpha: 0.5)
              : CashBookColors.brandGold,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: ctrl.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF111827)),
                )
              : const Text(
                  CashBookStrings.saveEntry,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
        ),
      ),
    );
  }
}

// â”€â”€ Shared Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: CashBookStyles.labelSecondary);
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final bool autofocus;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefix,
    this.autofocus = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: maxLines,
      style: CashBookStyles.inputText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: CashBookStyles.labelMuted,
        prefix: prefix,
        filled: true,
        fillColor: CashBookColors.searchBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CashBookColors.searchBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CashBookColors.searchBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: CashBookColors.brandGold, width: 1.5),
        ),
      ),
    );
  }
}
