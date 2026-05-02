// =============================================================================
// FILE        : lib/ui/settings/billing_setup/billing_setup_app_bar.dart
// MODULE      : Billing Setup
// DESCRIPTION : Shared custom AppBar used across all billing setup screens.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/billing_setup/billing_setup_theme.dart';

class BillingSetupAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String screenTitle;
  final String screenSubtitle;
  final VoidCallback onBack;

  const BillingSetupAppBar({
    super.key,
    required this.screenTitle,
    required this.screenSubtitle,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: BillingSetupColors.textDark,
        tooltip: 'Back',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            screenTitle,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BillingSetupColors.textDark,
            ),
          ),
          Text(
            screenSubtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: BillingSetupColors.textMuted,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
            height: 1, thickness: 1, color: BillingSetupColors.divider),
      ),
    );
  }
}
