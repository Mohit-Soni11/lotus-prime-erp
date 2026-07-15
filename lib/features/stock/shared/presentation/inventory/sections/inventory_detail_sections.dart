part of '../inventory_screen.dart';

extension _InventoryDetailSections on _InventoryScreenState {
  Widget _buildPageHeader() {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(InvStrings.pageTitle, style: InvStyles.pageTitle),
              const SizedBox(height: 4),
              Text(InvStrings.pageSubtitle, style: InvStyles.pageSubtitle),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: InvColors.brandGoldLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: InvColors.brandGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                InvIcons.calendar,
                size: 11,
                color: InvColors.brandGold,
              ),
              const SizedBox(width: 6),
              Text(
                today,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: InvColors.brandGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
