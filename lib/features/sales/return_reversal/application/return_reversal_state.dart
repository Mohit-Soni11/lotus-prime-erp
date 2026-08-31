import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_workflow_step.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';

class ReturnReversalState {
  final ReturnReversalOperationType operationType;
  final ReturnReversalTransactionSummary summary;
  final ReturnReversalLookupResult lookupResult;
  final ReturnReversalSourceDocument? selectedSourceDocument;
  final Set<int> selectedLineNumbers;
  final ReturnReversalWorkflowStep activeWorkflowStep;
  final int? activeInspectionLineNo;
  final Map<int, ReturnReversalLineInspectionDraft> lineInspectionDrafts;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String? lookupMessage;

  const ReturnReversalState({
    required this.operationType,
    required this.summary,
    required this.lookupResult,
    required this.selectedSourceDocument,
    required this.selectedLineNumbers,
    required this.activeWorkflowStep,
    required this.activeInspectionLineNo,
    required this.lineInspectionDrafts,
    required this.isLoading,
    required this.isSearching,
    required this.errorMessage,
    required this.lookupMessage,
  });

  const ReturnReversalState.initial()
      : operationType = ReturnReversalOperationType.salesReturn,
        summary = const ReturnReversalTransactionSummary.empty(),
        lookupResult = const ReturnReversalLookupResult.empty(),
        selectedSourceDocument = null,
        selectedLineNumbers = const {},
        activeWorkflowStep = ReturnReversalWorkflowStep.invoiceItems,
        activeInspectionLineNo = null,
        lineInspectionDrafts = const {},
        isLoading = false,
        isSearching = false,
        errorMessage = null,
        lookupMessage = null;

  ReturnReversalState copyWith({
    ReturnReversalOperationType? operationType,
    ReturnReversalTransactionSummary? summary,
    ReturnReversalLookupResult? lookupResult,
    ReturnReversalSourceDocument? selectedSourceDocument,
    Set<int>? selectedLineNumbers,
    ReturnReversalWorkflowStep? activeWorkflowStep,
    int? activeInspectionLineNo,
    Map<int, ReturnReversalLineInspectionDraft>? lineInspectionDrafts,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? lookupMessage,
    bool clearError = false,
    bool clearLookupMessage = false,
    bool clearSelectedSourceDocument = false,
    bool clearSelectedLineNumbers = false,
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
      selectedLineNumbers: clearSelectedLineNumbers
          ? const {}
          : selectedLineNumbers ?? this.selectedLineNumbers,
      activeWorkflowStep: activeWorkflowStep ?? this.activeWorkflowStep,
      activeInspectionLineNo: clearActiveInspectionLineNo
          ? null
          : activeInspectionLineNo ?? this.activeInspectionLineNo,
      lineInspectionDrafts: clearLineInspectionDrafts
          ? const {}
          : lineInspectionDrafts ?? this.lineInspectionDrafts,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lookupMessage:
          clearLookupMessage ? null : lookupMessage ?? this.lookupMessage,
    );
  }

  List<ReturnReversalSourceLineItem> get selectedLineItems {
    final document = selectedSourceDocument;
    if (document == null || selectedLineNumbers.isEmpty) {
      return const [];
    }
    return document.lineItems
        .where((line) => selectedLineNumbers.contains(line.lineNo))
        .toList(growable: false);
  }

  bool get hasSelectedLineItems => selectedLineItems.isNotEmpty;

  ReturnReversalSourceLineItem? get activeInspectionLineItem {
    final document = selectedSourceDocument;
    final lineNo = activeInspectionLineNo;
    if (document == null || lineNo == null) {
      return selectedLineItems.isEmpty ? null : selectedLineItems.first;
    }
    for (final line in document.lineItems) {
      if (line.lineNo == lineNo && selectedLineNumbers.contains(line.lineNo)) {
        return line;
      }
    }
    return selectedLineItems.isEmpty ? null : selectedLineItems.first;
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
