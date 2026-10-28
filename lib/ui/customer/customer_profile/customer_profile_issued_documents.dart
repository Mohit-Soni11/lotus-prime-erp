part of 'customer_profile_screen.dart';

extension _ProfileIssuedDocuments on _CustomerProfileScreenState {
  Future<Uint8List?> _loadIssuedSalesInvoice(int billId, String billNo) {
    return _readArchivedDocument(
      read: () async {
        try {
          await SalesInvoicePaymentRevisionService(
            archive: _issuedInvoiceArchive,
          ).synchronize(billId, billNo);
        } catch (error, stackTrace) {
          AppLogger.warning(
            'Sales payment PDF revision could not be synchronized.',
            error: error,
            stackTrace: stackTrace,
          );
        }
        return _issuedInvoiceArchive.read(
          IssuedInvoiceKind.sales,
          billId,
          billNo,
        );
      },
      unavailableMessage:
          'The original issued PDF is not stored for this bill.',
    );
  }

  Future<Uint8List?> _loadIssuedBookingInvoice(
    CustomerAdvanceOrderModel order,
  ) {
    return _readOrBuildDocument(
      read: () => _issuedInvoiceArchive.read(
        IssuedInvoiceKind.booking,
        order.id,
        order.orderNo,
      ),
      build: () async {
        final controller =
            BookingInvoicePreviewController(orderIds: [order.id]);
        try {
          await controller.load();
          return controller.pdfBytes;
        } finally {
          controller.dispose();
        }
      },
      unavailableMessage: 'Booking invoice PDF could not be opened.',
    );
  }

  Future<Uint8List?> _loadIssuedGirviInvoice(CustomerLoanModel loan) {
    return _readOrBuildDocument(
      read: () => _girviInvoiceStore.readInvoice(
        loanId: loan.id,
        ticketNo: loan.loanNo,
      ),
      build: () async {
        final draft = await _logic.fetchGirviInvoiceDraft(loan.id);
        if (draft == null) return null;
        return const GirviDocumentSetService().build(draft);
      },
      unavailableMessage: 'Girvi invoice PDF could not be opened.',
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
  }) async {
    try {
      final bytes = await read();
      if (bytes == null && mounted) _showInfoFeedback(unavailableMessage);
      return bytes;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Original issued PDF could not be read.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) _showInfoFeedback(unavailableMessage);
      return null;
    }
  }

  Future<Uint8List?> _readOrBuildDocument({
    required Future<Uint8List?> Function() read,
    required Future<Uint8List?> Function() build,
    required String unavailableMessage,
  }) async {
    try {
      Uint8List? savedBytes;
      try {
        savedBytes = await read();
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Issued PDF archive could not be read.',
          error: error,
          stackTrace: stackTrace,
        );
      }
      final bytes = savedBytes ?? await build();
      if (bytes == null && mounted) {
        _showInfoFeedback(unavailableMessage);
      }
      return bytes;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Customer profile PDF preview could not be loaded.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) _showInfoFeedback(unavailableMessage);
      return null;
    }
  }
}
