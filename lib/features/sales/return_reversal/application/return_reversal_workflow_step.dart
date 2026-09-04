enum ReturnReversalWorkflowStep {
  invoiceItems(
    label: 'Invoice Items',
    subtitle: 'Select return lines',
  ),
  verification(
    label: 'Verification',
    subtitle: 'Hallmark and unit match',
  ),
  weightCheck(
    label: 'Weight Check',
    subtitle: 'Received weight audit',
  ),
  valuation(
    label: 'Valuation',
    subtitle: 'Deductions and return value',
  ),
  stockRouting(
    label: 'Stock Routing',
    subtitle: 'Stock or melting route',
  ),
  settlement(
    label: 'Settlement',
    subtitle: 'Refund method',
  ),
  finish(
    label: 'Finish',
    subtitle: 'Approve and voucher',
  );

  final String label;
  final String subtitle;

  const ReturnReversalWorkflowStep({
    required this.label,
    required this.subtitle,
  });
}
