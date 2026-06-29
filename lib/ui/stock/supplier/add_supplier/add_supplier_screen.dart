import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/stock/add_supplier_logic.dart';
import '../../../../models/stock/supplier_model/add_supplier_form_model.dart';
import '../../../../models/stock/supplier_model/supplier_enums.dart';
import '../../../../models/stock/supplier_model/supplier_model.dart';
import '../../../../theme/stock/supplier/add_supplier/add_supplier_theme.dart';
import 'add_supplier_app_bar.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class AddSupplierScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSaved;
  final SupplierModel? existingSupplier;

  const AddSupplierScreen({
    super.key,
    this.onBack,
    this.onSaved,
    this.existingSupplier,
  });

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen>
    with TickerProviderStateMixin {
  late final AddSupplierLogic _logic;

  static const int _sectionCount = 7;
  late final List<AnimationController> _anims;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  final _businessNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _altContactCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _openingBalCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  final _businessNameFocus = FocusNode();
  final _contactPersonFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _whatsappFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _altContactFocus = FocusNode();
  final _panFocus = FocusNode();
  final _gstFocus = FocusNode();
  final _address1Focus = FocusNode();
  final _address2Focus = FocusNode();
  final _stateFocus = FocusNode();
  final _pincodeFocus = FocusNode();
  final _openingBalFocus = FocusNode();
  final _notesFocus = FocusNode();

  static const List<String> _countries = [
    'India',
    'UAE',
    'Singapore',
    'USA',
    'UK',
    'Canada',
    'Australia',
    'Other',
  ];

  static const List<String> _indiaStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _logic = AddSupplierLogic(existing: widget.existingSupplier)
      ..addListener(_rebuild);
    _syncControllersFromForm();
    _attachFocusListeners();

    _anims = List.generate(
      _sectionCount,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 460),
      ),
    );
    _fades = _anims
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        )
        .toList();
    _slides = _anims
        .map(
          (controller) => Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
          ),
        )
        .toList();

    for (var i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 50 + i * 75), () {
        if (mounted) _anims[i].forward();
      });
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _attachFocusListeners() {
    void bind(FocusNode node, SupplierActiveField field) {
      node.addListener(
        () => _logic.setActiveField(
          node.hasFocus ? field : SupplierActiveField.none,
        ),
      );
    }

    bind(_businessNameFocus, SupplierActiveField.businessName);
    bind(_contactPersonFocus, SupplierActiveField.contactPerson);
    bind(_mobileFocus, SupplierActiveField.mobile);
    bind(_whatsappFocus, SupplierActiveField.whatsapp);
    bind(_emailFocus, SupplierActiveField.email);
    bind(_altContactFocus, SupplierActiveField.alternateContact);
    bind(_panFocus, SupplierActiveField.panNumber);
    bind(_gstFocus, SupplierActiveField.gstNumber);
    bind(_address1Focus, SupplierActiveField.addressLine1);
    bind(_address2Focus, SupplierActiveField.addressLine2);
    bind(_stateFocus, SupplierActiveField.state);
    bind(_pincodeFocus, SupplierActiveField.pincode);
    bind(_openingBalFocus, SupplierActiveField.openingBalance);
    bind(_notesFocus, SupplierActiveField.notes);
  }

  void _syncControllersFromForm() {
    final form = _logic.form;
    _businessNameCtrl.text = form.businessName;
    _contactPersonCtrl.text = form.contactPersonName;
    _mobileCtrl.text = form.mobile;
    _whatsappCtrl.text = form.whatsapp;
    _emailCtrl.text = form.email;
    _altContactCtrl.text = form.alternateContact;
    _panCtrl.text = form.panNumber;
    _gstCtrl.text = form.gstNumber;
    _address1Ctrl.text = form.addressLine1;
    _address2Ctrl.text = form.addressLine2;
    _stateCtrl.text = form.state;
    _pincodeCtrl.text = form.pincode;
    _openingBalCtrl.text = form.openingBalance.toStringAsFixed(2);
    _notesCtrl.text = form.notes;
  }

  @override
  void dispose() {
    _logic
      ..removeListener(_rebuild)
      ..dispose();
    for (final controller in _anims) {
      controller.dispose();
    }
    for (final controller in [
      _businessNameCtrl,
      _contactPersonCtrl,
      _mobileCtrl,
      _whatsappCtrl,
      _emailCtrl,
      _altContactCtrl,
      _panCtrl,
      _gstCtrl,
      _address1Ctrl,
      _address2Ctrl,
      _stateCtrl,
      _pincodeCtrl,
      _openingBalCtrl,
      _notesCtrl,
    ]) {
      controller.dispose();
    }
    for (final focus in [
      _businessNameFocus,
      _contactPersonFocus,
      _mobileFocus,
      _whatsappFocus,
      _emailFocus,
      _altContactFocus,
      _panFocus,
      _gstFocus,
      _address1Focus,
      _address2Focus,
      _stateFocus,
      _pincodeFocus,
      _openingBalFocus,
      _notesFocus,
    ]) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = _logic.form;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AddSupplierColors.bodyBg,
        appBar: AddSupplierAppBar(
          onBack: widget.onBack ?? () => Navigator.maybePop(context),
          logic: _logic,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AddSupplierStyles.pagePadding,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _anim(0, _buildIdentitySection(form)),
                const SizedBox(height: 20),
                _anim(
                  1,
                  _buildSection(
                    icon: AddSupplierIcons.sectionBasic,
                    title: AddSupplierStrings.secBasic,
                    subtitle: AddSupplierStrings.secBasicSub,
                    accent: AddSupplierColors.accentBusiness,
                    stepNumber: 1,
                    child: _buildBusinessSection(form),
                  ),
                ),
                const SizedBox(height: 16),
                _anim(
                  2,
                  _buildSection(
                    icon: AddSupplierIcons.sectionContact,
                    title: AddSupplierStrings.secContact,
                    subtitle: AddSupplierStrings.secContactSub,
                    accent: AddSupplierColors.accentContact,
                    stepNumber: 2,
                    child: _buildContactSection(form),
                  ),
                ),
                const SizedBox(height: 16),
                _anim(
                  3,
                  _buildSection(
                    icon: AddSupplierIcons.sectionKyc,
                    title: AddSupplierStrings.secKyc,
                    subtitle: AddSupplierStrings.secKycSub,
                    accent: AddSupplierColors.accentKyc,
                    stepNumber: 3,
                    child: _buildKycSection(form),
                  ),
                ),
                const SizedBox(height: 16),
                _anim(
                  4,
                  _buildSection(
                    icon: AddSupplierIcons.sectionAddress,
                    title: AddSupplierStrings.secAddress,
                    subtitle: AddSupplierStrings.secAddressSub,
                    accent: AddSupplierColors.accentAddress,
                    stepNumber: 4,
                    child: _buildAddressSection(form),
                  ),
                ),
                const SizedBox(height: 16),
                _anim(
                  5,
                  _buildSection(
                    icon: AddSupplierIcons.sectionFinance,
                    title: AddSupplierStrings.secFinance,
                    subtitle: AddSupplierStrings.secFinanceSub,
                    accent: AddSupplierColors.accentFinance,
                    stepNumber: 5,
                    child: _buildFinanceSection(form),
                  ),
                ),
                const SizedBox(height: 24),
                if (_logic.errorMessage != null) ...[
                  _buildErrorBanner(_logic.errorMessage!),
                  const SizedBox(height: 14),
                ],
                _anim(6, _buildActionButtons()),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AddSupplierStrings.requiredNote,
                    style: AddSupplierStyles.requiredNote,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _anim(int index, Widget child) => FadeTransition(
        opacity: _fades[index],
        child: SlideTransition(position: _slides[index], child: child),
      );

  Widget _buildIdentitySection(AddSupplierFormModel form) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AddSupplierStyles.heroDecoration,
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  AddSupplierColors.brandGold,
                  AddSupplierColors.goldGradientStart,
                  AddSupplierColors.brandGold,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AddSupplierColors.brandGold.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AddSupplierColors.bodyPanelBg,
              ),
              child: Text(
                form.avatarInitials,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AddSupplierColors.brandGold,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AddSupplierColors.bodyTextMain,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${form.supplierType.label} | ${form.mobile.isEmpty ? 'Mobile pending' : form.mobile}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AddSupplierColors.bodyTextMuted,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: AddSupplierIcons.supplierType,
                      label: form.supplierType.label,
                      color: AddSupplierColors.accentBusiness,
                    ),
                    _InfoPill(
                      icon: AddSupplierIcons.openingBal,
                      label:
                          'Opening Rs ${form.openingBalance.toStringAsFixed(2)}',
                      color: AddSupplierColors.accentFinance,
                    ),
                    _InfoPill(
                      icon: AddSupplierIcons.country,
                      label: form.country,
                      color: AddSupplierColors.accentAddress,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 260, child: _buildTypeChips(form)),
        ],
      ),
    );
  }

  Widget _buildTypeChips(AddSupplierFormModel form) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: SupplierType.values.map((type) {
        final selected = form.supplierType == type;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _logic.setSupplierType(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AddSupplierColors.brandGold
                  : AddSupplierColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AddSupplierColors.brandGold
                    : AddSupplierColors.bodyBorder,
              ),
            ),
            child: Text(
              type.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.black : AddSupplierColors.bodyTextMain,
                letterSpacing: 0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required int stepNumber,
    required Widget child,
  }) {
    final lighterAccent = Color.lerp(accent, Colors.white, 0.24)!;
    return Container(
      decoration: AddSupplierStyles.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, lighterAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AddSupplierStyles.cardRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    stepNumber.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection(AddSupplierFormModel form) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblBusinessName,
                hint: AddSupplierStrings.hintBusinessName,
                ctrl: _businessNameCtrl,
                focus: _businessNameFocus,
                icon: AddSupplierIcons.businessName,
                errorText: form.businessNameError,
                onChanged: _logic.onBusinessNameChanged,
                textCap: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblContactPerson,
                hint: AddSupplierStrings.hintContactPerson,
                ctrl: _contactPersonCtrl,
                focus: _contactPersonFocus,
                icon: AddSupplierIcons.contactPerson,
                onChanged: _logic.onContactPersonChanged,
                textCap: TextCapitalization.words,
              ),
            ),
          ],
        ),
        _buildSupplierTypeDropdown(form),
      ],
    );
  }

  Widget _buildContactSection(AddSupplierFormModel form) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblMobile,
                hint: AddSupplierStrings.hintMobile,
                ctrl: _mobileCtrl,
                focus: _mobileFocus,
                icon: AddSupplierIcons.mobile,
                errorText: form.mobileError,
                onChanged: (value) {
                  _logic.onMobileChanged(value);
                  if (_logic.form.sameAsWhatsApp) {
                    _whatsappCtrl.value = TextEditingValue(
                      text: value,
                      selection: TextSelection.collapsed(offset: value.length),
                    );
                  }
                },
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblWhatsapp,
                hint: AddSupplierStrings.hintWhatsapp,
                ctrl: _whatsappCtrl,
                focus: _whatsappFocus,
                icon: AddSupplierIcons.whatsapp,
                errorText: form.whatsappError,
                onChanged: _logic.onWhatsappChanged,
                enabled: !form.sameAsWhatsApp,
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildCheckboxLine(
            value: form.sameAsWhatsApp,
            label: 'Use mobile number as WhatsApp',
            onChanged: (value) {
              _logic.setSameAsWhatsApp(value);
              _whatsappCtrl.text = value ? _mobileCtrl.text : '';
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblEmail,
                hint: AddSupplierStrings.hintEmail,
                ctrl: _emailCtrl,
                focus: _emailFocus,
                icon: AddSupplierIcons.email,
                errorText: form.emailError,
                onChanged: _logic.onEmailChanged,
                keyboard: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblAltContact,
                hint: AddSupplierStrings.hintAltContact,
                ctrl: _altContactCtrl,
                focus: _altContactFocus,
                icon: AddSupplierIcons.altContact,
                onChanged: _logic.onAlternateContactChanged,
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKycSection(AddSupplierFormModel form) {
    return Row(
      children: [
        Expanded(
          child: _buildField(
            label: AddSupplierStrings.lblGst,
            hint: AddSupplierStrings.hintGst,
            ctrl: _gstCtrl,
            focus: _gstFocus,
            icon: AddSupplierIcons.gst,
            errorText: form.gstError,
            onChanged: _logic.onGstChanged,
            textCap: TextCapitalization.characters,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(15),
              _UpperCaseTextFormatter(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildField(
            label: AddSupplierStrings.lblPan,
            hint: AddSupplierStrings.hintPan,
            ctrl: _panCtrl,
            focus: _panFocus,
            icon: AddSupplierIcons.pan,
            errorText: form.panError,
            onChanged: _logic.onPanChanged,
            textCap: TextCapitalization.characters,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(10),
              _UpperCaseTextFormatter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(AddSupplierFormModel form) {
    final isIndia = form.country == 'India';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown<String>(
                label: AddSupplierStrings.lblCountry,
                icon: AddSupplierIcons.country,
                value:
                    _countries.contains(form.country) ? form.country : 'Other',
                items: _countries,
                itemLabel: (country) => country,
                onChanged: _logic.setCountry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isIndia
                  ? _buildDropdown<String>(
                      label: AddSupplierStrings.lblState,
                      icon: AddSupplierIcons.state,
                      value:
                          _indiaStates.contains(form.state) ? form.state : null,
                      items: _indiaStates,
                      itemLabel: (state) => state,
                      onChanged: _logic.setStateName,
                    )
                  : _buildField(
                      label: AddSupplierStrings.lblState,
                      hint: AddSupplierStrings.hintState,
                      ctrl: _stateCtrl,
                      focus: _stateFocus,
                      icon: AddSupplierIcons.state,
                      onChanged: _logic.setStateName,
                      textCap: TextCapitalization.words,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblPincode,
                hint: AddSupplierStrings.hintPincode,
                ctrl: _pincodeCtrl,
                focus: _pincodeFocus,
                icon: AddSupplierIcons.pincode,
                errorText: form.pincodeError,
                onChanged: _logic.onPincodeChanged,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblAddress1,
                hint: AddSupplierStrings.hintAddress1,
                ctrl: _address1Ctrl,
                focus: _address1Focus,
                icon: AddSupplierIcons.address,
                onChanged: _logic.onAddressLine1Changed,
                textCap: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblAddress2,
                hint: AddSupplierStrings.hintAddress2,
                ctrl: _address2Ctrl,
                focus: _address2Focus,
                icon: AddSupplierIcons.address,
                onChanged: _logic.onAddressLine2Changed,
                textCap: TextCapitalization.words,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceSection(AddSupplierFormModel form) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: _buildField(
            label: AddSupplierStrings.lblOpeningBal,
            hint: AddSupplierStrings.hintOpeningBal,
            ctrl: _openingBalCtrl,
            focus: _openingBalFocus,
            icon: AddSupplierIcons.openingBal,
            errorText: form.openingBalanceError,
            onChanged: _logic.onOpeningBalanceChanged,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildField(
            label: AddSupplierStrings.lblNotes,
            hint: AddSupplierStrings.hintNotes,
            ctrl: _notesCtrl,
            focus: _notesFocus,
            icon: AddSupplierIcons.notes,
            onChanged: _logic.onNotesChanged,
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required FocusNode focus,
    required IconData icon,
    required ValueChanged<String> onChanged,
    String? errorText,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization textCap = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: AddSupplierStyles.fieldGap,
      child: TextFormField(
        controller: ctrl,
        focusNode: focus,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType: keyboard,
        textCapitalization: textCap,
        inputFormatters: formatters,
        maxLength: maxLength,
        maxLines: maxLines,
        style: AddSupplierStyles.fieldInput,
        decoration: AddSupplierStyles.fieldDecoration(
          label: label,
          hint: hint,
          prefix: Icon(icon, color: AddSupplierColors.brandGold, size: 20),
        ).copyWith(errorText: errorText),
      ),
    );
  }

  Widget _buildSupplierTypeDropdown(AddSupplierFormModel form) {
    return _buildDropdown<SupplierType>(
      label: AddSupplierStrings.lblSupplierType,
      icon: AddSupplierIcons.supplierType,
      value: form.supplierType,
      items: SupplierType.values,
      itemLabel: (type) => type.label,
      onChanged: _logic.setSupplierType,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: AddSupplierStyles.fieldGap,
      child: Container(
        height: AddSupplierStyles.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AddSupplierColors.inputBg,
          borderRadius: BorderRadius.circular(AddSupplierStyles.inputRadius),
          border: Border.all(color: AddSupplierColors.inputBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AddSupplierColors.brandGold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  hint: Text(label, style: AddSupplierStyles.fieldHint),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: AddSupplierStyles.fieldInput,
                  items: items
                      .map(
                        (item) => DropdownMenuItem<T>(
                          value: item,
                          child: Text(itemLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (selected) {
                    if (selected != null) onChanged(selected);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxLine({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            activeColor: AddSupplierColors.brandGold,
            checkColor: Colors.black,
            onChanged: (checked) => onChanged(checked ?? false),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AddSupplierColors.bodyTextMuted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AddSupplierColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AddSupplierColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            AddSupplierIcons.errorIcon,
            color: AddSupplierColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AddSupplierColors.error,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!_logic.isEditMode) ...[
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _logic.isSaving ? null : _handleClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AddSupplierColors.bodyTextMain,
                  side: const BorderSide(color: AddSupplierColors.bodyBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(AddSupplierIcons.clear, size: 20),
                label: Text(
                  AddSupplierStrings.btnClear,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _logic.canSave ? _handleSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AddSupplierColors.saveBtnBg,
                disabledBackgroundColor: AddSupplierColors.saveBtnDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _logic.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black54,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      AddSupplierIcons.save,
                      color: Colors.black87,
                      size: 22,
                    ),
              label: Text(
                _logic.isSaving
                    ? AddSupplierStrings.btnSaving
                    : _logic.isEditMode
                        ? AddSupplierStrings.btnSaveEdit
                        : AddSupplierStrings.btnSaveAdd,
                style: AddSupplierStyles.saveButtonText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final success = await _logic.save();
    if (!mounted) return;

    if (success) {
      _showFeedback(_logic.successMessage ?? 'Supplier saved', isSuccess: true);
      widget.onSaved?.call();
    } else {
      _showFeedback('Please check highlighted fields', isSuccess: false);
    }
  }

  void _handleClear() {
    _logic.resetForm();
    _syncControllersFromForm();
    _showFeedback('Supplier form cleared', isSuccess: true);
  }

  void _showFeedback(String message, {required bool isSuccess}) {
    AppFeedback.show(
      context,
      type: isSuccess ? AppFeedbackType.success : AppFeedbackType.error,
      message: message,
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
