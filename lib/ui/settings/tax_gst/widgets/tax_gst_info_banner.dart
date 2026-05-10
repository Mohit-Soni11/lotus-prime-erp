// ============================================================
// FILE    : lib/ui/settings/tax_gst/widgets/tax_gst_info_banner.dart
// MODULE  : Tax & GST Configuration
// DESC    : Info/warning banner shown at bottom of each section card.
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';

class TaxGstInfoBanner extends StatelessWidget {
  const TaxGstInfoBanner({
    super.key,
    required this.message,
    required this.accentColor,
    this.icon = TaxGstIcons.statusInfo,
  });

  final String message;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: TaxGstStyles.infoBannerDecoration(accentColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: accentColor.withOpacity(0.85)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TaxGstStyles.infoBannerText(context),
            ),
          ),
        ],
      ),
    );
  }
}
