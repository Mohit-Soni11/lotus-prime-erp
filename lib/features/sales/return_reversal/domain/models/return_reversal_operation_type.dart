enum ReturnReversalOperationType {
  salesReturn(
    title: 'Sales Return',
    ledgerLabel: 'RETURN',
    description: 'Reverse completed sales invoices and restore stock movement.',
  ),
  bookingCancellation(
    title: 'Booking Cancellation',
    ledgerLabel: 'CANCELLATION',
    description: 'Cancel advance bookings and settle customer refunds.',
  );

  final String title;
  final String ledgerLabel;
  final String description;

  const ReturnReversalOperationType({
    required this.title,
    required this.ledgerLabel,
    required this.description,
  });
}
