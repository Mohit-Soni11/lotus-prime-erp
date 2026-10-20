part of '../girvi_list_screen.dart';

class _LedgerTicketRow extends StatefulWidget {
  const _LedgerTicketRow({
    required this.data,
    required this.quote,
    required this.selected,
    required this.customerMeta,
    required this.money,
    required this.date,
    required this.onTap,
    required this.onDoubleTap,
  });

  final GirviLoanWithCustomer data;
  final GirviInterestQuote quote;
  final bool selected;
  final String customerMeta;
  final String Function(double) money;
  final String Function(DateTime?) date;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  State<_LedgerTicketRow> createState() => _LedgerTicketRowState();
}

class _LedgerTicketRowState extends State<_LedgerTicketRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final loan = widget.data.loan;
    final statusColor = loan.statusColor;
    final age = GirviLoanModel.elapsedPeriodBetween(
      loan.startDate,
      loan.releaseDate ?? DateTime.now(),
    ).displayLabel;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Pledge account ${loan.ticketNo}, ${loan.statusLabel}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.selected
              ? GirviColors.info.withValues(alpha: 0.075)
              : _hovered
                  ? GirviColors.info.withValues(alpha: 0.035)
                  : GirviColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.selected
                ? GirviColors.info.withValues(alpha: 0.65)
                : _hovered
                    ? GirviColors.info.withValues(alpha: 0.38)
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            onHover: (value) {
              if (_hovered != value && mounted) {
                setState(() => _hovered = value);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final stacked = constraints.maxWidth < 600;
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
                                color: GirviColors.textDark,
                                fontSize: 17,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RegisterStatusBadge(
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
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: GirviColors.divider),
                      const SizedBox(height: 11),
                      if (stacked) ...[
                        _buildIdentity(loan, age),
                        const SizedBox(height: 12),
                        _RegisterAmountPanel(
                          quote: widget.quote,
                          money: widget.money,
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildIdentity(loan, age)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 208,
                              child: _RegisterAmountPanel(
                                quote: widget.quote,
                                money: widget.money,
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentity(GirviLoanModel loan, String age) {
    final received = widget.data.interestPaidTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: GirviColors.textDark,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.customerMeta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: GirviColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          loan.itemSummary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          received > 0
              ? 'Interest received ${widget.money(received)}'
              : 'Interest not received yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: received > 0 ? GirviColors.success : GirviColors.textBody,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _RegisterMetaBadge(
              icon: GirviIcons.dates,
              label: 'Issue ${widget.date(loan.startDate)}',
              color: GirviColors.info,
            ),
            _RegisterMetaBadge(
              icon: GirviIcons.dates,
              label: loan.maturityDate == null
                  ? 'Maturity not set'
                  : 'Maturity ${widget.date(loan.maturityDate)}',
              color: loan.isPastMaturity
                  ? GirviColors.danger
                  : GirviColors.success,
            ),
            _RegisterMetaBadge(
              icon: Icons.timelapse_rounded,
              label: 'Age $age',
              color: GirviColors.textBody,
            ),
          ],
        ),
      ],
    );
  }
}
