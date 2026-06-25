part of '../interest_calc_screen.dart';

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GirviStyles.fieldLabel),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: GirviStyles.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: GirviStyles.inputNormal,
            child: Row(
              children: [
                Icon(icon, color: GirviColors.brandGold, size: 18),
                const SizedBox(width: 10),
                Container(width: 1, height: 22, color: GirviColors.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GirviStyles.fieldInput,
                  ),
                ),
                const Icon(
                  GirviIcons.expandDown,
                  color: GirviColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InterestLedgerBalanceStrip extends StatelessWidget {
  final double grossInterest;
  final double interestPaid;
  final double netDue;
  final int equivalentMonths;
  final NumberFormat moneyFmt;

  const _InterestLedgerBalanceStrip({
    required this.grossInterest,
    required this.interestPaid,
    required this.netDue,
    required this.equivalentMonths,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        equivalentMonths <= 0 ? 'Under 1 mo' : '$equivalentMonths mo';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _FocusMetric(
            label: 'Gross Interest',
            value: 'Rs ${moneyFmt.format(grossInterest)}',
            color: GirviColors.warning,
            wide: true,
          ),
          _FocusMetric(
            label: 'Interest Paid',
            value: 'Rs ${moneyFmt.format(interestPaid)}',
            color: GirviColors.success,
            wide: true,
          ),
          _FocusMetric(
            label: 'Net Due',
            value: 'Rs ${moneyFmt.format(netDue)}',
            color: netDue > 0 ? GirviColors.danger : GirviColors.success,
            wide: true,
          ),
          _FocusMetric(
            label: 'Entry Equals',
            value: monthLabel,
            color: GirviColors.info,
          ),
        ],
      ),
    );
  }
}

class _AmountShortcutRail extends StatelessWidget {
  final GirviPaymentType paymentType;
  final bool isInterestEntry;
  final double interestDue;
  final double monthlyInterest;
  final double principalOutstanding;
  final double expectedInterest;
  final NumberFormat moneyFmt;
  final ValueChanged<double> onPick;

  const _AmountShortcutRail({
    required this.paymentType,
    required this.isInterestEntry,
    required this.interestDue,
    required this.monthlyInterest,
    required this.principalOutstanding,
    required this.expectedInterest,
    required this.moneyFmt,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = <_AmountShortcut>[
      if (isInterestEntry && interestDue > 0)
        _AmountShortcut('Full Due', interestDue, GirviColors.warning),
      if (isInterestEntry && expectedInterest > 0)
        _AmountShortcut('Expected', expectedInterest, GirviColors.success),
      if (isInterestEntry && monthlyInterest > 0)
        _AmountShortcut('1 Month', monthlyInterest, GirviColors.info),
      if (paymentType == GirviPaymentType.partialPrincipal &&
          principalOutstanding > 0)
        _AmountShortcut(
          'Full Principal',
          principalOutstanding,
          GirviColors.purple,
        ),
    ];

    final uniqueShortcuts = <_AmountShortcut>[];
    for (final shortcut in shortcuts) {
      final alreadyExists = uniqueShortcuts.any(
        (item) => (item.amount - shortcut.amount).abs() < 0.01,
      );
      if (!alreadyExists) uniqueShortcuts.add(shortcut);
    }

    if (uniqueShortcuts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final shortcut in uniqueShortcuts)
          _AmountShortcutButton(
            label: shortcut.label,
            value: 'Rs ${moneyFmt.format(shortcut.amount)}',
            color: shortcut.color,
            onTap: () => onPick(shortcut.amount),
          ),
      ],
    );
  }
}

class _AmountShortcut {
  final String label;
  final double amount;
  final Color color;

  const _AmountShortcut(this.label, this.amount, this.color);
}

class _AmountShortcutButton extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _AmountShortcutButton({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AmountShortcutButton> createState() => _AmountShortcutButtonState();
}

class _AmountShortcutButtonState extends State<_AmountShortcutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hovered ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.color.withValues(alpha: _hovered ? 0.42 : 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on_rounded, color: widget.color, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.value,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  final GirviPaymentModel payment;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;

  const _PaymentHistoryRow({
    required this.payment,
    required this.moneyFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(payment.type);
    final period = payment.type == GirviPaymentType.fullRelease
        ? 'Principal Cash Rs ${moneyFmt.format(payment.principalComponent)} | Interest Cash Rs ${moneyFmt.format(payment.interestComponent)}'
        : payment.interestFromDate != null && payment.interestToDate != null
            ? '${dateFmt.format(payment.interestFromDate!)} - ${dateFmt.format(payment.interestToDate!)}'
            : payment.monthsCovered == null
                ? 'No interest period'
                : '${payment.monthsCovered} month${payment.monthsCovered == 1 ? '' : 's'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        children: [
          _IconBox(icon: _iconForType(payment.type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        payment.type.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFmt.format(payment.paymentDate)}  |  ${payment.mode.displayName}  |  $period',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment.type == GirviPaymentType.fullRelease
                    ? 'Cash Rs ${moneyFmt.format(payment.amount)}'
                    : 'Rs ${moneyFmt.format(payment.amount)}',
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (payment.discountAmount > 0)
                Text(
                  'Discount Rs ${moneyFmt.format(payment.discountAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: GirviColors.info,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              Text(
                payment.type == GirviPaymentType.fullRelease
                    ? 'Settlement Balance Rs ${moneyFmt.format(payment.balanceAfter)}'
                    : 'Balance Rs ${moneyFmt.format(payment.balanceAfter)}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: GirviColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
      case GirviPaymentType.partialInterest:
        return GirviIcons.interestRate;
      case GirviPaymentType.partialPrincipal:
        return GirviIcons.loanTerms;
      case GirviPaymentType.fullRelease:
        return GirviIcons.release;
      case GirviPaymentType.penalty:
        return GirviIcons.warning;
    }
  }

  static Color _colorForType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
        return GirviColors.success;
      case GirviPaymentType.partialInterest:
        return GirviColors.warning;
      case GirviPaymentType.partialPrincipal:
        return GirviColors.purple;
      case GirviPaymentType.fullRelease:
        return GirviColors.info;
      case GirviPaymentType.penalty:
        return GirviColors.danger;
    }
  }
}
