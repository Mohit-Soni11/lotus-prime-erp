import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../domain/purchase_billing_metal_profile.dart';
import 'purchase_billing_visuals.dart';

class PurchaseBillingMetalSelector extends StatelessWidget {
  final String selectedMetal;
  final Set<String> dirtyMetals;
  final ValueChanged<String> onSelected;

  const PurchaseBillingMetalSelector({
    super.key,
    required this.selectedMetal,
    required this.dirtyMetals,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Metal',
            style: GoogleFonts.manrope(
              color: BillingSetupColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Switch between Gold, Silver, Diamond and Platinum purchase controls.',
            style: GoogleFonts.inter(
              color: BillingSetupColors.textMuted,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 220)
                  .floor()
                  .clamp(1, PurchaseBillingMetalProfiles.all.length)
                  .toInt();
              const gap = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: PurchaseBillingMetalProfiles.all
                    .map(
                      (profile) => SizedBox(
                        width: itemWidth,
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
            },
          ),
        ],
      ),
    );
  }
}

class _MetalItem extends StatelessWidget {
  final PurchaseBillingMetalProfile profile;
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
    final accent = PurchaseBillingVisuals.accentFor(profile.metal);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : BillingSetupColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.28)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.16)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: selected ? 0.18 : 0.08),
                    blurRadius: selected ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                PurchaseBillingVisuals.logoAssetFor(profile.metal),
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => Icon(
                  PurchaseBillingVisuals.iconFor(profile.metal),
                  color: accent,
                  size: 18,
                ),
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
                          style: GoogleFonts.inter(
                            color: BillingSetupColors.textDark,
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
                    style: GoogleFonts.inter(
                      color: BillingSetupColors.textMuted,
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
