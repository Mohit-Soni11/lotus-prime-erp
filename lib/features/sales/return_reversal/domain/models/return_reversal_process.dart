import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';

enum ReturnReversalStockDisposition {
  addToStock('ADD_STOCK'),
  melting('MELTING'),
  managerHold('MANAGER_HOLD'),
  notApplicable('NOT_APPLICABLE');

  final String storageValue;

  const ReturnReversalStockDisposition(this.storageValue);
}

enum ReturnReversalSettlementMode {
  customerCredit('CUSTOMER_CREDIT');

  final String storageValue;

  const ReturnReversalSettlementMode(this.storageValue);
}

class ReturnReversalProcessLineInput {
  final int sourceLineNo;
  final double receivedNetWeight;
  final bool huidMatched;
  final bool unitMatched;
  final bool includeMakingCharge;
  final ReturnReversalStockDisposition stockDisposition;

  const ReturnReversalProcessLineInput({
    required this.sourceLineNo,
    required this.receivedNetWeight,
    required this.huidMatched,
    required this.unitMatched,
    required this.includeMakingCharge,
    required this.stockDisposition,
  });
}

class ReturnReversalProcessRequest {
  final ReturnReversalOperationType operationType;
  final ReturnReversalSourceDocument sourceDocument;
  final List<ReturnReversalProcessLineInput> lines;
  final ReturnReversalSettlementMode settlementMode;
  final String operatorNote;

  const ReturnReversalProcessRequest({
    required this.operationType,
    required this.sourceDocument,
    required this.lines,
    this.settlementMode = ReturnReversalSettlementMode.customerCredit,
    this.operatorNote = '',
  });
}

class ReturnReversalLineValuation {
  final double receivedRatio;
  final double adjustedLineAmount;
  final double adjustedMakingAmount;
  final double metalAmount;
  final double makingReturnedAmount;
  final double returnValue;

  const ReturnReversalLineValuation({
    required this.receivedRatio,
    required this.adjustedLineAmount,
    required this.adjustedMakingAmount,
    required this.metalAmount,
    required this.makingReturnedAmount,
    required this.returnValue,
  });
}

class ReturnReversalProcessResult {
  final int voucherId;
  final String voucherNo;
  final int processedLineCount;
  final double returnValue;
  final double dueAdjustedAmount;
  final double customerCreditAmount;
  final String status;

  const ReturnReversalProcessResult({
    required this.voucherId,
    required this.voucherNo,
    required this.processedLineCount,
    required this.returnValue,
    required this.dueAdjustedAmount,
    required this.customerCreditAmount,
    required this.status,
  });
}
