// =============================================================================
// FILE        : defaulter_data_table.dart
// MODULE      : Risk & Collections
// DESCRIPTION : Premium collection register for pledge accounts requiring action.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../logic/customer/defaulter_logic.dart';
import '../../../models/customer/defaulter_model.dart';
import '../../../theme/customer/defaulter/defaulter_theme.dart';

part 'defaulter_risk_account_card.dart';
part 'defaulter_risk_account_identity.dart';
part 'defaulter_risk_account_metrics.dart';
part 'defaulter_risk_account_actions.dart';
part 'defaulter_risk_account_support.dart';
part 'defaulter_table_states.dart';

class DefaulterDataTable extends StatelessWidget {
  final List<DefaulterModel> defaulters;
  final bool showRecoveryHistory;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<DefaulterModel> onOpenAccount;
  final ValueChanged<DefaulterModel> onOpenInterestEntry;
  final ValueChanged<DefaulterModel> onOpenContactRecovery;

  const DefaulterDataTable({
    super.key,
    required this.defaulters,
    this.showRecoveryHistory = false,
    required this.isLoading,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenContactRecovery,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Container(
        decoration: DefaulterStyles.tableContainerDecoration,
        child: Column(
          children: [
            _QueueHeader(
              count: defaulters.length,
              showRecoveryHistory: showRecoveryHistory,
            ),
            Expanded(
              child: _QueueBody(
                defaulters: defaulters,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onOpenAccount: onOpenAccount,
                onOpenInterestEntry: onOpenInterestEntry,
                onOpenContactRecovery: onOpenContactRecovery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  final int count;
  final bool showRecoveryHistory;

  const _QueueHeader({
    required this.count,
    required this.showRecoveryHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: DefaulterStyles.tableHeaderDecoration,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DefaulterColors.brandGoldLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DefaulterColors.brandGold.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              DefaulterIcons.defaulterShield,
              size: 18,
              color: DefaulterColors.brandGoldDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showRecoveryHistory
                      ? 'Recovery Register'
                      : 'Collection Accounts',
                  style: DefaulterStyles.customerName.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  showRecoveryHistory
                      ? 'Recovery cases in progress and completed settlements'
                      : 'Review each pledge balance and choose the next action',
                  style: DefaulterStyles.customerCity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _HeaderBadge(label: '$count account${count == 1 ? '' : 's'}'),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;

  const _HeaderBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DefaulterColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DefaulterColors.bodyBorder),
      ),
      child: Text(
        label,
        style: DefaulterStyles.riskBadgeText.copyWith(
          color: DefaulterColors.bodyTextMain,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _QueueBody extends StatelessWidget {
  final List<DefaulterModel> defaulters;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<DefaulterModel> onOpenAccount;
  final ValueChanged<DefaulterModel> onOpenInterestEntry;
  final ValueChanged<DefaulterModel> onOpenContactRecovery;

  const _QueueBody({
    required this.defaulters,
    required this.isLoading,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenContactRecovery,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _ShimmerRows();
    if (errorMessage != null) return _ErrorState(message: errorMessage!);
    if (defaulters.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: defaulters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final account = defaulters[index];
        return _RiskAccountCard(
          key: ValueKey(account.loanId),
          account: account,
          onOpenAccount: () => onOpenAccount(account),
          onOpenInterestEntry: () => onOpenInterestEntry(account),
          onOpenContactRecovery: () => onOpenContactRecovery(account),
        );
      },
    );
  }
}
