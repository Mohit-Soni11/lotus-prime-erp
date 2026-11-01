part of 'supplier_profile_screen.dart';

extension _SupplierProfileDeactivateActions on _SupplierProfileScreenState {
  void _showDeactivateDialog(SupplierProfileModel profile) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF718096).withValues(alpha: 0.22),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SupplierProfileColors.bodyPanelBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SupplierProfileColors.bodyBorder),
        ),
        icon: const Icon(
          SupplierProfileIcons.deactivate,
          color: SupplierProfileColors.danger,
          size: 34,
        ),
        title: const Text(SupplierProfileStrings.deleteTitle,
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.black)),
        content: Text(
          SupplierProfileStrings.deleteMsg,
          style: SupplierProfileStyles.historyMeta,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(SupplierProfileStrings.deleteCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SupplierProfileColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ok = await _logic.deactivateSupplier();
              if (!mounted || !ok) return;
              _showFeedback('${profile.businessName} deactivated');
            },
            child: const Text(SupplierProfileStrings.deleteConfirm),
          ),
        ],
      ),
    );
  }
}
