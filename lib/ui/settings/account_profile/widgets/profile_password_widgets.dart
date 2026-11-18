part of '../account_profile_screen.dart';

extension _ProfilePasswordWidgets on _AccountProfileScreenState {
  Widget _buildPasswordCard() {
    return Container(
      decoration: AccountProfileStyles.cardDecoration,
      child: Column(
        children: [
          InkWell(
            onTap: () => _updatePasswordUi(
                () => _showPasswordSection = !_showPasswordSection),
            borderRadius:
                BorderRadius.circular(AccountProfileStyles.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AccountProfileColors.infoBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              AccountProfileColors.info.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(AccountProfileIcons.lock,
                        color: AccountProfileColors.info, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AccountProfileStrings.sectionPassword,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AccountProfileColors.bodyTextMain)),
                        const SizedBox(height: 3),
                        Text('Update your login password',
                            style: AccountProfileStyles.avatarEmail),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showPasswordSection ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(AccountProfileIcons.chevronDown,
                        color: AccountProfileColors.bodyTextMuted, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildPasswordForm(),
            crossFadeState: _showPasswordSection
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Divider(
              color: AccountProfileColors.bodyBorder.withValues(alpha: 0.7),
              height: 1),
          const SizedBox(height: 18),
          _buildPasswordField(
            controller: _currPassCtrl,
            label: AccountProfileStrings.labelCurrentPass,
            obscure: _obscureCurr,
            onToggle: () =>
                _updatePasswordUi(() => _obscureCurr = !_obscureCurr),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _newPassCtrl,
            label: AccountProfileStrings.labelNewPass,
            obscure: _obscureNew,
            onToggle: () => _updatePasswordUi(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _confirmPassCtrl,
            label: AccountProfileStrings.labelConfirmPass,
            obscure: _obscureConfirm,
            onToggle: () =>
                _updatePasswordUi(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AccountProfileColors.info,
                disabledBackgroundColor:
                    AccountProfileColors.info.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(AccountProfileStrings.btnUpdatePass,
                      style: AccountProfileStyles.buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AccountProfileStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: AccountProfileStyles.fieldValue,
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(AccountProfileIcons.lock,
                  size: 17, color: AccountProfileColors.info),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? AccountProfileIcons.visibilityOff
                    : AccountProfileIcons.visibility,
                size: 18,
                color: AccountProfileColors.bodyTextMuted,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AccountProfileColors.inputBg,
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
                  color: AccountProfileColors.info, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
