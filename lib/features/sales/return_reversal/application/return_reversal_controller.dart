import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_workflow_step.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
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
        clearProcessMessage: true,
        clearLastProcessResult: true,
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
      final returnCartLineNumbers = _defaultCartLineNumbersFor(
        preferredDocument,
      );
      _setState(
        _state.copyWith(
          lookupResult: result,
          selectedSourceDocument: preferredDocument,
          clearSelectedSourceDocument: preferredDocument == null,
          returnCartLineNumbers: returnCartLineNumbers,
          activeInspectionLineNo: _firstLineNoFor(preferredDocument),
          clearActiveInspectionLineNo: preferredDocument == null,
          lineInspectionDrafts: _inspectionDraftsFor(preferredDocument),
          isSearching: false,
          lookupMessage:
              _hasAllowedDocuments(result) ? null : _emptyLookupMessage,
          clearProcessMessage: true,
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
        returnCartLineNumbers: _defaultCartLineNumbersFor(document),
        activeInspectionLineNo: _firstLineNoFor(document),
        lineInspectionDrafts: _inspectionDraftsFor(document),
        clearLookupMessage: true,
        clearProcessMessage: true,
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
    final lineItem = _lineItemByNo(lineNo);
    if (lineItem == null || _state.activeInspectionLineNo == lineNo) {
      return;
    }
    _setState(_state.copyWith(activeInspectionLineNo: lineNo));
  }

  void updateReceivedNetWeight(int lineNo, double receivedNetWeight) {
    if (_lineItemByNo(lineNo)?.isReversed ?? false) {
      return;
    }
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
    if (_lineItemByNo(lineNo)?.isReversed ?? false) {
      return;
    }
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    _updateInspectionDraft(lineNo, draft.copyWith(huidMatched: matched));
  }

  void setUnitMatched(int lineNo, bool matched) {
    if (_lineItemByNo(lineNo)?.isReversed ?? false) {
      return;
    }
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    _updateInspectionDraft(lineNo, draft.copyWith(unitMatched: matched));
  }

  void setLineMakingReturn(int lineNo, bool includeMakingCharge) {
    if (_lineItemByNo(lineNo)?.isReversed ?? false) {
      return;
    }
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
    if (_lineItemByNo(lineNo)?.isReversed ?? false) {
      return;
    }
    final draft = _draftForLine(lineNo);
    if (draft == null) {
      return;
    }
    _updateInspectionDraft(lineNo, draft.copyWith(stockRoute: route));
  }

  void addLineToReturnCart(int lineNo) {
    final lineItem = _lineItemByNo(lineNo);
    if (lineItem == null ||
        lineItem.isReversed ||
        _draftForLine(lineNo) == null) {
      if (lineItem?.isReversed ?? false) {
        _setState(
          _state.copyWith(
            lookupMessage:
                'Line $lineNo is already processed in ${lineItem!.reversalVoucherNo}.',
            clearError: true,
          ),
        );
      }
      return;
    }
    final cartLineNumbers = Set<int>.from(_state.returnCartLineNumbers)
      ..add(lineNo);
    _setState(
      _state.copyWith(
        returnCartLineNumbers: cartLineNumbers,
        clearLookupMessage: true,
        clearProcessMessage: true,
      ),
    );
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

  Future<void> processReturn() async {
    final document = _state.selectedSourceDocument;
    if (document == null) {
      _setState(
        _state.copyWith(
          lookupMessage: 'Select a source document before processing.',
          clearError: true,
        ),
      );
      return;
    }

    final cartLines = _state.returnCartLineItems
        .where((line) => !line.isReversed)
        .toList(growable: false);
    if (cartLines.isEmpty) {
      _setState(
        _state.copyWith(
          lookupMessage: _state.operationType.isBookingCancellation
              ? 'Select a pending advance booking before cancellation.'
              : 'Add at least one pending item to the return cart.',
          clearError: true,
        ),
      );
      return;
    }

    final lineInputs = [
      for (final line in cartLines) _processInputForLine(line),
    ];

    _setState(
      _state.copyWith(
        isProcessing: true,
        clearError: true,
        clearLookupMessage: true,
        clearProcessMessage: true,
        clearLastProcessResult: true,
      ),
    );

    try {
      final result = await _repository.processReturn(
        ReturnReversalProcessRequest(
          operationType: _state.operationType,
          sourceDocument: document,
          lines: lineInputs,
        ),
      );
      final summary = await _repository.fetchTransactionSummary();
      final refreshedDocument =
          await _repository.findSourceDocumentByNumber(document.documentNo);
      final effectiveDocument = refreshedDocument ?? document;
      _hydrateCustomerFields(effectiveDocument);
      if (sourceDocumentNumberCtrl.text != effectiveDocument.documentNo) {
        sourceDocumentNumberCtrl.text = effectiveDocument.documentNo;
      }

      _setState(
        _state.copyWith(
          summary: summary,
          lookupResult: _replaceLookupDocument(
            _state.lookupResult,
            effectiveDocument,
          ),
          selectedSourceDocument: effectiveDocument,
          clearReturnCartLineNumbers: true,
          activeInspectionLineNo: _firstLineNoFor(effectiveDocument),
          lineInspectionDrafts: _inspectionDraftsFor(effectiveDocument),
          isProcessing: false,
          lastProcessResult: result,
          processMessage:
              '${result.voucherNo} posted for ${result.processedLineCount} item(s). Return value Rs ${result.returnValue.round()}.',
          clearError: true,
          clearLookupMessage: true,
        ),
      );
    } catch (exception) {
      _setState(
        _state.copyWith(
          isProcessing: false,
          errorMessage: exception.toString(),
        ),
      );
    }
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

    if (!_state.operationType.acceptsSourceType(document.type)) {
      _setState(
        _state.copyWith(
          isSearching: false,
          lookupResult: _lookupResultFor(document),
          clearSelectedSourceDocument: true,
          clearReturnCartLineNumbers: true,
          clearActiveInspectionLineNo: true,
          clearLineInspectionDrafts: true,
          lookupMessage: _sourceMismatchMessage(document),
        ),
      );
      return;
    }

    _hydrateCustomerFields(document);
    _setState(
      _state.copyWith(
        lookupResult: _lookupResultFor(document),
        selectedSourceDocument: document,
        returnCartLineNumbers: _defaultCartLineNumbersFor(document),
        activeInspectionLineNo: _firstLineNoFor(document),
        lineInspectionDrafts: _inspectionDraftsFor(document),
        isSearching: false,
        clearLookupMessage: true,
        clearProcessMessage: true,
      ),
    );
  }

  int? _firstLineNoFor(ReturnReversalSourceDocument? document) {
    if (document == null || document.lineItems.isEmpty) {
      return null;
    }
    for (final line in document.lineItems) {
      if (!line.isReversed) {
        return line.lineNo;
      }
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

  Set<int> _defaultCartLineNumbersFor(
    ReturnReversalSourceDocument? document,
  ) {
    if (!_isBookingCancellationSource(document)) {
      return const {};
    }
    return {
      for (final lineItem in document!.lineItems)
        if (!lineItem.isReversed) lineItem.lineNo,
    };
  }

  bool _isBookingCancellationSource(ReturnReversalSourceDocument? document) {
    return _state.operationType.isBookingCancellation &&
        document?.type == ReturnReversalSourceDocumentType.advanceBooking;
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

  ReturnReversalProcessLineInput _processInputForLine(
    ReturnReversalSourceLineItem line,
  ) {
    if (_isBookingCancellationSource(_state.selectedSourceDocument)) {
      return ReturnReversalProcessLineInput(
        sourceLineNo: line.lineNo,
        receivedNetWeight: line.netWeight > 0 ? line.netWeight : 0,
        huidMatched: true,
        unitMatched: true,
        includeMakingCharge: false,
        stockDisposition: ReturnReversalStockDisposition.notApplicable,
      );
    }

    final draft = _draftForLine(line.lineNo) ??
        ReturnReversalLineInspectionDraft.fromLine(line);
    return ReturnReversalProcessLineInput(
      sourceLineNo: line.lineNo,
      receivedNetWeight: draft.receivedNetWeight,
      huidMatched: draft.huidMatched,
      unitMatched: draft.unitMatched,
      includeMakingCharge: draft.includeMakingCharge,
      stockDisposition: draft.stockRoute.disposition,
    );
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
      ReturnReversalOperationType.salesReturn => result.salesInvoices.isNotEmpty
          ? result.salesInvoices.first
          : result.customerPurchases.isNotEmpty
              ? result.customerPurchases.first
              : null,
      ReturnReversalOperationType.bookingCancellation =>
        result.advanceBookings.isNotEmpty ? result.advanceBookings.first : null,
    };
  }

  bool _hasAllowedDocuments(ReturnReversalLookupResult result) {
    return switch (_state.operationType) {
      ReturnReversalOperationType.salesReturn =>
        result.salesInvoices.isNotEmpty || result.customerPurchases.isNotEmpty,
      ReturnReversalOperationType.bookingCancellation =>
        result.advanceBookings.isNotEmpty,
    };
  }

  String get _emptyLookupMessage {
    return switch (_state.operationType) {
      ReturnReversalOperationType.salesReturn =>
        'No sales or purchase return records found.',
      ReturnReversalOperationType.bookingCancellation =>
        'No booking cancellation records found.',
    };
  }

  ReturnReversalLookupResult _lookupResultFor(
    ReturnReversalSourceDocument document,
  ) {
    return ReturnReversalLookupResult(
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
    );
  }

  ReturnReversalLookupResult _replaceLookupDocument(
    ReturnReversalLookupResult result,
    ReturnReversalSourceDocument document,
  ) {
    List<ReturnReversalSourceDocument> replaceIn(
      List<ReturnReversalSourceDocument> documents,
    ) {
      var replaced = false;
      final updated = [
        for (final current in documents)
          if (current.type == document.type && current.id == document.id) ...[
            document,
          ] else
            current,
      ];
      replaced = documents.any(
        (current) => current.type == document.type && current.id == document.id,
      );
      return replaced ? updated : [document, ...documents];
    }

    return switch (document.type) {
      ReturnReversalSourceDocumentType.salesInvoice =>
        ReturnReversalLookupResult(
          salesInvoices: replaceIn(result.salesInvoices),
          advanceBookings: result.advanceBookings,
          customerPurchases: result.customerPurchases,
        ),
      ReturnReversalSourceDocumentType.advanceBooking =>
        ReturnReversalLookupResult(
          salesInvoices: result.salesInvoices,
          advanceBookings: replaceIn(result.advanceBookings),
          customerPurchases: result.customerPurchases,
        ),
      ReturnReversalSourceDocumentType.customerPurchase =>
        ReturnReversalLookupResult(
          salesInvoices: result.salesInvoices,
          advanceBookings: result.advanceBookings,
          customerPurchases: replaceIn(result.customerPurchases),
        ),
    };
  }

  String _sourceMismatchMessage(ReturnReversalSourceDocument document) {
    final sourceLabel = document.type.label.toLowerCase();
    return switch (_state.operationType) {
      ReturnReversalOperationType.salesReturn =>
        '$sourceLabel is not available in Return setup. Use Cancellation setup for bookings.',
      ReturnReversalOperationType.bookingCancellation =>
        '$sourceLabel is not available in Cancellation setup. Use Return setup for sales or purchase returns.',
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
