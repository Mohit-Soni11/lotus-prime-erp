part of '../girvi_account_detail_screen.dart';

extension _GirviAccountRecoveryOverview on _GirviAccountDetailScreenState {
  Widget _buildRecoveryClosureOverview(
    GirviLoanWithCustomer account,
    GirviRecoveryClosureSnapshot closure,
  ) {
    final principalDue = account.principalDue;
    final interestDue = closure.totalDueAtClosure > principalDue
        ? closure.totalDueAtClosure - principalDue
        : 0.0;
    final cards = [
      _AccountBalanceCard(
        title: 'Principal Due at Closure',
        amount: _money(principalDue),
        icon: Icons.account_balance_rounded,
        color: GirviColors.info,
        compact: true,
      ),
      _AccountBalanceCard(
        title: 'Interest Due at Closure',
        amount: _money(interestDue),
        icon: GirviIcons.interestRate,
        color: GirviColors.warning,
        compact: true,
      ),
      _AccountBalanceCard(
        title: 'Total Due at Closure',
        amount: _money(closure.totalDueAtClosure),
        icon: Icons.receipt_long_rounded,
        color: GirviColors.danger,
        compact: true,
      ),
      if (!closure.isMelted)
        _AccountBalanceCard(
          title: 'Sale Proceeds Received',
          amount: _money(closure.actualProceeds),
          icon: GirviIcons.cash,
          color: GirviColors.success,
          compact: true,
        ),
      _AccountBalanceCard(
        title: 'Recovery Due at Closure',
        amount: _money(closure.recoveryDueAtClosure),
        icon: Icons.pending_actions_rounded,
        color: closure.recoveryDueAtClosure > 0
            ? GirviColors.danger
            : GirviColors.success,
        compact: true,
        note: 'Historical invoice amount; this account is closed.',
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 960
          ? 3
          : constraints.maxWidth >= 680
              ? 2
              : 1;
      const spacing = 12.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text('Recovery Closure', style: GirviStyles.sectionTitle),
        ),
        Text(
          closure.isMelted
              ? 'Item melted on ${_date(closure.closedAt)}. No cash receipt was recorded.'
              : 'Item sold on ${_date(closure.closedAt)}. Only actual sale proceeds were recorded.',
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        ),
      ]);
    });
  }
}
