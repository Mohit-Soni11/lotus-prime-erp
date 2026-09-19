part of '../new_girvi_screen.dart';

class _InterestPreviewCard extends StatelessWidget {
  final double principal;
  final double monthly;
  final double monthlyRate;
  final double total;
  final double annualRate;
  final int durationMonths;
  final bool hasLoanTerms;

  const _InterestPreviewCard({
    required this.principal,
    required this.monthly,
    required this.monthlyRate,
    required this.total,
    required this.annualRate,
    required this.durationMonths,
    required this.hasLoanTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GirviColors.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: GirviColors.info.withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(
              GirviIcons.interestRate,
              color: GirviColors.info,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repayment Preview',
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLoanTerms
                      ? 'Simple interest estimate for $durationMonths month${durationMonths == 1 ? '' : 's'}.'
                      : 'Enter loan amount, monthly interest and tenure to preview dues.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: GirviColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Text(
                hasLoanTerms
                    ? '${_formatSmartPercent(annualRate)} p.a.'
                    : 'Pending',
                style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final tiles = [
              _PreviewStat(
                label: 'Monthly Interest',
                value: hasLoanTerms
                    ? '${_formatSmartMoney(monthly)} · ${_formatSmartPercent(monthlyRate)} monthly'
                    : 'Not set',
                color: GirviColors.info,
                icon: Icons.calendar_month_outlined,
              ),
              _PreviewStat(
                label: 'Total Interest',
                value: hasLoanTerms ? _formatSmartMoney(total) : 'Not set',
                color: GirviColors.textDark,
                icon: Icons.trending_up_rounded,
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  for (int i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    tiles[i],
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (int i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: tiles[i]),
                ],
              ],
            );
          },
        ),
      ]),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _PreviewStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GirviColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(
                    alpha: color == GirviColors.textDark ? 0.06 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DisbursementSplitEditor extends StatelessWidget {
  final List<GirviPaymentMode> modes;
  final GirviPaymentMode selected;
  final double loanAmount;
  final double totalAmount;
  final double remainingAmount;
  final TextEditingController Function(GirviPaymentMode mode) controllerFor;
  final double Function(GirviPaymentMode mode) amountFor;
  final String Function(GirviPaymentMode mode) modeLabel;
  final void Function(GirviPaymentMode mode) onModeTap;

  const _DisbursementSplitEditor({
    required this.modes,
    required this.selected,
    required this.loanAmount,
    required this.totalAmount,
    required this.remainingAmount,
    required this.controllerFor,
    required this.amountFor,
    required this.modeLabel,
    required this.onModeTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 920
            ? 4
            : width >= 640
                ? 2
                : 1;
        final spacing = columns == 1 ? 0.0 : 10.0;
        final tileWidth = (width - (spacing * (columns - 1))) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: [
                for (final mode in modes)
                  SizedBox(
                    width: tileWidth,
                    child: _DisbursementAmountTile(
                      mode: mode,
                      label: modeLabel(mode),
                      controller: controllerFor(mode),
                      active: selected == mode || amountFor(mode) > 0,
                      amount: amountFor(mode),
                      onTap: () => onModeTap(mode),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DisbursementTotalStrip(
              loanAmount: loanAmount,
              totalAmount: totalAmount,
              remainingAmount: remainingAmount,
            ),
          ],
        );
      },
    );
  }
}

class _DisbursementAmountTile extends StatelessWidget {
  final GirviPaymentMode mode;
  final String label;
  final TextEditingController controller;
  final bool active;
  final double amount;
  final VoidCallback onTap;

  const _DisbursementAmountTile({
    required this.mode,
    required this.label,
    required this.controller,
    required this.active,
    required this.amount,
    required this.onTap,
  });

  Color get _color {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviColors.success;
      case GirviPaymentMode.upi:
        return GirviColors.info;
      case GirviPaymentMode.bankTransfer:
        return GirviColors.brandGold;
      case GirviPaymentMode.cheque:
        return GirviColors.textMuted;
      case GirviPaymentMode.neft:
        return GirviColors.brandGold;
    }
  }

  IconData get _icon {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      case GirviPaymentMode.bankTransfer:
      case GirviPaymentMode.neft:
        return GirviIcons.bank;
      case GirviPaymentMode.cheque:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.07) : GirviColors.inputBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color:
                active ? color.withValues(alpha: 0.35) : GirviColors.cardBorder,
            width: active ? 1.3 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: color, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (amount > 0)
                Icon(Icons.check_circle_rounded, color: color, size: 16),
            ]),
            const SizedBox(height: 9),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: GirviColors.cardBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active
                      ? color.withValues(alpha: 0.28)
                      : GirviColors.cardBorder,
                ),
              ),
              child: Row(children: [
                Text(
                  'Rs',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'girvi-disbursement-${mode.dbValue.toLowerCase().replaceAll(' ', '-')}',
                    ),
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    textAlign: TextAlign.right,
                    style: GoogleFonts.manrope(
                      color: GirviColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Amount',
                      hintStyle: GirviStyles.fieldHint.copyWith(fontSize: 13),
                      isDense: true,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisbursementTotalStrip extends StatelessWidget {
  final double loanAmount;
  final double totalAmount;
  final double remainingAmount;

  const _DisbursementTotalStrip({
    required this.loanAmount,
    required this.totalAmount,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final balanced = loanAmount > 0 && remainingAmount.abs() <= 0.50;
    final remainingColor = balanced ? GirviColors.success : GirviColors.warning;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final tiles = [
          _MiniAmountPanel(
            label: 'Loan Amount',
            value: loanAmount > 0 ? _formatSmartMoney(loanAmount) : 'Not set',
            color: GirviColors.brandGold,
          ),
          _MiniAmountPanel(
            label: 'Disbursed',
            value: totalAmount > 0 ? _formatSmartMoney(totalAmount) : 'Not set',
            color: GirviColors.info,
          ),
          _MiniAmountPanel(
            label: remainingAmount < 0 ? 'Over Limit' : 'Remaining',
            value: loanAmount > 0
                ? _formatSmartMoney(remainingAmount.abs())
                : 'Not set',
            color: remainingColor,
          ),
        ];
        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                tiles[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MiniAmountPanel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniAmountPanel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentModeSelector extends StatelessWidget {
  final GirviPaymentMode selected;
  final void Function(GirviPaymentMode) onChanged;

  const _PaymentModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GirviPaymentMode.values
          .where((mode) => mode != GirviPaymentMode.neft)
          .map((mode) {
        final isSelected = mode == selected;
        return GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? GirviColors.brandGold.withValues(alpha: 0.12)
                  : GirviColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? GirviColors.brandGold : GirviColors.cardBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isSelected)
                const Icon(GirviIcons.markDone,
                    color: GirviColors.brandGold, size: 14)
              else
                Icon(_modeIcon(mode), color: GirviColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(mode.displayName,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? GirviColors.brandGold
                        : GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  IconData _modeIcon(GirviPaymentMode m) {
    switch (m) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      default:
        return GirviIcons.bank;
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback? onTap;
  final String? valueText;

  const _DatePickerField({
    required this.label,
    required this.date,
    this.onTap,
    this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.fieldLabel),
          const SizedBox(height: 6),
          Container(
            height: GirviStyles.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: GirviStyles.inputNormal,
            child: Row(children: [
              const Icon(GirviIcons.dates,
                  color: GirviColors.accentDates, size: 18),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: GirviColors.cardBorder),
              const SizedBox(width: 10),
              Text(
                valueText ?? DateFormat('dd MMM yyyy').format(date),
                style: GirviStyles.fieldInput.copyWith(
                  color: valueText == 'Not set'
                      ? GirviColors.textMuted
                      : GirviColors.textDark,
                ),
              ),
              const Spacer(),
              Icon(
                interactive
                    ? Icons.edit_calendar_rounded
                    : Icons.calendar_month_outlined,
                color: GirviColors.textHint,
                size: 16,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
