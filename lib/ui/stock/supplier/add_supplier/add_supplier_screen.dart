// -----------------------------------------------------------------------------
// FILE: add_supplier_screen.dart
// MODULE: Supplier → Add / Edit Supplier
// DESCRIPTION: Full production Add/Edit Supplier form.
//              Section-based layout identical to AddCustomerScreen.
//              Dark AppBar + Cream body + Gold accents.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/stock/add_supplier_logic.dart';
import '../../../../models/stock/supplier_model/supplier_model.dart';
import '../../../../models/stock/supplier_model/supplier_enums.dart';
import '../../../../theme/stock/supplier/add_supplier/add_supplier_theme.dart';

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
    with SingleTickerProviderStateMixin {
  late final AddSupplierLogic _logic;
  final _formKey = GlobalKey<FormState>();

  // ── Text Controllers ─────────────────────────────────────────────────────
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _contactPersonCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _whatsappCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _altContactCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _address1Ctrl;
  late final TextEditingController _address2Ctrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _openingBalCtrl;
  late final TextEditingController _notesCtrl;

  late AnimationController _saveAnim;

  @override
  void initState() {
    super.initState();
    _logic = AddSupplierLogic(existing: widget.existingSupplier);
    _saveAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    final s = widget.existingSupplier;
    _businessNameCtrl = TextEditingController(text: s?.businessName ?? '');
    _contactPersonCtrl =
        TextEditingController(text: s?.contactPersonName ?? '');
    _mobileCtrl = TextEditingController(text: s?.mobile ?? '');
    _whatsappCtrl = TextEditingController(text: s?.whatsapp ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _altContactCtrl = TextEditingController(text: s?.alternateContact ?? '');
    _panCtrl = TextEditingController(text: s?.panNumber ?? '');
    _gstCtrl = TextEditingController(text: s?.gstNumber ?? '');
    _address1Ctrl = TextEditingController(text: s?.addressLine1 ?? '');
    _address2Ctrl = TextEditingController(text: s?.addressLine2 ?? '');
    _stateCtrl = TextEditingController(text: s?.state ?? '');
    _pincodeCtrl = TextEditingController(text: s?.pincode ?? '');
    _openingBalCtrl = TextEditingController(
      text: (s?.openingBalance ?? 0) > 0
          ? s!.openingBalance.toStringAsFixed(2)
          : '',
    );
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _logic.dispose();
    _saveAnim.dispose();
    for (final c in [
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
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AddSupplierColors.bodyBg,
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AddSupplierStyles.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  icon: AddSupplierIcons.sectionBasic,
                  title: AddSupplierStrings.secBasic,
                  subtitle: AddSupplierStrings.secBasicSub,
                  children: [
                    _buildField(
                        label: AddSupplierStrings.lblBusinessName,
                        hint: AddSupplierStrings.hintBusinessName,
                        ctrl: _businessNameCtrl,
                        icon: AddSupplierIcons.businessName,
                        onChanged: (v) => _logic.businessName = v,
                        validator: _logic.validateBusinessName,
                        textCap: TextCapitalization.words),
                    _buildField(
                        label: AddSupplierStrings.lblContactPerson,
                        hint: AddSupplierStrings.hintContactPerson,
                        ctrl: _contactPersonCtrl,
                        icon: AddSupplierIcons.contactPerson,
                        onChanged: (v) => _logic.contactPerson = v,
                        textCap: TextCapitalization.words),
                    _buildTypeDropdown(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: AddSupplierIcons.sectionContact,
                  title: AddSupplierStrings.secContact,
                  subtitle: AddSupplierStrings.secContactSub,
                  children: [
                    _buildField(
                        label: AddSupplierStrings.lblMobile,
                        hint: AddSupplierStrings.hintMobile,
                        ctrl: _mobileCtrl,
                        icon: AddSupplierIcons.mobile,
                        onChanged: (v) => _logic.mobile = v,
                        validator: _logic.validateMobile,
                        keyboard: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 10),
                    _buildField(
                        label: AddSupplierStrings.lblWhatsapp,
                        hint: AddSupplierStrings.hintWhatsapp,
                        ctrl: _whatsappCtrl,
                        icon: AddSupplierIcons.whatsapp,
                        onChanged: (v) => _logic.whatsapp = v,
                        keyboard: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 10),
                    _buildField(
                        label: AddSupplierStrings.lblEmail,
                        hint: AddSupplierStrings.hintEmail,
                        ctrl: _emailCtrl,
                        icon: AddSupplierIcons.email,
                        onChanged: (v) => _logic.email = v,
                        keyboard: TextInputType.emailAddress),
                    _buildField(
                        label: AddSupplierStrings.lblAltContact,
                        hint: AddSupplierStrings.hintAltContact,
                        ctrl: _altContactCtrl,
                        icon: AddSupplierIcons.altContact,
                        onChanged: (v) => _logic.alternateContact = v,
                        keyboard: TextInputType.phone),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: AddSupplierIcons.sectionKyc,
                  title: AddSupplierStrings.secKyc,
                  subtitle: AddSupplierStrings.secKycSub,
                  children: [
                    _buildField(
                        label: AddSupplierStrings.lblGst,
                        hint: AddSupplierStrings.hintGst,
                        ctrl: _gstCtrl,
                        icon: AddSupplierIcons.gst,
                        onChanged: (v) => _logic.gstNumber = v,
                        validator: _logic.validateGstNumber,
                        textCap: TextCapitalization.characters,
                        maxLength: 15),
                    _buildField(
                        label: AddSupplierStrings.lblPan,
                        hint: AddSupplierStrings.hintPan,
                        ctrl: _panCtrl,
                        icon: AddSupplierIcons.pan,
                        onChanged: (v) => _logic.panNumber = v,
                        validator: _logic.validatePanNumber,
                        textCap: TextCapitalization.characters,
                        maxLength: 10),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: AddSupplierIcons.sectionAddress,
                  title: AddSupplierStrings.secAddress,
                  subtitle: AddSupplierStrings.secAddressSub,
                  children: [
                    _buildField(
                        label: AddSupplierStrings.lblAddress1,
                        hint: AddSupplierStrings.hintAddress1,
                        ctrl: _address1Ctrl,
                        icon: AddSupplierIcons.address,
                        onChanged: (v) => _logic.addressLine1 = v,
                        textCap: TextCapitalization.words),
                    _buildField(
                        label: AddSupplierStrings.lblAddress2,
                        hint: AddSupplierStrings.hintAddress2,
                        ctrl: _address2Ctrl,
                        icon: AddSupplierIcons.address,
                        onChanged: (v) => _logic.addressLine2 = v,
                        textCap: TextCapitalization.words),
                    Row(
                      children: [
                        Expanded(
                            child: _buildField(
                                label: AddSupplierStrings.lblState,
                                hint: AddSupplierStrings.hintState,
                                ctrl: _stateCtrl,
                                icon: AddSupplierIcons.state,
                                onChanged: (v) => _logic.state = v,
                                textCap: TextCapitalization.words)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildField(
                                label: AddSupplierStrings.lblPincode,
                                hint: AddSupplierStrings.hintPincode,
                                ctrl: _pincodeCtrl,
                                icon: AddSupplierIcons.pincode,
                                onChanged: (v) => _logic.pincode = v,
                                keyboard: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                maxLength: 6)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: AddSupplierIcons.sectionFinance,
                  title: AddSupplierStrings.secFinance,
                  subtitle: AddSupplierStrings.secFinanceSub,
                  children: [
                    _buildField(
                        label: AddSupplierStrings.lblOpeningBal,
                        hint: AddSupplierStrings.hintOpeningBal,
                        ctrl: _openingBalCtrl,
                        icon: AddSupplierIcons.openingBal,
                        onChanged: _logic.setOpeningBalance,
                        keyboard: TextInputType.number),
                    _buildField(
                        label: AddSupplierStrings.lblNotes,
                        hint: AddSupplierStrings.hintNotes,
                        ctrl: _notesCtrl,
                        icon: AddSupplierIcons.notes,
                        onChanged: (v) => _logic.notes = v,
                        maxLines: 3),
                  ],
                ),
                const SizedBox(height: 28),
                if (_logic.errorMessage != null)
                  _buildErrorBanner(_logic.errorMessage!),
                const SizedBox(height: 12),
                _buildSaveButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(AddSupplierStyles.appBarHeight),
      child: Container(
        height: AddSupplierStyles.appBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: AddSupplierColors.shellPanelBg,
          border: Border(
              bottom:
                  BorderSide(color: AddSupplierColors.shellBorder, width: 1)),
          boxShadow: [
            BoxShadow(
                color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4))
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _buildBackButton(),
              const SizedBox(width: 20),
              Container(
                  width: 1, height: 32, color: AddSupplierColors.shellBorder),
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(AddSupplierIcons.moduleIcon,
                        color: AddSupplierColors.brandGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _logic.isEditMode
                          ? AddSupplierStrings.appBarTitleEdit
                          : AddSupplierStrings.appBarTitleAdd,
                      style: AddSupplierStyles.appBarTitle,
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(AddSupplierStrings.appBarSubtitle,
                      style: AddSupplierStyles.appBarSubtitle),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: widget.onBack ?? () => Navigator.pop(context),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AddSupplierColors.shellBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AddSupplierColors.shellBorder),
        ),
        child: const Icon(AddSupplierIcons.backArrow,
            color: AddSupplierColors.shellTextTitle, size: 20),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AddSupplierStyles.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: AddSupplierStyles.sectionIconBox,
                  height: AddSupplierStyles.sectionIconBox,
                  decoration: BoxDecoration(
                    color: AddSupplierColors.brandGoldBg,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AddSupplierColors.brandGoldBorder),
                  ),
                  child: Icon(icon,
                      color: AddSupplierColors.brandGold,
                      size: AddSupplierStyles.sectionIconSize),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AddSupplierStyles.sectionTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AddSupplierStyles.sectionSubtitle),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
              height: 1, color: AddSupplierColors.bodyBorder.withOpacity(0.5)),
          Padding(
            padding: AddSupplierStyles.cardPadding,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization textCap = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    int maxLines = 1,
  }) {
    return Padding(
      padding: AddSupplierStyles.fieldGap,
      child: TextFormField(
        controller: ctrl,
        onChanged: onChanged,
        validator: validator,
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
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Padding(
      padding: AddSupplierStyles.fieldGap,
      child: ListenableBuilder(
        listenable: _logic,
        builder: (_, __) => DropdownButtonFormField<SupplierType>(
          value: _logic.supplierType,
          decoration: AddSupplierStyles.fieldDecoration(
            label: AddSupplierStrings.lblSupplierType,
            prefix: const Icon(AddSupplierIcons.supplierType,
                color: AddSupplierColors.brandGold, size: 20),
          ),
          style: AddSupplierStyles.fieldInput,
          items: SupplierType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) _logic.setSupplierType(v);
          },
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AddSupplierColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddSupplierColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(AddSupplierIcons.errorIcon,
              color: AddSupplierColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AddSupplierColors.error,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _logic.isSaving ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AddSupplierColors.saveBtnBg,
          disabledBackgroundColor: AddSupplierColors.saveBtnDisabled,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: _logic.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.black54, strokeWidth: 2))
            : const Icon(AddSupplierIcons.save,
                color: Colors.black87, size: 22),
        label: Text(
          _logic.isSaving
              ? AddSupplierStrings.btnSaving
              : _logic.isEditMode
                  ? AddSupplierStrings.btnSaveEdit
                  : AddSupplierStrings.btnSaveAdd,
          style: AddSupplierStyles.saveButtonText,
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    // Sync all controller values
    _logic.businessName = _businessNameCtrl.text;
    _logic.contactPerson = _contactPersonCtrl.text;
    _logic.mobile = _mobileCtrl.text;
    _logic.whatsapp = _whatsappCtrl.text;
    _logic.email = _emailCtrl.text;
    _logic.alternateContact = _altContactCtrl.text;
    _logic.panNumber = _panCtrl.text;
    _logic.gstNumber = _gstCtrl.text;
    _logic.addressLine1 = _address1Ctrl.text;
    _logic.addressLine2 = _address2Ctrl.text;
    _logic.state = _stateCtrl.text;
    _logic.pincode = _pincodeCtrl.text;
    _logic.setOpeningBalance(_openingBalCtrl.text);
    _logic.notes = _notesCtrl.text;

    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await _logic.save();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_logic.successMessage ?? 'Saved!'),
        backgroundColor: AddSupplierColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      widget.onSaved?.call();
    }
  }
}
