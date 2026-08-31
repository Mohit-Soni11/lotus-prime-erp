import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_workflow_step.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/repositories/return_reversal_repository.dart';

class ReturnReversalController extends ChangeNotifier {
  final ReturnReversalRepository _repository;

  ReturnReversalState _state = const ReturnReversalState.initial();
  final TextEditingController customerMobileCtrl = TextEditingController();
  final TextEditingController customerNameCtrl = TextEditingController();
  final TextEditingController sourceDocumentNumberCtrl =
      TextEditingController();
  final TextEditingController customerAddressCtrl = TextEditingController();

  ReturnReversalController({
    required ReturnReversalRepository repository,
  }) : _repository = repository {
    customerMobileCtrl.addListener(notifyListeners);
    customerNameCtrl.addListener(notifyListeners);
    sourceDocumentNumberCtrl.addListener(notifyListeners);
    customerAddressCtrl.addListener(notifyListeners);
  }

  ReturnReversalState get state => _state;

  Future<void> load() async {
    _setState(_state.copyWith(isLoading: true, clearError: true));

    try {
      final summary = await _repository.fetchTransactionSummary();
      _setState(
        _state.copyWith(
          summary: summary,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (exception) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: exception.toString(),
        ),
      );
    }
  }

  void selectOperationType(ReturnReversalOperationType operationType) {
    if (_state.operationType == operationType) {
      return;
    }

    sourceDocumentNumberCtrl.clear();
    _setState(
      _state.copyWith(
        operationType: operationType,
        activeWorkflowStep: ReturnReversalWorkflowStep.invoiceItems,
        lookupResult: const ReturnReversalLookupResult.empty(),
        clearSelectedSourceDocument: true,
        clearReturnCartLineNumbers: true,
        clearActiveInspectionLineNo: true,
        clearLineInspectionDrafts: true,
        clearLookupMessage: true,
      ),
    );
  }

  Future<void> searchRecords() async {
    final sourceNumber = sourceDocumentNumberCtrl.text.trim();
    final mobile = customerMobileCtrl.text.trim();

    if (sourceNumber.isEmpty && mobile.isEmpty) {
      _setState(
        _state.copyWith(
          lookupMessage: 'Enter a mobile number or source document number.',
          clearError: true,
        ),
      );
      return;
    }

    _setState(
      _state.copyWith(
        isSearching: true,
        clearError: true,
        clearLookupMessage: true,
      ),
    );

    try {
      if (sourceNumber.isNotEmpty) {
        await _loadSourceDocument(sourceNumber);
        return;
      }

      final result = await _repository.findCustomerHistoryByMobile(mobile);
      final preferredDocument = _preferredDocument(result);
      if (preferredDocument != null) {
        _hydrateCustomerFields(preferredDocument);
        sourceDocumentNumberCtrl.text = preferredDocument.documentNo;
      }
      _setState(
        _state.copyWith(
          lookupResult: result,
          selectedSourceDocument: preferredDocument,
          clearReturnCartLineNumbers: true,
          activeInspectionLineNo: _firstLineNoFor(preferredDocument),
          lineInspectionDrafts: _inspectionDraftsFor(preferredDocument),
          isSearching: false,
          lookupMessage: result.hasDocuments
              ? null
              : 'No sales, purchase, or booking records found.',
        ),
      );
    } catch (exception) {
      _setState(
        _state.copyWith(
          isSearching: false,
          errorMessage: exception.toString(),
        ),
      );
    }
  }

  void selectSourceDocument(ReturnReversalSourceDocument document) {
    _hydrateCustomerFields(document);
    sourceDocumentNumberCtrl.text = document.documentNo;
    _setState(
      _state.copyWith(
        selectedSourceDocument: document,
        clearReturnCartLineNumbers: true,
        activeInspectionLineNo: _firstLineNoFor(document),
        lineInspectionDrafts: _inspectionDraftsFor(document),
        clearLookupMessage: true,
      ),
    );
  }

  void selectWorkflowStep(ReturnReversalWorkflowStep step) {
    if (_state.activeWorkflowStep == step) {
      return;
    }
    _setState(_state.copyWith(activeWorkflowStep: step));
  }

  void selectInspectionLine(int lineNo) {
    if (_lineItemByNo(lineNo) == null ||
        _state.activeInspectionLineNo == lineNo) {
      return;
    }
    _setState(_state.copyWith(activeInspectionLineNo: lineNo));
  }

  void updateReceivedNetWeight(int lineNo, double receivedNetWeight) {
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    final sanitizedWeight = receivedNetWeight.isFinite
        ? receivedNetWeight.clamp(0, double.infinity).toDouble()
        : draft.receivedNetWeight;
    _updateInspectionDraft(
      lineNo,
      draft.copyWith(receivedNetWeight: sanitizedWeight),
    );
  }

  void setHuidMatched(int lineNo, bool matched) {
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    _updateInspectionDraft(lineNo, draft.copyWith(huidMatched: matched));
  }

  void setUnitMatched(int lineNo, bool matched) {
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    _updateInspectionDraft(lineNo, draft.copyWith(unitMatched: matched));
  }

