part of 'add_supplier_screen.dart';

extension _SupplierActions on _AddSupplierScreenState {
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!_logic.isEditMode) ...[
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _logic.isSaving ? null : _handleClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AddSupplierColors.bodyTextMain,
                  side: const BorderSide(color: AddSupplierColors.bodyBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(AddSupplierIcons.clear, size: 20),
                label: Text(
                  AddSupplierStrings.btnClear,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _logic.canSave ? _handleSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AddSupplierColors.saveBtnBg,
                disabledBackgroundColor: AddSupplierColors.saveBtnDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _logic.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black54,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      AddSupplierIcons.save,
                      color: Colors.black87,
                      size: 22,
                    ),
              label: Text(
                _logic.isSaving
                    ? AddSupplierStrings.btnSaving
                    : _logic.isEditMode
                        ? AddSupplierStrings.btnSaveEdit
                        : AddSupplierStrings.btnSaveAdd,
                style: AddSupplierStyles.saveButtonText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final success = await _logic.save();
    if (!mounted) return;

    if (success) {
      _showFeedback(_logic.successMessage ?? 'Supplier saved', isSuccess: true);
      widget.onSaved?.call();
    } else {
      _showFeedback('Please check highlighted fields', isSuccess: false);
    }
  }

  void _handleClear() {
    _logic.resetForm();
    _syncControllersFromForm();
    _showFeedback('Supplier form cleared', isSuccess: true);
  }

  void _showFeedback(String message, {required bool isSuccess}) {
    AppFeedback.show(
      context,
      type: isSuccess ? AppFeedbackType.success : AppFeedbackType.error,
      message: message,
    );
  }
}
