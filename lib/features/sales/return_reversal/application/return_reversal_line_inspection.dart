import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';

enum ReturnReversalStockRoute {
  addToStock(
    label: 'Add Stock',
    subtitle: 'Return to sellable stock',
  ),
  melting(
    label: 'Melting',
    subtitle: 'Send to metal purchase flow',
  ),
  managerHold(
    label: 'Hold',
    subtitle: 'Manager review required',
  );

  final String label;
  final String subtitle;

  const ReturnReversalStockRoute({
    required this.label,
    required this.subtitle,
  });

  ReturnReversalStockDisposition get disposition {
    return switch (this) {
      ReturnReversalStockRoute.addToStock =>
        ReturnReversalStockDisposition.addToStock,
      ReturnReversalStockRoute.melting =>
        ReturnReversalStockDisposition.melting,
      ReturnReversalStockRoute.managerHold =>
        ReturnReversalStockDisposition.managerHold,
    };
  }
}

class ReturnReversalLineInspectionDraft {
  final int lineNo;
  final double receivedNetWeight;
  final bool huidMatched;
  final bool unitMatched;
  final bool includeMakingCharge;
  final ReturnReversalStockRoute stockRoute;

  const ReturnReversalLineInspectionDraft({
    required this.lineNo,
    required this.receivedNetWeight,
    required this.huidMatched,
    required this.unitMatched,
    required this.includeMakingCharge,
    required this.stockRoute,
  });

  factory ReturnReversalLineInspectionDraft.fromLine(
    ReturnReversalSourceLineItem lineItem,
  ) {
    final stockRoute = _stockRouteFromDisposition(
      lineItem.reversalStockDisposition,
    );
    return ReturnReversalLineInspectionDraft(
      lineNo: lineItem.lineNo,
      receivedNetWeight:
          lineItem.reversalReceivedNetWeight ?? lineItem.netWeight,
      huidMatched: lineItem.reversalHuidMatched ?? true,
      unitMatched: lineItem.reversalUnitMatched ?? true,
      includeMakingCharge: lineItem.reversalIncludeMakingCharge ?? false,
      stockRoute: stockRoute,
    );
  }

  ReturnReversalLineInspectionDraft copyWith({
    double? receivedNetWeight,
    bool? huidMatched,
    bool? unitMatched,
    bool? includeMakingCharge,
    ReturnReversalStockRoute? stockRoute,
  }) {
    return ReturnReversalLineInspectionDraft(
      lineNo: lineNo,
      receivedNetWeight: receivedNetWeight ?? this.receivedNetWeight,
      huidMatched: huidMatched ?? this.huidMatched,
      unitMatched: unitMatched ?? this.unitMatched,
      includeMakingCharge: includeMakingCharge ?? this.includeMakingCharge,
      stockRoute: stockRoute ?? this.stockRoute,
    );
  }
}

ReturnReversalStockRoute _stockRouteFromDisposition(String disposition) {
  final normalized = disposition.trim().toUpperCase();
  return switch (normalized) {
    'MELTING' => ReturnReversalStockRoute.melting,
    'MANAGER_HOLD' => ReturnReversalStockRoute.managerHold,
    _ => ReturnReversalStockRoute.addToStock,
  };
}
