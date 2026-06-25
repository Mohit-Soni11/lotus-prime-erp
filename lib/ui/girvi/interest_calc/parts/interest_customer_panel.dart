part of '../interest_calc_screen.dart';

class _HeaderIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? GirviColors.brandGold.withValues(alpha: 0.16)
                  : GirviColors.shellPanelBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _hovered ? GirviColors.brandGold : GirviColors.shellBorder,
              ),
            ),
            child: Icon(
              widget.icon,
              color:
                  _hovered ? GirviColors.brandGold : GirviColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _SearchField({
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: GirviStyles.inputNormal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(GirviIcons.search, color: GirviColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: GirviStyles.fieldInput.copyWith(fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GirviStyles.fieldHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerReadyPanel extends StatelessWidget {
  final GirviCustomerGirviAccount account;
  final NumberFormat moneyFmt;
  final int? selectedLoanId;
  final ValueChanged<GirviLoanWithCustomer> onLoanTap;

  const _CustomerReadyPanel({
    required this.account,
    required this.moneyFmt,
    required this.selectedLoanId,
    required this.onLoanTap,
  });

  @override
  Widget build(BuildContext context) {
    return GirviSectionCard(
      icon: GirviIcons.customer,
      title: account.customerName,
      subtitle:
          '${account.ticketCount} open Girvi ticket${account.ticketCount == 1 ? '' : 's'} available for this customer',
      accent: account.hasOverdueTickets ? GirviColors.danger : GirviColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _MiniMoney(
                label: 'Outstanding',
                value: 'Rs ${moneyFmt.format(account.outstandingPrincipal)}',
                color: GirviColors.purple,
              ),
              const SizedBox(width: 10),
              _MiniMoney(
                label: 'Interest Due',
                value: 'Rs ${moneyFmt.format(account.interestDue)}',
                color: account.hasOverdueTickets
                    ? GirviColors.danger
                    : GirviColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GirviColors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const _IconBox(
                      icon: GirviIcons.ticket,
                      color: GirviColors.info,
                      dark: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Girvi Bills',
                            style: GoogleFonts.inter(
                              color: GirviColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select the exact bill to open the collection desk.',
                            style: GoogleFonts.inter(
                              color: GirviColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CountBadge(value: account.ticketCount.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < account.loans.length; i++) ...[
                  _TicketStackRow(
                    data: account.loans[i],
                    selected: account.loans[i].loan.id == selectedLoanId,
                    moneyFmt: moneyFmt,
                    onTap: () => onLoanTap(account.loans[i]),
                  ),
                  if (i != account.loans.length - 1)
                    Container(height: 1, color: GirviColors.divider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerGirviCard extends StatelessWidget {
  final GirviCustomerGirviAccount account;
  final bool selected;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final VoidCallback onCustomerTap;

  const _CustomerGirviCard({
    required this.account,
    required this.selected,
    required this.moneyFmt,
    required this.dateFmt,
    required this.onCustomerTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCustomerTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? GirviColors.brandGold.withValues(alpha: 0.08)
              : GirviColors.inputBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? GirviColors.brandGold : GirviColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBox(
                  icon: GirviIcons.customer,
                  color: selected
                      ? GirviColors.brandGold
                      : account.hasOverdueTickets
                          ? GirviColors.danger
                          : GirviColors.info,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          account.customerMobile,
                          if ((account.customerCity ?? '').trim().isNotEmpty)
                            account.customerCity!.trim(),
                        ].join(' | '),
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
                const SizedBox(width: 8),
                _StatusPill(
                  label:
                      '${account.ticketCount} ticket${account.ticketCount == 1 ? '' : 's'}',
                  color: account.hasOverdueTickets
                      ? GirviColors.danger
                      : GirviColors.success,
                ),
                const SizedBox(width: 6),
                Icon(
                  selected ? GirviIcons.markDone : Icons.chevron_right_rounded,
                  color:
                      selected ? GirviColors.brandGold : GirviColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniMoney(
                  label: 'Outstanding',
                  value: 'Rs ${moneyFmt.format(account.outstandingPrincipal)}',
                  color: GirviColors.purple,
                ),
                const SizedBox(width: 10),
                _MiniMoney(
                  label: 'Interest Due',
                  value: 'Rs ${moneyFmt.format(account.interestDue)}',
                  color: account.hasOverdueTickets
                      ? GirviColors.danger
                      : GirviColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(GirviIcons.dates,
                    size: 13, color: GirviColors.textMuted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    account.hasOverdueTickets
                        ? '${account.overdueTicketCount} overdue ticket${account.overdueTicketCount == 1 ? '' : 's'} need attention'
                        : 'Latest activity ${dateFmt.format(account.latestActivity)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: account.hasOverdueTickets
                          ? GirviColors.danger
                          : GirviColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketStackRow extends StatefulWidget {
  final GirviLoanWithCustomer data;
  final bool selected;
  final NumberFormat moneyFmt;
  final VoidCallback onTap;

  const _TicketStackRow({
    required this.data,
    required this.selected,
    required this.moneyFmt,
    required this.onTap,
  });

  @override
  State<_TicketStackRow> createState() => _TicketStackRowState();
}

class _TicketStackRowState extends State<_TicketStackRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final loan = widget.data.loan;
    final highlighted = widget.selected || _hovered;
    final accent = widget.selected
        ? GirviColors.brandGold
        : loan.isOverdue
            ? GirviColors.danger
            : GirviColors.info;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          scale: _hovered && !widget.selected ? 1.006 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? GirviColors.brandGold.withValues(alpha: 0.15)
                  : _hovered
                      ? GirviColors.info.withValues(alpha: 0.07)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.selected
                    ? GirviColors.brandGold
                    : _hovered
                        ? GirviColors.info.withValues(alpha: 0.32)
                        : Colors.transparent,
                width: widget.selected ? 1.4 : 1,
              ),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 4,
                  height: 62,
                  decoration: BoxDecoration(
                    color: highlighted ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: loan.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    GirviIcons.ticket,
                    color: loan.statusColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              loan.ticketNo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GirviStyles.ticketNumber.copyWith(
                                fontSize: 13,
                                color: widget.selected
                                    ? GirviColors.brandDeep
                                    : GirviColors.brandGold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _TinyTag(label: loan.statusLabel),
                          if (widget.selected) ...[
                            const SizedBox(width: 6),
                            const _TinyTag(
                              label: 'Selected',
                              color: GirviColors.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loan.itemSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.data.interestPaidTotal <= 0
                            ? 'Interest not received yet'
                            : 'Interest paid Rs ${widget.moneyFmt.format(widget.data.interestPaidTotal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs ${widget.moneyFmt.format(widget.data.principalDue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Due Rs ${widget.moneyFmt.format(widget.data.netInterestDue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: widget.selected
                      ? const Icon(
                          GirviIcons.markDone,
                          key: ValueKey('selected'),
                          color: GirviColors.brandGold,
                          size: 20,
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          key: ValueKey(_hovered),
                          color: _hovered
                              ? GirviColors.info
                              : GirviColors.textMuted,
                          size: 20,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : GirviColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : GirviColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? color : GirviColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? GirviColors.textDark : GirviColors.textBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
