part of '../interest_calc_screen.dart';

class _TicketStackRow extends StatefulWidget {
  const _TicketStackRow({
    required this.data,
    required this.selected,
    required this.moneyFmt,
    required this.dateFmt,
    required this.onTap,
  });

  final GirviLoanWithCustomer data;
  final bool selected;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  State<_TicketStackRow> createState() => _TicketStackRowState();
}

class _TicketStackRowState extends State<_TicketStackRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final loan = widget.data.loan;
    final interestDue = widget.data.netInterestDue;
    final statusColor = loan.isOverdue
        ? GirviColors.danger
        : loan.girviStatus == GirviStatus.active
            ? GirviColors.success
            : GirviColors.info;
    final age = GirviLoanModel.elapsedPeriodBetween(
      loan.startDate,
      loan.releaseDate ?? DateTime.now(),
    );
    final unpaidPeriod = loan.unpaidInterestElapsedPeriod;
    final periodLabel = interestDue > 0
        ? 'Interest for ${unpaidPeriod.displayLabel}'
        : loan.hasAdvanceInterest
            ? 'Advance interest covered'
            : 'No pending interest';

    return Semantics(
      button: true,
      label: 'Open invoice ${loan.ticketNo}, ${loan.statusLabel}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.selected
              ? GirviColors.info.withValues(alpha: 0.07)
              : _hovered
                  ? GirviColors.info.withValues(alpha: 0.035)
                  : GirviColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.selected
                ? GirviColors.info.withValues(alpha: 0.70)
                : _hovered
                    ? GirviColors.info.withValues(alpha: 0.42)
                    : GirviColors.cardBorder,
            width: widget.selected ? 1.4 : 1,
          ),
          boxShadow: widget.selected || _hovered
              ? [
                  BoxShadow(
                    color: GirviColors.info.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) {
            if (_hovered != value && mounted) setState(() => _hovered = value);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final details = _TicketRowDetails(
                  data: widget.data,
                  dateFmt: widget.dateFmt,
                  moneyFmt: widget.moneyFmt,
                  ageLabel: age.displayLabel,
                );
                final amounts = _TicketDuePanel(
                  principalDue: widget.data.principalDue,
                  interestDue: interestDue,
                  periodLabel: periodLabel,
                  moneyFmt: widget.moneyFmt,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loan.ticketNo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GirviStyles.ticketNumber.copyWith(
                              fontSize: 17,
                              letterSpacing: 0.7,
                              color: GirviColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _TicketStatusBadge(
                          label: loan.statusLabel,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          widget.selected
                              ? GirviIcons.markDone
                              : Icons.chevron_right_rounded,
                          color: widget.selected
                              ? GirviColors.info
                              : GirviColors.textMuted,
                          size: 21,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: GirviColors.divider),
                    const SizedBox(height: 11),
                    if (compact) ...[
                      details,
                      const SizedBox(height: 12),
                      amounts,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: 18),
                          SizedBox(width: 214, child: amounts),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketRowDetails extends StatelessWidget {
  const _TicketRowDetails({
    required this.data,
    required this.dateFmt,
    required this.moneyFmt,
    required this.ageLabel,
  });

  final GirviLoanWithCustomer data;
  final DateFormat dateFmt;
  final NumberFormat moneyFmt;
  final String ageLabel;

  @override
  Widget build(BuildContext context) {
    final loan = data.loan;
    final paid = data.interestPaidTotal > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loan.itemSummary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          paid
              ? 'Interest received Rs ${moneyFmt.format(data.interestPaidTotal)}'
              : 'Interest not received yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: paid ? GirviColors.success : GirviColors.textBody,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _TicketMetaBadge(
              icon: GirviIcons.dates,
              label: 'Issue ${dateFmt.format(loan.startDate)}',
              color: GirviColors.info,
            ),
            _TicketMetaBadge(
              icon: GirviIcons.dates,
              label: loan.maturityDate == null
                  ? 'Maturity not set'
                  : 'Maturity ${dateFmt.format(loan.maturityDate!)}',
              color: loan.isPastMaturity
                  ? GirviColors.danger
                  : GirviColors.success,
            ),
            _TicketMetaBadge(
              icon: Icons.timelapse_rounded,
              label: 'Age $ageLabel',
              color: GirviColors.textBody,
            ),
          ],
        ),
      ],
    );
  }
}

class _TicketDuePanel extends StatelessWidget {
  const _TicketDuePanel({
    required this.principalDue,
    required this.interestDue,
    required this.periodLabel,
    required this.moneyFmt,
  });

  final double principalDue;
  final double interestDue;
  final String periodLabel;
  final NumberFormat moneyFmt;

  @override
  Widget build(BuildContext context) {
    final interestColor =
        interestDue > 0 ? GirviColors.danger : GirviColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Principal Due',
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Rs ${moneyFmt.format(principalDue)}',
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Divider(height: 1, color: GirviColors.divider),
          const SizedBox(height: 7),
          Text(
            'Interest Due',
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            interestDue > 0 ? 'Rs ${moneyFmt.format(interestDue)}' : 'None',
            style: GoogleFonts.manrope(
              color: interestColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            periodLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
