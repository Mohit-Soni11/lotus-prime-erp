import 'package:flutter/material.dart';

Future<String?> showGoogleRecoveryPasswordDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _GoogleRecoveryPasswordDialog(),
    );

class _GoogleRecoveryPasswordDialog extends StatefulWidget {
  const _GoogleRecoveryPasswordDialog();

  @override
  State<_GoogleRecoveryPasswordDialog> createState() =>
      _GoogleRecoveryPasswordDialogState();
}

class _GoogleRecoveryPasswordDialogState
    extends State<_GoogleRecoveryPasswordDialog> {
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _continue() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(_password.text);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Connect Google account'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'This Google account will be used for Drive backups and password recovery. Confirm your Lotus ERP password to protect account recovery.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  autofocus: true,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Current Lotus ERP password'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your current password.'
                      : null,
                  onFieldSubmitted: (_) => _continue(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(onPressed: _continue, child: const Text('Continue')),
        ],
      );
}
