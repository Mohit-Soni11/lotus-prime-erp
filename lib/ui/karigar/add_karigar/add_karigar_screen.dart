// =============================================================================
// FILE        : add_karigar_screen.dart
// MODULE      : Karigar â†’ Add Karigar
// LAYER       : UI / Screen
// DESCRIPTION : Full production Add Karigar screen.
//               Matches AddCustomerScreen pattern exactly.
//               6 Sections with animated entry:
//               1. Profile Photo
//               2. Identity & Name
//               3. Contact Details
//               4. Professional Profile
//               5. Address
//               6. Financial Setup
//               7. Notes & Status
//               ListenableBuilder â€” zero setState in UI.
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../logic/karigar/add_karigar_logic.dart';
import '../../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../../theme/karigar/add_karigar/add_karigar_theme.dart';
import 'add_karigar_app_bar.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class AddKarigarScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const AddKarigarScreen({super.key, this.onBack, this.onSaved});

  @override
  State<AddKarigarScreen> createState() => _AddKarigarScreenState();
}

class _AddKarigarScreenState extends State<AddKarigarScreen>
    with TickerProviderStateMixin {
  late final AddKarigarLogic _logic;
  final _imgPick = ImagePicker();

  static const int _sectionCount = 7;
  late final List<AnimationController> _anims;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  // â”€â”€ Text Controllers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _rateAmountCtrl = TextEditingController(text: '0.00');
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0.00');
  final _notesCtrl = TextEditingController();

  // â”€â”€ Focus Nodes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _altPhoneFocus = FocusNode();
  final _rateAmountFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _balanceFocus = FocusNode();
  final _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _logic = AddKarigarLogic();
    _logic.addListener(_rebuild);

    _anims = List.generate(
        _sectionCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 480)));
    _fades = _anims
        .map((a) => CurvedAnimation(parent: a, curve: Curves.easeInOut))
        .toList();
    _slides = _anims
        .map((a) => Tween<Offset>(
                begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)))
        .toList();

    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 60 + i * 80), () {
        if (mounted) _anims[i].forward();
      });
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _logic
      ..removeListener(_rebuild)
      ..dispose();
    for (final a in _anims) {
      a.dispose();
    }
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _phoneCtrl,
      _altPhoneCtrl,
      _rateAmountCtrl,
      _addressCtrl,
      _cityCtrl,
      _balanceCtrl,
      _notesCtrl
    ]) {
      c.dispose();
    }
    for (final f in [
      _firstNameFocus,
      _lastNameFocus,
      _phoneFocus,
      _altPhoneFocus,
      _rateAmountFocus,
      _addressFocus,
      _cityFocus,
      _balanceFocus,
      _notesFocus
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // â”€â”€ ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
    if (src == null) return;
    final file =
        await _imgPick.pickImage(source: src, imageQuality: 75, maxWidth: 600);
    if (file != null) _logic.setProfileImagePath(file.path);
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final ok = await _logic.saveKarigar();
    if (!mounted) return;
    if (ok) {
      _showFeedback(AddKarigarStrings.successMsg, isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      widget.onSaved?.call();
      widget.onBack?.call();
    } else if (_logic.errorMessage != null) {
      _showFeedback(_logic.errorMessage!, isSuccess: false);
    }
  }

  void _handleClear() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _phoneCtrl,
      _altPhoneCtrl,
      _rateAmountCtrl,
      _addressCtrl,
      _cityCtrl,
      _notesCtrl
    ]) {
      c.clear();
    }
    _balanceCtrl.text = '0.00';
    _rateAmountCtrl.text = '0.00';
    _logic.resetForm();
    FocusScope.of(context).unfocus();
  }

  void _showFeedback(String msg, {required bool isSuccess}) {
    AppFeedback.show(
      context,
      type: isSuccess ? AppFeedbackType.success : AppFeedbackType.error,
      message: msg,
      duration: const Duration(seconds: 3),
    );
  }

  Widget _anim(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AddKarigarColors.bodyBg,
        appBar: AddKarigarAppBar(
          onBack: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AddKarigarStyles.pagePadding,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // S0: Photo
                _anim(0, _buildPhotoSection()),
                const SizedBox(height: 20),

                // S1: Identity
                _anim(
                    1,
                    _buildSectionCard(
                      icon: AddKarigarIcons.name,
                      title: AddKarigarStrings.secIdentity,
                      subtitle: AddKarigarStrings.subIdentity,
                      accent: AddKarigarColors.accentIdentity,
                      step: 1,
                      child: _buildIdentitySection(),
                    )),
                const SizedBox(height: 16),

                // S2: Contact
                _anim(
                    2,
                    _buildSectionCard(
                      icon: AddKarigarIcons.phone,
                      title: AddKarigarStrings.secContact,
                      subtitle: AddKarigarStrings.subContact,
                      accent: AddKarigarColors.accentContact,
                      step: 2,
                      child: _buildContactSection(),
                    )),
                const SizedBox(height: 16),

                // S3: Professional
                _anim(
                    3,
                    _buildSectionCard(
                      icon: AddKarigarIcons.speciality,
                      title: AddKarigarStrings.secProfessional,
                      subtitle: AddKarigarStrings.subProfessional,
                      accent: AddKarigarColors.accentProfessional,
                      step: 3,
                      child: _buildProfessionalSection(),
                    )),
                const SizedBox(height: 16),

                // S4: Address
                _anim(
                    4,
                    _buildSectionCard(
                      icon: AddKarigarIcons.address,
                      title: AddKarigarStrings.secAddress,
                      subtitle: AddKarigarStrings.subAddress,
                      accent: AddKarigarColors.accentAddress,
                      step: 4,
                      child: _buildAddressSection(),
                    )),
                const SizedBox(height: 16),

                // S5: Financial
                _anim(
                    5,
                    _buildSectionCard(
                      icon: AddKarigarIcons.balance,
                      title: AddKarigarStrings.secFinancial,
                      subtitle: AddKarigarStrings.subFinancial,
                      accent: AddKarigarColors.accentFinancial,
                      step: 5,
                      child: _buildFinancialSection(),
                    )),
                const SizedBox(height: 16),

                // S6: Notes + Status
                _anim(
                    6,
                    _buildSectionCard(
                      icon: AddKarigarIcons.notes,
                      title: AddKarigarStrings.secNotes,
                      subtitle: AddKarigarStrings.subNotes,
                      accent: AddKarigarColors.accentNotes,
                      step: 6,
                      child: _buildNotesSection(),
                    )),
                const SizedBox(height: 28),

                _anim(6, _buildActionButtons()),
                const SizedBox(height: 8),
                Center(
                    child: Text(AddKarigarStrings.requiredNote,
                        style: AddKarigarStyles.requiredNote)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION CARD SHELL
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required int step,
    required Widget child,
  }) {
    final lighter = Color.lerp(accent, Colors.white, 0.25)!;
    return Container(
      decoration: AddKarigarStyles.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Gradient header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, lighter],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AddKarigarStyles.cardRadius)),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30), width: 1),
              ),
              child: Center(
                  child: Text(
                step.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              )),
            ),
            const SizedBox(width: 14),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.3,
                      )),
                ])),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: child,
        ),
      ]),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION 0: PHOTO
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildPhotoSection() {
    final imagePath = _logic.form.profileImagePath;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AddKarigarColors.brandGold.withValues(alpha: 0.14),
            AddKarigarColors.brandGold.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AddKarigarColors.brandGold.withValues(alpha: 0.30),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AddKarigarColors.brandGold.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  AddKarigarColors.brandGold,
                  AddKarigarColors.brandGold.withValues(alpha: 0.4),
                  AddKarigarColors.brandGold,
                ]),
                boxShadow: [
                  BoxShadow(
                      color: AddKarigarColors.brandGold.withValues(alpha: 0.40),
                      blurRadius: 16,
                      spreadRadius: 2)
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: imagePath != null
                      ? Image.file(File(imagePath),
                          fit: BoxFit.cover, width: 84, height: 84)
                      : Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFFF0EDE8),
                          child: const Icon(Icons.engineering_rounded,
                              size: 44, color: Color(0xFFD4AF37)),
                        ),
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AddKarigarColors.brandGold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AddKarigarColors.brandGold.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: Colors.black87),
            ),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AddKarigarStrings.secPhoto,
              style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AddKarigarColors.bodyTextMain)),
          const SizedBox(height: 5),
          Text(
            imagePath != null
                ? AddKarigarStrings.photoUploaded
                : AddKarigarStrings.photoAuto,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: imagePath != null
                    ? AddKarigarColors.success
                    : AddKarigarColors.bodyTextMuted),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _miniBtn(
              label: imagePath != null
                  ? AddKarigarStrings.btnChangePhoto
                  : AddKarigarStrings.btnUploadPhoto,
              icon: Icons.camera_alt_rounded,
              bg: AddKarigarColors.brandGold,
              fg: Colors.black87,
              onTap: _pickImage,
            ),
            if (imagePath != null) ...[
              const SizedBox(width: 8),
              _miniBtn(
                label: AddKarigarStrings.btnRemove,
                icon: Icons.delete_outline_rounded,
                bg: AddKarigarColors.errorBg,
                fg: AddKarigarColors.error,
                border: AddKarigarColors.error.withValues(alpha: 0.3),
                onTap: () => _logic.setProfileImagePath(null),
              ),
            ],
          ]),
        ])),
      ]),
    );
  }

  Widget _miniBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    Color? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border != null ? Border.all(color: border) : null,
          boxShadow: bg == AddKarigarColors.brandGold
              ? [
                  BoxShadow(
                      color: AddKarigarColors.brandGold.withValues(alpha: 0.30),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION 1: IDENTITY
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildIdentitySection() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child: _field(
        label: AddKarigarStrings.lblFirstName,
        hint: AddKarigarStrings.hintFirstName,
        icon: AddKarigarIcons.name,
        ctrl: _firstNameCtrl,
        focus: _firstNameFocus,
        next: _lastNameFocus,
        required: true,
        error: _logic.form.firstNameError,
        onChanged: _logic.onFirstNameChanged,
        capitalization: TextCapitalization.words,
      )),
      const SizedBox(width: 14),
      Expanded(
          child: _field(
        label: AddKarigarStrings.lblLastName,
        hint: AddKarigarStrings.hintLastName,
        icon: AddKarigarIcons.name,
        ctrl: _lastNameCtrl,
        focus: _lastNameFocus,
        next: _phoneFocus,
        onChanged: _logic.onLastNameChanged,
        capitalization: TextCapitalization.words,
      )),
    ]);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION 2: CONTACT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildContactSection() {
    return Column(children: [
      _field(
        label: AddKarigarStrings.lblPhone,
        hint: AddKarigarStrings.hintPhone,
        icon: AddKarigarIcons.phone,
        ctrl: _phoneCtrl,
        focus: _phoneFocus,
        next: _altPhoneFocus,
        required: true,
        error: _logic.form.phoneError,
        onChanged: _logic.onPhoneChanged,
        keyboardType: TextInputType.number,
        maxLength: 10,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        suffix:
            (_logic.form.phone.length == 10 && _logic.form.phoneError == null)
                ? const Icon(Icons.check_circle_rounded,
                    color: AddKarigarColors.success, size: 20)
                : null,
      ),
      const SizedBox(height: 14),
      _field(
        label: AddKarigarStrings.lblAltPhone,
        hint: AddKarigarStrings.hintAltPhone,
        icon: AddKarigarIcons.altPhone,
        ctrl: _altPhoneCtrl,
        focus: _altPhoneFocus,
        onChanged: _logic.onAlternatePhoneChanged,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        formatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    ]);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION 3: PROFESSIONAL
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildProfessionalSection() {
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _dropdown<KarigarSpecialization>(
          label: AddKarigarStrings.lblSpecialty,
          icon: AddKarigarIcons.speciality,
          value: _logic.form.specialization,
          items: KarigarSpecialization.values,
          itemLabel: (e) => e.label,
          onChanged: (v) {
            if (v != null) _logic.setSpecialization(v);
          },
        )),
        const SizedBox(width: 14),
        Expanded(
            child: _dropdown<KarigarRateType>(
          label: AddKarigarStrings.lblRateType,
          icon: AddKarigarIcons.rateType,
          value: _logic.form.rateType,
          items: KarigarRateType.values,
          itemLabel: (e) => e.label,
          onChanged: (v) {
            if (v != null) _logic.setRateType(v);
          },
        )),
      ]),
      const SizedBox(height: 14),
      _field(
        label: AddKarigarStrings.lblRateAmount,
        hint: AddKarigarStrings.hintRateAmount,
        icon: AddKarigarIcons.rateAmount,
        ctrl: _rateAmountCtrl,
        focus: _rateAmountFocus,
        prefix: 'â‚¹',
        onChanged: _logic.onRateAmountChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      ),
    ]);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION 4: ADDRESS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildAddressSection() {
    return Column(children: [
      _field(
        label: AddKarigarStrings.lblAddress,
        hint: AddKarigarStrings.hintAddress,
        icon: AddKarigarIcons.address,
        ctrl: _addressCtrl,
        focus: _addressFocus,
        next: _cityFocus,
        onChanged: _logic.onAddressChanged,
        capitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 14),
      _field(
        label: AddKarigarStrings.lblCity,
        hint: AddKarigarStrings.hintCity,
        icon: AddKarigarIcons.city,
        ctrl: _cityCtrl,
        focus: _cityFocus,
        next: _balanceFocus,
        onChanged: _logic.onCityChanged,
        capitalization: TextCapitalization.words,
      ),
    ]);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION 5: FINANCIAL
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildFinancialSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
        label: AddKarigarStrings.lblBalance,
        hint: AddKarigarStrings.hintBalance,
        icon: AddKarigarIcons.balance,
        ctrl: _balanceCtrl,
        focus: _balanceFocus,
        next: _notesFocus,
        prefix: 'â‚¹',
        onChanged: _logic.onOpeningBalanceChanged,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        formatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
        ],
      ),
      const SizedBox(height: 8),
      Text(AddKarigarStrings.balanceNote,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AddKarigarColors.bodyTextHint,
            fontStyle: FontStyle.italic,
          )),
    ]);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION 6: NOTES + STATUS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildNotesSection() {
    return Column(children: [
      _field(
        label: AddKarigarStrings.lblNotes,
        hint: AddKarigarStrings.hintNotes,
        icon: AddKarigarIcons.notes,
        ctrl: _notesCtrl,
        focus: _notesFocus,
        maxLines: 3,
        onChanged: _logic.onNotesChanged,
        capitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 20),

      // Status Toggle
      Row(children: [
        Text(AddKarigarStrings.lblStatus.toUpperCase(),
            style: AddKarigarStyles.fieldLabel),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statusChip(
          label: AddKarigarStrings.statusActive,
          hint: AddKarigarStrings.statusActiveHint,
          icon: Icons.check_circle_outline_rounded,
          isSelected: _logic.form.isActive,
          color: AddKarigarColors.success,
          onTap: () => _logic.setIsActive(true),
        ),
        const SizedBox(width: 12),
        _statusChip(
          label: AddKarigarStrings.statusInactive,
          hint: AddKarigarStrings.statusInactiveHint,
          icon: Icons.block_rounded,
          isSelected: !_logic.form.isActive,
          color: AddKarigarColors.error,
          onTap: () => _logic.setIsActive(false),
        ),
      ]),
    ]);
  }

  Widget _statusChip({
    required String label,
    required String hint,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.08)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 18, color: isSelected ? color : Colors.black54),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? color : Colors.black87)),
                  Text(hint,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.black45),
                      maxLines: 2),
                ])),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ]),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ACTION BUTTONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildActionButtons() {
    final canSave = _logic.canSave;
    final saving = _logic.isSaving;
    return Row(children: [
      OutlinedButton.icon(
        onPressed: saving ? null : _handleClear,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text(AddKarigarStrings.btnClear),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: canSave
              ? AddKarigarColors.saveBtnBg
              : AddKarigarColors.saveBtnDisabled,
          borderRadius: BorderRadius.circular(12),
          boxShadow: canSave
              ? [
                  BoxShadow(
                    color: AddKarigarColors.saveBtnBg.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSave ? _handleSave : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black54, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(AddKarigarIcons.save,
                          size: 20,
                          color: canSave ? Colors.black87 : Colors.black54),
                      const SizedBox(width: 10),
                      Text(AddKarigarStrings.btnSave,
                          style: AddKarigarStyles.saveBtnText.copyWith(
                              color:
                                  canSave ? Colors.black87 : Colors.black54)),
                    ]),
            ),
          ),
        ),
      )),
    ]);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // REUSABLE FIELD BUILDER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    required void Function(String) onChanged,
    FocusNode? focus,
    FocusNode? next,
    bool required = false,
    bool enabled = true,
    String? error,
    Widget? suffix,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    final hasFocus = focus != null && (focus.hasFocus);
    final hasValue = ctrl.text.isNotEmpty;
    final hasError = error != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: AddKarigarStyles.fieldLabel),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(
                  color: AddKarigarColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ]),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: maxLines > 1 ? null : 54,
        decoration: BoxDecoration(
          color: enabled
              ? (hasFocus
                  ? AddKarigarColors.inputBgFocus
                  : AddKarigarColors.inputBg)
              : const Color(0xFFF3F2EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError
                ? AddKarigarColors.error
                : hasFocus
                    ? AddKarigarColors.inputBorderFocus
                    : hasValue
                        ? Colors.black54
                        : AddKarigarColors.inputBorder,
            width: hasFocus || hasValue ? 1.5 : 1,
          ),
          boxShadow: hasFocus
              ? [
                  BoxShadow(
                    color: AddKarigarColors.brandGold.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : hasError
                  ? [
                      BoxShadow(
                        color: AddKarigarColors.error.withValues(alpha: 0.08),
                        blurRadius: 6,
                      )
                    ]
                  : [],
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: maxLines > 1 ? 54 : double.infinity,
            decoration: BoxDecoration(
              color: hasFocus
                  ? AddKarigarColors.brandGold.withValues(alpha: 0.12)
                  : hasError
                      ? AddKarigarColors.error.withValues(alpha: 0.08)
                      : hasValue
                          ? Colors.black.withValues(alpha: 0.03)
                          : const Color(0xFFF0EDE8),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: Border(
                  right: BorderSide(
                      color: hasFocus
                          ? AddKarigarColors.brandGold.withValues(alpha: 0.3)
                          : AddKarigarColors.inputBorder,
                      width: 1)),
            ),
            child: Center(
                child: Icon(icon,
                    size: 20,
                    color: hasFocus
                        ? AddKarigarColors.brandGold
                        : hasError
                            ? AddKarigarColors.error
                            : Colors.black87)),
          ),
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(prefix,
                  style: AddKarigarStyles.fieldText.copyWith(
                      color: Colors.black87, fontWeight: FontWeight.w700)),
            ),
          Expanded(
              child: TextFormField(
            controller: ctrl,
            focusNode: focus,
            enabled: enabled,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            textCapitalization: capitalization,
            onChanged: onChanged,
            style: AddKarigarStyles.fieldText,
            textInputAction:
                next != null ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (next != null) {
                FocusScope.of(context).requestFocus(next);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AddKarigarStyles.fieldHint,
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: maxLines > 1 ? 14 : 0),
            ),
          )),
          if (suffix != null) ...[suffix, const SizedBox(width: 12)],
        ]),
      ),
      if (hasError) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.error_rounded,
              color: AddKarigarColors.error, size: 14),
          const SizedBox(width: 5),
          Text(error,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AddKarigarColors.error,
                  fontWeight: FontWeight.w600)),
        ]),
      ],
    ]);
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AddKarigarStyles.fieldLabel),
      const SizedBox(height: 8),
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: AddKarigarColors.brandGold.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AddKarigarColors.brandGold.withValues(alpha: 0.4),
              width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AddKarigarColors.brandGold.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: const Border(
                  right: BorderSide(color: AddKarigarColors.inputBorder)),
            ),
            child: Icon(icon, size: 20, color: AddKarigarColors.brandGold),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.black54, size: 22),
                style: AddKarigarStyles.fieldText,
                items: items
                    .map((item) => DropdownMenuItem<T>(
                          value: item,
                          child: Text(itemLabel(item),
                              style: AddKarigarStyles.fieldText),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          )),
        ]),
      ),
    ]);
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// IMAGE SOURCE SHEET
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Select Photo Source',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        const SizedBox(height: 16),
        _btn(context, Icons.camera_alt_rounded, 'Camera', ImageSource.camera),
        _btn(context, Icons.photo_library_rounded, 'Gallery',
            ImageSource.gallery),
        const SizedBox(height: 12),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54))),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _btn(BuildContext ctx, IconData icon, String label, ImageSource src) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0x18D4AF37),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 22)),
      title: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
      onTap: () => Navigator.pop(ctx, src),
    );
  }
}
