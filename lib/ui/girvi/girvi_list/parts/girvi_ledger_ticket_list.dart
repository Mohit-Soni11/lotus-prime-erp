part of '../girvi_list_screen.dart';

extension _GirviLedgerTicketList on _GirviListScreenState {
  Widget _buildTicketRegister({required bool compact}) {
    final loans = _controller.loans;
    final title = _controller.filter == GirviFilter.all
        ? 'Pledge Account Register'
        : '${_controller.filter.displayName} Accounts';

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
        final rowKey = _ticketRowKeys.putIfAbsent(
          item.loan.id,
          () => GlobalKey(debugLabel: 'girvi-ticket-${item.loan.id}'),
        );
        final principalDueColor = _dueAmountColor(item.principalDue);
        final interestDueColor = _dueAmountColor(item.netInterestDue);
        final totalPayableColor = _dueAmountColor(item.totalPayable);
        return KeyedSubtree(
          key: rowKey,
          child: _LedgerTicketRow(
            selected: _isSelected(item),
            ticketNo: item.loan.ticketNo,
            customerName: item.customerName,
            customerMeta: _compactCustomerLocation(item),
            itemSummary: item.loan.itemSummary,
            statusLabel: item.loan.statusLabel,
            statusIcon: _loanStatusIcon(item.loan),
            statusColor: item.loan.statusColor,
            timelineTitle: _ticketTimelineTitle(item.loan),
            timelineValue: _ticketTimelineValue(item.loan),
            timelineColor: _ticketTimelineColor(
              item.loan,
              hasDueAmount: item.totalPayable > 0.005,
            ),
            principalDue: _money(item.principalDue),
            interestDue: _money(item.netInterestDue),
            totalPayable: _money(item.totalPayable),
            principalDueColor: principalDueColor,
            interestDueColor: interestDueColor,
            totalPayableColor: totalPayableColor,
            onTap: () => _selectLoan(item),
            onDoubleTap: () => _openTicketAccount(item),
          ),
        );
      },
    );

    return MouseRegion(
      onEnter: (_) => _setTicketRegisterPointerInside(true),
      onExit: (_) => _setTicketRegisterPointerInside(false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _activateTicketRegisterNavigation(),
        child: Focus(
          focusNode: _ticketRegisterFocusNode,
          onKeyEvent: _handleTicketRegisterKey,
          child: _LedgerSurface(
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
                        '${loans.length} visible account${loans.length == 1 ? '' : 's'}',
                  ),
                ),
                const Divider(height: 1, color: GirviColors.divider),
                if (loans.isEmpty)
                  SizedBox(
                    height: compact ? 280 : 360,
                    child: _LedgerEmptyState(
                      icon: GirviIcons.search,
                      title: 'No Matching Accounts',
                      message: 'Change the search text or select another view.',
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
          ),
        ),
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
  final String timelineTitle;
  final String timelineValue;
  final Color timelineColor;
  final String principalDue;
  final String interestDue;
  final String totalPayable;
  final Color principalDueColor;
  final Color interestDueColor;
  final Color totalPayableColor;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _LedgerTicketRow({
    required this.selected,
    required this.ticketNo,
    required this.customerName,
    required this.customerMeta,
    required this.itemSummary,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
    required this.timelineTitle,
    required this.timelineValue,
    required this.timelineColor,
    required this.principalDue,
    required this.interestDue,
    required this.totalPayable,
    required this.principalDueColor,
    required this.interestDueColor,
    required this.totalPayableColor,
    required this.onTap,
    required this.onDoubleTap,
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
            onDoubleTap: onDoubleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? GirviColors.info.withValues(alpha: 0.075)
                    : GirviColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? GirviColors.info.withValues(alpha: 0.48)
                      : GirviColors.cardBorder,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: GirviColors.info.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                ],
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
          flex: 5,
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
            color: principalDueColor,
          ),
        ),
        Expanded(
          flex: 2,
          child: _TicketAmountBlock(
            label: 'Interest Due',
            value: interestDue,
            color: interestDueColor,
          ),
        ),
        Expanded(
          flex: 2,
          child: _TicketAmountBlock(
            label: 'Net Payable',
            value: totalPayable,
            color: totalPayableColor,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          child: _TicketTimelineBlock(
            title: timelineTitle,
            value: timelineValue,
            valueColor: timelineColor,
          ),
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
                color: principalDueColor,
              ),
            ),
            SizedBox(
              width: 150,
              child: _TicketAmountBlock(
                label: 'Interest Due',
                value: interestDue,
                color: interestDueColor,
              ),
            ),
            SizedBox(
              width: 150,
              child: _TicketAmountBlock(
                label: 'Net Payable',
                value: totalPayable,
                color: totalPayableColor,
              ),
            ),
            SizedBox(
              width: 150,
              child: _TicketTimelineBlock(
                title: timelineTitle,
                value: timelineValue,
                valueColor: timelineColor,
              ),
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
            fontSize: 12.5,
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

class _TicketTimelineBlock extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _TicketTimelineBlock({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 12.5,
            height: 1.18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
