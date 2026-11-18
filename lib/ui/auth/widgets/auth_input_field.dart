import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/dashboard/app/uv.dart';

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.validator,
    this.isPassword = false,
    this.isMobile = false,
    this.passwordVisible = false,
    this.onVisibilityToggle,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool isPassword;
  final bool isMobile;
  final bool passwordVisible;
  final VoidCallback? onVisibilityToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword && !passwordVisible,
      enableSuggestions: !isPassword,
      autocorrect: !isPassword,
      keyboardType: isMobile ? TextInputType.phone : TextInputType.text,
      inputFormatters: isMobile
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      style: UV.styles.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: UV.styles.hint,
        prefixIcon: Icon(
          icon,
          color: UV.colors.primary.withValues(alpha: 0.7),
          size: UV.layout.iconMd,
        ),
        suffixIcon: isPassword
            ? IconButton(
                tooltip: passwordVisible ? 'Hide password' : 'Show password',
                onPressed: onVisibilityToggle,
                icon: Icon(
                  passwordVisible ? UV.icons.visible : UV.icons.visibleOff,
                  color: UV.colors.textSecondary,
                  size: UV.layout.iconMd,
                ),
              )
            : null,
        filled: true,
        fillColor: UV.colors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UV.layout.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UV.layout.radiusSm),
          borderSide: BorderSide(color: UV.colors.inputBorderFocus),
        ),
      ),
    );
  }
}
