part of 'supplier_profile_screen.dart';

extension _SupplierProfileEditActions on _SupplierProfileScreenState {
  Future<void> _showEditDialog(SupplierProfileModel profile) async {
    final supplier =
        await SupplierRepository(AppDatabase()).getById(profile.id);
    if (!mounted) return;
    if (supplier == null) {
      AppFeedback.show(context,
          type: AppFeedbackType.error,
          message: 'Supplier details could not be loaded.');
      return;
    }
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (editorContext) => AddSupplierScreen(
          existingSupplier: supplier,
          onBack: () => Navigator.of(editorContext).pop(false),
          onSaved: () => Navigator.of(editorContext).pop(true),
        ),
      ),
    );
    if (updated == true && mounted) await _logic.refresh();
  }
}
