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
                      child: _buildTicketRegister(compact: false),
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
    return Column(
      children: [
        _buildPortfolioOverview(),
        const SizedBox(height: 12),
        _buildLedgerControls(),
        const SizedBox(height: 12),
        Expanded(
          child: _controller.hasLoans
              ? ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildTicketRegister(compact: true),
                    const SizedBox(height: 12),
                    _buildLedgerDetailPanel(
                      item: _selectedLoan,
                      compact: true,
                    ),
                  ],
                )
              : _buildFirstRunEmptyState(),
        ),
      ],
    );
  }

  Widget _buildFirstRunEmptyState() {
    return _LedgerSurface(
      child: _LedgerEmptyState(
        icon: GirviIcons.moduleIcon,
        title: 'No Girvi Tickets',
        message: 'Create the first Girvi ticket to start the ledger.',
        action: widget.onNewGirvi == null
            ? null
            : _LedgerPrimaryButton(
                icon: Icons.add_rounded,
                label: 'New Girvi',
                onTap: _openNewGirvi,
              ),
      ),
    );
  }
}
