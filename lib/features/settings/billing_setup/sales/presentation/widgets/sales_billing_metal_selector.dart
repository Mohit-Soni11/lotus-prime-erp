import 'package:flutter/material.dart';

import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../presentation/theme/billing_setup_design_tokens.dart';
import '../../domain/sales_billing_metal_profile.dart';
import 'sales_billing_visuals.dart';

class SalesBillingMetalSelector extends StatelessWidget {
  final String selectedMetal;
  final Set<String> dirtyMetals;
  final ValueChanged<String> onSelected;

  const SalesBillingMetalSelector({
    super.key,
    required this.selectedMetal,
    required this.dirtyMetals,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: SalesBillingMetalProfiles.all
                .map(
                  (profile) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: _MetalItem(
                      profile: profile,
                      selected: selectedMetal == profile.metal,
                      dirty: dirtyMetals.contains(profile.metal),
                      onTap: () => onSelected(profile.metal),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        }

        return Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BillingSetupDesignTokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BillingSetupDesignTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 4, 8, 10),
                child: Text(
                  'Metals',
                  style: TextStyle(
                    color: BillingSetupDesignTokens.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final profile in SalesBillingMetalProfiles.all)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MetalItem(
                    profile: profile,
                    selected: selectedMetal == profile.metal,
                    dirty: dirtyMetals.contains(profile.metal),
                    onTap: () => onSelected(profile.metal),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MetalItem extends StatelessWidget {
  final SalesBillingMetalProfile profile;
  final bool selected;
  final bool dirty;
  final VoidCallback onTap;

  const _MetalItem({
    required this.profile,
    required this.selected,
    required this.dirty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = SalesBillingVisuals.accentFor(profile.metal);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.30)
                : BillingSetupDesignTokens.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                SalesBillingVisuals.iconFor(profile.metal),
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BillingSetupDesignTokens.textStrong,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (dirty)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    BillingMetal.displayName(profile.metal),
                    style: const TextStyle(
                      color: BillingSetupDesignTokens.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
