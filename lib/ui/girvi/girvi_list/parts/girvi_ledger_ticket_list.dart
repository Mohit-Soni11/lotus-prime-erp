part of '../girvi_list_screen.dart';

extension _GirviLedgerTicketList on _GirviListScreenState {
  Widget _buildTicketRegister({required bool compact}) {
    final loans = _controller.loans;
    final title = _controller.filter == GirviFilter.all
        ? 'Ticket Register'
        : '${_controller.filter.displayName} Tickets';

    final list = ListView.separated(
      shrinkWrap: compact,
      physics: compact
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: loans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = loans[index];
        return _LedgerTicketRow(
          selected: _isSelected(item),
          ticketNo: item.loan.ticketNo,
          customerName: item.customerName,
          customerMeta: _compactCustomerLocation(item),
          itemSummary: item.loan.itemSummary,
          statusLabel: item.loan.statusLabel,
          statusIcon: _loanStatusIcon(item.loan),
          statusColor: item.loan.statusColor,
          maturityLabel: _maturityLabel(item.loan),
          principalDue: _money(item.principalDue),
          interestDue: _money(item.netInterestDue),
          totalPayable: _money(item.totalPayable),
          onTap: () => _selectLoan(item),
        );
      },
    );

    return _LedgerSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: _LedgerSectionHeader(
              icon: GirviIcons.ticket,
              color: GirviColors.info,
              title: title,
              subtitle:
                  '${loans.length} visible record${loans.length == 1 ? '' : 's'}',
            ),
          ),
          const Divider(height: 1, color: GirviColors.divider),
          if (loans.isEmpty)
            SizedBox(
              height: compact ? 280 : 360,
              child: _LedgerEmptyState(
                icon: GirviIcons.search,
                title: 'No Matching Tickets',
                message: 'Change the search text or select another filter.',
                action: _searchController.text.isEmpty
                    ? null
                    : _LedgerPrimaryButton(
                        icon: Icons.close_rounded,
                        label: 'Clear Search',
                        onTap: _clearSearch,
                      ),
              ),
            )
          else if (compact)
            list
          else
            Expanded(child: list),
        ],
      ),
    );
  }
}

class _LedgerTicketRow extends StatelessWidget {
  final bool selected;
  final String ticketNo;
  final String customerName;
  final String customerMeta;
  final String itemSummary;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusColor;
  final String maturityLabel;
  final String principalDue;
  final String interestDue;
  final String totalPayable;
  final VoidCallback onTap;

  const _LedgerTicketRow({
    required this.selected,
    required this.ticketNo,
    required this.customerName,
    required this.customerMeta,
    required this.itemSummary,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
    required this.maturityLabel,
    required this.principalDue,
    required this.interestDue,
    required this.totalPayable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? GirviColors.brandGold.withValues(alpha: 0.08)
                    : GirviColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      selected ? GirviColors.brandGold : GirviColors.cardBorder,
                ),
              ),
              child: compact ? _buildCompactRow() : _buildWideRow(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideRow() {
    return Row(
      children: [
        _LedgerIconBox(icon: statusIcon, color: statusColor),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: _TicketIdentityBlock(
            ticketNo: ticketNo,
            customerName: customerName,
            customerMeta: customerMeta,
            itemSummary: itemSummary,
            statusLabel: statusLabel,
            statusColor: statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _TicketAmountBlock(
            label: 'Principal Due',
            value: principalDue,
            color: GirviColors.textDark,
          ),
        ),
        Expanded(
          flex: 2,
          child: _TicketAmountBlock(
            label: 'Interest Due',
            value: interestDue,
            color: GirviColors.warning,
          ),
        ),
        Expanded(
          flex: 2,
          child: _TicketAmountBlock(
            label: 'Net Payable',
            value: totalPayable,
            color: GirviColors.success,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: _TicketMaturityBlock(label: maturityLabel),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: GirviColors.textMuted,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildCompactRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LedgerIconBox(icon: statusIcon, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: _TicketIdentityBlock(
                ticketNo: ticketNo,
                customerName: customerName,
                customerMeta: customerMeta,
                itemSummary: itemSummary,
                statusLabel: statusLabel,
                statusColor: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 150,
              child: _TicketAmountBlock(
                label: 'Principal Due',
                value: principalDue,
                color: GirviColors.textDark,
              ),
            ),
            SizedBox(
              width: 150,
              child: _TicketAmountBlock(
                label: 'Interest Due',
                value: interestDue,
                color: GirviColors.warning,
              ),
            ),
            SizedBox(
              width: 150,
              child: _TicketAmountBlock(
                label: 'Net Payable',
                value: totalPayable,
                color: GirviColors.success,
              ),
            ),
            SizedBox(
              width: 150,
              child: _TicketMaturityBlock(label: maturityLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _TicketIdentityBlock extends StatelessWidget {
  final String ticketNo;
  final String customerName;
  final String customerMeta;
  final String itemSummary;
  final String statusLabel;
  final Color statusColor;

  const _TicketIdentityBlock({
    required this.ticketNo,
    required this.customerName,
    required this.customerMeta,
    required this.itemSummary,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                ticketNo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GirviStyles.ticketNumber,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _LedgerStatusBadge(
                icon: Icons.circle,
                label: statusLabel,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: GirviColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          customerMeta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: GirviColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          itemSummary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: GirviColors.textBody,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TicketAmountBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TicketAmountBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketMaturityBlock extends StatelessWidget {
  final String label;

  const _TicketMaturityBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maturity',
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
