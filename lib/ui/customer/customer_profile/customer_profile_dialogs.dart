part of 'customer_profile_screen.dart';

extension _ProfileDialogs on _CustomerProfileScreenState {
  Future<void> _openCustomerEditor(CustomerProfileModel profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (editorContext) => AddCustomerScreen(
          customerId: profile.id,
          onBack: () => Navigator.of(editorContext).pop(false),
          onSaved: () => Navigator.of(editorContext).pop(true),
        ),
      ),
    );

    if (updated == true && mounted) await _logic.refresh();
  }

  void _showDeleteDialog(CustomerProfileModel profile) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(CustomerProfileStrings.deleteTitle),
        content: const Text(CustomerProfileStrings.deleteMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(CustomerProfileStrings.deleteCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final deleted = await _logic.deleteCustomer();
              if (!deleted && mounted) {
                AppFeedback.show(
                  context,
                  type: AppFeedbackType.error,
                  message:
                      _logic.deleteError ?? CustomerProfileStrings.deleteError,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: CustomerProfileColors.deleteText,
            ),
            child: const Text(CustomerProfileStrings.deleteConfirm),
          ),
        ],
      ),
    );
  }
}
