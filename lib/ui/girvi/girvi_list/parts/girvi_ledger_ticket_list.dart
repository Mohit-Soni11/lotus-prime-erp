part of '../girvi_list_screen.dart';

extension _GirviLedgerTicketList on _GirviListScreenState {
  String get _registerTitle => _controller.filter == GirviFilter.all
      ? 'Pledge Account Register'
      : '${_controller.filter.displayName} Register';

  Widget _buildRegisterHeading() {
    final count = _controller.loans.length;
    return _LedgerSectionHeader(
      icon: GirviIcons.ticket,
      color: GirviColors.info,
      title: _registerTitle,
      subtitle:
          '$count visible account${count == 1 ? '' : 's'} · Ticket number order',
    );
  }

  Widget _buildTicketRegister() {
    final loans = _controller.loans;
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
                  child: _buildRegisterHeading(),
                ),
                const Divider(height: 1, color: GirviColors.divider),
                if (loans.isEmpty)
                  SizedBox(height: 300, child: _buildRegisterEmptyState())
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: loans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) =>
                          _buildRegisterRow(loans[index]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRegisterHeading() => _LedgerSurface(
        child: _buildRegisterHeading(),
      );

  Widget _buildRegisterEmptyState() => _LedgerEmptyState(
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
      );

  Widget _buildRegisterRow(GirviLoanWithCustomer item) {
    final rowKey = _ticketRowKeys.putIfAbsent(
      item.loan.id,
      () => GlobalKey(debugLabel: 'girvi-ticket-${item.loan.id}'),
    );
    return KeyedSubtree(
      key: rowKey,
      child: _LedgerTicketRow(
        data: item,
        quote: item.interestQuoteAt(),
        selected: _isSelected(item),
        customerMeta: _compactCustomerLocation(item),
        money: _money,
        date: _date,
        onTap: () => _selectLoan(item),
        onDoubleTap: () => _openTicketAccount(item),
      ),
    );
  }
}
