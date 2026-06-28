import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_colors.dart';

class ShopPrintInformationSummary extends StatelessWidget {
  final ShopPrintInformationState state;
  final VoidCallback onOpenShopProfile;

  const ShopPrintInformationSummary({
    super.key,
    required this.state,
    required this.onOpenShopProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BillingSetupColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BillingSetupColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: BillingSetupColors.shadowSubtle,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BillingSetupColors.successBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BillingSetupColors.successBorder),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: BillingSetupColors.success,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop Print Information',
                  style: GoogleFonts.manrope(
                    color: BillingSetupColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Select which saved Shop Setup details should appear on printed bills, receipts and vouchers.',
                  style: GoogleFonts.inter(
                    color: BillingSetupColors.textBody,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                      label: '${state.enabledCount} enabled',
                      icon: Icons.check_circle_rounded,
                    ),
                    _MetricPill(
                      label: '${state.configuredCount} configured',
                      icon: Icons.verified_rounded,
                    ),
                    _MetricPill(
                      label: '${state.fields.length} fields',
                      icon: Icons.tune_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: onOpenShopProfile,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Open Shop Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BillingSetupColors.success,
              side: const BorderSide(color: BillingSetupColors.successBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopPrintInformationSection extends StatelessWidget {
  final ShopPrintFieldGroup group;
  final List<ShopPrintField> fields;
  final bool Function(ShopPrintField field) isEnabled;
  final void Function(ShopPrintField field, bool enabled) onChanged;

  const ShopPrintInformationSection({
    super.key,
    required this.group,
    required this.fields,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final meta = ShopPrintGroupMeta.forGroup(group);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BillingSetupColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BillingSetupColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: BillingSetupColors.shadowSubtle,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meta.icon, color: meta.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                meta.title,
                style: GoogleFonts.manrope(
                  color: BillingSetupColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                meta.source,
                style: GoogleFonts.inter(
                  color: BillingSetupColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 780 ? 2 : 1;
              final tileWidth =
                  (constraints.maxWidth - ((columns - 1) * 10)) / columns;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: tileWidth,
                      child: ShopPrintInformationTile(
                        field: field,
                        accent: meta.accent,
                        enabled: isEnabled(field),
                        onChanged: (value) => onChanged(field, value),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ShopPrintInformationTile extends StatelessWidget {
  final ShopPrintField field;
  final Color accent;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const ShopPrintInformationTile({
    super.key,
    required this.field,
    required this.accent,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = field.isConfigured;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled && isAvailable
            ? accent.withValues(alpha: 0.07)
            : BillingSetupColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled && isAvailable
              ? accent.withValues(alpha: 0.28)
              : BillingSetupColors.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: BillingSetupColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  field.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: BillingSetupColors.textMuted,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isAvailable ? field.value : 'Not configured in Shop Setup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: isAvailable
                        ? BillingSetupColors.textBody
                        : BillingSetupColors.danger,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: enabled && isAvailable,
            onChanged: isAvailable ? onChanged : null,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.26),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class ShopPrintGroupMeta {
  final String title;
  final String source;
  final IconData icon;
  final Color accent;

  const ShopPrintGroupMeta({
    required this.title,
    required this.source,
    required this.icon,
    required this.accent,
  });

  static ShopPrintGroupMeta forGroup(ShopPrintFieldGroup group) {
    switch (group) {
      case ShopPrintFieldGroup.identity:
        return const ShopPrintGroupMeta(
          title: 'Identity',
          source: 'Basic Info',
          icon: Icons.badge_rounded,
          accent: BillingSetupColors.brandGold,
        );
      case ShopPrintFieldGroup.contact:
        return const ShopPrintGroupMeta(
          title: 'Contact',
          source: 'Basic Info',
          icon: Icons.contact_phone_rounded,
          accent: BillingSetupColors.salesBrand,
        );
      case ShopPrintFieldGroup.statutory:
        return const ShopPrintGroupMeta(
          title: 'GST & Legal',
          source: 'GST & Legal',
          icon: Icons.verified_rounded,
          accent: BillingSetupColors.purchaseBrand,
        );
      case ShopPrintFieldGroup.address:
        return const ShopPrintGroupMeta(
          title: 'Address',
          source: 'Address',
          icon: Icons.location_on_rounded,
          accent: BillingSetupColors.girviBrand,
        );
      case ShopPrintFieldGroup.social:
        return const ShopPrintGroupMeta(
          title: 'Social Channels',
          source: 'Branding',
          icon: Icons.campaign_rounded,
          accent: BillingSetupColors.info,
        );
      case ShopPrintFieldGroup.banking:
        return const ShopPrintGroupMeta(
          title: 'Payment Details',
          source: 'Banking',
          icon: Icons.account_balance_rounded,
          accent: BillingSetupColors.success,
        );
    }
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetricPill({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BillingSetupColors.inputBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BillingSetupColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: BillingSetupColors.success),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: BillingSetupColors.textBody,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
