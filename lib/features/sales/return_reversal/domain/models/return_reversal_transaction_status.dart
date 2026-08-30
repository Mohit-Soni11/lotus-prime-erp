enum ReturnReversalTransactionStatus {
  draft('Draft'),
  verified('Verified'),
  posted('Posted'),
  voided('Voided');

  final String label;

  const ReturnReversalTransactionStatus(this.label);
}
