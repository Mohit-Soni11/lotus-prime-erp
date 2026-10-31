part of 'add_customer_screen.dart';

extension _CustomerActionsSection on _AddCustomerScreenState {
  Widget _buildActionButtons() {
    final canSave = _logic.canSave;
    final saving = _logic.isSaving;
    return Row(children: [
      OutlinedButton.icon(
        onPressed: saving ? null : _handleClear,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          _isEditMode
              ? AddCustomerStrings.btnResetChanges
              : AddCustomerStrings.btnClear,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: canSave
              ? AddCustomerColors.saveBtnBg
              : AddCustomerColors.saveBtnDisabled,
          borderRadius: BorderRadius.circular(12),
          boxShadow: canSave
              ? [
                  BoxShadow(
                      color:
                          AddCustomerColors.saveBtnBg.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 5))
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSave ? _handleSave : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black54, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(AddCustomerIcons.save,
                          size: 20,
                          color: canSave ? Colors.black87 : Colors.black54),
                      const SizedBox(width: 10),
                      Text(
                          _isEditMode
                              ? AddCustomerStrings.btnUpdate
                              : AddCustomerStrings.btnSave,
                          style: AddCustomerStyles.saveBtnText.copyWith(
                              color:
                                  canSave ? Colors.black87 : Colors.black54)),
                    ]),
            ),
          ),
        ),
      )),
    ]);
  }
  // REUSABLE HELPERS

  ActiveField _activeFieldFor(FocusNode fn) {
    if (fn == _firstNameFocus) return ActiveField.firstName;
    if (fn == _lastNameFocus) return ActiveField.lastName;
    if (fn == _companyFocus) return ActiveField.companyName;
    if (fn == _contactFocus) return ActiveField.contactPerson;
    if (fn == _mobileFocus) return ActiveField.mobile;
    if (fn == _whatsappFocus) return ActiveField.whatsapp;
    if (fn == _emailFocus) return ActiveField.email;
    if (fn == _altFocus) return ActiveField.alternateContact;
    if (fn == _panFocus) return ActiveField.panNumber;
    if (fn == _idProofNoFocus) return ActiveField.idProofNumber;
    if (fn == _gstFocus) return ActiveField.gstNumber;
    if (fn == _addr1Focus) return ActiveField.addressLine1;
    if (fn == _addr2Focus) return ActiveField.addressLine2;
    if (fn == _pincodeFocus) return ActiveField.pincode;
    return ActiveField.none;
  }
}
