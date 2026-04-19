// =============================================================================
// FILE        : bank_book_entry_dialog.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : UI
// DESCRIPTION : Slide-up animated dialog for adding a bank transaction entry.
//               Credit / Debit toggle, category dropdown, payment mode,
//               cheque fields (conditionally visible), party name, description,
//               date picker, value date picker.
//               ListenableBuilder — zero setState except for dialog animation.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/finance/bank_book/bank_book_controller.dart';
import '../../../models/finance/bank_book/bank_book_enums.dart';
import '../../../theme/finance/bank_book/bank_book_theme.dart';

class BankBookEntryDialog extends StatelessWidget {
  final BankBookController ctrl;
  const BankBookEntryDialog({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: _DialogContent(ctrl: ctrl),
    );
  }
}

class _DialogContent extends StatefulWidget {
  final BankBookController ctrl;
  const _DialogContent({required this.ctrl});

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          decoration: BoxDecoration(
            color:        BankBookColors.bodyPanel,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.18),
                blurRadius: 40,
                offset:     const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Dialog Header ────────────────────────────────────────────
              _DialogHeader(ctrl: widget.ctrl),

              // ── Form Body ────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ListenableBuilder(
                    listenable: widget.ctrl,
                    builder: (_, __) => _EntryForm(ctrl: widget.ctrl),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dialog Header ──────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final BankBookController ctrl;
  const _DialogHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: const BoxDecoration(
        color: BankBookColors.shellPanel,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        BankBookColors.brandGoldLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(BankBookIcons.moduleIcon,
              size: 16, color: BankBookColors.brandGold),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(BankBookStrings.addEntry,
                style: BankBookStyles.appBarTitle
                    .copyWith(fontSize: 16, letterSpacing: 0.5)),
            ListenableBuilder(
              listenable: ctrl,
              builder: (_, __) => Text(
                ctrl.selectedAccount?.accountName ?? '',
                style: const TextStyle(
                  fontSize:   11,
                  color:      BankBookColors.shellMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        BankBookColors.shellBorder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close_rounded,
                size: 16, color: BankBookColors.shellMuted),
          ),
        ),
      ]),
    );
  }
}

// ── Entry Form ─────────────────────────────────────────────────────────────────

class _EntryForm extends StatelessWidget {
  final BankBookController ctrl;
  const _EntryForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // 1. Credit / Debit Toggle
        _TypeToggle(ctrl: ctrl),
        const SizedBox(height: 16),

        // 2. Amount
        _FormLabel(BankBookStrings.amount),
        const SizedBox(height: 6),
        _AmountField(ctrl: ctrl),
        const SizedBox(height: 16),

        // 3. Category
        _FormLabel(BankBookStrings.category),
        const SizedBox(height: 6),
        _CategoryDropdown(ctrl: ctrl),
        const SizedBox(height: 16),

        // 4. Payment Mode
        _FormLabel(BankBookStrings.paymentMode),
        const SizedBox(height: 6),
        _PaymentModeSelector(ctrl: ctrl),
        const SizedBox(height: 16),

        // 5. Cheque Fields (conditional)
        if (ctrl.isChequeMode) ...[
          _FormLabel(BankBookStrings.chequeNumber),
          const SizedBox(height: 6),
          _InputField(
            controller: ctrl.chequeNumberCtrl,
            hint:       BankBookStrings.chequeNumberHint,
            icon:       BankBookIcons.cheque,
          ),
          const SizedBox(height: 12),
          _FormLabel(BankBookStrings.chequeStatusLabel),
          const SizedBox(height: 6),
          _ChequeStatusSelector(ctrl: ctrl),
          const SizedBox(height: 16),
        ],

        // 6. Party Name
        _FormLabel(BankBookStrings.partyName),
        const SizedBox(height: 6),
        _InputField(
          controller: ctrl.partyNameCtrl,
          hint:       BankBookStrings.partyHint,
          icon:       Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),

        // 7. Description
        _FormLabel(BankBookStrings.description),
        const SizedBox(height: 6),
        _InputField(
          controller: ctrl.descriptionCtrl,
          hint:       BankBookStrings.descriptionHint,
          icon:       Icons.notes_rounded,
          maxLines:   2,
        ),
        const SizedBox(height: 16),

