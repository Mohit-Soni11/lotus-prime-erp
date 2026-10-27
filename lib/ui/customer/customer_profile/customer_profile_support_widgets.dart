part of 'customer_profile_screen.dart';

extension _ProfileSupportWidgets on _CustomerProfileScreenState {
  void _showInfoFeedback(String message) {
    if (!mounted) return;
    AppFeedback.show(context, type: AppFeedbackType.info, message: message);
  }

  Widget _buildLoading({String message = 'Loading profile...'}) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(
              color: CustomerProfileColors.brandGold),
          const SizedBox(height: 14),
          Text(message, style: CustomerProfileStyles.infoValue),
        ]),
      );

  Widget _buildError() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded,
              size: 46, color: CustomerProfileColors.deleteText),
          const SizedBox(height: 12),
          Text(_logic.error ?? 'Profile could not be loaded',
              style: CustomerProfileStyles.infoValue),
          const SizedBox(height: 14),
          FilledButton(onPressed: _logic.refresh, child: const Text('Retry')),
        ]),
      );

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(title, style: CustomerProfileStyles.sectionTitle)),
      ]);

  Widget _buildTypeBadge(CustomerProfileModel profile) {
    final tier = profile.customerTier;
    final (accent, icon) = switch (tier) {
      CustomerType.standard => (const Color(0xFF2563EB), Icons.person_rounded),
      CustomerType.silver => (const Color(0xFF475569), Icons.stars_rounded),
      CustomerType.gold => (const Color(0xFFB77905), Icons.stars_rounded),
      CustomerType.elite => (
          const Color(0xFF7C3AED),
          Icons.workspace_premium_rounded
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          accent.withValues(alpha: 0.18),
          accent.withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.48)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 6),
        Flexible(
            child: Text('${tier.displayLabel} Customer',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: CustomerProfileColors.bodyTextMain))),
      ]),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String sub,
  }) =>
      Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 42, color: CustomerProfileColors.bodyTextMain),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: CustomerProfileStyles.sectionTitle),
          const SizedBox(height: 5),
          Text(sub,
              textAlign: TextAlign.center,
              style: CustomerProfileStyles.infoValue),
        ]),
      ));

  String _fmt(double value) {
    final whole = value.toStringAsFixed(2).split('.');
    final digits = whole.first;
    final sign = digits.startsWith('-') ? '-' : '';
    final number = sign.isEmpty ? digits : digits.substring(1);
    if (number.length <= 3) return '$sign$number.${whole.last}';
    final tail = number.substring(number.length - 3);
    var prefix = number.substring(0, number.length - 3);
    final groups = <String>[];
    while (prefix.length > 2) {
      groups.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    if (prefix.isNotEmpty) groups.insert(0, prefix);
    return '$sign${groups.join(',')},$tail.${whole.last}';
  }
}
