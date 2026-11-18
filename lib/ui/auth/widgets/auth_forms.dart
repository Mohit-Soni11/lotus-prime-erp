import 'package:flutter/material.dart';

import '../../../theme/dashboard/app/uv.dart';
import 'auth_field_validator.dart';
import 'auth_input_field.dart';

class SignInForm extends StatelessWidget {
  const SignInForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AuthInputField(
            label: 'Email Address',
            icon: UV.icons.email,
            controller: emailController,
            validator: AuthFieldValidator.email,
            isEmail: true,
          ),
          SizedBox(height: UV.layout.pMd),
          AuthInputField(
            label: 'Password',
            icon: UV.icons.lock,
            controller: passwordController,
            validator: AuthFieldValidator.loginPassword,
            isPassword: true,
            passwordVisible: passwordVisible,
            onVisibilityToggle: onTogglePassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              child: Text(
                'Forgot Password?',
                style: UV.styles.body.copyWith(
                  color: UV.colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AuthActionButton(
            label: 'SIGN IN',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      );
}

class OwnerRegistrationForm extends StatelessWidget {
  const OwnerRegistrationForm({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final name = AuthInputField(
              label: 'Owner Name',
              icon: UV.icons.person,
              controller: nameController,
              validator: AuthFieldValidator.requiredText,
            );
            final mobile = AuthInputField(
              label: 'Mobile',
              icon: UV.icons.phone,
              controller: mobileController,
              validator: AuthFieldValidator.mobile,
              isMobile: true,
            );
            if (constraints.maxWidth < 440) {
              return Column(children: [
                name,
                SizedBox(height: UV.layout.pMd),
                mobile,
              ]);
            }
            return Row(children: [
              Expanded(child: name),
              SizedBox(width: UV.layout.pSm),
              Expanded(child: mobile),
            ]);
          }),
          SizedBox(height: UV.layout.pMd),
          AuthInputField(
            label: 'Email Address',
            icon: UV.icons.email,
            controller: emailController,
            validator: AuthFieldValidator.email,
            isEmail: true,
          ),
          SizedBox(height: UV.layout.pMd),
          AuthInputField(
            label: 'Password',
            icon: UV.icons.lock,
            controller: passwordController,
            validator: AuthFieldValidator.newPassword,
            isPassword: true,
            passwordVisible: passwordVisible,
            onVisibilityToggle: onTogglePassword,
          ),
          SizedBox(height: UV.layout.pMd),
          AuthInputField(
            label: 'Confirm Password',
            icon: UV.icons.lock,
            controller: confirmPasswordController,
            validator: (value) => AuthFieldValidator.confirmPassword(
              value,
              passwordController.text,
            ),
            isPassword: true,
            passwordVisible: passwordVisible,
            onVisibilityToggle: onTogglePassword,
          ),
          const SizedBox(height: 24),
          AuthActionButton(
            label: 'CREATE ACCOUNT',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      );
}

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: UV.colors.goldGradient,
          borderRadius: BorderRadius.circular(UV.layout.radiusSm),
          boxShadow: [
            BoxShadow(
              color: UV.colors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UV.layout.radiusSm),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Text(label, style: UV.styles.button),
        ),
      );
}
