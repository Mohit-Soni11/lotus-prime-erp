// -----------------------------------------------------------------------------
// FILE: lib/ui/settings/account_profile/account_profile_screen.dart
// MODULE: Settings â†’ Account Profile
// DESCRIPTION: Role-based profile page
//              - Dark shell app bar (exact CustomerList style)
//              - Cream + White body
//              - Photo upload + crop
//              - Role badge (OWNER / MANAGER / STAFF)
//              - Fade-in animations
//              - Password change section (collapsible)
//              - Owner-only account details panel
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/auth/services/auth_service.dart';
import '../../../theme/settings/account_profile/account_profile_theme.dart';
import 'account_profile_app_bar.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen>
    with SingleTickerProviderStateMixin {
  // â”€â”€ Services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _pickedImageFile;

  // â”€â”€ Form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _emailCtrl;

  // â”€â”€ Password â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _showPasswordSection = false;
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurr = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // â”€â”€ Animation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // â”€â”€ Role helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get _role => (_userData?['role'] ?? 'STAFF').toString().toUpperCase();
  bool get _isOwner => _role == 'OWNER';
  bool get _isManager => _role == 'MANAGER';
  bool get _canEditName => _isOwner || _isManager || _role == 'STAFF';
  bool get _canEditMobile => _isOwner || _isManager;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _emailCtrl = TextEditingController();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _loadUserData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // DATA
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.getUserDetails();
      if (data != null && mounted) {
        setState(() {
          _userData = data;
          _nameCtrl.text = data['name'] ?? '';
          _mobileCtrl.text = data['mobile'] ?? '';
          _emailCtrl.text = _auth.currentUser?.email ?? data['email'] ?? '';
          _isLoading = false;
        });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PHOTO PICK + CROP
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickAndCropPhoto() async {
    // 1. Pick from gallery
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1024,
    );
    if (picked == null) return;

    // 2. Crop (circular crop for profile photo)
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Photo',
          toolbarColor: AccountProfileColors.shellPanelBg,
          toolbarWidgetColor: AccountProfileColors.brandGold,
          activeControlsWidgetColor: AccountProfileColors.brandGold,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped != null && mounted) {
      setState(() => _pickedImageFile = File(cropped.path));
    }
  }

  void _showPhotoMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoMenuSheet(
        onGallery: () {
          Navigator.pop(context);
          _pickAndCropPhoto();
        },
        onRemove: () {
          Navigator.pop(context);
          setState(() => _pickedImageFile = null);
        },
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SAVE PROFILE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _auth.currentUser?.updateDisplayName(_nameCtrl.text.trim());

      final Map<String, dynamic> update = {
        'name': _nameCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_canEditMobile) update['mobile'] = _mobileCtrl.text.trim();
      // TODO: upload _pickedImageFile to Firebase Storage when configured
      // For now store local path
      if (_pickedImageFile != null) {
        update['profileImageUrl'] = _pickedImageFile!.path;
      }

      await _firestore.collection('users').doc(uid).update(update);

      if (mounted) {
        _showFeedback(AccountProfileStrings.successProfile, isError: false);
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        _showFeedback('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CHANGE PASSWORD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showFeedback(AccountProfileStrings.errorPassMismatch, isError: true);
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      _showFeedback(AccountProfileStrings.errorPassLength, isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currPassCtrl.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPassCtrl.text);

      if (mounted) {
        _showFeedback(AccountProfileStrings.successPassword, isError: false);
        _currPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        setState(() => _showPasswordSection = false);
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'wrong-password'
          ? AccountProfileStrings.errorWrongPass
          : 'Password change failed. Try again.';
      if (mounted) _showFeedback(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SNACKBAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showFeedback(String msg, {required bool isError}) {
    AppFeedback.show(
      context,
      type: isError ? AppFeedbackType.success : AppFeedbackType.error,
      message: msg,
      duration: const Duration(seconds: 3),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUILD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccountProfileColors.bodyBg,
      appBar: AccountProfileAppBar(
        onBack: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AccountProfileColors.brandGold),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // â”€â”€ TOP: Avatar + Form side by side â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _buildTopRow(),
                      const SizedBox(height: 20),

                      // â”€â”€ Password section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _buildPasswordCard(),
                      const SizedBox(height: 20),

                      // â”€â”€ Owner-only account details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (_isOwner) ...[
                        _buildAccountDetailsCard(),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TOP ROW: Avatar (left) + Form (right)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar card
        _buildAvatarCard(),
        const SizedBox(width: 20),
        // Form card
        Expanded(child: _buildFormCard()),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // AVATAR CARD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAvatarCard() {
    final networkUrl = _userData?['profileImageUrl'] as String?;
    final hasNetwork = networkUrl != null && networkUrl.startsWith('http');
    final hasLocal = _pickedImageFile != null;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: AccountProfileStyles.cardDecoration,
      child: Column(
        children: [
          // â”€â”€ Avatar circle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Stack(
            children: [
              Container(
                width: AccountProfileStyles.avatarSize,
                height: AccountProfileStyles.avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AccountProfileColors.brandGold, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AccountProfileColors.brandGold.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasLocal
                      ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                      : hasNetwork
                          ? Image.network(networkUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildInitialsAvatar())
                          : _buildInitialsAvatar(),
                ),
              ),

              // Camera / Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showPhotoMenu,
                  child: Container(
                    width: AccountProfileStyles.cameraIconSize,
                    height: AccountProfileStyles.cameraIconSize,
                    decoration: BoxDecoration(
                      color: AccountProfileColors.brandGold,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AccountProfileColors.bodyPanelBg, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AccountProfileColors.brandGold
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(AccountProfileIcons.camera,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name
          Text(
            _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
            style: AccountProfileStyles.avatarName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            _emailCtrl.text,
            style: AccountProfileStyles.avatarEmail,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Role badge
          _buildRoleBadge(_role),
          const SizedBox(height: 10),

          // Online dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AccountProfileColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AccountProfileColors.success,
                        blurRadius: 4,
                        spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text('Online',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AccountProfileColors.success,
                      fontWeight: FontWeight.w600)),
            ],
          ),

          if (_pickedImageFile != null) ...[
            const SizedBox(height: 12),
            // Crop hint
            GestureDetector(
              onTap: _pickAndCropPhoto,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AccountProfileColors.brandGoldBg,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AccountProfileColors.brandGoldBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AccountProfileIcons.crop,
                        size: 13, color: AccountProfileColors.brandGold),
                    const SizedBox(width: 5),
                    Text(AccountProfileStrings.btnCrop,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AccountProfileColors.brandGold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final name = _nameCtrl.text;
    String initials = 'U';
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      initials = parts.length > 1
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : name[0].toUpperCase();
    }
    return Container(
      color: AccountProfileColors.avatarBg,
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.manrope(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AccountProfileColors.avatarInitials,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg, text, border;
    IconData icon;
    switch (role) {
      case 'OWNER':
        bg = AccountProfileColors.ownerBadgeBg;
        text = AccountProfileColors.ownerBadgeText;
        border = AccountProfileColors.ownerBadgeBorder;
        icon = AccountProfileIcons.shield;
        break;
      case 'MANAGER':
        bg = AccountProfileColors.managerBadgeBg;
        text = AccountProfileColors.managerBadgeText;
        border = AccountProfileColors.managerBadgeBorder;
        icon = Icons.supervisor_account_outlined;
        break;
      default:
        bg = AccountProfileColors.staffBadgeBg;
        text = AccountProfileColors.staffBadgeText;
        border = AccountProfileColors.staffBadgeBorder;
        icon = AccountProfileIcons.person;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 13),
          const SizedBox(width: 5),
          Text(role,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: text,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FORM CARD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AccountProfileStyles.cardDecoration,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildSectionHeader(
              icon: AccountProfileIcons.edit,
              title: AccountProfileStrings.sectionProfile,
            ),
            const SizedBox(height: 20),

            // Full Name
            _buildInputField(
              controller: _nameCtrl,
              label: AccountProfileStrings.labelName,
              icon: AccountProfileIcons.person,
              enabled: _canEditName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AccountProfileStrings.errorNameRequired
                  : null,
            ),
            const SizedBox(height: 14),

            // Mobile
            _buildInputField(
              controller: _mobileCtrl,
              label: AccountProfileStrings.labelMobile,
              icon: AccountProfileIcons.phone,
              enabled: _canEditMobile,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            // Email (always read-only)
            _buildInputField(
              controller: _emailCtrl,
              label: AccountProfileStrings.labelEmail,
              icon: AccountProfileIcons.email,
              enabled: false,
              hintText: AccountProfileStrings.labelEmailNote,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AccountProfileColors.brandGold,
                  disabledBackgroundColor:
                      AccountProfileColors.brandGold.withValues(alpha: 0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(AccountProfileIcons.save,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(AccountProfileStrings.btnSave,
                              style: AccountProfileStyles.buttonText),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AccountProfileStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: AccountProfileStyles.fieldValue.copyWith(
            color: enabled
                ? AccountProfileColors.bodyTextMain
                : AccountProfileColors.inputDisabledText,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
                fontSize: 12, color: AccountProfileColors.bodyTextMuted),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                icon,
                size: 18,
                color: enabled
                    ? AccountProfileColors.brandGold
                    : AccountProfileColors.inputDisabledText,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: enabled
                ? AccountProfileColors.inputBg
                : AccountProfileColors.inputDisabledBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AccountProfileColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AccountProfileColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AccountProfileColors.inputFocus, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color:
                      AccountProfileColors.inputBorder.withValues(alpha: 0.5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AccountProfileColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AccountProfileColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PASSWORD CARD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPasswordCard() {
    return Container(
      decoration: AccountProfileStyles.cardDecoration,
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: () =>
                setState(() => _showPasswordSection = !_showPasswordSection),
            borderRadius:
                BorderRadius.circular(AccountProfileStyles.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AccountProfileColors.infoBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              AccountProfileColors.info.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(AccountProfileIcons.lock,
                        color: AccountProfileColors.info, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AccountProfileStrings.sectionPassword,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AccountProfileColors.bodyTextMain)),
                        const SizedBox(height: 3),
                        Text('Update your login password',
                            style: AccountProfileStyles.avatarEmail),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showPasswordSection ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(AccountProfileIcons.chevronDown,
                        color: AccountProfileColors.bodyTextMuted, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Expandable form
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildPasswordForm(),
            crossFadeState: _showPasswordSection
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Divider(
              color: AccountProfileColors.bodyBorder.withValues(alpha: 0.7),
              height: 1),
          const SizedBox(height: 18),
          _buildPasswordField(
            controller: _currPassCtrl,
            label: AccountProfileStrings.labelCurrentPass,
            obscure: _obscureCurr,
            onToggle: () => setState(() => _obscureCurr = !_obscureCurr),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _newPassCtrl,
            label: AccountProfileStrings.labelNewPass,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _confirmPassCtrl,
            label: AccountProfileStrings.labelConfirmPass,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AccountProfileColors.info,
                disabledBackgroundColor:
                    AccountProfileColors.info.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(AccountProfileStrings.btnUpdatePass,
                      style: AccountProfileStyles.buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AccountProfileStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: AccountProfileStyles.fieldValue,
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(AccountProfileIcons.lock,
                  size: 17, color: AccountProfileColors.info),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? AccountProfileIcons.visibilityOff
                    : AccountProfileIcons.visibility,
                size: 18,
                color: AccountProfileColors.bodyTextMuted,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AccountProfileColors.inputBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AccountProfileColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AccountProfileColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AccountProfileColors.info, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // OWNER ACCOUNT DETAILS CARD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAccountDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AccountProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(AccountProfileStyles.cardRadius),
        border: Border.all(
            color: AccountProfileColors.brandGold.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
              color: AccountProfileColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: AccountProfileIcons.verified,
            title: AccountProfileStrings.sectionAccount,
          ),
          const SizedBox(height: 16),
          Divider(
              color: AccountProfileColors.bodyBorder.withValues(alpha: 0.6),
              height: 1),
          const SizedBox(height: 14),
          _infoRow('Company ID', _userData?['companyId'] ?? 'â€”'),
          _infoRow('User ID', _auth.currentUser?.uid ?? 'â€”'),
          _infoRow('Plan', _userData?['plan'] ?? 'Enterprise'),
          _infoRow(
            'Email Verified',
            (_auth.currentUser?.emailVerified ?? false)
                ? 'âœ“ Verified'
                : 'âœ— Not Verified',
            valueColor: (_auth.currentUser?.emailVerified ?? false)
                ? AccountProfileColors.successText
                : AccountProfileColors.danger,
          ),
          _infoRow('Assigned Units',
              (_userData?['assignedUnits'] as List?)?.join(', ') ?? 'ALL'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AccountProfileStyles.infoLabel),
          ),
          Expanded(
            child: Text(
              value,
              style: AccountProfileStyles.infoValue.copyWith(
                color: valueColor ?? AccountProfileColors.bodyTextMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SECTION HEADER
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AccountProfileColors.brandGoldBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AccountProfileColors.brandGoldBorder),
          ),
          child: Icon(icon, size: 14, color: AccountProfileColors.brandGold),
        ),
        const SizedBox(width: 10),
        Text(title, style: AccountProfileStyles.sectionTitle),
      ],
    );
  }
}

// =============================================================================
// PHOTO MENU BOTTOM SHEET
// =============================================================================

class _PhotoMenuSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _PhotoMenuSheet({required this.onGallery, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AccountProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AccountProfileColors.bodyBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AccountProfileColors.bodyBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _SheetTile(
            icon: AccountProfileIcons.gallery,
            label: AccountProfileStrings.photoMenuGallery,
            color: AccountProfileColors.brandGold,
            onTap: onGallery,
          ),
          Divider(
              color: AccountProfileColors.bodyBorder.withValues(alpha: 0.5),
              height: 1,
              indent: 20,
              endIndent: 20),
          _SheetTile(
            icon: AccountProfileIcons.deletePhoto,
            label: AccountProfileStrings.photoMenuRemove,
            color: AccountProfileColors.danger,
            onTap: onRemove,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AccountProfileColors.bodyTextMain)),
          ],
        ),
      ),
    );
  }
}
