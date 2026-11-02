part of 'cash_book_entry_dialog.dart';

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
          firstDate: DateTime(1),
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
