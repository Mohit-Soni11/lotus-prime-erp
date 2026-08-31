import 'package:flutter/material.dart';

enum ReturnReversalWorkflowStep {
  invoiceItems(
    label: 'Invoice Items',
    subtitle: 'Select return lines',
    icon: Icons.receipt_long_rounded,
    enabled: true,
  ),
  verification(
    label: 'Verification',
    subtitle: 'Hallmark and unit match',
    icon: Icons.verified_rounded,
  ),
  weightCheck(
    label: 'Weight Check',
    subtitle: 'Received weight audit',
    icon: Icons.scale_rounded,
  ),
  valuation(
    label: 'Valuation',
    subtitle: 'Deductions and return value',
    icon: Icons.currency_rupee_rounded,
  ),
  stockRouting(
    label: 'Stock Routing',
    subtitle: 'Stock or melting route',
    icon: Icons.account_tree_rounded,
  ),
  settlement(
    label: 'Settlement',
    subtitle: 'Refund method',
    icon: Icons.account_balance_wallet_rounded,
  ),
  finish(
    label: 'Finish',
    subtitle: 'Approve and voucher',
    icon: Icons.task_alt_rounded,
  );

  final String label;
  final String subtitle;
  final IconData icon;
  final bool enabled;

  const ReturnReversalWorkflowStep({
    required this.label,
    required this.subtitle,
    required this.icon,
    this.enabled = false,
  });
}