  void setLineMakingReturn(int lineNo, bool includeMakingCharge) {
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    _updateInspectionDraft(
      lineNo,
      draft.copyWith(includeMakingCharge: includeMakingCharge),
    );
  }

  void setStockRoute(int lineNo, ReturnReversalStockRoute route) {
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    _updateInspectionDraft(lineNo, draft.copyWith(stockRoute: route));
  }

  void addLineToReturnCart(int lineNo) {
    if (_draftForLine(lineNo) == null) {
      return;
    }
    final cartLineNumbers = Set<int>.from(_state.returnCartLineNumbers)
      ..add(lineNo);
    _setState(_state.copyWith(returnCartLineNumbers: cartLineNumbers));
  }

  void removeLineFromReturnCart(int lineNo) {
    if (!_state.returnCartLineNumbers.contains(lineNo)) {
      return;
    }
    final cartLineNumbers = Set<int>.from(_state.returnCartLineNumbers)
      ..remove(lineNo);
    _setState(
      _state.copyWith(
        returnCartLineNumbers: cartLineNumbers,
      ),
    );
  }

  bool isLineInReturnCart(int lineNo) {
    return _state.returnCartLineNumbers.contains(lineNo);
  }

  Future<void> _loadSourceDocument(String sourceNumber) async {
    final document = await _repository.findSourceDocumentByNumber(sourceNumber);
    if (document == null) {
      _setState(
        _state.copyWith(
          isSearching: false,
          clearSelectedSourceDocument: true,
          clearReturnCartLineNumbers: true,
          clearActiveInspectionLineNo: true,
          clearLineInspectionDrafts: true,
          lookupMessage: 'No document found for $sourceNumber.',
        ),
      );
      return;
    }

    _hydrateCustomerFields(document);
    _setState(
      _state.copyWith(
        lookupResult: ReturnReversalLookupResult(
          salesInvoices:
              document.type == ReturnReversalSourceDocumentType.salesInvoice
                  ? [document]
                  : const [],
          advanceBookings:
              document.type == ReturnReversalSourceDocumentType.advanceBooking
                  ? [document]
                  : const [],
          customerPurchases:
              document.type == ReturnReversalSourceDocumentType.customerPurchase
                  ? [document]
                  : const [],
        ),
        selectedSourceDocument: document,
        clearReturnCartLineNumbers: true,
        activeInspectionLineNo: _firstLineNoFor(document),
        lineInspectionDrafts: _inspectionDraftsFor(document),
        isSearching: false,
        clearLookupMessage: true,
      ),
    );
  }

  int? _firstLineNoFor(ReturnReversalSourceDocument? document) {
    if (document == null || document.lineItems.isEmpty) {
      return null;
    }
    return document.lineItems.first.lineNo;
  }

  Map<int, ReturnReversalLineInspectionDraft> _inspectionDraftsFor(
    ReturnReversalSourceDocument? document,
  ) {
    if (document == null) {
      return const {};
    }
    return {
      for (final lineItem in document.lineItems)
        lineItem.lineNo: ReturnReversalLineInspectionDraft.fromLine(lineItem),
    };
  }

  ReturnReversalSourceLineItem? _lineItemByNo(int lineNo) {
    final document = _state.selectedSourceDocument;
    if (document == null) {
      return null;
    }
    for (final line in document.lineItems) {
      if (line.lineNo == lineNo) {
        return line;
      }
    }
    return null;
  }

  ReturnReversalLineInspectionDraft? _draftForLine(int lineNo) {
    final lineItem = _lineItemByNo(lineNo);
    if (lineItem == null) {
      return null;
    }
    return _state.lineInspectionDrafts[lineNo] ??
        ReturnReversalLineInspectionDraft.fromLine(lineItem);
  }

  void _updateInspectionDraft(
    int lineNo,
    ReturnReversalLineInspectionDraft draft,
  ) {
    final drafts = Map<int, ReturnReversalLineInspectionDraft>.from(
      _state.lineInspectionDrafts,
    )..[lineNo] = draft;
    _setState(_state.copyWith(lineInspectionDrafts: drafts));
  }

  ReturnReversalSourceDocument? _preferredDocument(
    ReturnReversalLookupResult result,
  ) {
    return switch (_state.operationType) {
      ReturnReversalOperationType.salesReturn =>
        result.salesInvoices.isNotEmpty ? result.salesInvoices.first : null,
      ReturnReversalOperationType.bookingCancellation =>
        result.advanceBookings.isNotEmpty ? result.advanceBookings.first : null,
    };
  }

  void _hydrateCustomerFields(ReturnReversalSourceDocument document) {
    if (customerMobileCtrl.text != document.mobile) {
      customerMobileCtrl.text = document.mobile;
    }
    if (customerNameCtrl.text != document.customerName) {
      customerNameCtrl.text = document.customerName;
    }
    if (customerAddressCtrl.text != document.address) {
      customerAddressCtrl.text = document.address;
    }
  }

  void _setState(ReturnReversalState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    customerMobileCtrl.dispose();
    customerNameCtrl.dispose();
    sourceDocumentNumberCtrl.dispose();
    customerAddressCtrl.dispose();
    super.dispose();
  }
}