        // 8. Transaction Date
        _FormLabel(BankBookStrings.date),
        const SizedBox(height: 6),
        _DatePickerField(
          date:    ctrl.entryDate,
          onPick:  (d) => ctrl.setEntryDate(d),
          icon:    BankBookIcons.calendar,
        ),
        const SizedBox(height: 16),

        // 9. Value Date (clearing date — optional)
        _FormLabel('${BankBookStrings.valueDate} (Optional)'),
        const SizedBox(height: 6),
        _DatePickerField(
          date:       ctrl.entryValueDate,
          onPick:     (d) => ctrl.setEntryValueDate(d),
          icon:       BankBookIcons.calendar,
          isOptional: true,
        ),
        const SizedBox(height: 24),

        // 10. Save Button
        _SaveButton(ctrl: ctrl),
        const SizedBox(height: 8),

        // 11. Cancel
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BankBookStrings.cancel,
                style: TextStyle(color: BankBookColors.textSecondary)),
          ),
        ),
      ],
    );
  }
}

// ── Type Toggle (Credit / Debit) ───────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final BankBookController ctrl;
  const _TypeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color:        BankBookColors.toggleInactiveBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: BankBookColors.bodyBorder),
      ),
      child: Row(children: BankTransactionType.values.map((type) {
        final isActive = ctrl.entryType == type;
        final color    = type == BankTransactionType.credit
            ? BankBookColors.creditAccent
            : BankBookColors.debitAccent;

        return Expanded(
          child: GestureDetector(
            onTap: () => ctrl.setEntryType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isActive
                    ? Border.all(color: color.withOpacity(0.4))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == BankTransactionType.credit
                        ? BankBookIcons.credit
                        : BankBookIcons.debit,
                    size:  14,
                    color: isActive ? color : BankBookColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(type.displayLabel, style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      isActive ? color : BankBookColors.textMuted,
                  )),
                ],
              ),
            ),
          ),
        );
      }).toList()),
    );
  }
}

// ── Amount Field ───────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final BankBookController ctrl;
  const _AmountField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   ctrl.amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style:        BankBookStyles.amountMedium,
      decoration: InputDecoration(
        hintText:    BankBookStrings.amountHint,
        hintStyle:   BankBookStyles.labelMuted,
        prefixText:  '₹  ',
        prefixStyle: BankBookStyles.amountMedium,
        filled:      true,
        fillColor:   BankBookColors.toggleInactiveBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: BankBookColors.bodyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: BankBookColors.brandGold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Category Dropdown ──────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final BankBookController ctrl;
  const _CategoryDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final categories = ctrl.availableCategories;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color:        BankBookColors.toggleInactiveBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: BankBookColors.bodyBorder),
      ),
      child: DropdownButton<String>(
        value:         ctrl.entryCategory,
        isExpanded:    true,
        underline:     const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: BankBookColors.textSecondary),
        style:        BankBookStyles.labelPrimary,
        dropdownColor: BankBookColors.bodyPanel,
        items: categories.map((dbValue) {
          final label = ctrl.categoryLabel(dbValue, ctrl.entryType);
          return DropdownMenuItem(
            value: dbValue,
            child: Text(label, style: BankBookStyles.labelPrimary),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) ctrl.setEntryCategory(v);
        },
      ),
    );
  }
}

// ── Payment Mode Selector ──────────────────────────────────────────────────────

