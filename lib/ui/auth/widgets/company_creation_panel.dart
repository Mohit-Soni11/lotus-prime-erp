import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/password_policy.dart';
import 'auth_field_validator.dart';
import 'company_registration_input.dart';
import 'luxury_auth_palette.dart';

class CompanyCreationPanel extends StatefulWidget {
  const CompanyCreationPanel({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onBackToSignIn,
  });

  final bool isLoading;
  final Future<void> Function(CompanyRegistrationInput) onSubmit;
  final VoidCallback onBackToSignIn;

  @override
  State<CompanyCreationPanel> createState() => _CompanyCreationPanelState();
}

class _CompanyCreationPanelState extends State<CompanyCreationPanel> {
  final _formKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _mobile = TextEditingController();
  final _companyName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmation = false;

  @override
  void dispose() {
    _ownerName.dispose();
    _mobile.dispose();
    _companyName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isLoading || !_formKey.currentState!.validate()) return;
    widget.onSubmit(CompanyRegistrationInput(
      ownerName: _ownerName.text.trim(),
      mobile: _mobile.text.trim(),
      companyName: _companyName.text.trim(),
      email: _email.text.trim().toLowerCase(),
      password: _password.text,
    ));
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: LuxuryAuthPalette.ivory,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = (constraints.maxWidth * .055).clamp(24.0, 44.0);
            final twoColumns = constraints.maxWidth >= 600;
            return SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: horizontal, vertical: 25),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 50).clamp(0, double.infinity),
                ),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 23),
                        _row(twoColumns, [
                          _field(
                            label: 'Owner Name',
                            controller: _ownerName,
                            hint: 'Enter owner name',
                            icon: Icons.person_outline_rounded,
                            validator: AuthFieldValidator.requiredText,
                            autofillHints: const [AutofillHints.name],
                          ),
                          _field(
                            label: 'Mobile Number',
                            controller: _mobile,
                            hint: 'Enter 10-digit mobile number',
                            icon: Icons.phone_outlined,
                            validator: AuthFieldValidator.mobile,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10)
                            ],
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                          ),
                        ]),
                        const SizedBox(height: 13),
                        _field(
                          label: 'Company / Shop Name',
                          controller: _companyName,
                          hint: 'Enter company or shop name',
                          icon: Icons.storefront_outlined,
                          validator: AuthFieldValidator.requiredText,
                          autofillHints: const [AutofillHints.organizationName],
                        ),
                        const SizedBox(height: 13),
                        _row(twoColumns, [
                          _field(
                            label: 'Email Address',
                            controller: _email,
                            hint: 'Enter sign-in email address',
                            icon: Icons.mail_outline_rounded,
                            validator: AuthFieldValidator.email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                          ),
                          _field(
                            label: 'Password',
                            controller: _password,
                            hint: 'Create a password',
                            icon: Icons.lock_outline_rounded,
                            validator: (value) =>
                                PasswordPolicy.validate(value ?? ''),
                            obscureText: !_showPassword,
                            suffix: IconButton(
                              tooltip: _showPassword
                                  ? 'Hide password'
                                  : 'Show password',
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                              icon: Icon(_showPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                        ]),
                        const SizedBox(height: 13),
                        _field(
                          label: 'Confirm Password',
                          controller: _confirmation,
                          hint: 'Re-enter the password',
                          icon: Icons.lock_outline_rounded,
                          validator: (value) =>
                              AuthFieldValidator.confirmPassword(
                                  value, _password.text),
                          obscureText: !_showConfirmation,
                          suffix: IconButton(
                            tooltip: _showConfirmation
                                ? 'Hide confirmation'
                                : 'Show confirmation',
                            onPressed: () => setState(
                                () => _showConfirmation = !_showConfirmation),
                            icon: Icon(_showConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(height: 25),
                        Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LuxuryAuthPalette.goldGradient,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: widget.isLoading ? null : _submit,
                            icon: widget.isLoading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.add_box_outlined, size: 24),
                            label: const Text('Create Company'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: LuxuryAuthPalette.ink,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              textStyle: const TextStyle(
                                  fontSize: 21, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text('or',
                                style: TextStyle(
                                    color: LuxuryAuthPalette.mutedInk
                                        .withValues(alpha: .9))),
                          ),
                          const Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed:
                                widget.isLoading ? null : widget.onBackToSignIn,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Back to Sign In'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LuxuryAuthPalette.ink,
                              side: const BorderSide(
                                  color: LuxuryAuthPalette.ink, width: 1.4),
                              textStyle: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _header() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: LuxuryAuthPalette.paleGold,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: LuxuryAuthPalette.darkGold, size: 41),
          ),
          const SizedBox(width: 19),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Company',
                  style: TextStyle(
                      color: LuxuryAuthPalette.ink,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.12)),
              const SizedBox(height: 5),
              const Text('Set up your jewellery business in Lotus ERP.',
                  style: TextStyle(
                      color: LuxuryAuthPalette.mutedInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              Container(
                  width: 125,
                  height: 3,
                  decoration: const BoxDecoration(
                      gradient: LuxuryAuthPalette.goldGradient)),
            ],
          )),
        ],
      );

  Widget _row(bool twoColumns, List<Widget> children) => twoColumns
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: children[0]),
          const SizedBox(width: 18),
          Expanded(child: children[1]),
        ])
      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          children[0],
          const SizedBox(height: 13),
          children[1],
        ]);

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required Iterable<String> autofillHints,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffix,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 5),
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: label,
                  style: const TextStyle(
                      color: LuxuryAuthPalette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const TextSpan(
                  text: ' *',
                  style: TextStyle(
                      color: Color(0xFFD32920),
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ])),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            autofillHints: autofillHints,
            obscureText: obscureText,
            enableSuggestions: !obscureText,
            autocorrect: false,
            style: const TextStyle(
                color: LuxuryAuthPalette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: LuxuryAuthPalette.mutedInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, color: LuxuryAuthPalette.ink, size: 23),
              suffixIcon: suffix,
              filled: true,
              fillColor: LuxuryAuthPalette.ivory,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: LuxuryAuthPalette.outline, width: 1.4)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: LuxuryAuthPalette.darkGold, width: 1.8)),
            ),
          ),
        ],
      );
}
