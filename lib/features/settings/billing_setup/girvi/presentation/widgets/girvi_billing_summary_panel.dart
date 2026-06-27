import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_policy_input.dart';
import 'package:lotus_erp/features/settings/billing_setup/presentation/theme/billing_setup_design_tokens.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

class GirviBillingSummaryPanel extends StatelessWidget {
  final GirviBillingModel model;
  final GirviBillingPolicyInput input;
  final double? width;

  const GirviBillingSummaryPanel({
    super.key,
    required this.model,
    required this.input,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final nextTicket =
        '${input.girviPrefix}${input.startingNumber.padLeft(4, '0')}';

    return Container(
      width: width ?? double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BillingSetupDesignTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BillingSetupDesignTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Policy Snapshot',
            style: TextStyle(
              color: BillingSetupDesignTokens.textStrong,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Current Girvi receipt and loan defaults',
            style: TextStyle(
              color: BillingSetupDesignTokens.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _MetricTile(
            label: 'Next Ticket',
            value: nextTicket,
            icon: Icons.confirmation_number_outlined,
            accent: BillingSetupDesignTokens.girvi,
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: 'Interest Policy',
            value: '${input.defaultInterestRate}% ${model.interestType}',
            icon: Icons.percent_rounded,
            accent: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: 'Loan Duration',
            value: model.defaultDuration,
            icon: Icons.timelapse_rounded,
            accent: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: 'Notice Window',
            value: '${input.noticeDays} days',
            icon: Icons.campaign_outlined,
            accent: const Color(0xFF9333EA),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: BillingSetupDesignTokens.border),
          const SizedBox(height: 16),
          _InlineStat(
            label: 'Item Fields',
            value: '${model.visibleInvoiceFieldCount}',
          ),
          const SizedBox(height: 10),
          _InlineStat(
            label: 'Receipt Sections',
            value: '${model.visibleDocumentFieldCount}',
          ),
          const SizedBox(height: 10),
          _InlineStat(
            label: 'Auto Print',
            value: model.autoPrint ? 'Enabled' : 'Disabled',
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: BillingSetupDesignTokens.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BillingSetupDesignTokens.textStrong,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;

  const _InlineStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: BillingSetupDesignTokens.textBody,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: BillingSetupDesignTokens.textStrong,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
