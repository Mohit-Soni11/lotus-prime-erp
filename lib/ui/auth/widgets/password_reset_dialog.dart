import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _recoveryCode = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _recoveryCode.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.authService.resetPassword(
      recoveryCode: _recoveryCode.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.isSuccess) {
      setState(() => _error = result.message);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Save your new recovery code'),
        content: SelectableText(
          'Your old code no longer works. Save this one securely:\n\n${result.recoveryCode}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I saved it'),
          )
        ],
      ),
    );
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Reset local password'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Enter the recovery code saved when this account was created.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recoveryCode,
                  decoration: const InputDecoration(labelText: 'Recovery code'),
                  validator: AuthFieldValidator.requiredText,
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: AuthFieldValidator.newPassword,
                ),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                  validator: (value) =>
                      AuthFieldValidator.confirmPassword(value, _password.text),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _busy ? null : _reset,
              child: Text(_busy ? 'Resetting…' : 'Reset password')),
        ],
      );
}

Future<AuthResult?> showPasswordResetDialog(
        BuildContext context, AuthService authService) =>
    showDialog<AuthResult>(
        context: context,
        builder: (_) => PasswordResetDialog(authService: authService));
