import 'package:flutter/material.dart';

import '../security_access_theme.dart';

class SecurityPasswordField extends StatelessWidget {
  const SecurityPasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.textInputAction,
    required this.onFieldSubmitted,
    required this.validator,
    this.autofillHints,
    this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final TextInputAction textInputAction;
  final ValueChanged<String> onFieldSubmitted;
  final FormFieldValidator<String> validator;
  final Iterable<String>? autofillHints;
  final String? hintText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: SecurityAccessTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            obscureText: obscureText,
            obscuringCharacter: '•',
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: const TextStyle(
              color: SecurityAccessTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: SecurityAccessTheme.surface,
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: SecurityAccessTheme.gold, size: 20),
              suffixIcon: IconButton(
                tooltip: obscureText ? 'Show password' : 'Hide password',
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SecurityAccessTheme.muted,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hintText,
              hintStyle: const TextStyle(
                color: SecurityAccessTheme.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: _border(SecurityAccessTheme.inputBorder),
              enabledBorder: _border(SecurityAccessTheme.inputBorder),
              focusedBorder: _border(SecurityAccessTheme.gold, width: 1.6),
              errorBorder: _border(const Color(0xFFDC2626)),
              focusedErrorBorder: _border(const Color(0xFFDC2626), width: 1.6),
            ),
          ),
        ],
      );

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: color, width: width),
      );
}
