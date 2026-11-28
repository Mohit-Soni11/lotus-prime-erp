import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../database/local_database/shop_database_helper.dart';
import '../../theme/dashboard/app/uv.dart';
import 'services/auth_service.dart';
import 'services/auth_session_controller.dart';
import 'widgets/auth_brand_panel.dart';
import 'widgets/auth_forms.dart';
import 'widgets/company_creation_preview.dart';
import 'widgets/password_reset_dialog.dart';

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
  final _confirmPassword = TextEditingController();
  final _name = TextEditingController();
  final _mobile = TextEditingController();

  bool _isLogin = true;
  bool _showCompanyPreview = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _canCreateOwner = false;
  bool _registrationChecked = false;
  bool _hasCompanyProfile = false;
  bool _registrationCheckFailed = false;

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
          _isLogin = !canCreateOwner;
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
    _confirmPassword.dispose();
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: UV.colors.bgPrimary,
        body: LayoutBuilder(
          builder: (context, viewport) {
            final width = math.min(
              UV.layout.cardMaxWidth,
              math.max(0.0, viewport.maxWidth - 32),
            );
            final height = math.min(
              UV.layout.cardMaxHeight,
              math.max(560.0, viewport.maxHeight - 32),
            );
            return Stack(
              children: [
                Positioned(
                  top: -100,
                  left: -100,
                  child: _glowOrb(UV.colors.glowPrimary),
                ),
                Positioned(
                  bottom: -100,
                  right: -100,
                  child: _glowOrb(UV.colors.glowAccent),
                ),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: Center(
                      child: Container(
                        width: width,
                        height: height,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: UV.colors.glassBase,
                          borderRadius:
                              BorderRadius.circular(UV.layout.radiusLg),
                          border: Border.all(color: UV.colors.glassBorder),
                          boxShadow: [UV.colors.softShadow],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(UV.layout.radiusLg),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: UV.layout.blurMd,
                              sigmaY: UV.layout.blurMd,
                            ),
                            child: width < 880
                                ? Column(
                                    children: [
                                      const SizedBox(
                                        height: 175,
                                        child: AuthBrandPanel(),
                                      ),
                                      Expanded(child: _rightPanel()),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Expanded(
                                        flex: 4,
                                        child: AuthBrandPanel(),
                                      ),
                                      Expanded(flex: 6, child: _rightPanel()),
                                    ],
                                  ),
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

  Widget _rightPanel() => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: UV.layout.pXl,
          vertical: UV.layout.pLg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                _showCompanyPreview
                    ? 'Create Company'
                    : _isLogin
                        ? 'Welcome Back'
                        : 'Create Your Account',
                style: UV.styles.h1,
              ),
              SizedBox(height: UV.layout.pXs),
              Text(
                _showCompanyPreview
                    ? 'Review the original showroom registration flow.'
                    : _isLogin
                        ? 'Sign in to manage billing, inventory, and daily operations.'
                        : 'Create the owner account for this shop installation.',
                style: UV.styles.label,
              ),
              SizedBox(height: UV.layout.pLg),
              Expanded(
                child: SingleChildScrollView(
                  child: _showCompanyPreview
                      ? const CompanyCreationPreview()
                      : _isLogin
                          ? SignInForm(
                              usernameController: _username,
                              passwordController: _password,
                              isLoading: _isLoading,
                              passwordVisible: _isPasswordVisible,
                              onTogglePassword: _togglePassword,
                              onForgotPassword: _resetPassword,
                              onSubmit: _handleLogin,
                            )
                          : OwnerRegistrationForm(
                              nameController: _name,
                              mobileController: _mobile,
                              usernameController: _username,
                              passwordController: _password,
                              confirmPasswordController: _confirmPassword,
                              isLoading: _isLoading,
                              passwordVisible: _isPasswordVisible,
                              onTogglePassword: _togglePassword,
                              onSubmit: _handleRegister,
                            ),
                ),
              ),
              SizedBox(height: UV.layout.pMd),
              if (_showCompanyPreview)
                Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _showCompanyPreview = false),
                    child: Text('Back to Sign In', style: UV.styles.action),
                  ),
                ),
              if (!_showCompanyPreview && (_canCreateOwner || !_isLogin))
                Align(
                  alignment: Alignment.center,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'New here?' : 'Already have an account?',
                        style: UV.styles.body,
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _switchForm,
                        child: Text(
                          _isLogin ? 'Create Account' : 'Back to Sign In',
                          style: UV.styles.action,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_showCompanyPreview &&
                  _registrationChecked &&
                  !_canCreateOwner &&
                  _isLogin)
                Padding(
                  padding: EdgeInsets.only(top: UV.layout.pSm),
                  child: Text(
                    _hasCompanyProfile
                        ? 'Current company account is ready. Sign in to continue.'
                        : 'Owner account created. Sign in to finish company setup.',
                    textAlign: TextAlign.center,
                    style: UV.styles.body.copyWith(
                      color: UV.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (!_showCompanyPreview && _registrationCheckFailed)
                Padding(
                  padding: EdgeInsets.only(top: UV.layout.pSm),
                  child: TextButton(
                    onPressed: _loadRegistrationAvailability,
                    child: const Text('Could not check company setup. Retry'),
                  ),
                ),
              if (!_showCompanyPreview && _isLogin)
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _showCompanyPreview = true),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Create Company'),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _glowOrb(Color color) => Container(
        width: UV.layout.glowOrbSize,
        height: UV.layout.glowOrbSize,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: UV.layout.blurGlow,
            sigmaY: UV.layout.blurGlow,
          ),
          child: Container(color: Colors.transparent),
        ),
      );

  void _togglePassword() =>
      setState(() => _isPasswordVisible = !_isPasswordVisible);

  void _switchForm() {
    if (_isLogin && !_canCreateOwner) return;
    _formKey.currentState?.reset();
    _password.clear();
    _confirmPassword.clear();
    setState(() {
      _isLogin = !_isLogin;
      _isPasswordVisible = false;
    });
  }

  Future<void> _resetPassword() async {
    final result = await showPasswordResetDialog(context, _authService);
    if (!mounted || result == null) return;
    AppFeedback.show(
      context,
      type: result.isSuccess ? AppFeedbackType.success : AppFeedbackType.error,
      message: result.message,
    );
  }

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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await _session.registerOwner(
      username: _username.text,
      password: _password.text,
      ownerName: _name.text,
      mobile: _mobile.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.accountCreated) {
      _password.clear();
      _confirmPassword.clear();
      setState(() {
        _isLogin = true;
        _canCreateOwner = false;
        _hasCompanyProfile = false;
        _registrationChecked = true;
      });
      await _showRecoveryCode(result.recoveryCode!);
      return;
    }
    AppFeedback.show(
      context,
      type: result.accountCreated
          ? AppFeedbackType.warning
          : AppFeedbackType.error,
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
