part of '../girvi_list_screen.dart';

extension _GirviLedgerLayout on _GirviListScreenState {
  Widget _buildLedgerBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1120;
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: compact
                ? _buildCompactLedgerLayout()
                : _buildWideLedgerLayout(),
          );
        },
      ),
    );
  }

  Widget _buildWideLedgerLayout() {
    return Column(
      children: [
        _buildPortfolioOverview(),
        const SizedBox(height: 12),
        _buildLedgerControls(),
        const SizedBox(height: 12),
        Expanded(
          child: _controller.hasLoans
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildTicketRegister(),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 420,
                      child: _buildLedgerDetailPanel(
                        item: _selectedLoan,
                        compact: false,
                      ),
                    ),
                  ],
                )
              : _buildFirstRunEmptyState(),
        ),
      ],
    );
  }

  Widget _buildCompactLedgerLayout() {
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildPortfolioOverview()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildLedgerControls()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (!_controller.hasLoans)
                SliverToBoxAdapter(child: _buildFirstRunEmptyState())
              else ...[
                SliverToBoxAdapter(child: _buildCompactRegisterHeading()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (loans.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 260,
                      child: _buildRegisterEmptyState(),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _buildRegisterRow(loans[index]),
                      ),
                      childCount: loans.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _buildLedgerDetailPanel(
                    item: _selectedLoan,
                    compact: true,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstRunEmptyState() {
    return _LedgerSurface(
      child: _LedgerEmptyState(
        icon: GirviIcons.moduleIcon,
        title: 'No Pledge Accounts',
        message: 'Create the first pledge account to start the ledger.',
        action: widget.onNewGirvi == null
            ? null
            : _LedgerPrimaryButton(
                icon: Icons.add_rounded,
                label: 'New Pledge Ticket',
                onTap: _openNewGirvi,
              ),
      ),
    );
  }
}
