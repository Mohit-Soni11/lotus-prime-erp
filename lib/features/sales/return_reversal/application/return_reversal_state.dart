import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_workflow_step.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';

class ReturnReversalState {
  final ReturnReversalOperationType operationType;
  final ReturnReversalTransactionSummary summary;
  final ReturnReversalLookupResult lookupResult;
  final ReturnReversalSourceDocument? selectedSourceDocument;
  final Set<int> returnCartLineNumbers;
  final ReturnReversalWorkflowStep activeWorkflowStep;
  final int? activeInspectionLineNo;
  final Map<int, ReturnReversalLineInspectionDraft> lineInspectionDrafts;
  final bool isProcessing;
  final ReturnReversalProcessResult? lastProcessResult;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String? lookupMessage;
  final String? processMessage;

  const ReturnReversalState({
    required this.operationType,
    required this.summary,
    required this.lookupResult,
    required this.selectedSourceDocument,
    required this.returnCartLineNumbers,
    required this.activeWorkflowStep,
    required this.activeInspectionLineNo,
    required this.lineInspectionDrafts,
    required this.isProcessing,
    required this.lastProcessResult,
    required this.isLoading,
    required this.isSearching,
    required this.errorMessage,
    required this.lookupMessage,
    required this.processMessage,
  });

  const ReturnReversalState.initial()
      : operationType = ReturnReversalOperationType.salesReturn,
        summary = const ReturnReversalTransactionSummary.empty(),
        lookupResult = const ReturnReversalLookupResult.empty(),
        selectedSourceDocument = null,
        returnCartLineNumbers = const {},
        activeWorkflowStep = ReturnReversalWorkflowStep.invoiceItems,
        activeInspectionLineNo = null,
        lineInspectionDrafts = const {},
        isProcessing = false,
        lastProcessResult = null,
        isLoading = false,
        isSearching = false,
        errorMessage = null,
        lookupMessage = null,
        processMessage = null;

  ReturnReversalState copyWith({
    ReturnReversalOperationType? operationType,
    ReturnReversalTransactionSummary? summary,
    ReturnReversalLookupResult? lookupResult,
    ReturnReversalSourceDocument? selectedSourceDocument,
    Set<int>? returnCartLineNumbers,
    ReturnReversalWorkflowStep? activeWorkflowStep,
    int? activeInspectionLineNo,
    Map<int, ReturnReversalLineInspectionDraft>? lineInspectionDrafts,
    bool? isProcessing,
    ReturnReversalProcessResult? lastProcessResult,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? lookupMessage,
    String? processMessage,
    bool clearError = false,
    bool clearLookupMessage = false,
    bool clearProcessMessage = false,
    bool clearLastProcessResult = false,
    bool clearSelectedSourceDocument = false,
    bool clearReturnCartLineNumbers = false,
    bool clearActiveInspectionLineNo = false,
    bool clearLineInspectionDrafts = false,
  }) {
    return ReturnReversalState(
      operationType: operationType ?? this.operationType,
      summary: summary ?? this.summary,
      lookupResult: lookupResult ?? this.lookupResult,
      selectedSourceDocument: clearSelectedSourceDocument
          ? null
          : selectedSourceDocument ?? this.selectedSourceDocument,
      returnCartLineNumbers: clearReturnCartLineNumbers
          ? const {}
          : returnCartLineNumbers ?? this.returnCartLineNumbers,
      activeWorkflowStep: activeWorkflowStep ?? this.activeWorkflowStep,
      activeInspectionLineNo: clearActiveInspectionLineNo
          ? null
          : activeInspectionLineNo ?? this.activeInspectionLineNo,
      lineInspectionDrafts: clearLineInspectionDrafts
          ? const {}
          : lineInspectionDrafts ?? this.lineInspectionDrafts,
      isProcessing: isProcessing ?? this.isProcessing,
      lastProcessResult: clearLastProcessResult
          ? null
          : lastProcessResult ?? this.lastProcessResult,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lookupMessage:
          clearLookupMessage ? null : lookupMessage ?? this.lookupMessage,
      processMessage:
          clearProcessMessage ? null : processMessage ?? this.processMessage,
    );
  }

  List<ReturnReversalSourceLineItem> get invoiceLineItems {
    return selectedSourceDocument?.lineItems ?? const [];
  }

  List<ReturnReversalSourceLineItem> get returnCartLineItems {
    final document = selectedSourceDocument;
    if (document == null || returnCartLineNumbers.isEmpty) {
      return const [];
    }
    return document.lineItems
        .where((line) => returnCartLineNumbers.contains(line.lineNo))
        .toList(growable: false);
  }

  bool get hasReturnCartLineItems => returnCartLineItems.isNotEmpty;

  ReturnReversalSourceLineItem? get activeInspectionLineItem {
    final document = selectedSourceDocument;
    final lineNo = activeInspectionLineNo;
    if (document == null || lineNo == null) {
      return invoiceLineItems.isEmpty ? null : invoiceLineItems.first;
    }
    for (final line in document.lineItems) {
      if (line.lineNo == lineNo) {
        return line;
      }
    }
    return invoiceLineItems.isEmpty ? null : invoiceLineItems.first;
  }

  ReturnReversalLineInspectionDraft? get activeInspectionDraft {
    final lineItem = activeInspectionLineItem;
    if (lineItem == null) {
      return null;
    }
    return lineInspectionDrafts[lineItem.lineNo] ??
        ReturnReversalLineInspectionDraft.fromLine(lineItem);
  }
}
