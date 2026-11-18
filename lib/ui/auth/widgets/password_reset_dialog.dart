import 'package:flutter/material.dart';

import '../../../theme/dashboard/app/uv.dart';
import '../services/auth_result.dart';
import '../services/auth_service.dart';
import 'auth_field_validator.dart';

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key, required this.authService});

  final AuthService authService;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    final result =
        await widget.authService.resetPassword(_emailController.text);
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: UV.colors.bgSecondary,
        title: Text('Reset Password', style: UV.styles.h2),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address to receive a password reset link.',
                style: UV.styles.body,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                validator: AuthFieldValidator.email,
                keyboardType: TextInputType.emailAddress,
                style: UV.styles.body,
                onFieldSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  hintStyle: UV.styles.hint,
                  filled: true,
                  fillColor: UV.colors.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSending ? null : () => Navigator.pop(context),
            child: Text('Cancel', style: UV.styles.action),
          ),
          TextButton(
            onPressed: _isSending ? null : _send,
            child: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Send Link', style: UV.styles.action),
          ),
        ],
      );
}

Future<AuthResult?> showPasswordResetDialog(
  BuildContext context,
  AuthService authService,
) =>
    showDialog<AuthResult>(
      context: context,
      builder: (_) => PasswordResetDialog(authService: authService),
    );
