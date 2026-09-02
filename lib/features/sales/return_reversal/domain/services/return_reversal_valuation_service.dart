import 'dart:math' as math;

import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';

class ReturnReversalValuationService {
  const ReturnReversalValuationService();

  ReturnReversalLineValuation valueLine({
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
  }) {
    final ratio = _receivedWeightRatio(
      soldNetWeight: sourceLine.netWeight,
      receivedNetWeight: returnLine.receivedNetWeight,
    );
    final adjustedLineAmount = sourceLine.displayLineTotal * ratio;
    final adjustedMakingAmount = sourceLine.makingAmount * ratio;
    final metalAmount =
        math.max(0.0, adjustedLineAmount - adjustedMakingAmount);
    final makingReturnedAmount =
        returnLine.includeMakingCharge ? adjustedMakingAmount : 0.0;

    return ReturnReversalLineValuation(
      receivedRatio: ratio,
      adjustedLineAmount: adjustedLineAmount,
      adjustedMakingAmount: adjustedMakingAmount,
      metalAmount: metalAmount,
      makingReturnedAmount: makingReturnedAmount,
      returnValue: metalAmount + makingReturnedAmount,
    );
  }

  double totalReturnValue({
    required ReturnReversalSourceDocument sourceDocument,
    required List<ReturnReversalProcessLineInput> returnLines,
  }) {
    return returnLines.fold<double>(0, (total, returnLine) {
      final sourceLine = sourceDocument.lineByNo(returnLine.sourceLineNo);
      if (sourceLine == null) {
        return total;
      }
      return total +
          valueLine(sourceLine: sourceLine, returnLine: returnLine).returnValue;
    });
  }

  double _receivedWeightRatio({
    required double soldNetWeight,
    required double receivedNetWeight,
  }) {
    if (soldNetWeight <= 0) {
      return 1;
    }
    return (receivedNetWeight / soldNetWeight).clamp(0.0, 1.0);
  }
}
