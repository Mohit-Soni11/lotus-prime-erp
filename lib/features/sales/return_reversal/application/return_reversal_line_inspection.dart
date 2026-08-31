import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';

enum ReturnReversalStockRoute {
  addToStock(
    label: 'Add Stock',
    subtitle: 'Return to sellable stock',
    icon: Icons.inventory_2_rounded,
  ),
  melting(
    label: 'Melting',
    subtitle: 'Send to metal purchase flow',
    icon: Icons.local_fire_department_rounded,
  ),
  managerHold(
    label: 'Hold',
    subtitle: 'Manager review required',
    icon: Icons.admin_panel_settings_rounded,
  );

  final String label;
  final String subtitle;
  final IconData icon;

  const ReturnReversalStockRoute({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
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
    return ReturnReversalLineInspectionDraft(
      lineNo: lineItem.lineNo,
      receivedNetWeight: lineItem.netWeight,
      huidMatched: true,
      unitMatched: true,
      includeMakingCharge: false,
      stockRoute: ReturnReversalStockRoute.addToStock,
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
