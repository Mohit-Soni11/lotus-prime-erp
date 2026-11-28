import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _email = TextEditingController();
  final _link = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _useEmail = false;
  bool _linkSent = false;
  String? _error;

  @override
  void dispose() {
    _recoveryCode.dispose();
    _email.dispose();
    _link.dispose();
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
    final result = _useEmail
        ? await widget.authService.resetPasswordWithEmail(
            email: _email.text, link: _link.text, newPassword: _password.text)
        : await widget.authService.resetPassword(
            recoveryCode: _recoveryCode.text, newPassword: _password.text);
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

  Future<void> _sendLink() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your registered recovery email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.authService.sendPasswordResetEmail(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.isSuccess ? null : result.message;
      _linkSent = result.isSuccess;
    });
    if (result.isSuccess) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Reset password'),
        content: SingleChildScrollView(
            child: SizedBox(
          width: 430,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: false,
                        label: Text('Recovery code'),
                        icon: Icon(Icons.key_outlined)),
                    ButtonSegment(
                        value: true,
                        label: Text('Email link'),
                        icon: Icon(Icons.mail_outline)),
                  ],
                  selected: {_useEmail},
                  onSelectionChanged: _busy
                      ? null
                      : (value) => setState(() {
                            _useEmail = value.first;
                            _error = null;
                            _formKey.currentState?.reset();
                          }),
                ),
                const SizedBox(height: 16),
                if (_useEmail) ...[
                  const Text(
                      'Use the email verified in Security & Access. Copy the link address from the email and paste it here.'),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Recovery email'),
                    validator: AuthFieldValidator.requiredText,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _sendLink,
                      icon: const Icon(Icons.send_outlined),
                      label:
                          Text(_linkSent ? 'Send new link' : 'Send email link'),
                    ),
                  ),
                  TextFormField(
                    controller: _link,
                    decoration: InputDecoration(
                        labelText: 'Link from email',
                        suffixIcon: IconButton(
                          tooltip: 'Paste link',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) _link.text = data!.text!;
                          },
                          icon: const Icon(Icons.content_paste_rounded),
                        )),
                    validator: AuthFieldValidator.requiredText,
                  ),
                  if (_linkSent)
                    const Text(
                        'Link requested. Check your inbox and spam folder.'),
                ] else ...[
                  const Text(
                      'Enter the recovery code saved when this account was created.'),
                  TextFormField(
                    controller: _recoveryCode,
                    decoration:
                        const InputDecoration(labelText: 'Recovery code'),
                    validator: AuthFieldValidator.requiredText,
                  ),
                ],
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
        )),
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
