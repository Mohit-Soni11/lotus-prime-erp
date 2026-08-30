class ReturnReversalTransactionSummary {
  final int eligibleSalesInvoices;
  final int eligibleAdvanceBookings;
  final int postedReturns;
  final int postedCancellations;
  final double refundableAmount;
  final double restoredNetWeight;

  const ReturnReversalTransactionSummary({
    required this.eligibleSalesInvoices,
    required this.eligibleAdvanceBookings,
    required this.postedReturns,
    required this.postedCancellations,
    required this.refundableAmount,
    required this.restoredNetWeight,
  });

  const ReturnReversalTransactionSummary.empty()
      : eligibleSalesInvoices = 0,
        eligibleAdvanceBookings = 0,
        postedReturns = 0,
        postedCancellations = 0,
        refundableAmount = 0,
        restoredNetWeight = 0;

  bool get hasActivity =>
      eligibleSalesInvoices > 0 ||
      eligibleAdvanceBookings > 0 ||
      postedReturns > 0 ||
      postedCancellations > 0 ||
      refundableAmount > 0 ||
      restoredNetWeight > 0;
}
