import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';

class ReturnReversalState {
  final ReturnReversalOperationType operationType;
  final ReturnReversalTransactionSummary summary;
  final ReturnReversalLookupResult lookupResult;
  final ReturnReversalSourceDocument? selectedSourceDocument;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String? lookupMessage;

  const ReturnReversalState({
    required this.operationType,
    required this.summary,
    required this.lookupResult,
    required this.selectedSourceDocument,
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
        isLoading = false,
        isSearching = false,
        errorMessage = null,
        lookupMessage = null;

  ReturnReversalState copyWith({
    ReturnReversalOperationType? operationType,
    ReturnReversalTransactionSummary? summary,
    ReturnReversalLookupResult? lookupResult,
    ReturnReversalSourceDocument? selectedSourceDocument,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? lookupMessage,
    bool clearError = false,
    bool clearLookupMessage = false,
    bool clearSelectedSourceDocument = false,
  }) {
    return ReturnReversalState(
      operationType: operationType ?? this.operationType,
      summary: summary ?? this.summary,
      lookupResult: lookupResult ?? this.lookupResult,
      selectedSourceDocument: clearSelectedSourceDocument
          ? null
          : selectedSourceDocument ?? this.selectedSourceDocument,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lookupMessage:
          clearLookupMessage ? null : lookupMessage ?? this.lookupMessage,
    );
  }
}
