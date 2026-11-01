part of 'add_supplier_screen.dart';

extension _SupplierIdentitySection on _AddSupplierScreenState {
  Widget _buildIdentitySection(AddSupplierFormModel form) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AddSupplierStyles.heroDecoration,
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  AddSupplierColors.brandGold,
                  AddSupplierColors.goldGradientStart,
                  AddSupplierColors.brandGold,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AddSupplierColors.brandGold.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AddSupplierColors.bodyPanelBg,
              ),
              child: Text(
                form.avatarInitials,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AddSupplierColors.brandGold,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AddSupplierColors.bodyTextMain,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  form.mobile.isEmpty
                      ? 'Mobile number pending'
                      : 'Mobile: ${form.mobile}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AddSupplierColors.bodyTextMuted,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: AddSupplierIcons.country,
                      label: form.country,
                      color: AddSupplierColors.accentAddress,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
