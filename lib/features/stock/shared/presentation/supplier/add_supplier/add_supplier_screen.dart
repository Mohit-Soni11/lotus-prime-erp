import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/application/add_supplier_logic.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/add_supplier_form_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/theme/stock/supplier/add_supplier/add_supplier_theme.dart';
import 'add_supplier_app_bar.dart';

part 'add_supplier_widgets.dart';
part 'add_supplier_identity_section.dart';
part 'add_supplier_business_section.dart';
part 'add_supplier_contact_section.dart';
part 'add_supplier_address_section.dart';
part 'add_supplier_field_bindings.dart';
part 'add_supplier_actions.dart';

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

  static const int _sectionCount = 6;
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
                const SizedBox(height: 24),
                if (_logic.errorMessage != null) ...[
                  _buildErrorBanner(_logic.errorMessage!),
                  const SizedBox(height: 14),
                ],
                _anim(5, _buildActionButtons()),
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
}
