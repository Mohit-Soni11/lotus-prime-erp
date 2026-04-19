// =============================================================================
// FILE        : add_karigar_dialog.dart
// MODULE      : Karigar
// LAYER       : UI / Shared Components
// DESCRIPTION : Slide-up modal dialog for adding a new Karigar master record.
//               Reused in Issue and Receive screens. Returns the newly created
//               KarigarMaster via Navigator.pop(context, newKarigar).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/karigar/karigar_master_controller.dart';
import '../../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../../theme/karigar/karigar_theme.dart';
import 'karigar_field_widgets.dart';

class AddKarigarDialog extends StatefulWidget {
  final KarigarMasterController masterCtrl;

  const AddKarigarDialog({
    super.key,
    required this.masterCtrl,
  });

  @override
  State<AddKarigarDialog> createState() => _AddKarigarDialogState();
}

class _AddKarigarDialogState extends State<AddKarigarDialog> {

  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _cityCtrl     = TextEditingController();
  final _rateCtrl     = TextEditingController(text: '0.00');
  final _balanceCtrl  = TextEditingController(text: '0.00');
  final _notesCtrl    = TextEditingController();

  final _nameFocus    = FocusNode();
  final _phoneFocus   = FocusNode();
  final _rateFocus    = FocusNode();

  KarigarSpecialization _specialization = KarigarSpecialization.allMetals;
  KarigarRateType       _rateType       = KarigarRateType.perGram;

  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _altPhoneCtrl, _addressCtrl,
                     _cityCtrl, _rateCtrl, _balanceCtrl, _notesCtrl]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _phoneFocus, _rateFocus]) f.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final added = await widget.masterCtrl.addKarigar(
      name:           _nameCtrl.text,
      phone:          _phoneCtrl.text,
      alternatePhone: _altPhoneCtrl.text,
      specialization: _specialization.label,
      rateType:       _rateType.label,
      rateAmount:     double.tryParse(_rateCtrl.text) ?? 0.0,
      address:        _addressCtrl.text,
      city:           _cityCtrl.text,
      openingBalance: double.tryParse(_balanceCtrl.text) ?? 0.0,
      notes:          _notesCtrl.text,
    );

    setState(() => _isSaving = false);

    if (added != null && mounted) {
      Navigator.pop(context, added);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: KarigarColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KarigarColors.brandGold.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 18),
              decoration: BoxDecoration(
                color: KarigarColors.shellPanelBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(
                  bottom: BorderSide(color: KarigarColors.shellBorder, width: 1),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KarigarColors.brandGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(KarigarIcons.addKarigar,
                      color: KarigarColors.brandGold, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Karigar',
                        style: GoogleFonts.manrope(
                          color: KarigarColors.shellTextTitle,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                    Text('Create an artisan master record',
                        style: GoogleFonts.inter(
                          color: KarigarColors.shellTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(KarigarIcons.close,
                      color: KarigarColors.shellTextMuted, size: 20),
                ),
              ]),
            ),

            // ── Form Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(children: [

                    // Name + Phone
                    KarigarRowTwo(
                      left: KarigarInputField(
                        label:     KarigarStrings.lblKarigarName,
                        hint:      KarigarStrings.hintKarigarName,
                        icon:      KarigarIcons.karigar,
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        nextFocus: _phoneFocus,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Name is required';
                          if (v.trim().length < 2) return 'Too short';
                          return null;
                        },
                      ),
                      right: KarigarInputField(
                        label:       KarigarStrings.lblPhone,
                        hint:        KarigarStrings.hintPhone,
                        icon:        KarigarIcons.phone,
                        controller:  _phoneCtrl,
                        focusNode:   _phoneFocus,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone is required';
                          if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Alt Phone + Address
                    KarigarRowTwo(
                      left: KarigarInputField(
                        label:       KarigarStrings.lblAltPhone,
                        hint:        KarigarStrings.hintAltPhone,
                        icon:        KarigarIcons.phone,
                        controller:  _altPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      right: KarigarInputField(
                        label:      KarigarStrings.lblCity,
                        hint:       KarigarStrings.hintCity,
                        icon:       KarigarIcons.city,
                        controller: _cityCtrl,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Specialization + Rate Type
                    KarigarRowTwo(
                      left: KarigarDropdown<KarigarSpecialization>(
                        label:     KarigarStrings.lblSpecialization,
                        icon:      KarigarIcons.speciality,
                        value:     _specialization,
                        items:     KarigarSpecialization.values,
                        itemLabel: (e) => e.label,
                        onChanged: (v) {
                          if (v != null) setState(() => _specialization = v);
                        },
                      ),
                      right: KarigarDropdown<KarigarRateType>(
                        label:     KarigarStrings.lblRateType,
                        icon:      KarigarIcons.rate,
                        value:     _rateType,
                        items:     KarigarRateType.values,
                        itemLabel: (e) => e.label,
                        onChanged: (v) {
                          if (v != null) setState(() => _rateType = v);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rate Amount + Opening Balance
                    KarigarRowTwo(
                      left: KarigarInputField(
                        label:       KarigarStrings.lblRateAmount,
                        hint:        KarigarStrings.hintRate,
                        icon:        KarigarIcons.money,
                        controller:  _rateCtrl,
                        focusNode:   _rateFocus,
                        prefixText:  '₹',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                      ),
                      right: KarigarInputField(
                        label:       KarigarStrings.lblOpeningBalance,
                        hint:        KarigarStrings.hintBalance,
                        icon:        KarigarIcons.balance,
                        controller:  _balanceCtrl,
                        prefixText:  '₹',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(KarigarStrings.noteOpeningBalance,
                          style: KarigarStyles.caption),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    KarigarInputField(
                      label:      KarigarStrings.lblNotes,
                      hint:       KarigarStrings.hintNotes,
                      icon:       KarigarIcons.notes,
                      controller: _notesCtrl,
                      maxLines:   2,
                    ),
                  ]),
                ),
              ),
            ),

            // ── Footer Buttons ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: KarigarColors.divider, width: 1)),
              ),
              child: Row(children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: KarigarColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Cancel', style: KarigarStyles.resetButtonText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _onSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(KarigarIcons.save, size: 18, color: KarigarColors.shellBg),
                    label: Text(
                      _isSaving ? KarigarStrings.btnSaving : KarigarStrings.btnSaveKarigar,
                      style: KarigarStyles.saveButtonText,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KarigarColors.brandGold,
                      foregroundColor: KarigarColors.shellBg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
