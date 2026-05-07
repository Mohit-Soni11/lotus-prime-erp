// =============================================================================
// FILE        : add_customer_screen.dart
// MODULE      : Customer → Add New Customer
// LAYER       : UI / Screen
// DESCRIPTION : Full production Add Customer screen.
//               Uses centralized theme files and external AppBar.
//               8 Sections: Photo | Personal | Contact | KYC |
//               Address | Billing | Preferences | Additional
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//import '../../../database/db/app_database.dart';
import '../../../logic/customer/add_customer_logic.dart';
import '../../../models/customer/customer_enums/add_customer_enums.dart';
import '../../../models/customer/add_customer/add_customer_form_model.dart';
import '../../../theme/customer/add_customer/add_customer_theme.dart'; // ✅ Added centralized theme
import 'add_customer_app_bar.dart'; // ✅ Added external AppBar (Adjust path as needed)

// =============================================================================
// MASTER SCREEN
// =============================================================================

class AddCustomerScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSaved;
  const AddCustomerScreen({super.key, this.onBack, this.onSaved});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen>
    with TickerProviderStateMixin {
  late final AddCustomerLogic _logic;
  final _imgPick = ImagePicker();

  static const _sectionCount = 8;
  late final List<AnimationController> _anims;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _altContactCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _idProofNoCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _openBalCtrl = TextEditingController(text: '0');
  final _creditLimCtrl = TextEditingController(text: '0');
  final _memberIdCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _contactFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _whatsappFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _altFocus = FocusNode();
  final _panFocus = FocusNode();
  final _idProofNoFocus = FocusNode();
  final _gstFocus = FocusNode();
  final _addr1Focus = FocusNode();
  final _addr2Focus = FocusNode();
  final _cityFocus = FocusNode();
  final _pincodeFocus = FocusNode();
  final _notesFocus = FocusNode();

  String? _selectedCountry = 'India';
  String? _selectedState;

  static const List<String> _countries = [
    'India',
    'USA',
    'UAE',
    'UK',
    'Canada',
    'Australia',
    'Singapore',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _logic = AddCustomerLogic();
    _logic.addListener(_rebuild);

    _anims = List.generate(
        _sectionCount,
        (i) => AnimationController(
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

    _attachFocusListeners();
    _memberIdCtrl.text = _logic.generateMembershipId();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _attachFocusListeners() {
    void bind(FocusNode fn, ActiveField af) {
      fn.addListener(
          () => _logic.setActiveField(fn.hasFocus ? af : ActiveField.none));
    }

    bind(_firstNameFocus, ActiveField.firstName);
    bind(_lastNameFocus, ActiveField.lastName);
    bind(_companyFocus, ActiveField.companyName);
    bind(_contactFocus, ActiveField.contactPerson);
    bind(_mobileFocus, ActiveField.mobile);
    bind(_whatsappFocus, ActiveField.whatsapp);
    bind(_emailFocus, ActiveField.email);
    bind(_altFocus, ActiveField.alternateContact);
    bind(_panFocus, ActiveField.panNumber);
    bind(_idProofNoFocus, ActiveField.idProofNumber);
    bind(_gstFocus, ActiveField.gstNumber);
    bind(_addr1Focus, ActiveField.addressLine1);
    bind(_addr2Focus, ActiveField.addressLine2);
    bind(_pincodeFocus, ActiveField.pincode);
    bind(_notesFocus, ActiveField.notes);
  }

  @override
  void dispose() {
    _logic
      ..removeListener(_rebuild)
      ..dispose();
    for (final a in _anims) a.dispose();
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _companyCtrl,
      _contactCtrl,
      _mobileCtrl,
      _whatsappCtrl,
      _emailCtrl,
      _altContactCtrl,
      _panCtrl,
      _idProofNoCtrl,
      _gstCtrl,
      _addr1Ctrl,
      _addr2Ctrl,
      _cityCtrl,
      _pincodeCtrl,
      _openBalCtrl,
      _creditLimCtrl,
      _memberIdCtrl,
      _notesCtrl,
    ]) c.dispose();
    for (final f in [
      _firstNameFocus,
      _lastNameFocus,
      _companyFocus,
      _contactFocus,
      _mobileFocus,
      _whatsappFocus,
      _emailFocus,
      _altFocus,
      _panFocus,
      _idProofNoFocus,
      _gstFocus,
      _addr1Focus,
      _addr2Focus,
      _cityFocus,
      _pincodeFocus,
      _notesFocus,
    ]) f.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════════════

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

  Future<void> _pickIdDoc() async {
    final file =
        await _imgPick.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) _logic.setIdProofDocPath(file.path);
  }

  Future<void> _pickDate(BuildContext ctx,
      {required void Function(DateTime) onPicked,
      DateTime? firstDate,
      DateTime? lastDate}) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime(1940),
      lastDate: lastDate ?? DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AddCustomerColors.brandGold,
            onPrimary: Colors.black,
            surface: Colors.white,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final ok = await _logic.saveCustomer();
    if (!mounted) return;
    if (ok) {
      _showSnack(AddCustomerStrings.successMsg, isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      widget.onSaved?.call();
      widget.onBack?.call();
    } else if (_logic.saveState == SaveState.duplicate) {
      _showSnack(AddCustomerStrings.duplicateMsg, isSuccess: false);
    } else {
      _showSnack(AddCustomerStrings.errorMsg, isSuccess: false);
    }
  }

  void _handleClear() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _companyCtrl,
      _contactCtrl,
      _mobileCtrl,
      _emailCtrl,
      _altContactCtrl,
      _panCtrl,
      _idProofNoCtrl,
      _gstCtrl,
      _addr1Ctrl,
      _addr2Ctrl,
      _cityCtrl,
      _pincodeCtrl,
      _notesCtrl,
    ]) c.clear();
    _whatsappCtrl.clear();
    _openBalCtrl.text = '0';
    _creditLimCtrl.text = '0';
    setState(() {
      _selectedCountry = 'India';
      _selectedState = null;
    });
    _logic.resetForm();
    _memberIdCtrl.text = _logic.generateMembershipId();
    FocusScope.of(context).unfocus();
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
      ]),
      backgroundColor:
          isSuccess ? AddCustomerColors.success : AddCustomerColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AddCustomerColors.bodyBg,
        appBar: AddCustomerAppBar(
          // ✅ Replaced hardcoded AppBar with external component
          onBack: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AddCustomerStyles.pagePadding,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _anim(0, _buildPhotoSection()),
                const SizedBox(height: 20),
                _anim(
                    1,
                    _buildSection(
                      icon: AddCustomerIcons.name,
                      title: 'Personal Information',
                      subtitle: 'Identity & entity details',
                      accent:
                          const Color(0xFF4F46E5), // Previously _C.accentPerson
                      stepNumber: 1,
                      child: _buildPersonalSection(),
                    )),
                const SizedBox(height: 16),
                _anim(
                    2,
                    _buildSection(
                      icon: AddCustomerIcons.contactSection,
                      title: AddCustomerStrings.secContact,
                      subtitle: 'Mobile, WhatsApp & email',
                      accent: const Color(
                          0xFF059669), // Previously _C.accentContact
                      stepNumber: 2,
                      child: _buildContactSection(),
                    )),
                const SizedBox(height: 16),
                _anim(
                    3,
                    _buildSection(
                      icon: Icons.verified_user_rounded,
                      title: 'KYC & Compliance',
                      subtitle: 'PAN, ID proof & GST details',
                      accent:
                          const Color(0xFFD97706), // Previously _C.accentKyc
                      stepNumber: 3,
                      child: _buildKycSection(),
                    )),
                const SizedBox(height: 16),
                _anim(
                    4,
                    _buildSection(
                      icon: AddCustomerIcons.locationSection,
                      title: AddCustomerStrings.secLocation,
                      subtitle: 'Delivery & billing address',
                      accent: const Color(
                          0xFF0284C7), // Previously _C.accentAddress
                      stepNumber: 4,
                      child: _buildAddressSection(),
                    )),
                const SizedBox(height: 16),
                _anim(
                    5,
                    _buildSection(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Account & Billing',
                      subtitle: 'Credit limit, tier & membership',
                      accent: const Color(
                          0xFF7C3AED), // Previously _C.accentBilling
                      stepNumber: 5,
                      child: _buildBillingSection(),
                    )),
                const SizedBox(height: 16),
                _anim(
                    6,
                    _buildSection(
                      icon: Icons.favorite_border_rounded,
                      title: 'Preferences & CRM',
                      subtitle: 'Sizes, family & personalization',
                      accent:
                          const Color(0xFFDB2777), // Previously _C.accentPref
                      stepNumber: 6,
                      child: _buildPreferencesSection(),
                    )),
                const SizedBox(height: 16),
                _anim(
                    7,
                    _buildSection(
                      icon: AddCustomerIcons.notes,
                      title: 'Additional Info',
                      subtitle: 'Referral source & internal notes',
                      accent: const Color(
                          0xFF475569), // Previously _C.accentAdditional
                      stepNumber: 7,
                      child: _buildAdditionalSection(),
                    )),
                const SizedBox(height: 28),
                _anim(7, _buildActionButtons()),
                const SizedBox(height: 8),
                Center(
                    child: Text(AddCustomerStrings.requiredNote,
                        style: AddCustomerStyles.requiredNote)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _anim(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  // ════════════════════════════════════════════════════════════════════════
  // SECTION CARD
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required Widget child,
    required int stepNumber,
  }) {
    final lighterAccent = Color.lerp(accent, Colors.white, 0.25)!;
    return Container(
      decoration: AddCustomerStyles.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, lighterAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AddCustomerStyles.cardRadius)),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.white.withOpacity(0.30), width: 1),
              ),
              child: Center(
                  child: Text(
                stepNumber.toString().padLeft(2, '0'),
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
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
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
                      color: Colors.white,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 0.3,
                    )),
              ],
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: child,
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 0: PROFILE PHOTO
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildPhotoSection() {
    final imagePath = _logic.form.profileImagePath;
    final gender = _logic.form.gender;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AddCustomerColors.brandGold.withOpacity(0.14),
            AddCustomerColors.brandGold.withOpacity(0.04)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AddCustomerColors.brandGold.withOpacity(0.30), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AddCustomerColors.brandGold.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
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
                  AddCustomerColors.brandGold,
                  AddCustomerColors.brandGold.withOpacity(0.4),
                  AddCustomerColors.brandGold
                ]),
                boxShadow: [
                  BoxShadow(
                      color: AddCustomerColors.brandGold.withOpacity(0.40),
                      blurRadius: 16,
                      spreadRadius: 2)
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AddCustomerColors.bodyPanelBg),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: imagePath != null
                      ? Image.file(File(imagePath),
                          fit: BoxFit.cover, width: 84, height: 84)
                      : _buildAvatar(gender),
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AddCustomerColors.brandGold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AddCustomerColors.brandGold.withOpacity(0.5),
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
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Photo',
                style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AddCustomerColors.bodyTextMain)),
            const SizedBox(height: 5),
            Text(
              imagePath != null
                  ? '✓ Photo uploaded'
                  : 'Avatar will auto-switch based on gender selection.',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: imagePath != null
                      ? AddCustomerColors.success
                      : AddCustomerColors.bodyTextMuted),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _miniBtn(
                label: imagePath != null ? 'Change Photo' : 'Upload Photo',
                icon: Icons.camera_alt_rounded,
                bg: AddCustomerColors.brandGold,
                fg: Colors.black87,
                onTap: _pickImage,
              ),
              if (imagePath != null) ...[
                const SizedBox(width: 8),
                _miniBtn(
                  label: 'Remove',
                  icon: Icons.delete_outline_rounded,
                  bg: AddCustomerColors.errorBg,
                  fg: AddCustomerColors.error,
                  border: AddCustomerColors.error.withOpacity(0.3),
                  onTap: () => _logic.setProfileImagePath(null),
                ),
              ],
            ]),
          ],
        )),
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
          boxShadow: bg == AddCustomerColors.brandGold
              ? [
                  BoxShadow(
                      color: AddCustomerColors.brandGold.withOpacity(0.30),
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

  Widget _buildAvatar(Gender? gender) {
    final isFemale = gender == Gender.female;
    return Container(
      width: 84,
      height: 84,
      color: isFemale ? const Color(0xFFFFF0F5) : const Color(0xFFF0F4FF),
      child: isFemale
          ? FaIcon(FontAwesomeIcons.solidUser,
              size: 40, color: const Color(0xFFEC4899))
          : Icon(Icons.person_rounded,
              size: 48, color: const Color(0xFF6366F1)),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 1: PERSONAL
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildPersonalSection() {
    final isCorp = _logic.form.isCorporate;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: _EntityChip(
          icon: Icons.person_rounded,
          label: 'Individual',
          subtitle: 'Personal customer',
          isSelected: !isCorp,
          activeColor: const Color(0xFF4F46E5),
          onTap: () => _logic.setEntityType(CustomerEntityType.individual),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _EntityChip(
          icon: Icons.business_rounded,
          label: 'Corporate',
          subtitle: 'Company / B2B',
          isSelected: isCorp,
          activeColor: const Color(0xFFD97706),
          onTap: () => _logic.setEntityType(CustomerEntityType.corporate),
        )),
      ]),
      const SizedBox(height: 20),
      if (isCorp) ...[
        _field(
            label: 'Company Name',
            required: true,
            icon: Icons.business_rounded,
            ctrl: _companyCtrl,
            focus: _companyFocus,
            next: _contactFocus,
            hint: 'Enter company / firm name',
            onChanged: _logic.onCompanyNameChanged,
            capitalization: TextCapitalization.words),
        const SizedBox(height: 14),
        _field(
            label: 'Contact Person Name',
            icon: AddCustomerIcons.name,
            ctrl: _contactCtrl,
            focus: _contactFocus,
            next: _mobileFocus,
            hint: 'Owner / Manager name',
            onChanged: _logic.onContactPersonChanged,
            capitalization: TextCapitalization.words),
      ] else ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _field(
                  label: 'First Name',
                  required: true,
                  icon: AddCustomerIcons.name,
                  ctrl: _firstNameCtrl,
                  focus: _firstNameFocus,
                  next: _lastNameFocus,
                  hint: 'First name',
                  error: _logic.form.firstNameError,
                  onChanged: _logic.onFirstNameChanged,
                  capitalization: TextCapitalization.words)),
          const SizedBox(width: 14),
          Expanded(
              child: _field(
                  label: 'Last Name',
                  icon: Icons.person_rounded,
                  ctrl: _lastNameCtrl,
                  focus: _lastNameFocus,
                  next: _mobileFocus,
                  hint: 'Last name',
                  onChanged: _logic.onLastNameChanged,
                  capitalization: TextCapitalization.words)),
        ]),
      ],
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildDateField(
                label: 'Date of Birth',
                icon: Icons.cake_rounded,
                value: _logic.form.dateOfBirth,
                onTap: () => _pickDate(context,
                    onPicked: _logic.setDateOfBirth,
                    lastDate: DateTime.now()))),
        const SizedBox(width: 14),
        Expanded(
            child: _buildDropdown<Gender>(
                label: 'Gender',
                icon: Icons.people_alt_rounded,
                value: _logic.form.gender,
                items: Gender.values,
                itemLabel: (g) => g.label,
                onChanged: _logic.setGender,
                hint: 'Select gender',
                nullable: true)),
      ]),
      const SizedBox(height: 14),
      _buildDateField(
          label: 'Anniversary Date (Optional)',
          icon: Icons.favorite_rounded,
          value: _logic.form.anniversaryDate,
          onTap: () => _pickDate(context,
              onPicked: _logic.setAnniversaryDate, lastDate: DateTime.now())),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 2: CONTACT
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildContactSection() {
    final sameWa = _logic.form.sameAsWhatsApp;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
        label: AddCustomerStrings.lblMobile,
        required: true,
        icon: AddCustomerIcons.mobile,
        ctrl: _mobileCtrl,
        focus: _mobileFocus,
        hint: AddCustomerStrings.hintMobile,
        error: _logic.form.mobileError,
        onChanged: (v) {
          _logic.onMobileChanged(v);
          if (sameWa) _whatsappCtrl.text = v;
        },
        keyboardType: TextInputType.number,
        maxLength: 10,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        suffix:
            (_logic.form.mobile.length == 10 && _logic.form.mobileError == null)
                ? const Icon(AddCustomerIcons.successIcon,
                    color: AddCustomerColors.success, size: 20)
                : null,
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () {
          _logic.setSameAsWhatsApp(!sameWa);
          if (!sameWa)
            _whatsappCtrl.text = _mobileCtrl.text;
          else
            _whatsappCtrl.clear();
        },
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: sameWa ? const Color(0xFF059669) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: sameWa
                      ? const Color(0xFF059669)
                      : AddCustomerColors.inputBorder,
                  width: 1.5),
            ),
            child: sameWa
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text('Same as WhatsApp',
              style:
                  AddCustomerStyles.fieldLabel.copyWith(color: Colors.black87)),
          const SizedBox(width: 6),
          const FaIcon(FontAwesomeIcons.whatsapp,
              size: 18, color: Color(0xFF25D366)),
        ]),
      ),
      const SizedBox(height: 14),
      _field(
          label: AddCustomerStrings.lblWhatsapp,
          icon: AddCustomerIcons.whatsapp,
          ctrl: _whatsappCtrl,
          focus: _whatsappFocus,
          next: _emailFocus,
          hint: AddCustomerStrings.hintWhatsapp,
          onChanged: _logic.onWhatsappChanged,
          enabled: !sameWa,
          keyboardType: TextInputType.number,
          maxLength: 10,
          formatters: [FilteringTextInputFormatter.digitsOnly]),
      const SizedBox(height: 14),
      _field(
          label: 'Email Address',
          icon: Icons.email_outlined,
          ctrl: _emailCtrl,
          focus: _emailFocus,
          next: _altFocus,
          hint: 'customer@email.com',
          error: _logic.form.emailError,
          onChanged: _logic.onEmailChanged,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 14),
      _field(
          label: 'Alternate Contact No.',
          icon: Icons.phone_outlined,
          ctrl: _altContactCtrl,
          focus: _altFocus,
          hint: 'Secondary number (optional)',
          onChanged: _logic.onAlternateContactChanged,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          formatters: [FilteringTextInputFormatter.digitsOnly]),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 3: KYC
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildKycSection() {
    final isCorp = _logic.form.isCorporate;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
        label: 'PAN Number',
        icon: Icons.credit_card_rounded,
        ctrl: _panCtrl,
        focus: _panFocus,
        next: _idProofNoFocus,
        hint: 'ABCDE1234F',
        error: _logic.form.panError,
        onChanged: (v) {
          _panCtrl.value = TextEditingValue(
            text: v.toUpperCase(),
            selection: TextSelection.collapsed(offset: v.length),
          );
          _logic.onPanChanged(v);
        },
        maxLength: 10,
        formatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(10),
        ],
        suffix:
            (_logic.form.panNumber.length == 10 && _logic.form.panError == null)
                ? const Icon(Icons.verified_rounded,
                    color: AddCustomerColors.success, size: 20)
                : null,
      ),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildDropdown<IdProofType>(
                label: 'ID Proof Type',
                icon: Icons.badge_outlined,
                value: _logic.form.idProofType,
                items: IdProofType.values,
                itemLabel: (t) => t.label,
                onChanged: _logic.setIdProofType,
                hint: 'Select ID type',
                nullable: true)),
        const SizedBox(width: 14),
        Expanded(
            child: _field(
                label: 'ID Proof Number',
                icon: Icons.numbers_rounded,
                ctrl: _idProofNoCtrl,
                focus: _idProofNoFocus,
                hint: 'ID number',
                onChanged: _logic.onIdProofNumberChanged)),
      ]),
      const SizedBox(height: 14),
      _buildUploadButton(
          label: 'Upload ID Document',
          icon: Icons.upload_file_rounded,
          filePath: _logic.form.idProofDocPath,
          onTap: _pickIdDoc,
          onRemove: () => _logic.setIdProofDocPath(null),
          accentColor: const Color(0xFFD97706)),
      const SizedBox(height: 14),
      _field(
          label: isCorp ? 'GST Number' : 'GST Number (Optional)',
          icon: Icons.receipt_long_rounded,
          ctrl: _gstCtrl,
          focus: _gstFocus,
          hint: '22ABCDE1234F1Z5',
          onChanged: (v) {
            _gstCtrl.value = TextEditingValue(
              text: v.toUpperCase(),
              selection: TextSelection.collapsed(offset: v.length),
            );
            _logic.onGstChanged(v);
          },
          maxLength: 15,
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(15),
          ]),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 4: ADDRESS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAddressSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
          label: 'Address Line 1',
          icon: Icons.home_rounded,
          ctrl: _addr1Ctrl,
          focus: _addr1Focus,
          next: _addr2Focus,
          hint: 'House no., Street, Area',
          onChanged: _logic.onAddressLine1Changed,
          capitalization: TextCapitalization.sentences),
      const SizedBox(height: 14),
      _field(
          label: 'Address Line 2 (Optional)',
          icon: Icons.location_on_outlined,
          ctrl: _addr2Ctrl,
          focus: _addr2Focus,
          hint: 'Landmark, Locality',
          onChanged: _logic.onAddressLine2Changed,
          capitalization: TextCapitalization.sentences),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildSimpleDropdown(
                label: 'Country',
                icon: Icons.public_rounded,
                value: _selectedCountry,
                items: _countries,
                onChanged: (v) {
                  setState(() {
                    _selectedCountry = v;
                    _selectedState = null;
                  });
                  if (v != null) _logic.setCountry(v);
                })),
        const SizedBox(width: 14),
        Expanded(
          child: _selectedCountry == 'India'
              ? _buildDropdown<IndiaState>(
                  label: 'State',
                  icon: Icons.map_outlined,
                  value: _selectedState != null
                      ? IndiaState.values.firstWhere(
                          (s) => s.label == _selectedState,
                          orElse: () => IndiaState.jh)
                      : null,
                  items: IndiaState.values,
                  itemLabel: (s) => s.label,
                  onChanged: (s) {
                    if (s != null) {
                      setState(() => _selectedState = s.label);
                      _logic.setState_(s.label);
                    }
                  },
                  hint: 'Select state',
                  nullable: true)
              : _field(
                  label: 'State / Province',
                  icon: Icons.map_outlined,
                  ctrl: TextEditingController(),
                  hint: 'Enter state',
                  onChanged: _logic.setState_),
        ),
      ]),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _field(
                label: AddCustomerStrings.lblCity,
                icon: AddCustomerIcons.city,
                ctrl: _cityCtrl,
                focus: _cityFocus,
                next: _pincodeFocus,
                hint: AddCustomerStrings.hintCity,
                onChanged: _logic.onCityChanged,
                capitalization: TextCapitalization.words)),
        const SizedBox(width: 14),
        Expanded(
            child: _field(
                label: 'Pincode',
                icon: Icons.pin_drop_rounded,
                ctrl: _pincodeCtrl,
                focus: _pincodeFocus,
                hint: '6-digit pincode',
                onChanged: _logic.onPincodeChanged,
                keyboardType: TextInputType.number,
                maxLength: 6,
                formatters: [FilteringTextInputFormatter.digitsOnly])),
      ]),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 5: BILLING
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBillingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _field(
                label: 'Opening Balance',
                icon: Icons.account_balance_rounded,
                ctrl: _openBalCtrl,
                focus: FocusNode(),
                hint: '0.00',
                prefix: '₹',
                onChanged: _logic.onOpeningBalanceChanged,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ])),
        const SizedBox(width: 14),
        Expanded(
            child: _field(
                label: 'Credit Limit (Udhaar)',
                icon: Icons.credit_score_rounded,
                ctrl: _creditLimCtrl,
                focus: FocusNode(),
                hint: '0.00',
                prefix: '₹',
                onChanged: _logic.onCreditLimitChanged,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ])),
      ]),
      const SizedBox(height: 20),
      Text('CUSTOMER TIER / CATEGORY', style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 10),
      Row(
        children: CustomerTier.values.map((t) {
          final isSelected = _logic.form.customerTier == t;
          final isLast = t == CustomerTier.values.last;
          return Expanded(
              child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () => _logic.setCustomerTier(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _tierColor(t).withOpacity(0.12)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          isSelected ? _tierColor(t) : const Color(0xFFE5E7EB),
                      width: isSelected ? 1.5 : 1),
                ),
                child: Column(children: [
                  Icon(_tierIcon(t),
                      color: isSelected ? _tierColor(t) : Colors.black54,
                      size: 18),
                  const SizedBox(height: 4),
                  Text(t.label,
                      style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? _tierColor(t) : Colors.black87)),
                ]),
              ),
            ),
          ));
        }).toList(),
      ),
      const SizedBox(height: 20),
      Text('MEMBERSHIP ID', style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      Container(
        height: 50,
        decoration: BoxDecoration(
          color: AddCustomerColors.brandGoldLight,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AddCustomerColors.brandGoldBorder, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          const Icon(Icons.card_membership_rounded,
              color: AddCustomerColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  _logic.form.membershipId.isEmpty
                      ? 'LTMP-000000-0001'
                      : _logic.form.membershipId,
                  style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB8960C),
                      letterSpacing: 1.2))),
          GestureDetector(
            onTap: () {
              final id = _logic.generateMembershipId();
              _memberIdCtrl.text = id;
            },
            child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: AddCustomerColors.brandGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.refresh_rounded,
                    color: AddCustomerColors.brandGold, size: 16)),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Text('Auto-generated. Tap ↻ to regenerate.',
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54)),
    ]);
  }

  Color _tierColor(CustomerTier t) {
    switch (t) {
      case CustomerTier.regular:
        return const Color(0xFF64748B);
      case CustomerTier.silver:
        return const Color(0xFF94A3B8);
      case CustomerTier.gold:
        return const Color(0xFFB8960C);
      case CustomerTier.vip:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _tierIcon(CustomerTier t) {
    switch (t) {
      case CustomerTier.regular:
        return Icons.person_rounded;
      case CustomerTier.silver:
        return Icons.star_half_rounded;
      case CustomerTier.gold:
        return Icons.star_rounded;
      case CustomerTier.vip:
        return Icons.workspace_premium_rounded;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 6: PREFERENCES
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildPreferencesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildDropdown<RingSize>(
                label: 'Ring Size',
                icon: Icons.radio_button_checked_rounded,
                value: _logic.form.ringSize,
                items: RingSize.values,
                itemLabel: (r) => r.label,
                onChanged: _logic.setRingSize,
                hint: 'Select size',
                nullable: true)),
        const SizedBox(width: 14),
        Expanded(
            child: _buildDropdown<BangleSize>(
                label: 'Bangle Size',
                icon: Icons.circle_outlined,
                value: _logic.form.bangleSize,
                items: BangleSize.values,
                itemLabel: (b) => b.label,
                onChanged: _logic.setBangleSize,
                hint: 'Select size',
                nullable: true)),
      ]),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FAMILY DETAILS', style: AddCustomerStyles.fieldLabel),
          Text('For birthday & anniversary wishes',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54)),
        ]),
        GestureDetector(
          onTap: _logic.addFamilyMember,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDB2777).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFFDB2777).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.add_rounded, color: Color(0xFFDB2777), size: 16),
              const SizedBox(width: 5),
              Text('Add Member',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDB2777))),
            ]),
          ),
        ),
      ]),
      if (_logic.form.familyMembers.isNotEmpty) ...[
        const SizedBox(height: 12),
        ..._logic.form.familyMembers.map((member) => _FamilyMemberRow(
              member: member,
              onUpdate: (u) => _logic.updateFamilyMember(member.id, u),
              onRemove: () => _logic.removeFamilyMember(member.id),
              onPickDate: (cb) => _pickDate(context, onPicked: cb),
            )),
      ],
      if (_logic.form.familyMembers.isEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDB2777).withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: const Color(0xFFDB2777).withOpacity(0.15)),
          ),
          child: Row(children: [
            Icon(Icons.people_outline_rounded,
                color: const Color(0xFFDB2777).withOpacity(0.5), size: 20),
            const SizedBox(width: 12),
            Text('No family members added yet',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFDB2777).withOpacity(0.8))),
          ]),
        ),
      ],
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION 7: ADDITIONAL
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAdditionalSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildDropdown<ReferralSource>(
          label: 'Referral Source',
          icon: Icons.share_rounded,
          value: _logic.form.referralSource,
          items: ReferralSource.values,
          itemLabel: (r) => r.label,
          onChanged: _logic.setReferralSource,
          hint: 'How did customer find us?',
          nullable: true),
      const SizedBox(height: 14),
      Row(children: [
        Text('INTERNAL NOTES / REMARKS', style: AddCustomerStyles.fieldLabel),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF475569).withOpacity(0.10),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('Staff only · Not on bill',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569))),
        ),
      ]),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AddCustomerColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _logic.activeField == ActiveField.notes
                ? AddCustomerColors.brandGold
                : AddCustomerColors.inputBorder,
            width: _logic.activeField == ActiveField.notes ? 2 : 1,
          ),
          boxShadow: _logic.activeField == ActiveField.notes
              ? [
                  BoxShadow(
                      color: AddCustomerColors.brandGold.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        padding: const EdgeInsets.all(14),
        child: TextField(
          controller: _notesCtrl,
          focusNode: _notesFocus,
          maxLines: 4,
          onChanged: _logic.onNotesChanged,
          style: AddCustomerStyles.fieldText,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: AddCustomerStrings.hintNotes,
            hintStyle: AddCustomerStyles.fieldHint,
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    final canSave = _logic.canSave;
    final saving = _logic.isSaving;
    return Row(children: [
      OutlinedButton.icon(
        onPressed: saving ? null : _handleClear,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text(AddCustomerStrings.btnClear),
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
              ? AddCustomerColors.saveBtnBg
              : AddCustomerColors.saveBtnDisabled,
          borderRadius: BorderRadius.circular(12),
          boxShadow: canSave
              ? [
                  BoxShadow(
                      color: AddCustomerColors.saveBtnBg.withOpacity(0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 5))
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
                      Icon(AddCustomerIcons.save,
                          size: 20,
                          color: canSave ? Colors.black87 : Colors.black54),
                      const SizedBox(width: 10),
                      Text(AddCustomerStrings.btnSave,
                          style: AddCustomerStyles.saveBtnText.copyWith(
                              color:
                                  canSave ? Colors.black87 : Colors.black54)),
                    ]),
            ),
          ),
        ),
      )),
    ]);
  }

  // ════════════════════════════════════════════════════════════════════════
  // REUSABLE HELPERS
  // ════════════════════════════════════════════════════════════════════════

  ActiveField _activeFieldFor(FocusNode fn) {
    if (fn == _firstNameFocus) return ActiveField.firstName;
    if (fn == _lastNameFocus) return ActiveField.lastName;
    if (fn == _companyFocus) return ActiveField.companyName;
    if (fn == _contactFocus) return ActiveField.contactPerson;
    if (fn == _mobileFocus) return ActiveField.mobile;
    if (fn == _whatsappFocus) return ActiveField.whatsapp;
    if (fn == _emailFocus) return ActiveField.email;
    if (fn == _altFocus) return ActiveField.alternateContact;
    if (fn == _panFocus) return ActiveField.panNumber;
    if (fn == _idProofNoFocus) return ActiveField.idProofNumber;
    if (fn == _gstFocus) return ActiveField.gstNumber;
    if (fn == _addr1Focus) return ActiveField.addressLine1;
    if (fn == _addr2Focus) return ActiveField.addressLine2;
    if (fn == _pincodeFocus) return ActiveField.pincode;
    if (fn == _notesFocus) return ActiveField.notes;
    return ActiveField.none;
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required void Function(String) onChanged,
    FocusNode? focus,
    FocusNode? next,
    String hint = '',
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
    final isFocused =
        focus != null && _logic.activeField == _activeFieldFor(focus);
    final hasError = error != null;
    final hasValue = ctrl.text.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(
                  color: AddCustomerColors.error,
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
              ? (isFocused
                  ? AddCustomerColors.inputBgFocus
                  : AddCustomerColors.inputBg)
              : const Color(0xFFF3F2EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError
                ? AddCustomerColors.error
                : isFocused
                    ? AddCustomerColors.inputBorderFocus
                    : hasValue
                        ? Colors.black54
                        : AddCustomerColors.inputBorder,
            width: isFocused || hasValue ? 1.5 : 1,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                      color: AddCustomerColors.brandGold.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : hasError
                  ? [
                      BoxShadow(
                          color: AddCustomerColors.error.withOpacity(0.08),
                          blurRadius: 6)
                    ]
                  : [],
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: maxLines > 1 ? 54 : double.infinity,
            decoration: BoxDecoration(
              color: isFocused
                  ? AddCustomerColors.brandGold.withOpacity(0.12)
                  : hasError
                      ? AddCustomerColors.error.withOpacity(0.08)
                      : hasValue
                          ? Colors.black.withOpacity(0.03)
                          : const Color(0xFFF0EDE8),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: Border(
                  right: BorderSide(
                      color: isFocused
                          ? AddCustomerColors.brandGold.withOpacity(0.3)
                          : AddCustomerColors.inputBorder,
                      width: 1)),
            ),
            child: Center(
                child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon,
                  key: ValueKey('$isFocused$hasError'),
                  size: 20,
                  color: isFocused
                      ? AddCustomerColors.brandGold
                      : hasError
                          ? AddCustomerColors.error
                          : Colors.black87),
            )),
          ),
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(prefix,
                  style: AddCustomerStyles.fieldText.copyWith(
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
            style: AddCustomerStyles.fieldText,
            textInputAction:
                next != null ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (next != null)
                FocusScope.of(context).requestFocus(next);
              else
                FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AddCustomerStyles.fieldHint,
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
          const Icon(AddCustomerIcons.errorIcon,
              color: AddCustomerColors.error, size: 14),
          const SizedBox(width: 5),
          Text(error,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AddCustomerColors.error,
                  fontWeight: FontWeight.w600)),
        ]),
      ],
    ]);
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final fmt = value != null ? DateFormat('dd MMM yyyy').format(value) : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            color: fmt != null
                ? AddCustomerColors.brandGold.withOpacity(0.05)
                : AddCustomerColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: fmt != null
                    ? AddCustomerColors.brandGold.withOpacity(0.4)
                    : AddCustomerColors.inputBorder,
                width: fmt != null ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: fmt != null
                    ? AddCustomerColors.brandGold.withOpacity(0.10)
                    : const Color(0xFFF0EDE8),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11)),
                border: Border(
                    right: BorderSide(color: AddCustomerColors.inputBorder)),
              ),
              child: Icon(icon,
                  size: 20,
                  color: fmt != null
                      ? AddCustomerColors.brandGold
                      : Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(fmt ?? 'Select date',
                    style: fmt != null
                        ? AddCustomerStyles.fieldText
                        : AddCustomerStyles.fieldHint)),
            if (fmt != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AddCustomerColors.successBg,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('Set',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AddCustomerColors.success)),
                ),
              )
            else
              Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(Icons.calendar_month_rounded,
                      size: 20, color: Colors.black87)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required String hint,
    bool nullable = false,
  }) {
    final hasValue = value != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: hasValue
              ? AddCustomerColors.brandGold.withOpacity(0.04)
              : AddCustomerColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? AddCustomerColors.brandGold.withOpacity(0.4)
                  : AddCustomerColors.inputBorder,
              width: hasValue ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: hasValue
                  ? AddCustomerColors.brandGold.withOpacity(0.10)
                  : const Color(0xFFF0EDE8),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: Border(
                  right: BorderSide(color: AddCustomerColors.inputBorder)),
            ),
            child: Icon(icon,
                size: 20,
                color: hasValue ? AddCustomerColors.brandGold : Colors.black87),
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
                style: AddCustomerStyles.fieldText,
                hint: Text(hint, style: AddCustomerStyles.fieldHint),
                items: [
                  if (nullable)
                    DropdownMenuItem<T>(
                        value: null,
                        child: Text(hint, style: AddCustomerStyles.fieldHint)),
                  ...items.map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item),
                          style: AddCustomerStyles.fieldText))),
                ],
                onChanged: onChanged,
              ),
            ),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildSimpleDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final hasValue = value != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: hasValue
              ? AddCustomerColors.brandGold.withOpacity(0.04)
              : AddCustomerColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? AddCustomerColors.brandGold.withOpacity(0.4)
                  : AddCustomerColors.inputBorder,
              width: hasValue ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: hasValue
                  ? AddCustomerColors.brandGold.withOpacity(0.10)
                  : const Color(0xFFF0EDE8),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11)),
              border: Border(
                  right: BorderSide(color: AddCustomerColors.inputBorder)),
            ),
            child: Icon(icon,
                size: 20,
                color: hasValue ? AddCustomerColors.brandGold : Colors.black87),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.black54, size: 22),
                style: AddCustomerStyles.fieldText,
                items: items
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: AddCustomerStyles.fieldText)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildUploadButton({
    required String label,
    required IconData icon,
    required String? filePath,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required Color accentColor,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: filePath != null
                ? accentColor.withOpacity(0.05)
                : AddCustomerColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: filePath != null
                    ? accentColor.withOpacity(0.4)
                    : AddCustomerColors.inputBorder,
                width: filePath != null ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: filePath != null
                    ? accentColor.withOpacity(0.10)
                    : const Color(0xFFF0EDE8),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11)),
                border: Border(
                    right: BorderSide(color: AddCustomerColors.inputBorder)),
              ),
              child: Icon(filePath != null ? Icons.file_present_rounded : icon,
                  size: 20,
                  color: filePath != null ? accentColor : Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    filePath != null
                        ? filePath.split('/').last
                        : 'Tap to upload document',
                    style: filePath != null
                        ? AddCustomerStyles.fieldText
                            .copyWith(color: accentColor)
                        : AddCustomerStyles.fieldHint,
                    overflow: TextOverflow.ellipsis)),
            if (filePath != null)
              GestureDetector(
                  onTap: onRemove,
                  child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: const Icon(Icons.close_rounded,
                          color: AddCustomerColors.error, size: 20))),
            if (filePath == null)
              Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: const Icon(Icons.upload_rounded,
                      color: Colors.black87, size: 20)),
          ]),
        ),
      ),
    ]);
  }
}

