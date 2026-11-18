import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../theme/dashboard/app/uv.dart';
import 'services/auth_service.dart';
import 'services/auth_session_controller.dart';
import 'services/installation_account_binding.dart';
import 'widgets/auth_brand_panel.dart';
import 'widgets/auth_forms.dart';
import 'widgets/password_reset_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _session = AuthSessionController.instance;
  final _authService = AuthService();
  final _installation = InstallationAccountBinding();
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _name = TextEditingController();
  final _mobile = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _canCreateOwner = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrationAvailability();
  }

  Future<void> _loadRegistrationAvailability() async {
    try {
      final canCreateOwner = await _installation.canCreateOwner();
      if (mounted) setState(() => _canCreateOwner = canCreateOwner);
    } catch (_) {
      if (mounted) setState(() => _canCreateOwner = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
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
                _isLogin ? 'Welcome Back' : 'Create Your Account',
                style: UV.styles.h1,
              ),
              SizedBox(height: UV.layout.pXs),
              Text(
                _isLogin
                    ? 'Sign in to manage billing, inventory, and daily operations.'
                    : 'Create the owner account for this shop installation.',
                style: UV.styles.label,
              ),
              SizedBox(height: UV.layout.pLg),
              Expanded(
                child: SingleChildScrollView(
                  child: _isLogin
                      ? SignInForm(
                          emailController: _email,
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
                          emailController: _email,
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
              if (_canCreateOwner || !_isLogin)
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
      email: _email.text,
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
      email: _email.text,
      password: _password.text,
      ownerName: _name.text,
      mobile: _mobile.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.accountCreated) {
      _password.clear();
      _confirmPassword.clear();
      setState(() => _isLogin = true);
    }
    AppFeedback.show(
      context,
      type: result.accountCreated
          ? AppFeedbackType.warning
          : AppFeedbackType.error,
      message: result.message,
    );
  }
}
