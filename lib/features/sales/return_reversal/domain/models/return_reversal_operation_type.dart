import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';

enum ReturnReversalOperationType {
  salesReturn(
    title: 'Return',
    ledgerLabel: 'RETURN',
    description: 'Process sales returns and purchase returns.',
  ),
  bookingCancellation(
    title: 'Cancellation',
    ledgerLabel: 'CANCELLATION',
    description: 'Cancel advance bookings and settle refunds.',
  );

  final String title;
  final String ledgerLabel;
  final String description;

  const ReturnReversalOperationType({
    required this.title,
    required this.ledgerLabel,
    required this.description,
  });

  bool get isReturn => this == ReturnReversalOperationType.salesReturn;

  bool acceptsSourceType(ReturnReversalSourceDocumentType sourceType) {
    return switch (this) {
      ReturnReversalOperationType.salesReturn =>
        sourceType == ReturnReversalSourceDocumentType.salesInvoice ||
            sourceType == ReturnReversalSourceDocumentType.customerPurchase,
      ReturnReversalOperationType.bookingCancellation =>
        sourceType == ReturnReversalSourceDocumentType.advanceBooking,
    };
  }
}
