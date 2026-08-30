import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
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
        lookupResult: const ReturnReversalLookupResult.empty(),
        clearSelectedSourceDocument: true,
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
        clearLookupMessage: true,
      ),
    );
  }

  Future<void> _loadSourceDocument(String sourceNumber) async {
    final document = await _repository.findSourceDocumentByNumber(sourceNumber);
    if (document == null) {
      _setState(
        _state.copyWith(
          isSearching: false,
          clearSelectedSourceDocument: true,
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
        isSearching: false,
        clearLookupMessage: true,
      ),
    );
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