class _PaymentModeSelector extends StatelessWidget {
  final BankBookController ctrl;
  const _PaymentModeSelector({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BankPaymentMode.values.map((mode) {
        final isActive = ctrl.entryMode == mode;
        return GestureDetector(
          onTap: () => ctrl.setEntryMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? BankBookColors.brandGold.withOpacity(0.15)
                  : BankBookColors.toggleInactiveBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:  isActive
                    ? BankBookColors.brandGold
                    : BankBookColors.bodyBorder,
                width:  isActive ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_modeIcon(mode), size: 12,
                color: isActive
                    ? BankBookColors.brandGold
                    : BankBookColors.textMuted),
              const SizedBox(width: 5),
              Text(mode.displayLabel, style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? BankBookColors.brandGold
                    : BankBookColors.textSecondary,
              )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  IconData _modeIcon(BankPaymentMode mode) {
    return switch (mode) {
      BankPaymentMode.neft          => BankBookIcons.neft,
      BankPaymentMode.rtgs          => BankBookIcons.neft,
      BankPaymentMode.imps          => BankBookIcons.neft,
      BankPaymentMode.upi           => BankBookIcons.upi,
      BankPaymentMode.cheque        => BankBookIcons.cheque,
      BankPaymentMode.cashDeposit   => BankBookIcons.cash,
      BankPaymentMode.cashWithdrawal=> BankBookIcons.cash,
      BankPaymentMode.card          => BankBookIcons.card,
      BankPaymentMode.autoDebit     => Icons.autorenew_rounded,
    };
  }
}

// ── Cheque Status Selector ─────────────────────────────────────────────────────

class _ChequeStatusSelector extends StatelessWidget {
  final BankBookController ctrl;
  const _ChequeStatusSelector({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color:        BankBookColors.chequeBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: BankBookColors.chequeBorder),
      ),
      child: DropdownButton<ChequeStatus>(
        value:         ctrl.entryChequeStatus,
        isExpanded:    true,
        underline:     const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: BankBookColors.chequeText),
        style:         BankBookStyles.labelPrimary,
        dropdownColor: BankBookColors.bodyPanel,
        items: ChequeStatus.values.map((s) => DropdownMenuItem(
          value: s,
          child: Text(s.displayLabel, style: BankBookStyles.labelPrimary),
        )).toList(),
        onChanged: (v) {
          if (v != null) ctrl.setEntryChequeStatus(v);
        },
      ),
    );
  }
}

// ── Date Picker Field ──────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final DateTime?         date;
  final ValueChanged<DateTime> onPick;
  final IconData          icon;
  final bool              isOptional;

  const _DatePickerField({
    required this.date,
    required this.onPick,
    required this.icon,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = date != null
        ? DateFormat('d MMM yyyy').format(date!)
        : (isOptional ? 'Not set' : DateFormat('d MMM yyyy').format(DateTime.now()));

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context:      context,
          initialDate:  date ?? DateTime.now(),
          firstDate:    DateTime(2020),
          lastDate:     DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary:   BankBookColors.brandGold,
                onPrimary: Color(0xFF111827),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color:        BankBookColors.toggleInactiveBg,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: BankBookColors.bodyBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: BankBookColors.textSecondary),
          const SizedBox(width: 10),
          Text(displayText, style: BankBookStyles.labelPrimary.copyWith(
            color: date == null && isOptional
                ? BankBookColors.textMuted
                : BankBookColors.textPrimary,
          )),
        ]),
      ),
    );
  }
}

// ── Generic Input Field ────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final IconData              icon;
  final int                   maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style:      BankBookStyles.labelPrimary,
      maxLines:   maxLines,
      decoration: InputDecoration(
        hintText:    hint,
        hintStyle:   BankBookStyles.labelMuted,
        prefixIcon:  Icon(icon, size: 16, color: BankBookColors.textSecondary),
        filled:      true,
        fillColor:   BankBookColors.toggleInactiveBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: BankBookColors.bodyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: BankBookColors.brandGold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Form Label ─────────────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: BankBookStyles.labelSecondary.copyWith(
      fontWeight: FontWeight.w600,
    ));
  }
}

// ── Save Button ────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final BankBookController ctrl;
  const _SaveButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: BankBookColors.brandGold,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: ctrl.isSaving
            ? null
            : () async {
                final success = await ctrl.saveEntry();
                if (!context.mounted) return;
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Entry saved successfully'),
                      backgroundColor: BankBookColors.creditAccent,
                      behavior:        SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin:   const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Please enter a valid amount'),
                      backgroundColor: BankBookColors.debitAccent,
                      behavior:        SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
        child: ctrl.isSaving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color:       Color(0xFF111827),
                  strokeWidth: 2,
                ),
              )
            : Text(BankBookStrings.saveEntry, style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w800,
                color:      Color(0xFF111827),
              )),
      ),
    );
  }
}