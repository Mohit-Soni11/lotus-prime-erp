import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/ui/auth/services/auth_service.dart';

import '../security_access_theme.dart';

class RecoveryEmailCard extends StatefulWidget {
  const RecoveryEmailCard({super.key});

  @override
  State<RecoveryEmailCard> createState() => _RecoveryEmailCardState();
}

class _RecoveryEmailCardState extends State<RecoveryEmailCard> {
  final _auth = AuthService();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _link = TextEditingController();
  String? _verifiedEmail;
  bool _linkedToGoogle = false;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await _auth.getRecoveryEmail();
    final linkedToGoogle = await _auth.isRecoveryLinkedToGoogle();
    final owner = await _auth.getUserDetails();
    final signInId = owner?['username'] as String?;
    if (!mounted) return;
    setState(() {
      _verifiedEmail = email;
      _linkedToGoogle = linkedToGoogle;
      _email.text = email ?? (signInId?.contains('@') == true ? signInId! : '');
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _email.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await _auth.sendRecoveryEmailEnrollment(
        currentPassword: _password.text, email: _email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result.message;
    });
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await _auth.confirmRecoveryEmailEnrollment(
      currentPassword: _password.text,
      email: _email.text,
      link: _link.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result.message;
      if (result.isSuccess) {
        _verifiedEmail = _email.text.trim().toLowerCase();
        _password.clear();
        _link.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: SecurityAccessTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SecurityAccessTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.mark_email_read_outlined,
                  color: SecurityAccessTheme.gold, size: 28),
              SizedBox(width: 12),
              Text('Recovery Email',
                  style: TextStyle(
                      color: SecurityAccessTheme.text,
                      fontSize: 23,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            Text(
                _verifiedEmail == null
                    ? 'Connect Google in Backup & Restore to use that account for backup and password recovery. You can also verify an email below without Drive.'
                    : 'Verified: $_verifiedEmail',
                style: const TextStyle(
                    color: SecurityAccessTheme.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            if (_linkedToGoogle) ...[
              const SizedBox(height: 14),
              const Text(
                  'This email is linked through Google Drive Backup. Change the connected account there to update recovery.',
                  style: TextStyle(
                      color: SecurityAccessTheme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ] else ...[
              const SizedBox(height: 18),
              TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.alternate_email)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send_outlined),
                label: Text(_verifiedEmail == null
                    ? 'Send verification link'
                    : 'Change recovery email'),
              ),
              ...[
                const SizedBox(height: 18),
                const Text(
                    'Copy the link address from your email and paste it below.',
                    style: TextStyle(color: SecurityAccessTheme.text)),
                const SizedBox(height: 10),
                TextField(
                  controller: _link,
                  decoration: InputDecoration(
                      labelText: 'Email link',
                      suffixIcon: IconButton(
                          tooltip: 'Paste link',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) _link.text = data!.text!;
                          },
                          icon: const Icon(Icons.content_paste_rounded))),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _confirm,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Verify email'),
                ),
              ],
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!,
                  style: const TextStyle(
                      color: SecurityAccessTheme.text,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );
}
