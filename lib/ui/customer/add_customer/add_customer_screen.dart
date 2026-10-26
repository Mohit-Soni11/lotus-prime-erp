import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../logic/customer/add_customer_logic.dart';
import '../../../models/customer/customer_enums/add_customer_enums.dart';
import '../../../models/customer/add_customer/add_customer_form_model.dart';
import '../../../theme/customer/add_customer/add_customer_theme.dart';
import 'add_customer_app_bar.dart';
import 'add_customer_components.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'add_customer_form_fields.dart';
part 'add_customer_identity_sections.dart';
part 'add_customer_contact_sections.dart';
part 'add_customer_form_initialization.dart';
part 'add_customer_account_sections.dart';
part 'add_customer_preferences_sections.dart';

// =============================================================================
// MASTER SCREEN
// =============================================================================

class AddCustomerScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSaved;
  final int? customerId;
  final String? initialName;
  final String? initialMobile;
  final String? initialAddress;

  const AddCustomerScreen({
    super.key,
    this.onBack,
    this.onSaved,
    this.customerId,
    this.initialName,
    this.initialMobile,
    this.initialAddress,
  });

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
  final _stateProvinceCtrl = TextEditingController();
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
  bool _isLoadingInitialData = false;
  String? _initialLoadError;

  bool get _isEditMode => widget.customerId != null;

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
    _logic = AddCustomerLogic(customerId: widget.customerId);
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
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    if (!_isEditMode) {
      _memberIdCtrl.text = _logic.generateMembershipId();
      _applyInitialValues();
      return;
    }

    setState(() => _isLoadingInitialData = true);
    final form = await _logic.loadCustomerForEdit();
    if (!mounted) return;

    if (form == null) {
      setState(() {
        _isLoadingInitialData = false;
        _initialLoadError = 'Customer details could not be loaded.';
      });
      return;
    }

    _populateControllers(form);
    setState(() {
      _isLoadingInitialData = false;
      _initialLoadError = null;
    });
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
      _stateProvinceCtrl,
      _cityCtrl,
      _pincodeCtrl,
      _openBalCtrl,
      _creditLimCtrl,
      _memberIdCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
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
    ]) {
      f.dispose();
    }
    super.dispose();
  }
  // ACTIONS

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomerImageSourceSheet(),
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
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
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
      _showFeedback(
        _isEditMode
            ? AddCustomerStrings.updateSuccessMsg
            : AddCustomerStrings.successMsg,
        isSuccess: true,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final onSaved = widget.onSaved;
      if (onSaved != null) {
        onSaved();
      } else {
        widget.onBack?.call();
      }
    } else if (_logic.saveState == SaveState.duplicate) {
      _showFeedback(AddCustomerStrings.duplicateMsg, isSuccess: false);
    } else {
      _showFeedback(AddCustomerStrings.errorMsg, isSuccess: false);
    }
  }

  void _handleClear() {
    if (_isEditMode) {
      _logic.resetForm();
      _populateControllers(_logic.form);
      setState(() {});
      FocusScope.of(context).unfocus();
      return;
    }

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
      _stateProvinceCtrl,
      _cityCtrl,
      _pincodeCtrl,
      _notesCtrl,
    ]) {
      c.clear();
    }
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

  void _showFeedback(String msg, {required bool isSuccess}) {
    AppFeedback.show(
      context,
      type: isSuccess ? AppFeedbackType.success : AppFeedbackType.error,
      message: msg,
      duration: const Duration(seconds: 3),
    );
  }

  void _changeCountry(String? country) {
    setState(() {
      _selectedCountry = country;
      _selectedState = null;
      _stateProvinceCtrl.clear();
    });
    if (country != null) _logic.setCountry(country);
  }

  void _changeIndianState(IndiaState state) {
    setState(() => _selectedState = state.label);
    _logic.setState_(state.label);
  }
  // BUILD

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AddCustomerColors.bodyBg,
        appBar: AddCustomerAppBar(
          onBack: widget.onBack ?? () => Navigator.maybePop(context),
          title: _isEditMode
              ? AddCustomerStrings.editAppBarTitle
              : AddCustomerStrings.appBarTitle,
        ),
        body: SafeArea(
          child: _isLoadingInitialData
              ? const Center(child: CircularProgressIndicator())
              : _initialLoadError != null
                  ? _buildInitialLoadError()
                  : SingleChildScrollView(
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
                                accent: const Color(0xFF4F46E5),
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
                                accent: const Color(0xFF059669),
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
                                accent: const Color(0xFFD97706),
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
                                accent: const Color(0xFF0284C7),
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
                                accent: const Color(0xFF7C3AED),
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
                                accent: const Color(0xFFDB2777),
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
                                accent: const Color(0xFF475569),
                                stepNumber: 7,
                                child: _buildAdditionalSection(),
                              )),
                          const SizedBox(height: 28),
                          _anim(7, _buildActionButtons()),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _isEditMode
                                  ? AddCustomerStrings.editRequiredNote
                                  : AddCustomerStrings.requiredNote,
                              style: AddCustomerStyles.requiredNote,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
