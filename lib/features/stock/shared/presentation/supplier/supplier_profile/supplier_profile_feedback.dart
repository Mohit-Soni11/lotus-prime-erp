part of 'supplier_profile_screen.dart';

extension _SupplierProfileFeedback on _SupplierProfileScreenState {
  void _showFeedback(String message) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: SupplierProfileColors.brandGold),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: SupplierProfileStyles.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              SupplierProfileIcons.empty,
              color: SupplierProfileColors.bodyTextMuted,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _logic.error ?? 'Supplier profile not found',
              textAlign: TextAlign.center,
              style: SupplierProfileStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logic.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
