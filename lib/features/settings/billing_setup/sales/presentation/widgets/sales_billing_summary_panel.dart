import 'package:flutter/material.dart';

import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../presentation/theme/billing_setup_design_tokens.dart';
import '../../domain/sales_billing_metal_profile.dart';
import '../../domain/sales_billing_policy_input.dart';
import 'sales_billing_visuals.dart';

class SalesBillingSummaryPanel extends StatelessWidget {
  final SalesBillingModel model;
  final SalesBillingPolicyInput input;

  const SalesBillingSummaryPanel({
    super.key,
    required this.model,
    required this.input,
  });

  @override
  Widget build(BuildContext context) {
    final accent = SalesBillingVisuals.accentFor(model.metal);
    final activeFields = SalesBillingMetalProfiles.activeFieldCount(model);

    return Container(
      width: 310,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BillingSetupDesignTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BillingSetupDesignTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  SalesBillingVisuals.iconFor(model.metal),
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${BillingMetal.displayName(model.metal)} Summary',
                  style: const TextStyle(
                    color: BillingSetupDesignTokens.textStrong,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryMetric(
            label: 'Active invoice fields',
            value: activeFields.toString(),
          ),
          _SummaryMetric(
            label: 'Return mode',
            value: model.returnMode,
          ),
          _SummaryMetric(
            label: 'Return window',
            value: '${input.returnWindowDays.trim()} days',
          ),
          _SummaryMetric(
            label: 'Buyback rate',
            value: '${input.buybackRatePercent.trim()}%',
          ),
          _SummaryMetric(
            label: 'Print template',
            value: TemplateOptions.labelFor(model.selectedTemplate),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BillingSetupDesignTokens.border),
            ),
            child: const Text(
              'Each metal is saved independently. Changes here affect only the selected sales invoice category.',
              style: TextStyle(
                color: BillingSetupDesignTokens.textBody,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: BillingSetupDesignTokens.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BillingSetupDesignTokens.textStrong,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
