// ============================================================
// FILE    : lib/ui/settings/tax_gst/widgets/tax_gst_sync_banner.dart
// MODULE  : Tax & GST Configuration
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';

class TaxGstSyncBanner extends StatelessWidget {
  const TaxGstSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TaxGstStyles.bannerPadding,
      decoration: TaxGstStyles.syncBannerDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TaxGstColors.accentPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              TaxGstIcons.linkedChain,
              size: 14,
              color: TaxGstColors.accentPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      TaxGstStrings.syncBannerTitle,
                      style: TaxGstStyles.syncBannerTitle(context),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: TaxGstColors.accentPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        TaxGstStrings.syncBannerTag,
                        style: TaxGstStyles.syncBannerTag(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TaxGstStrings.syncBannerBody,
                  style: TaxGstStyles.syncBannerBody(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
