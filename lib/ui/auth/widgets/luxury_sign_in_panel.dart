import 'package:flutter/material.dart';

import 'auth_field_validator.dart';
import 'luxury_auth_palette.dart';

class LuxurySignInPanel extends StatelessWidget {
  const LuxurySignInPanel({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSignIn,
    required this.onCreateCompany,
    required this.companyStatus,
    this.onCreateOwner,
    this.onRetryStatus,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignIn;
  final VoidCallback onCreateCompany;
  final VoidCallback? onCreateOwner;
  final String? companyStatus;
  final VoidCallback? onRetryStatus;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: LuxuryAuthPalette.ivory,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: (constraints.maxWidth * .105).clamp(30.0, 78.0),
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 60).clamp(0, double.infinity)),
              child: Center(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: LuxuryAuthPalette.ink,
                          fontSize: 58,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign in to manage billing, inventory, and daily operations.',
                        style: TextStyle(
                          color: LuxuryAuthPalette.mutedInk,
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 17),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 132,
                          height: 3,
                          decoration: const BoxDecoration(
                              gradient: LuxuryAuthPalette.goldGradient),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _input(
                        controller: usernameController,
                        hint: 'Username',
                        icon: Icons.person_outline_rounded,
                        validator: AuthFieldValidator.username,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        validator: AuthFieldValidator.loginPassword,
                        obscureText: !passwordVisible,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => onSignIn(),
                        suffixIcon: IconButton(
                          tooltip: passwordVisible
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: onTogglePassword,
                          icon: Icon(passwordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : onForgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: LuxuryAuthPalette.darkGold,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LuxuryAuthPalette.goldGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x339F6C13),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onSignIn,
                          icon: isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: LuxuryAuthPalette.ink))
                              : const Icon(Icons.login_rounded, size: 27),
                          label: const Text('SIGN IN'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: LuxuryAuthPalette.ink,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            textStyle: const TextStyle(
                                fontFamily: 'Segoe UI',
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 21),
                      Row(children: [
                        Expanded(
                            child: Divider(
                                color: LuxuryAuthPalette.outline
                                    .withValues(alpha: .7))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 17),
                          child: Text('or',
                              style: TextStyle(
                                  color: LuxuryAuthPalette.mutedInk,
                                  fontSize: 17)),
                        ),
                        Expanded(
                            child: Divider(
                                color: LuxuryAuthPalette.outline
                                    .withValues(alpha: .7))),
                      ]),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : onCreateCompany,
                          icon: const Icon(Icons.apartment_rounded, size: 23),
                          label: const Text('Create Company'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LuxuryAuthPalette.ink,
                            side: const BorderSide(
                                color: LuxuryAuthPalette.ink, width: 1.5),
                            textStyle: const TextStyle(
                                fontFamily: 'Segoe UI',
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17)),
                          ),
                        ),
                      ),
                      if (companyStatus != null) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_rounded,
                                size: 19, color: LuxuryAuthPalette.ink),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(companyStatus!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: LuxuryAuthPalette.ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                      if (onCreateOwner != null)
                        TextButton(
                          onPressed: isLoading ? null : onCreateOwner,
                          child: const Text('Create Owner Account'),
                        ),
                      if (onRetryStatus != null)
                        TextButton(
                          onPressed: onRetryStatus,
                          child: const Text(
                              'Could not check company setup. Retry'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required Iterable<String> autofillHints,
    required TextInputAction textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onFieldSubmitted,
  }) =>
      TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        enableSuggestions: !obscureText,
        autocorrect: !obscureText,
        style: const TextStyle(
            color: LuxuryAuthPalette.ink,
            fontSize: 21,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF5D6E88),
              fontSize: 21,
              fontWeight: FontWeight.w500),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Icon(icon, color: LuxuryAuthPalette.ink, size: 29),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 70),
          suffixIcon: suffixIcon,
          suffixIconColor: LuxuryAuthPalette.mutedInk,
          filled: true,
          fillColor: const Color(0xFFFEFCF9),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 19, horizontal: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide: const BorderSide(color: LuxuryAuthPalette.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide:
                const BorderSide(color: LuxuryAuthPalette.outline, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide:
                const BorderSide(color: LuxuryAuthPalette.darkGold, width: 1.8),
          ),
        ),
      );
}
