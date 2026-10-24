import 'girvi_notice_action_model.dart';

/// Historical invoice amounts fixed when collateral recovery closed the account.
class GirviRecoveryClosureSnapshot {
  const GirviRecoveryClosureSnapshot({
    required this.totalDueAtClosure,
    required this.actualProceeds,
    required this.recoveryDueAtClosure,
    required this.closedAt,
    required this.disposition,
  });

  final double totalDueAtClosure;
  final double actualProceeds;
  final double recoveryDueAtClosure;
  final DateTime closedAt;
  final String disposition;

  bool get isMelted => disposition == 'MELTED';

  factory GirviRecoveryClosureSnapshot.fromAction(
    GirviNoticeAction action, {
    required String disposition,
  }) =>
      GirviRecoveryClosureSnapshot(
        totalDueAtClosure: action.settlementTotal,
        actualProceeds: action.recoveredAmount,
        recoveryDueAtClosure: action.customerBalanceDue,
        closedAt: action.actionAt,
        disposition: disposition.trim().toUpperCase(),
      );
}
