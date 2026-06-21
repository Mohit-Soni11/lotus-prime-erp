part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDetailLayout on _GirviAccountDetailScreenState {
  Widget _buildAccountDetailBody(GirviLoanWithCustomer account) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1180;
        final horizontalPadding = wide ? 22.0 : 14.0;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAccountHero(account),
                    const SizedBox(height: 14),
                    _buildFinancialOverview(account),
                    const SizedBox(height: 14),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: [
                                _buildPledgedItemPanel(account),
                                const SizedBox(height: 14),
                                _buildLoanTermsPanel(account),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildDeliveryPanel(account),
                                const SizedBox(height: 14),
                                _buildPaymentLedger(
                                  account,
                                  _controller.payments,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _buildPledgedItemPanel(account),
                      const SizedBox(height: 14),
                      _buildLoanTermsPanel(account),
                      const SizedBox(height: 14),
                      _buildDeliveryPanel(account),
                      const SizedBox(height: 14),
                      _buildPaymentLedger(account, _controller.payments),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
