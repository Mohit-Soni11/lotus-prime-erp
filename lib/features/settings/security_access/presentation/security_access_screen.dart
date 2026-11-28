import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/features/settings/security_access/application/change_password_controller.dart';
import 'package:lotus_erp/features/settings/security_access/data/security_access_repository.dart';
import 'package:lotus_erp/features/settings/security_access/domain/password_strength.dart';
import 'package:lotus_erp/features/settings/security_access/domain/security_access_identity.dart';

import 'security_access_theme.dart';
import 'widgets/security_access_app_bar.dart';
import 'widgets/security_identity_panel.dart';
import 'widgets/security_password_field.dart';
import 'widgets/security_password_strength_meter.dart';
import 'widgets/recovery_email_card.dart';

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
  final _identityRepository = SecurityAccessRepository();
  late final ChangePasswordController _controller;
  SecurityAccessIdentity? _identity;
  bool _identityLoading = true;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirmation = true;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _controller = ChangePasswordController()..addListener(_refresh);
    _newPassword.addListener(_refresh);
    _loadIdentity();
  }

  @override
  void dispose() {
    _newPassword.removeListener(_refresh);
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

  Future<void> _loadIdentity() async {
    final identity = await _identityRepository.loadIdentity();
    if (!mounted) return;
    setState(() {
      _identity = identity;
      _identityLoading = false;
    });
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
    await _loadIdentity();
    if (mounted) {
      AppFeedback.success(context, message: 'Password changed successfully.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SecurityAccessTheme.page,
        appBar: SecurityAccessAppBar(onBack: () => Navigator.of(context).pop()),
        body: SafeArea(
          top: false,
          child: _identityLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: SecurityAccessTheme.gold))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 980;
                    final identity = _identity!;
                    final card = _PasswordChangeCard(
                      identity: identity,
                      formKey: _formKey,
                      controller: _controller,
                      currentPassword: _currentPassword,
                      newPassword: _newPassword,
                      confirmPassword: _confirmPassword,
                      currentFocus: _currentFocus,
                      newFocus: _newFocus,
                      confirmFocus: _confirmFocus,
                      hideCurrent: _hideCurrent,
                      hideNew: _hideNew,
                      hideConfirmation: _hideConfirmation,
                      showValidation: _showValidation,
                      onToggleCurrent: () =>
                          setState(() => _hideCurrent = !_hideCurrent),
                      onToggleNew: () => setState(() => _hideNew = !_hideNew),
                      onToggleConfirmation: () => setState(
                          () => _hideConfirmation = !_hideConfirmation),
                      onSubmit: _submit,
                    );
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 24 : 46,
                          vertical: compact ? 28 : 48),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1320),
                          child: compact
                              ? Column(children: [
                                  SecurityIdentityPanel(identity: identity),
                                  const SizedBox(height: 32),
                                  card,
                                  const SizedBox(height: 24),
                                  const RecoveryEmailCard(),
                                ])
                              : Column(children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 36),
                                          child: SecurityIdentityPanel(
                                              identity: identity),
                                        ),
                                      ),
                                      const SizedBox(width: 42),
                                      Expanded(flex: 5, child: card),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  const RecoveryEmailCard(),
                                ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}

class _PasswordChangeCard extends StatelessWidget {
  const _PasswordChangeCard({
    required this.identity,
    required this.formKey,
    required this.controller,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.currentFocus,
    required this.newFocus,
    required this.confirmFocus,
    required this.hideCurrent,
    required this.hideNew,
    required this.hideConfirmation,
    required this.showValidation,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleConfirmation,
    required this.onSubmit,
  });

  final SecurityAccessIdentity identity;
  final GlobalKey<FormState> formKey;
  final ChangePasswordController controller;
  final TextEditingController currentPassword;
  final TextEditingController newPassword;
  final TextEditingController confirmPassword;
  final FocusNode currentFocus;
  final FocusNode newFocus;
  final FocusNode confirmFocus;
  final bool hideCurrent;
  final bool hideNew;
  final bool hideConfirmation;
  final bool showValidation;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirmation;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthEvaluator.evaluate(newPassword.text);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SecurityAccessTheme.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A1E293B), blurRadius: 32, offset: Offset(0, 16)),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          autovalidateMode: showValidation
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: SecurityAccessTheme.goldSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SecurityAccessTheme.goldBorder),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: SecurityAccessTheme.gold, size: 31),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Change Password',
                          style: TextStyle(
                              color: SecurityAccessTheme.text,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6)),
                      const SizedBox(height: 4),
                      Text(
                          'Update the sign-in password for ${identity.shopName}.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: SecurityAccessTheme.muted,
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 30),
              SecurityPasswordField(
                controller: currentPassword,
                focusNode: currentFocus,
                label: 'Current Password',
                obscureText: hideCurrent,
                onToggleVisibility: onToggleCurrent,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => newFocus.requestFocus(),
                validator: controller.validateCurrentPassword,
                autofillHints: const [AutofillHints.password],
                hintText: 'Enter the password used to sign in',
              ),
              const SizedBox(height: 20),
              SecurityPasswordField(
                controller: newPassword,
                focusNode: newFocus,
                label: 'New Password',
                obscureText: hideNew,
                onToggleVisibility: onToggleNew,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => confirmFocus.requestFocus(),
                validator: controller.validateNewPassword,
                autofillHints: const [AutofillHints.newPassword],
              ),
              SecurityPasswordStrengthMeter(strength: strength),
              const SizedBox(height: 20),
              SecurityPasswordField(
                controller: confirmPassword,
                focusNode: confirmFocus,
                label: 'Confirm New Password',
                obscureText: hideConfirmation,
                onToggleVisibility: onToggleConfirmation,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                validator: (value) =>
                    controller.validateConfirmation(value, newPassword.text),
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: controller.isSubmitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: SecurityAccessTheme.gold,
                    foregroundColor: SecurityAccessTheme.text,
                    disabledBackgroundColor:
                        SecurityAccessTheme.gold.withValues(alpha: 0.35),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                icon: controller.isSubmitting
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: SecurityAccessTheme.text))
                    : const Icon(Icons.sync_lock_rounded, size: 21),
                label: Text(controller.isSubmitting
                    ? 'Changing Password...'
                    : 'Change Password'),
              ),
              const SizedBox(height: 24),
              _LastChangedStrip(changedAt: identity.lastPasswordChangedAt),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastChangedStrip extends StatelessWidget {
  const _LastChangedStrip({required this.changedAt});
  final DateTime? changedAt;

  @override
  Widget build(BuildContext context) {
    final label = changedAt == null
        ? 'Not changed since account setup'
        : DateFormat('dd MMM yyyy, hh:mm a').format(changedAt!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
          color: SecurityAccessTheme.goldSoft,
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.calendar_month_outlined,
            size: 21, color: SecurityAccessTheme.gold),
        const SizedBox(width: 10),
        Flexible(
          child: Text('Last Password Changed:  $label',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: SecurityAccessTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
