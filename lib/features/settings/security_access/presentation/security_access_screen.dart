import 'package:flutter/material.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/features/settings/security_access/application/change_password_controller.dart';

import 'security_access_theme.dart';
import 'widgets/security_access_app_bar.dart';
import 'widgets/security_password_field.dart';

class SecurityAccessScreen extends StatefulWidget {
  const SecurityAccessScreen({super.key});

  @override
  State<SecurityAccessScreen> createState() => _SecurityAccessScreenState();
}

class _SecurityAccessScreenState extends State<SecurityAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();
  late final ChangePasswordController _controller;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirmation = true;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _controller = ChangePasswordController()..addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    setState(() => _showValidation = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await _controller.submit(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
    );
    if (!mounted) return;
    if (!result.isSuccess) {
      AppFeedback.error(context, message: result.message);
      _currentFocus.requestFocus();
      return;
    }

    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
    _formKey.currentState?.reset();
    _currentFocus.requestFocus();
    AppFeedback.success(context, message: 'Password changed successfully.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SecurityAccessTheme.page,
        appBar: SecurityAccessAppBar(onBack: () => Navigator.of(context).pop()),
        body: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: SecurityAccessTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SecurityAccessTheme.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _showValidation
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: SecurityAccessTheme.goldSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: SecurityAccessTheme.goldBorder),
                                ),
                                child: const Icon(Icons.password_rounded,
                                    color: SecurityAccessTheme.gold, size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Change Password',
                                style: TextStyle(
                                  color: SecurityAccessTheme.text,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          SecurityPasswordField(
                            controller: _currentPassword,
                            focusNode: _currentFocus,
                            label: 'Current Password',
                            obscureText: _hideCurrent,
                            onToggleVisibility: () =>
                                setState(() => _hideCurrent = !_hideCurrent),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _newFocus.requestFocus(),
                            validator: _controller.validateCurrentPassword,
                            autofillHints: const [AutofillHints.password],
                            hintText: 'Enter the password used to sign in',
                          ),
                          const SizedBox(height: 18),
                          SecurityPasswordField(
                            controller: _newPassword,
                            focusNode: _newFocus,
                            label: 'New Password',
                            obscureText: _hideNew,
                            onToggleVisibility: () =>
                                setState(() => _hideNew = !_hideNew),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _confirmFocus.requestFocus(),
                            validator: _controller.validateNewPassword,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(height: 18),
                          SecurityPasswordField(
                            controller: _confirmPassword,
                            focusNode: _confirmFocus,
                            label: 'Confirm Password',
                            obscureText: _hideConfirmation,
                            onToggleVisibility: () => setState(
                                () => _hideConfirmation = !_hideConfirmation),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) => _controller
                                .validateConfirmation(value, _newPassword.text),
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(height: 28),
                          FilledButton.icon(
                            onPressed:
                                _controller.isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: SecurityAccessTheme.gold,
                              foregroundColor: SecurityAccessTheme.text,
                              disabledBackgroundColor: SecurityAccessTheme.gold
                                  .withValues(alpha: 0.35),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            icon: _controller.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: SecurityAccessTheme.text),
                                  )
                                : const Icon(Icons.lock_reset_rounded,
                                    size: 20),
                            label: Text(_controller.isSubmitting
                                ? 'Changing Password...'
                                : 'Change Password'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
