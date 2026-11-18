part of '../account_profile_screen.dart';

extension _ProfileFormWidgets on _AccountProfileScreenState {
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AccountProfileStyles.cardDecoration,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: AccountProfileIcons.edit,
              title: AccountProfileStrings.sectionProfile,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _nameCtrl,
              label: AccountProfileStrings.labelName,
              icon: AccountProfileIcons.person,
              enabled: _canEditName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AccountProfileStrings.errorNameRequired
                  : null,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _mobileCtrl,
              label: AccountProfileStrings.labelMobile,
              icon: AccountProfileIcons.phone,
              enabled: _canEditMobile,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _emailCtrl,
              label: AccountProfileStrings.labelEmail,
              icon: AccountProfileIcons.email,
              enabled: false,
              hintText: AccountProfileStrings.labelEmailNote,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AccountProfileColors.brandGold,
                  disabledBackgroundColor:
                      AccountProfileColors.brandGold.withValues(alpha: 0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(AccountProfileIcons.save,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(AccountProfileStrings.btnSave,
                              style: AccountProfileStyles.buttonText),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AccountProfileStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: AccountProfileStyles.fieldValue.copyWith(
            color: enabled
                ? AccountProfileColors.bodyTextMain
                : AccountProfileColors.inputDisabledText,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
                fontSize: 12, color: AccountProfileColors.bodyTextMuted),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                icon,
                size: 18,
                color: enabled
                    ? AccountProfileColors.brandGold
                    : AccountProfileColors.inputDisabledText,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: enabled
                ? AccountProfileColors.inputBg
                : AccountProfileColors.inputDisabledBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AccountProfileColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AccountProfileColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AccountProfileColors.inputFocus, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color:
                      AccountProfileColors.inputBorder.withValues(alpha: 0.5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AccountProfileColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AccountProfileColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
