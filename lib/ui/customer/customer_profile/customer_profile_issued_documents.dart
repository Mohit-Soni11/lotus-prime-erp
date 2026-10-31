part of 'customer_profile_screen.dart';

extension _ProfileIssuedDocuments on _CustomerProfileScreenState {
  Future<Uint8List?> _loadIssuedSalesInvoice(
    int billId,
    String billNo, {
    bool notifyUnavailable = true,
  }) {
    return _readArchivedDocument(
      read: () async {
        await SalesInvoicePaymentRevisionService(
          archive: _issuedInvoiceArchive,
        ).synchronize(billId, billNo);
        return _issuedInvoiceArchive.read(
          IssuedInvoiceKind.sales,
          billId,
          billNo,
        );
      },
      unavailableMessage:
          'The issued sales PDF is unavailable or could not be updated.',
      notifyUnavailable: notifyUnavailable,
    );
  }

  Future<Uint8List?> _loadIssuedBookingInvoice(
    CustomerAdvanceOrderModel order,
  ) {
    return _readArchivedDocument(
      read: () async {
        final saved = await _issuedInvoiceArchive.read(
          IssuedInvoiceKind.booking,
          order.id,
          order.orderNo,
        );
        if (saved != null) return saved;

        final controller =
            BookingInvoicePreviewController(orderIds: [order.id]);
        try {
          await controller.load();
          return controller.pdfBytes;
        } finally {
          controller.dispose();
        }
      },
      unavailableMessage: 'Advance receipt PDF could not be opened.',
    );
  }

  Future<Uint8List?> _loadIssuedGirviInvoice(CustomerLoanModel loan) {
    return _readArchivedDocument(
      read: () async {
        if (loan.isManagedGirvi) {
          final draft = await _logic.fetchGirviInvoiceDraft(loan.id);
          if (draft != null) {
            return const GirviDocumentSetService().build(draft);
          }
        }
        return _girviInvoiceStore.readInvoice(
          loanId: loan.id,
          ticketNo: loan.loanNo,
        );
      },
      unavailableMessage: 'Girvi receipt PDF could not be opened.',
    );
  }

  Future<Uint8List?> _loadIssuedReturnVoucher(
    CustomerLinkedDocumentModel document,
  ) {
    return _readArchivedDocument(
      read: () => _issuedInvoiceArchive.read(
        IssuedInvoiceKind.returnVoucher,
        document.id,
        document.documentNo,
      ),
      unavailableMessage: 'This return voucher PDF is not available.',
    );
  }

  Future<Uint8List?> _readArchivedDocument({
    required Future<Uint8List?> Function() read,
    required String unavailableMessage,
    bool notifyUnavailable = true,
  }) async {
    try {
      final bytes = await read();
      if (bytes != null) IssuedInvoiceArchive.validatePdf(bytes);
      if (bytes == null && mounted && notifyUnavailable) {
        _showInfoFeedback(unavailableMessage);
      }
      return bytes;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Original issued PDF could not be read.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted && notifyUnavailable) {
        _showInfoFeedback(unavailableMessage);
      }
      return null;
    }
  }
}
