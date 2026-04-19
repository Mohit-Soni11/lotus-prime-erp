import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ Fixed Import Path (Assuming file is in lib/ui/auth/)
import '../../theme/dashboard/app/uv.dart'; 

// ✅ Service Import (Ensure auth_service.dart is in lib/ui/auth/services/ or adjust this)
import 'services/auth_service.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // ==========================================
  // ⚡ DEVELOPER CONFIG
  // ==========================================
  final String _devEmail = "reyanshsoni3216@gmail.com"; 
  final String _devPass = "123456"; 
  // ==========================================

  // State
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();

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
          // 1. Background Ambience (Glows)
          Positioned(
            top: -100, left: -100, 
            child: _buildGlowOrb(UV.colors.glowPrimary) 
          ),
          Positioned(
            bottom: -100, right: -100, 
            child: _buildGlowOrb(UV.colors.glowAccent)
          ),

          // 2. Main Center Card
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: UV.layout.cardMaxWidth,   
                maxHeight: UV.layout.cardMaxHeight 
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
                    sigmaY: UV.layout.blurMd
                  ), 
                  child: Row(
                    children: [
                      // LEFT: Branding Panel (40%)
                      Expanded(flex: 4, child: _buildLeftPanel()),
                      
                      // RIGHT: Form Panel (60%)
                      Expanded(flex: 6, child: _buildRightPanel()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LEFT: BRANDING PANEL ---
  Widget _buildLeftPanel() {
    return Container(
      color: UV.colors.overlayDark, 
      padding: EdgeInsets.all(UV.layout.pLg), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(UV.icons.defaultStore, size: UV.layout.iconXl, color: UV.colors.primary), 
          SizedBox(height: UV.layout.pMd),
          Text(
            "LOTUS ERP",
            style: UV.styles.hero, 
          ),
          SizedBox(height: UV.layout.pSm),
          Text(
            "Premium Jewellery Management",
            style: UV.styles.label, 
          ),
          const SizedBox(height: 50), 
          
          // Trust Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: UV.layout.pMd, vertical: UV.layout.pXs),
            decoration: BoxDecoration(
              border: Border.all(color: UV.colors.successBorder), 
              borderRadius: BorderRadius.circular(UV.layout.radiusCircular), 
              color: UV.colors.successBg, 
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(UV.icons.success, color: UV.colors.success, size: UV.layout.iconSm), 
                SizedBox(width: UV.layout.pXs),
                Text(
                  "Enterprise Secured", 
                  style: UV.styles.hint.copyWith(color: UV.colors.success, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- RIGHT: FORM PANEL ---
  Widget _buildRightPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: UV.layout.pXl, 
        vertical: UV.layout.pLg   
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLogin ? "Welcome Back" : "Create Account",
              style: UV.styles.h1, 
            ),
            SizedBox(height: UV.layout.pXs),
            Text(
              _isLogin ? "Access your dashboard securely." : "Register your showroom in seconds.",
              style: UV.styles.label, 
            ),
            SizedBox(height: UV.layout.pLg), 

            // DYNAMIC FORM FIELDS
            Expanded(
              child: SingleChildScrollView(
                child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
              ),
            ),

            SizedBox(height: UV.layout.pMd),
            // SWITCH MODE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? "New User?" : "Already have ID?",
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
                    _isLogin ? "Register Now" : "Login Here",
                    style: UV.styles.action, 
                  ),
                )
              ],
            )
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
        _buildInput("Password", UV.icons.lock, _passwordController, isPass: true), 
        
        // --- FORGOT PASSWORD BUTTON ---
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
        _buildGradientButton("SECURE LOGIN", _handleLogin),

        // 🛠️ 🛠️ 🛠️ DEVELOPER BUTTON 🛠️ 🛠️ 🛠️
        const SizedBox(height: 20),
        Center(
          child: InkWell(
            onTap: _handleDevBypass, 
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.developer_mode, color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Text("DEV BYPASS (Auto Login)", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        // ---------------------------------------------
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildInput("Owner Name", UV.icons.person, _nameController)), 
          SizedBox(width: UV.layout.pSm),
          Expanded(child: _buildInput("Mobile", UV.icons.phone, _phoneController, isNumber: true)), 
        ]),
        SizedBox(height: UV.layout.pMd),
        _buildInput("Company Name", UV.icons.business, _companyController), 
        SizedBox(height: UV.layout.pMd),
        _buildInput("Email Address", UV.icons.email, _emailController),
        SizedBox(height: UV.layout.pMd),
        _buildInput("Password", UV.icons.lock, _passwordController, isPass: true),
        const SizedBox(height: 30),
        _buildGradientButton("REGISTER SHOWROOM", _handleRegister),
      ],
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildInput(String label, IconData icon, TextEditingController controller, {bool isPass = false, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? !_isPasswordVisible : false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : [],
      style: UV.styles.body,
      validator: (v) => v!.isEmpty ? "Required field" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: UV.styles.hint,
        prefixIcon: Icon(icon, color: UV.colors.primary.withOpacity(0.7), size: UV.layout.iconMd), 
        suffixIcon: isPass ? IconButton(
          icon: Icon(_isPasswordVisible ? UV.icons.visible : UV.icons.visibleOff, color: UV.colors.textSecondary, size: UV.layout.iconMd),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ) : null,
        filled: true,
        fillColor: UV.colors.bgSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(UV.layout.radiusSm), borderSide: BorderSide.none), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(UV.layout.radiusSm), borderSide: BorderSide(color: UV.colors.inputBorderFocus)),
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
          BoxShadow(color: UV.colors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))
        ]
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UV.layout.radiusSm))
        ),
        child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
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
        filter: ImageFilter.blur(sigmaX: UV.layout.blurGlow, sigmaY: UV.layout.blurGlow), 
        child: Container(color: Colors.transparent),
      ),
    );
  }

  // --- ACTIONS (LOGIC) ---

  void _handleDevBypass() {
    _emailController.text = _devEmail;
    _passwordController.text = _devPass;
    _handleLogin(); 
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
            Text("Enter your email to receive a reset link.", style: UV.styles.body),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              style: UV.styles.body,
              decoration: InputDecoration(
                hintText: "example@email.com",
                hintStyle: UV.styles.hint,
                filled: true,
                fillColor: UV.colors.bgPrimary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: UV.styles.action.copyWith(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (resetEmailController.text.isEmpty) return;
              Navigator.pop(context); 
              
              String res = await _authService.resetPassword(resetEmailController.text.trim());
              
              if(!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res == "SUCCESS" ? "Reset link sent! Check email." : res),
                backgroundColor: res == "SUCCESS" ? UV.colors.success : UV.colors.error,
              ));
            },
            child: Text("Send Link", style: UV.styles.action),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    // ⚡ Dev Bypass Logic (Only validate if fields are empty and NOT dev credentials)
    // Simple logic: If fields are empty, run validation. If filled (by dev button), skip validation.
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        if (!_formKey.currentState!.validate()) return;
    }
    
    setState(() => _isLoading = true);
    
    // Auth Service Call
    String res = await _authService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim()
    );
    
    if (!mounted) return; 
    setState(() => _isLoading = false);

    if (res == "SUCCESS") {
       // ✅ LOGIN SUCCESS
       // Hum yahan Navigator.push nahi karenge. 🚫
       // Bas user ko batao ki login ho gaya. 
       // main.dart ka StreamBuilder (AuthGate) automatic detect karke page badal dega.

       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: const Text("Login Success! Redirecting..."), 
         backgroundColor: UV.colors.success,
         duration: const Duration(seconds: 1), // Short duration
       ));

       // NO NAVIGATION CODE HERE - LET AUTH GATE HANDLE IT

    } else {
       // ❌ LOGIN FAILED
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text(res), 
         backgroundColor: UV.colors.error 
       ));
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String res = await _authService.registerOwner(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      ownerName: _nameController.text.trim(),
      mobile: _phoneController.text.trim(),
      companyName: _companyController.text.trim()
    );
    
    if (!mounted) return;

    setState(() => _isLoading = false);
    
    if (res == "SUCCESS") {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: const Text("Account Created! Check Email & Login."), 
         backgroundColor: UV.colors.success 
       ));
       // Switch to Login tab automatically
       setState(() => _isLogin = true); 
    } else {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text(res), 
         backgroundColor: UV.colors.error 
       ));
    }
  }
}