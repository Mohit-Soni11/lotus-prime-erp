// =============================================================================
// FILE        : expense_entry_dialog.dart
// MODULE      : Expense Entry
// LAYER       : UI
// DESCRIPTION : Slide-up animated dialog for adding a new expense entry.
//               ✅ All 12 expense categories with dropdown.
//               ✅ Custom label field for OTHER_EXPENSE category.
//               ✅ Payment mode selector chips.
//               ✅ Date picker (gold themed).
//               ✅ Save button disables until required fields filled.
//               ✅ ListenableBuilder — zero setState inside dialog body.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/finance/expense/expense_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/finance/expense/expense_theme.dart';

class ExpenseEntryDialog extends StatefulWidget {
  final ExpenseController ctrl;
  const ExpenseEntryDialog({super.key, required this.ctrl});

  @override
  State<ExpenseEntryDialog> createState() => _ExpenseEntryDialogState();
}

class _ExpenseEntryDialogState extends State<ExpenseEntryDialog>
    with SingleTickerProviderStateMixin {

  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    widget.ctrl.resetEntryForm();

    _slideCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end:   Offset.zero,
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
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 40),
          child: Container(
            width:      540,
            decoration: BoxDecoration(
              color:        ExpenseColors.bodyPanel,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: ExpenseColors.cardBorderLight),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.15),
                  blurRadius: 32,
                  offset:     const Offset(0, 12),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: widget.ctrl,
              builder:    (_, __) => _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ctrl = widget.ctrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize:       MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Dialog Header ─────────────────────────────────────────────
          Row(children: [
            Container(
              width:  40, height: 40,
              decoration: BoxDecoration(
                color:        ExpenseColors.moduleAccentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                ExpenseIcons.expense,
                size:  20,
                color: ExpenseColors.moduleAccent,
              ),
            ),
            const SizedBox(width: 12),
            Text(ExpenseStrings.addExpense,
                style: ExpenseStyles.labelPrimary.copyWith(fontSize: 16)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color:        ExpenseColors.summaryChipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(ExpenseIcons.close,
                    size: 16, color: ExpenseColors.textSecondary),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // ── Amount ────────────────────────────────────────────────────
          _FieldLabel(ExpenseStrings.amount),
          const SizedBox(height: 6),
          _AmountField(ctrl: ctrl),

          const SizedBox(height: 16),

          // ── Category ──────────────────────────────────────────────────
          _FieldLabel(ExpenseStrings.category),
          const SizedBox(height: 6),
          _CategoryDropdown(ctrl: ctrl),

          // ── Custom Label (only for OTHER_EXPENSE) ─────────────────────
          if (ctrl.entryNeedsCustomLabel) ...[
            const SizedBox(height: 10),
            _CustomLabelField(ctrl: ctrl),
          ],

          const SizedBox(height: 16),

          // ── Payment Mode ──────────────────────────────────────────────
          _FieldLabel(ExpenseStrings.paymentMode),
          const SizedBox(height: 8),
          _PaymentModeChips(ctrl: ctrl),

          const SizedBox(height: 16),

          // ── Date ──────────────────────────────────────────────────────
          _FieldLabel(ExpenseStrings.date),
          const SizedBox(height: 6),
          _DateSelector(ctrl: ctrl),

          const SizedBox(height: 16),

          // ── Vendor / Party Name ───────────────────────────────────────
          _FieldLabel(ExpenseStrings.partyName),
          const SizedBox(height: 6),
          _InputField(
            controller: ctrl.partyNameCtrl,
            hint:       ExpenseStrings.partyHint,
          ),

          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────────────────
          _FieldLabel(ExpenseStrings.description),
          const SizedBox(height: 6),
          _InputField(
            controller: ctrl.descriptionCtrl,
            hint:       ExpenseStrings.descriptionHint,
            maxLines:   2,
          ),

          const SizedBox(height: 24),

          // ── Action Buttons ────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:         const EdgeInsets.symmetric(vertical: 14),
                  side:            const BorderSide(
                      color: ExpenseColors.bodyBorder),
                  shape:           RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  foregroundColor: ExpenseColors.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(ExpenseStrings.cancel,
                    style: ExpenseStyles.labelSecondary),
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

// ── Amount Field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final ExpenseController ctrl;
  const _AmountField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   ctrl.amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus:    true,
      style:        ExpenseStyles.amountInput,
      decoration: InputDecoration(
        hintText:  ExpenseStrings.amountHint,
        hintStyle: ExpenseStyles.amountInput.copyWith(
            color: ExpenseColors.textMuted),
        prefix: Text('₹  ',
            style: ExpenseStyles.amountInput.copyWith(
                color: ExpenseColors.moduleAccent)),
        filled:      true,
        fillColor:   ExpenseColors.moduleAccentLight,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: ExpenseColors.moduleAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: ExpenseColors.moduleAccent.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: ExpenseColors.moduleAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Category Dropdown ─────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final ExpenseController ctrl;
  const _CategoryDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color:        ExpenseColors.searchBg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: ExpenseColors.searchBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExpenseCategory>(
          value:        ctrl.entryCategory,
          isExpanded:   true,
          style:        ExpenseStyles.labelPrimary,
          dropdownColor: ExpenseColors.bodyPanel,
          items: ExpenseCategory.values.map((cat) {
            final isOther = cat == ExpenseCategory.otherExpense;
            return DropdownMenuItem(
              value: cat,
              child: Row(children: [
                if (isOther) ...[
                  const Icon(ExpenseIcons.edit,
                      size: 14, color: ExpenseColors.moduleAccent),
                  const SizedBox(width: 6),
                ],
                Text(cat.displayLabel,
                    style: ExpenseStyles.labelPrimary),
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

// ── Custom Label Field ────────────────────────────────────────────────────────

class _CustomLabelField extends StatelessWidget {
  final ExpenseController ctrl;
  const _CustomLabelField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve:    Curves.easeOutCubic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4, height: 4,
              decoration: const BoxDecoration(
                color: ExpenseColors.moduleAccent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Specify Category *',
                style: ExpenseStyles.labelSecondary.copyWith(
                  color: ExpenseColors.moduleAccent)),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl.customLabelCtrl,
            style:      ExpenseStyles.inputText,
            decoration: InputDecoration(
              hintText:  'e.g. Temple Donation, Tool Purchase, Medical…',
              hintStyle: ExpenseStyles.labelMuted,
              filled:    true,
              fillColor: ExpenseColors.moduleAccentLight,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: ExpenseColors.moduleAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: ExpenseColors.moduleAccent.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: ExpenseColors.moduleAccent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Mode Chips ────────────────────────────────────────────────────────

class _PaymentModeChips extends StatelessWidget {
  final ExpenseController ctrl;
  const _PaymentModeChips({required this.ctrl});

  IconData _modeIcon(PaymentMode mode) => switch (mode) {
    PaymentMode.cash   => ExpenseIcons.cash,
    PaymentMode.upi    => ExpenseIcons.upi,
    PaymentMode.card   => ExpenseIcons.card,
    PaymentMode.bank   => ExpenseIcons.bank,
    PaymentMode.cheque => ExpenseIcons.cheque,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: PaymentMode.values.map((mode) {
        final isActive = ctrl.entryMode == mode;
        return GestureDetector(
          onTap: () => ctrl.setEntryMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? ExpenseColors.moduleAccentLight
                  : ExpenseColors.summaryChipBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? ExpenseColors.moduleAccent.withOpacity(0.5)
                    : ExpenseColors.bodyBorder,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_modeIcon(mode),
                  size: 14,
                  color: isActive
                      ? ExpenseColors.moduleAccent
                      : ExpenseColors.textSecondary),
              const SizedBox(width: 6),
              Text(mode.displayLabel,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? ExpenseColors.moduleAccent
                        : ExpenseColors.textSecondary,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Date Selector ─────────────────────────────────────────────────────────────

class _DateSelector extends StatelessWidget {
  final ExpenseController ctrl;
  const _DateSelector({required this.ctrl});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context:     ctx,
          initialDate: ctrl.entryDate,
          firstDate:   DateTime(2020),
          lastDate:    DateTime.now(),
          builder: (_, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary:   ExpenseColors.brandGold,
                onPrimary: Color(0xFF111827),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) ctrl.setEntryDate(picked);
      },
      child: Container(
        height:  48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:        ExpenseColors.searchBg,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: ExpenseColors.searchBorder),
        ),
        child: Row(children: [
          const Icon(ExpenseIcons.calendar,
              size: 16, color: ExpenseColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            DateFormat('d MMMM yyyy').format(ctrl.entryDate),
            style: ExpenseStyles.labelPrimary,
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down_rounded,
              color: ExpenseColors.textMuted),
        ]),
      ),
    );
  }
}

// ── Save Button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final ExpenseController ctrl;
  final BuildContext      context;
  const _SaveButton({required this.ctrl, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final isDisabled = ctrl.entryNeedsCustomLabel &&
        ctrl.customLabelCtrl.text.trim().isEmpty;

    return GestureDetector(
      onTap: (ctrl.isSaving || isDisabled) ? null : () async {
        final ok = await ctrl.saveExpense();
        if (ok && ctx.mounted) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: const Text(ExpenseStrings.saveSuccess,
                style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: ExpenseColors.moduleAccent,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin:   const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ));
        } else if (!ok && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: const Text(ExpenseStrings.saveFailed,
                style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: ExpenseColors.danger,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin:   const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height:   48,
        decoration: BoxDecoration(
          color: (ctrl.isSaving || isDisabled)
              ? ExpenseColors.moduleAccent.withOpacity(0.5)
              : ExpenseColors.moduleAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: ctrl.isSaving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  ExpenseStrings.saveExpense,
                  style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w800,
                    color:      Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: ExpenseStyles.labelSecondary);
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final int                   maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines:   maxLines,
      style:      ExpenseStyles.inputText,
      decoration: InputDecoration(
        hintText:       hint,
        hintStyle:      ExpenseStyles.labelMuted,
        filled:         true,
        fillColor:      ExpenseColors.searchBg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ExpenseColors.searchBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ExpenseColors.searchBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: ExpenseColors.moduleAccent, width: 1.5),
        ),
      ),
    );
  }
}
