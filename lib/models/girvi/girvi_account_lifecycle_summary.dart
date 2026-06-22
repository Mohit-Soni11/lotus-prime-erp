import 'girvi_enums.dart';
import 'girvi_loan_model.dart';

enum GirviLifecycleTileKind {
  runningPeriod,
  closedPeriod,
  settlementComplete,
  settlementPending,
  deliveryDelivered,
  deliveryReady,
  deliveryPending,
}

class GirviLifecycleTile {
  final GirviLifecycleTileKind kind;
  final String title;
  final String value;
  final String subtitle;

  const GirviLifecycleTile({
    required this.kind,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class GirviAccountLifecycleSummary {
  final GirviLifecycleTile period;
  final GirviLifecycleTile settlement;
  final GirviLifecycleTile delivery;
  final bool settlementComplete;
  final bool delivered;

  const GirviAccountLifecycleSummary({
    required this.period,
    required this.settlement,
    required this.delivery,
    required this.settlementComplete,
    required this.delivered,
  });

  factory GirviAccountLifecycleSummary.fromAccount(
    GirviLoanWithCustomer account, {
    DateTime? now,
    String Function(DateTime?) dateLabel = _fallbackDateLabel,
    String Function(DateTime?) dateTimeLabel = _fallbackDateLabel,
    String Function(double value) moneyLabel = _fallbackMoneyLabel,
  }) {
    final loan = account.loan;
    final delivered =
        loan.deliveredAt != null || loan.girviStatus == GirviStatus.released;
    final settlementComplete = isSettlementComplete(account);
    final rawRefDate =
        loan.deliveredAt ?? loan.releaseDate ?? now ?? DateTime.now();
    final refDate =
        rawRefDate.isBefore(loan.startDate) ? loan.startDate : rawRefDate;
    final elapsed =
        GirviLoanModel.elapsedPeriodBetween(loan.startDate, refDate);
    final elapsedDays = refDate.difference(loan.startDate).inDays;
    final chargeableMonths =
        GirviLoanModel.chargeableMonthsBetween(loan.startDate, refDate);

    return GirviAccountLifecycleSummary(
      period: GirviLifecycleTile(
        kind: delivered
            ? GirviLifecycleTileKind.closedPeriod
            : GirviLifecycleTileKind.runningPeriod,
        title: delivered ? 'Closed Period' : 'Running Period',
        value: elapsed.displayLabel,
        subtitle:
            '$elapsedDays total day${elapsedDays == 1 ? '' : 's'} | $chargeableMonths bill month${chargeableMonths == 1 ? '' : 's'}',
      ),
      settlement: GirviLifecycleTile(
        kind: settlementComplete
            ? GirviLifecycleTileKind.settlementComplete
            : GirviLifecycleTileKind.settlementPending,
        title:
            settlementComplete ? 'Settlement Complete' : 'Settlement Pending',
        value: settlementComplete
            ? 'Balance cleared'
            : moneyLabel(account.totalPayable),
        subtitle: settlementComplete
            ? 'Principal and interest cleared'
            : 'Net payable remaining',
      ),
      delivery: GirviLifecycleTile(
        kind: delivered
            ? GirviLifecycleTileKind.deliveryDelivered
            : settlementComplete
                ? GirviLifecycleTileKind.deliveryReady
                : GirviLifecycleTileKind.deliveryPending,
        title: delivered
            ? 'Delivery Delivered'
            : settlementComplete
                ? 'Delivery Pending'
                : 'Delivery Pending',
        value: delivered
            ? 'Delivered'
            : settlementComplete
                ? 'Pickup pending'
                : 'Not delivered',
        subtitle: delivered
            ? 'Done ${dateTimeLabel(loan.deliveredAt ?? loan.releaseDate)}'
            : settlementComplete
                ? 'Expected ${dateLabel(loan.expectedDeliveryDate)}'
                : 'Settle balance before delivery',
      ),
      settlementComplete: settlementComplete,
      delivered: delivered,
    );
  }

  static bool isSettlementComplete(GirviLoanWithCustomer account) {
    final loan = account.loan;
    return account.totalPayable <= 0.01 ||
        loan.girviStatus == GirviStatus.readyForDelivery ||
        loan.girviStatus == GirviStatus.released ||
        loan.deliveredAt != null;
  }
}

String _fallbackDateLabel(DateTime? value) {
  if (value == null) return 'Not set';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _fallbackMoneyLabel(double value) => 'Rs ${value.round()}';
