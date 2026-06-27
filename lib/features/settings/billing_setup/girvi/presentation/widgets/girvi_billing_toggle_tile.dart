import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/billing_setup/presentation/theme/billing_setup_design_tokens.dart';

class GirviBillingToggleTile extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const GirviBillingToggleTile({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? accent.withValues(alpha: 0.07) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? accent.withValues(alpha: 0.24)
              : BillingSetupDesignTokens.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: BillingSetupDesignTokens.textStrong,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: BillingSetupDesignTokens.textMuted,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Transform.scale(
            scale: 0.86,
            child: Switch(
              value: value,
              activeThumbColor: accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