// =============================================================================
// ENTITY CHIP
// =============================================================================

class _EntityChip extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _EntityChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.08)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: activeColor.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.12)
                  : const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 18, color: isSelected ? activeColor : Colors.black54),
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
                        color: isSelected ? activeColor : Colors.black87)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54)),
              ])),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: activeColor, size: 18),
        ]),
      ),
    );
  }
}

// =============================================================================
// FAMILY MEMBER ROW
// =============================================================================

class _FamilyMemberRow extends StatefulWidget {
  final FamilyMember member;
  final void Function(FamilyMember) onUpdate;
  final VoidCallback onRemove;
  final Future<void> Function(void Function(DateTime)) onPickDate;

  const _FamilyMemberRow({
    required this.member,
    required this.onUpdate,
    required this.onRemove,
    required this.onPickDate,
  });

  @override
  State<_FamilyMemberRow> createState() => _FamilyMemberRowState();
}

class _FamilyMemberRowState extends State<_FamilyMemberRow> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dob = widget.member.dateOfBirth;
    final dobStr = dob != null ? DateFormat('dd/MM/yyyy').format(dob) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDB2777).withOpacity(0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2DDD6))),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _nameCtrl,
              onChanged: (v) =>
                  widget.onUpdate(widget.member.copyWith(name: v)),
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  hintText: 'Member name',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38),
                  border: InputBorder.none,
                  isDense: true),
            ),
          )),
          const SizedBox(width: 8),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2DDD6))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FamilyRelation>(
                value: widget.member.relation,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Colors.black54),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                items: FamilyRelation.values
                    .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (r) {
                  if (r != null)
                    widget.onUpdate(widget.member.copyWith(relation: r));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onRemove,
            child: Container(
                width: 36,
                height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFFDC2626), size: 18)),
          ),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => widget.onPickDate(
              (d) => widget.onUpdate(widget.member.copyWith(dateOfBirth: d))),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2DDD6))),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(Icons.cake_rounded,
                  size: 16,
                  color:
                      dob != null ? const Color(0xFFDB2777) : Colors.black54),
              const SizedBox(width: 8),
              Text(
                dobStr ?? 'Date of Birth (optional)',
                style: dob != null
                    ? GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDB2777))
                    : GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// IMAGE SOURCE SHEET
// =============================================================================

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
