import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui/auth/services/auth_service.dart';
import '../../../theme/settings/account_profile/account_profile_theme.dart';
import 'account_profile_app_bar.dart';
import 'profile_photo_store.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'widgets/profile_avatar_widgets.dart';
part 'widgets/profile_form_widgets.dart';
part 'widgets/profile_details_widgets.dart';
part 'widgets/profile_photo_menu.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ProfilePhotoStore _photoStore = ProfilePhotoStore();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _pickedImageFile;
  bool _photoRemoved = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _emailCtrl;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String get _role => (_userData?['role'] ?? 'STAFF').toString().toUpperCase();
  bool get _isOwner => _role == 'OWNER';
  bool get _isManager => _role == 'MANAGER';
  bool get _canEditName => _isOwner || _isManager || _role == 'STAFF';
  bool get _canEditMobile => _isOwner || _isManager;

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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.getUserDetails();
      final uid = _authService.currentUserId;
      final photo = uid == null ? null : await _photoStore.read(uid);
      if (mounted) {
        setState(() {
          _userData = data;
          _nameCtrl.text = data?['name'] ?? '';
          _mobileCtrl.text = data?['mobile'] ?? '';
          _emailCtrl.text = data?['username'] ?? '';
          _pickedImageFile = photo;
          _photoRemoved = false;
          _isLoading = false;
        });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndCropPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1024,
    );
    if (picked == null) return;

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
      setState(() {
        _pickedImageFile = File(cropped.path);
        _photoRemoved = false;
      });
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
          setState(() {
            _pickedImageFile = null;
            _photoRemoved = true;
          });
        },
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uid = _authService.currentUserId;
      if (uid == null) {
        _showFeedback('Your session has ended. Sign in again.', isError: true);
        return;
      }

      final result = await _authService.updateProfile(
          name: _nameCtrl.text.trim(), mobile: _mobileCtrl.text.trim());
      if (!result.isSuccess) throw StateError(result.message);

      if (_photoRemoved) {
        await _photoStore.remove(uid);
      } else if (_pickedImageFile != null) {
        _pickedImageFile = await _photoStore.save(uid, _pickedImageFile!);
      }

      if (mounted) {
        _showFeedback(AccountProfileStrings.successProfile, isError: false);
        await _loadUserData();
      }
    } catch (_) {
      if (mounted) {
        _showFeedback('Profile could not be saved. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showFeedback(String msg, {required bool isError}) {
    AppFeedback.show(
      context,
      type: isError ? AppFeedbackType.error : AppFeedbackType.success,
      message: msg,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccountProfileColors.bodyBg,
      appBar: AccountProfileAppBar(
        onBack: widget.onBack ?? () => Navigator.pop(context),
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
                      _buildTopRow(),
                      const SizedBox(height: 20),
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
}
