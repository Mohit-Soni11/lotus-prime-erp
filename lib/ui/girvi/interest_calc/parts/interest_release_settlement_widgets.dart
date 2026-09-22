part of '../interest_calc_screen.dart';

class _ReleaseSettlementBalanceStrip extends StatelessWidget {
  final double originalPrincipal;
  final double principalDue;
  final double interestDue;
  final double totalInterest;
  final double principalCollected;
  final double interestCollected;
  final double previousDiscount;
  final double discount;
  final double interestRate;
  final DateTime startDate;
  final DateTime? maturityDate;
  final DateTime releaseDate;
  final int chargeableMonths;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;

  const _ReleaseSettlementBalanceStrip({
    required this.originalPrincipal,
    required this.principalDue,
    required this.interestDue,
    required this.totalInterest,
    required this.principalCollected,
    required this.interestCollected,
    required this.previousDiscount,
    required this.discount,
    required this.interestRate,
    required this.startDate,
    required this.maturityDate,
    required this.releaseDate,
    required this.chargeableMonths,
    required this.moneyFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final grossDue = principalDue + interestDue;
    final netPayable = math.max(grossDue - discount, 0.0);
    final earlierCash = principalCollected + interestCollected;
    final hasPriorSettlement = earlierCash > 0 || previousDiscount > 0;
    final totalInterestPaid = interestCollected;
    final elapsedLabel = _formatElapsedPeriod(
      GirviLoanModel.elapsedPeriodBetween(startDate, releaseDate),
    );
    final compoundApplied =
        chargeableMonths > GirviLoanModel.compoundCycleMonths;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettlementHeader(
            label: 'Net Payable',
            amount: _money(netPayable),
            helper: discount > 0
                ? 'Final release payable after interest waiver'
                : 'Principal due plus current interest due',
          ),
          const SizedBox(height: 14),
          _SettlementSummarySection(
            title: 'Loan Timeline',
            rows: [
              _SettlementSummaryRow(
                label: 'Principal Amount',
                value: _money(originalPrincipal),
                color: GirviColors.textDark,
              ),
              _SettlementSummaryRow(
                label: 'Start Date',
                value: dateFmt.format(startDate),
                color: GirviColors.info,
              ),
              _SettlementSummaryRow(
                label: 'Maturity Date',
                value: maturityDate == null
                    ? 'Not set'
                    : dateFmt.format(maturityDate!),
                color: GirviColors.purple,
              ),
              _SettlementSummaryRow(
                label: 'Interest Rate',
                value: '${_formatSmartNumber(interestRate)}% monthly',
                color: GirviColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettlementSummarySection(
            title: 'Interest Position',
            rows: [
              _SettlementSummaryRow(
                label: 'Elapsed Period',
                value: elapsedLabel,
                color: GirviColors.info,
              ),
              _SettlementSummaryRow(
                label: 'Chargeable Months',
                value: _formatMonths(chargeableMonths),
                color: GirviColors.textDark,
              ),
              _SettlementSummaryRow(
                label: 'Total Interest',
                value: _money(totalInterest),
                color: GirviColors.warning,
              ),
              if (totalInterestPaid > 0)
                _SettlementSummaryRow(
                  label: 'Interest Paid',
                  value: _money(totalInterestPaid),
                  color: GirviColors.success,
                )
              else
                const _SettlementSummaryRow(
                  label: 'Interest Paid',
                  value: 'Not received',
                  color: GirviColors.textMuted,
                ),
              _SettlementSummaryRow(
                label: totalInterestPaid > 0
                    ? 'Interest Balance'
                    : 'Unpaid Interest',
                value: _money(interestDue),
                color:
                    interestDue > 0 ? GirviColors.danger : GirviColors.success,
              ),
              if (compoundApplied)
                const _SettlementSummaryRow(
                  label: 'Compound Interest',
                  value: 'Applied',
                  color: GirviColors.purple,
                ),
              if (discount > 0)
                _SettlementSummaryRow(
                  label: 'Interest Waiver',
                  value: '- ${_money(discount)}',
                  color: GirviColors.success,
                ),
              if (discount > 0)
                _SettlementSummaryRow(
                  label: 'Net Payable',
                  value: _money(netPayable),
                  color: GirviColors.textDark,
                  strong: true,
                ),
            ],
          ),
          if (hasPriorSettlement) ...[
            const SizedBox(height: 10),
            _PriorSettlementNote(
              earlierCash: earlierCash,
              previousDiscount: previousDiscount,
              moneyFmt: moneyFmt,
            ),
          ],
        ],
      ),
    );
  }

  String _money(double value) => 'Rs ${moneyFmt.format(value)}';

  String _formatMonths(int months) {
    if (months <= 0) return 'Not charged';
    return '$months month${months == 1 ? '' : 's'}';
  }

  String _formatElapsedPeriod(GirviElapsedPeriod period) {
    final totalMonths = (period.years * 12) + period.months;
    final monthText = '$totalMonths month${totalMonths == 1 ? '' : 's'}';
    final dayText = '${period.days} day${period.days == 1 ? '' : 's'}';
    return '$monthText $dayText';
  }

  String _formatSmartNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _SettlementSummarySection extends StatelessWidget {
  final String title;
  final List<_SettlementSummaryRow> rows;

  const _SettlementSummarySection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 560;
              if (!twoColumns) {
                return Column(
                  children: [
                    for (var index = 0; index < rows.length; index++) ...[
                      if (index > 0) const SizedBox(height: 8),
                      _SettlementSummaryTile.fromRow(rows[index]),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rows.map((row) {
                  final width = row.strong
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 8) / 2;
                  return SizedBox(
                    width: width,
                    child: _SettlementSummaryTile.fromRow(row),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettlementSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool strong;

  const _SettlementSummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SettlementSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool strong;

  const _SettlementSummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.strong,
  });

  factory _SettlementSummaryTile.fromRow(_SettlementSummaryRow row) {
    return _SettlementSummaryTile(
      label: row.label,
      value: row.value,
      color: row.color,
      strong: row.strong,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: strong
            ? color.withValues(alpha: 0.07)
            : GirviColors.inputBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: strong ? color.withValues(alpha: 0.22) : GirviColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: GirviColors.textDark,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: strong ? 13.5 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: strong ? 16 : 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementHeader extends StatelessWidget {
  final String label;
  final String amount;
  final String helper;

  const _SettlementHeader({
    required this.label,
    required this.amount,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: GirviColors.success.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: GirviColors.success,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorSettlementNote extends StatelessWidget {
  final double earlierCash;
  final double previousDiscount;
  final NumberFormat moneyFmt;

  const _PriorSettlementNote({
    required this.earlierCash,
    required this.previousDiscount,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (earlierCash > 0) 'cash Rs ${moneyFmt.format(earlierCash)}',
      if (previousDiscount > 0)
        'discount Rs ${moneyFmt.format(previousDiscount)}',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: GirviColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            color: GirviColors.info,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Already settled before this entry: ${parts.join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
