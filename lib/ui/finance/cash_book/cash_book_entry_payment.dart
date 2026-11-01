part of 'cash_book_entry_dialog.dart';

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
                AppFeedback.show(
                  ctx,
                  type: AppFeedbackType.success,
                  message: 'Entry saved successfully',
                  duration: const Duration(seconds: 2),
                );
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
