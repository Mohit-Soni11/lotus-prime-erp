import 'package:flutter/material.dart';

import '../../domain/entities/billing_setup_module.dart';
import '../theme/billing_setup_design_tokens.dart';

class BillingSetupPreviewPanel extends StatelessWidget {
  final List<BillingSetupModule> modules;
  final double? width;

  const BillingSetupPreviewPanel({
    super.key,
    required this.modules,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
            'Configuration Health',
            style: TextStyle(
              color: BillingSetupDesignTokens.textStrong,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Current billing areas are active and ready for detailed refactor.',
            style: TextStyle(
              color: BillingSetupDesignTokens.textBody,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ...modules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HealthRow(module: module),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BillingSetupDesignTokens.border),
            ),
            child: const Text(
              'Next upgrade: move validation, saving, and print settings into dedicated controllers and value objects.',
              style: TextStyle(
                color: BillingSetupDesignTokens.textBody,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final BillingSetupModule module;

  const _HealthRow({required this.module});

  @override
  Widget build(BuildContext context) {
    final accent = BillingSetupDesignTokens.accentFor(module.id);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            BillingSetupDesignTokens.iconFor(module.id),
            color: accent,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: BillingSetupDesignTokens.textStrong,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                module.statusLabel,
                style: const TextStyle(
                  color: BillingSetupDesignTokens.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
