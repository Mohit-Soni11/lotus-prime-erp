import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/dashboard/app/uv.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UV.colors.bgPrimary,
      body: Stack(
        children: [
          Positioned(
              top: -100,
              left: -100,
              child: _buildGlowOrb(UV.colors.glowPrimary)),
          Positioned(
            bottom: -100,
            right: -100,
            child: _buildGlowOrb(UV.colors.glowAccent),
          ),
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: UV.layout.cardMaxWidth,
                maxHeight: UV.layout.cardMaxHeight,
              ),
              margin: EdgeInsets.all(UV.layout.pMd),
              decoration: BoxDecoration(
                color: UV.colors.glassBase,
                borderRadius: BorderRadius.circular(UV.layout.radiusLg),
                border: Border.all(color: UV.colors.glassBorder),
                boxShadow: [UV.colors.softShadow],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UV.layout.radiusLg),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: UV.layout.blurMd,
                    sigmaY: UV.layout.blurMd,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 880;
                      if (isCompact) {
                        return Column(
                          children: [
                            SizedBox(height: 220, child: _buildLeftPanel()),
                            Expanded(child: _buildRightPanel()),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(flex: 4, child: _buildLeftPanel()),
                          Expanded(flex: 6, child: _buildRightPanel()),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: UV.colors.overlayDark,
      padding: EdgeInsets.all(UV.layout.pLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            UV.icons.defaultStore,
            size: UV.layout.iconXl,
            color: UV.colors.primary,
          ),
          SizedBox(height: UV.layout.pMd),
          Text("LOTUS ERP", style: UV.styles.hero, textAlign: TextAlign.center),
          SizedBox(height: UV.layout.pSm),
          Text(
            "Professional Jewellery Operations Platform",
            style: UV.styles.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: UV.layout.pMd,
              vertical: UV.layout.pXs,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: UV.colors.successBorder),
              borderRadius: BorderRadius.circular(UV.layout.radiusCircular),
              color: UV.colors.successBg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  UV.icons.success,
                  color: UV.colors.success,
                  size: UV.layout.iconSm,
                ),
                SizedBox(width: UV.layout.pXs),
                Text(
                  "Enterprise Secure",
                  style: UV.styles.hint.copyWith(
                    color: UV.colors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Padding(
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
              _isLogin ? "Welcome Back" : "Create Your Account",
              style: UV.styles.h1,
            ),
            SizedBox(height: UV.layout.pXs),
            Text(
              _isLogin
                  ? "Sign in to manage billing, inventory, and daily operations."
                  : "Set up your showroom account and start working securely.",
              style: UV.styles.label,
            ),
            SizedBox(height: UV.layout.pLg),
            Expanded(
              child: SingleChildScrollView(
                child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
              ),
            ),
            SizedBox(height: UV.layout.pMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? "New here?" : "Already have an account?",
                  style: UV.styles.body,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(
                    _isLogin ? "Create Account" : "Back to Sign In",
                    style: UV.styles.action,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildInput("Email Address", UV.icons.email, _emailController),
        SizedBox(height: UV.layout.pMd),
        _buildInput(
          "Password",
          UV.icons.lock,
          _passwordController,
          isPass: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Text(
              "Forgot Password?",
              style: UV.styles.body.copyWith(
                color: UV.colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildGradientButton("SIGN IN", _handleLogin),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInput(
                "Owner Name",
                UV.icons.person,
                _nameController,
              ),
            ),
            SizedBox(width: UV.layout.pSm),
            Expanded(
              child: _buildInput(
                "Mobile",
                UV.icons.phone,
                _phoneController,
                isNumber: true,
              ),
            ),
          ],
        ),
        SizedBox(height: UV.layout.pMd),
        _buildInput("Company Name", UV.icons.business, _companyController),
        SizedBox(height: UV.layout.pMd),
        _buildInput("Email Address", UV.icons.email, _emailController),
        SizedBox(height: UV.layout.pMd),
        _buildInput(
          "Password",
          UV.icons.lock,
          _passwordController,
          isPass: true,
        ),
        const SizedBox(height: 30),
        _buildGradientButton("CREATE ACCOUNT", _handleRegister),
      ],
    );
  }

  String? _validateField(
    String label,
    String? value, {
    bool isPass = false,
    bool isNumber = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return "This field is required.";

    if (label == "Email Address") {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(text)) {
        return "Enter a valid email address.";
      }
    }

    if (isPass && text.length < 6) {
      return "Password must be at least 6 characters.";
    }

    if (isNumber && text.length != 10) {
      return "Enter a valid 10-digit mobile number.";
    }

    return null;
  }

  Widget _buildInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPass = false,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? !_isPasswordVisible : false,
      keyboardType: isNumber
          ? TextInputType.number
          : label == "Email Address"
              ? TextInputType.emailAddress
              : TextInputType.text,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : [],
      style: UV.styles.body,
      validator: (v) => _validateField(
        label,
        v,
        isPass: isPass,
        isNumber: isNumber,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: UV.styles.hint,
        prefixIcon: Icon(
          icon,
          color: UV.colors.primary.withValues(alpha: 0.7),
          size: UV.layout.iconMd,
        ),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? UV.icons.visible : UV.icons.visibleOff,
                  color: UV.colors.textSecondary,
                  size: UV.layout.iconMd,
                ),
                onPressed: () => setState(
                  () => _isPasswordVisible = !_isPasswordVisible,
                ),
              )
            : null,
        filled: true,
        fillColor: UV.colors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UV.layout.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UV.layout.radiusSm),
          borderSide: BorderSide(color: UV.colors.inputBorderFocus),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: UV.colors.goldGradient,
        borderRadius: BorderRadius.circular(UV.layout.radiusSm),
        boxShadow: [
          BoxShadow(
            color: UV.colors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UV.layout.radiusSm),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(text, style: UV.styles.button),
      ),
    );
  }

  Widget _buildGlowOrb(Color color) {
    return Container(
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
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: UV.colors.bgSecondary,
        title: Text("Reset Password", style: UV.styles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter your email address to receive a password reset link.",
              style: UV.styles.body,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              style: UV.styles.body,
              decoration: InputDecoration(
                hintText: "name@example.com",
                hintStyle: UV.styles.hint,
                filled: true,
                fillColor: UV.colors.bgPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: UV.styles.action.copyWith(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              Navigator.pop(context);

              final res = await _authService.resetPassword(
                resetEmailController.text.trim(),
              );

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    res == "SUCCESS"
                        ? "Password reset link sent. Please check your email."
                        : res,
                  ),
                  backgroundColor:
                      res == "SUCCESS" ? UV.colors.success : UV.colors.error,
                ),
              );
            },
            child: Text("Send Link", style: UV.styles.action),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final res = await _authService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res == "SUCCESS") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Signed in successfully. Redirecting..."),
          backgroundColor: UV.colors.success,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res),
        backgroundColor: UV.colors.error,
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final res = await _authService.registerOwner(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      ownerName: _nameController.text.trim(),
      mobile: _phoneController.text.trim(),
      companyName: _companyController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res == "SUCCESS") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Account created successfully. Please verify your email and sign in.",
          ),
          backgroundColor: UV.colors.success,
        ),
      );
      setState(() => _isLogin = true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res),
        backgroundColor: UV.colors.error,
      ),
    );
  }
}
