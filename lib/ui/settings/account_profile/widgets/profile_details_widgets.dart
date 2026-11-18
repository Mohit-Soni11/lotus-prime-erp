part of '../account_profile_screen.dart';

extension _ProfileDetailsWidgets on _AccountProfileScreenState {
  Widget _buildAccountDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AccountProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(AccountProfileStyles.cardRadius),
        border: Border.all(
            color: AccountProfileColors.brandGold.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
              color: AccountProfileColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: AccountProfileIcons.verified,
            title: AccountProfileStrings.sectionAccount,
          ),
          const SizedBox(height: 16),
          Divider(
              color: AccountProfileColors.bodyBorder.withValues(alpha: 0.6),
              height: 1),
          const SizedBox(height: 14),
          _infoRow('User ID', _auth.currentUser?.uid ?? 'â€”'),
          _infoRow(
            'Email Verified',
            (_auth.currentUser?.emailVerified ?? false)
                ? 'âœ“ Verified'
                : 'âœ— Not Verified',
            valueColor: (_auth.currentUser?.emailVerified ?? false)
                ? AccountProfileColors.successText
                : AccountProfileColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AccountProfileStyles.infoLabel),
          ),
          Expanded(
            child: Text(
              value,
              style: AccountProfileStyles.infoValue.copyWith(
                color: valueColor ?? AccountProfileColors.bodyTextMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AccountProfileColors.brandGoldBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AccountProfileColors.brandGoldBorder),
          ),
          child: Icon(icon, size: 14, color: AccountProfileColors.brandGold),
        ),
        const SizedBox(width: 10),
        Text(title, style: AccountProfileStyles.sectionTitle),
      ],
    );
  }
}
