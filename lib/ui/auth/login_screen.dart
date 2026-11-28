import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../database/local_database/shop_database_helper.dart';
import 'services/auth_service.dart';
import 'services/auth_session_controller.dart';
import 'services/company_google_enrollment.dart';
import 'widgets/auth_brand_panel.dart';
import 'widgets/company_creation_panel.dart';
import 'widgets/company_registration_input.dart';
import 'widgets/luxury_auth_background.dart';
import 'widgets/luxury_auth_palette.dart';
import 'widgets/luxury_sign_in_panel.dart';
import 'widgets/password_recovery_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _session = AuthSessionController.instance;
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _showCompanyCreation = false;
  bool _showPasswordRecovery = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _canCreateOwner = false;
  bool _registrationChecked = false;
  bool _hasCompanyProfile = false;
  bool _registrationCheckFailed = false;
  String? _companyConnectionStatus;

  @override
  void initState() {
    super.initState();
    _loadRegistrationAvailability();
  }

  Future<void> _loadRegistrationAvailability() async {
    try {
      final canCreateOwner = !await _authService.hasOwnerAccount();
      final hasCompanyProfile = !canCreateOwner &&
          await ShopDatabaseHelper().firstPersistedTenantId() != null;
      if (mounted) {
        setState(() {
          _canCreateOwner = canCreateOwner;
          _hasCompanyProfile = hasCompanyProfile;
          _registrationChecked = true;
          _registrationCheckFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _canCreateOwner = false;
          _registrationCheckFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: LuxuryAuthPalette.navy,
        body: LayoutBuilder(
          builder: (context, viewport) {
            final width = math.min(
              1260.0,
              math.max(0.0, viewport.maxWidth - 48),
            );
            final compact = width < 880;
            final height = compact
                ? 920.0
                : math.min(706.0, math.max(660.0, viewport.maxHeight - 64));
            return Stack(
              children: [
                const Positioned.fill(child: LuxuryAuthBackground()),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: Center(
                      child: Container(
                        width: width,
                        height: height,
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: LuxuryAuthPalette.navy,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                              color: LuxuryAuthPalette.gold, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xCC000717),
                              blurRadius: 48,
                              offset: Offset(0, 24),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: compact
                              ? Column(
                                  children: [
                                    const SizedBox(
                                      height: 225,
                                      child: AuthBrandPanel(),
                                    ),
                                    Expanded(child: _animatedRightPanel()),
                                  ],
                                )
                              : Row(
                                  children: [
                                    const Expanded(
                                      flex: 41,
                                      child: AuthBrandPanel(),
                                    ),
                                    Expanded(
                                        flex: 59, child: _animatedRightPanel()),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _animatedRightPanel() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_showPasswordRecovery
              ? 'recovery'
              : _showCompanyCreation
                  ? 'company'
                  : 'login'),
          child: _rightPanel(),
        ),
      );

  Widget _rightPanel() {
    if (_showPasswordRecovery) {
      return PasswordRecoveryPanel(
        authService: _authService,
        onBackToSignIn: () => setState(() => _showPasswordRecovery = false),
      );
    }
    if (_showCompanyCreation) {
      return CompanyCreationPanel(
        isLoading: _isLoading,
        onSubmit: _handleRegister,
        onBackToSignIn: () => setState(() => _showCompanyCreation = false),
      );
    }
    return LuxurySignInPanel(
      formKey: _formKey,
      usernameController: _username,
      passwordController: _password,
      isLoading: _isLoading,
      passwordVisible: _isPasswordVisible,
      onTogglePassword: _togglePassword,
      onForgotPassword: () => setState(() => _showPasswordRecovery = true),
      onSignIn: _handleLogin,
      onCreateCompany: () => setState(() => _showCompanyCreation = true),
      companyStatus: _companyConnectionStatus ??
          (_registrationChecked && !_canCreateOwner
              ? (_hasCompanyProfile
                  ? 'Current company account is ready. Sign in to continue.'
                  : 'Owner account created. Sign in to finish company setup.')
              : null),
      onRetryStatus:
          _registrationCheckFailed ? _loadRegistrationAvailability : null,
    );
  }

  void _togglePassword() =>
      setState(() => _isPasswordVisible = !_isPasswordVisible);

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await _session.loginUser(
      username: _username.text,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.error,
      message: result.message,
    );
  }

  Future<void> _handleRegister(CompanyRegistrationInput input) async {
    setState(() => _isLoading = true);
    final result = await _session.registerOwner(
      username: input.email,
      password: input.password,
      ownerName: input.ownerName,
      mobile: input.mobile,
      companyName: input.companyName,
    );
    if (!mounted) return;
    if (result.accountCreated) {
      _username.text = input.email;
      _password.clear();
      setState(() {
        _showCompanyCreation = false;
        _canCreateOwner = false;
        _hasCompanyProfile = false;
        _registrationChecked = true;
        _companyConnectionStatus =
            'Company created. Save the recovery code to continue Google setup.';
      });
      await _showRecoveryCode(result.recoveryCode!);
      if (!mounted) return;
      setState(() => _companyConnectionStatus =
          'Connecting ${input.email} for backup and password recovery...');
      try {
        await CompanyGoogleEnrollment().connect(
          email: input.email,
          password: input.password,
        );
        if (!mounted) return;
        setState(() => _companyConnectionStatus =
            'Google account linked for backup and password recovery. Sign in to continue.');
      } catch (error) {
        if (!mounted) return;
        setState(() => _companyConnectionStatus =
            'Company created. Google connection is pending; sign in to finish it in Backup & Restore.');
        AppFeedback.show(
          context,
          type: AppFeedbackType.warning,
          message: error.toString().replaceFirst('Bad state: ', ''),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }
    setState(() => _isLoading = false);
    AppFeedback.show(
      context,
      type: AppFeedbackType.error,
      message: result.message,
    );
  }

  Future<void> _showRecoveryCode(String code) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Save your recovery code'),
          content: SelectableText(
            'Keep this code in a safe place. It is shown only once and is required to reset your password offline.\n\n$code',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I saved it'),
            ),
          ],
        ),
      );
}
