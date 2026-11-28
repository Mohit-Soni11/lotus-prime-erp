import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_result.dart';
import '../services/password_recovery_actions.dart';
import '../services/password_policy.dart';
import 'luxury_auth_palette.dart';

enum _RecoveryStep { email, otp, password, success }

class PasswordRecoveryPanel extends StatefulWidget {
  const PasswordRecoveryPanel({
    super.key,
    required this.authService,
    required this.onBackToSignIn,
  });

  final PasswordRecoveryActions authService;
  final VoidCallback onBackToSignIn;

  @override
  State<PasswordRecoveryPanel> createState() => _PasswordRecoveryPanelState();
}

class _PasswordRecoveryPanelState extends State<PasswordRecoveryPanel> {
  static final ButtonStyle _linkStyle = TextButton.styleFrom(
      foregroundColor: LuxuryAuthPalette.darkGold,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _recoveryCode = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _otpFocus = FocusNode();
  _RecoveryStep _step = _RecoveryStep.email;
  bool _busy = false;
  bool _useRecoveryCode = false;
  bool _showPassword = false;
  bool _showConfirmation = false;
  String? _error;
  String? _newRecoveryCode;
  bool _recoveryCodeSaved = false;
  DateTime? _resendAt;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    _recoveryCode.dispose();
    _password.dispose();
    _confirmation.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = 'Enter a valid registered email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.authService.sendPasswordResetOtp(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.isSuccess ? null : result.message;
      if (result.isSuccess) {
        _step = _RecoveryStep.otp;
        _otp.clear();
        _resendAt = DateTime.now().add(const Duration(minutes: 1));
      }
    });
    if (result.isSuccess) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _step == _RecoveryStep.otp) setState(() {});
      });
      _otpFocus.requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    if (_otp.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.authService.verifyPasswordResetOtp(
      email: _email.text,
      code: _otp.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.isSuccess ? null : result.message;
      if (result.isSuccess) _step = _RecoveryStep.password;
    });
  }

  Future<void> _resetPassword() async {
    final policyError = PasswordPolicy.validate(_password.text);
    if (policyError != null || _password.text != _confirmation.text) {
      setState(() => _error = policyError ?? 'The passwords do not match.');
      return;
    }
    if (_useRecoveryCode && _recoveryCode.text.trim().isEmpty) {
      setState(() => _error = 'Enter your saved recovery code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final AuthResult result = _useRecoveryCode
        ? await widget.authService.resetPassword(
            recoveryCode: _recoveryCode.text.trim(),
            newPassword: _password.text,
          )
        : await widget.authService.resetPasswordWithOtp(
            email: _email.text,
            newPassword: _password.text,
          );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.isSuccess ? null : result.message;
      if (result.isSuccess) {
        _newRecoveryCode = result.recoveryCode;
        _password.clear();
        _confirmation.clear();
        _otp.clear();
        _step = _RecoveryStep.success;
      }
    });
  }

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
                      minHeight: (constraints.maxHeight - 60)
                          .clamp(0, double.infinity),
                    ),
                    child: Center(
                        child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                                  begin: const Offset(.035, 0),
                                  end: Offset.zero)
                              .animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('${_step.name}-$_useRecoveryCode'),
                        child: _content(),
                      ),
                    )),
                  ),
                )),
      );

  Widget _content() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_step != _RecoveryStep.success)
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LuxuryAuthPalette.paleGold,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Text(
                      'Step ${_step == _RecoveryStep.email ? '01' : _step == _RecoveryStep.otp ? '02' : '03'} of 03',
                      style: const TextStyle(
                          color: LuxuryAuthPalette.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_step == _RecoveryStep.success)
            _successContent()
          else ...[
            _heading(),
            const SizedBox(height: 24),
            if (_step == _RecoveryStep.email) _emailContent(),
            if (_step == _RecoveryStep.otp) _otpContent(),
            if (_step == _RecoveryStep.password) _passwordContent(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 25),
            _primaryButton(
              _step == _RecoveryStep.email
                  ? 'Send OTP'
                  : _step == _RecoveryStep.otp
                      ? 'Verify OTP'
                      : 'Reset Password',
              _step == _RecoveryStep.email
                  ? Icons.send_rounded
                  : _step == _RecoveryStep.otp
                      ? Icons.verified_user_outlined
                      : Icons.restart_alt_rounded,
              _step == _RecoveryStep.email
                  ? _sendCode
                  : _step == _RecoveryStep.otp
                      ? _verifyCode
                      : _resetPassword,
            ),
            const SizedBox(height: 15),
            _backButton(),
          ],
        ],
      );

  Widget _heading() {
    final title = _step == _RecoveryStep.email
        ? 'Forgot Password'
        : _step == _RecoveryStep.otp
            ? 'Verify OTP'
            : 'Reset Password';
    final subtitle = _step == _RecoveryStep.email
        ? 'Reset your account password securely.'
        : _step == _RecoveryStep.otp
            ? 'Enter the 6-digit code sent to your email.'
            : 'Create a new password for your account.';
    final icon = _step == _RecoveryStep.email
        ? Icons.mail_outline_rounded
        : _step == _RecoveryStep.otp
            ? Icons.shield_outlined
            : Icons.lock_outline_rounded;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
                color: LuxuryAuthPalette.paleGold,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: LuxuryAuthPalette.darkGold, size: 33)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: LuxuryAuthPalette.ink,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  color: LuxuryAuthPalette.mutedInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ])),
      ]),
      const SizedBox(height: 14),
      Container(
          width: 95,
          height: 3,
          decoration:
              const BoxDecoration(gradient: LuxuryAuthPalette.goldGradient)),
    ]);
  }

  Widget _emailContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter your registered email address.',
              style: TextStyle(
                  color: LuxuryAuthPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _field(_email, 'Registered email address', Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email]),
          const SizedBox(height: 14),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  style: _linkStyle,
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _useRecoveryCode = true;
                            _step = _RecoveryStep.password;
                            _error = null;
                          }),
                  child: const Text('Use saved recovery code instead'))),
        ],
      );

  Widget _otpContent() {
    final seconds = _resendAt == null
        ? 0
        : _resendAt!.difference(DateTime.now()).inSeconds.clamp(0, 60);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFE9F0FB),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.mark_email_read_outlined,
                color: LuxuryAuthPalette.ink, size: 20),
            const SizedBox(width: 9),
            Expanded(
                child: Text('Code sent to ${_email.text.trim()}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: LuxuryAuthPalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600))),
            TextButton(
                style: _linkStyle,
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _step = _RecoveryStep.email;
                          _otp.clear();
                          _error = null;
                        }),
                child: const Text('Change')),
          ])),
      const SizedBox(height: 17),
      Semantics(
          label: 'Six digit email verification code',
          textField: true,
          child: Stack(children: [
            Row(
                children: List.generate(
                    6,
                    (index) => Expanded(
                            child: Container(
                          height: 58,
                          margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: const Color(0xFFFEFCF9),
                              border: Border.all(
                                  color: LuxuryAuthPalette.outline, width: 1.3),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                              index < _otp.text.length ? _otp.text[index] : '–',
                              style: const TextStyle(
                                  color: LuxuryAuthPalette.ink,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700)),
                        )))),
            Positioned.fill(
                child: TextField(
              controller: _otp,
              focusNode: _otpFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: ''),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6)
              ],
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _verifyCode(),
            )),
          ])),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: Text(
                seconds > 0
                    ? 'Resend available in 00:${seconds.toString().padLeft(2, '0')}'
                    : 'Didn’t receive the code?',
                style: const TextStyle(
                    color: LuxuryAuthPalette.mutedInk, fontSize: 14))),
        TextButton.icon(
            style: _linkStyle,
            onPressed: _busy || seconds > 0 ? null : _sendCode,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Resend OTP')),
      ]),
    ]);
  }

  Widget _passwordContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_useRecoveryCode) ...[
            const Text('Saved recovery code',
                style: TextStyle(
                    color: LuxuryAuthPalette.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            _field(
                _recoveryCode, 'Enter your recovery code', Icons.key_outlined),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    style: _linkStyle,
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _useRecoveryCode = false;
                              _step = _RecoveryStep.email;
                              _error = null;
                            }),
                    child: const Text('Use email OTP instead'))),
            const SizedBox(height: 12),
          ],
          const Text('New Password',
              style: TextStyle(
                  color: LuxuryAuthPalette.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          _field(_password, 'Enter new password', Icons.lock_outline_rounded,
              obscure: !_showPassword,
              suffix: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined))),
          const SizedBox(height: 12),
          const Text('Confirm New Password',
              style: TextStyle(
                  color: LuxuryAuthPalette.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          _field(_confirmation, 'Re-enter new password',
              Icons.lock_outline_rounded,
              obscure: !_showConfirmation,
              suffix: IconButton(
                  tooltip:
                      _showConfirmation ? 'Hide password' : 'Show password',
                  onPressed: () =>
                      setState(() => _showConfirmation = !_showConfirmation),
                  icon: Icon(_showConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined))),
          const SizedBox(height: 12),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FB),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text(
                  'Use at least 8 characters, including a letter and a number.',
                  style:
                      TextStyle(color: LuxuryAuthPalette.ink, fontSize: 14))),
        ],
      );

  Widget _successContent() => Column(children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: Color(0xFF07965C), size: 88),
        const SizedBox(height: 18),
        const Text('Password Reset Successful',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: LuxuryAuthPalette.ink,
                fontSize: 30,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        const Text('You can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: LuxuryAuthPalette.mutedInk, fontSize: 16)),
        const SizedBox(height: 22),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
                color: const Color(0xFFE5F3E6),
                borderRadius: BorderRadius.circular(15)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Save your new recovery code',
                  style: TextStyle(
                      color: LuxuryAuthPalette.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              const Text(
                  'Your previous code no longer works. Keep this code in a safe place.',
                  style: TextStyle(color: LuxuryAuthPalette.ink, fontSize: 14)),
              const SizedBox(height: 9),
              SelectableText(_newRecoveryCode ?? '',
                  style: const TextStyle(
                      color: LuxuryAuthPalette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ])),
        CheckboxListTile(
            activeColor: LuxuryAuthPalette.darkGold,
            value: _recoveryCodeSaved,
            onChanged: (value) =>
                setState(() => _recoveryCodeSaved = value ?? false),
            title: const Text('I saved my new recovery code',
                style: TextStyle(
                    color: LuxuryAuthPalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero),
        const SizedBox(height: 12),
        _primaryButton(
            'Back to Sign In', Icons.login_rounded, widget.onBackToSignIn),
      ]);

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    bool obscure = false,
    Widget? suffix,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        obscureText: obscure,
        enableSuggestions: !obscure,
        autocorrect: !obscure,
        style: const TextStyle(
            color: LuxuryAuthPalette.ink,
            fontSize: 17,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: LuxuryAuthPalette.mutedInk, fontSize: 16),
          prefixIcon: Icon(icon, color: LuxuryAuthPalette.ink),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFFEFCF9),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 17, horizontal: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: LuxuryAuthPalette.outline)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                  color: LuxuryAuthPalette.outline, width: 1.3)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                  color: LuxuryAuthPalette.darkGold, width: 1.8)),
        ),
      );

  Widget _primaryButton(String label, IconData icon, VoidCallback onPressed) =>
      Container(
        height: 58,
        decoration: BoxDecoration(
            gradient: LuxuryAuthPalette.goldGradient,
            borderRadius: BorderRadius.circular(16)),
        child: ElevatedButton.icon(
          onPressed:
              _busy || (_step == _RecoveryStep.success && !_recoveryCodeSaved)
                  ? null
                  : onPressed,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: LuxuryAuthPalette.ink))
              : Icon(icon, size: 22),
          label: Text(_busy ? 'Please wait…' : label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: LuxuryAuthPalette.ink,
            textStyle:
                const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );

  Widget _backButton() => SizedBox(
        height: 54,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : widget.onBackToSignIn,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to Sign In'),
          style: OutlinedButton.styleFrom(
            foregroundColor: LuxuryAuthPalette.ink,
            side: const BorderSide(color: LuxuryAuthPalette.ink, width: 1.4),
            textStyle:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      );
}
