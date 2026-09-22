part of '../interest_calc_screen.dart';

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
  final DateFormat dateFmt;
  final int? selectedLoanId;
  final ValueChanged<GirviLoanWithCustomer> onLoanTap;

  const _CustomerReadyPanel({
    required this.account,
    required this.moneyFmt,
    required this.dateFmt,
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
                    dateFmt: dateFmt,
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
