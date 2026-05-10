// ============================================================
// FILE    : lib/ui/settings/tax_gst/sections/gst_registration_section.dart
// MODULE  : Tax & GST — Card 01
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../../logic/setting/tax_gst/sections/gst_registration_logic.dart';
import '../widgets/tax_gst_section_header.dart';
import '../widgets/tax_gst_info_banner.dart';
import '../widgets/tax_gst_field_row.dart';

class GstRegistrationSection extends StatelessWidget {
  const GstRegistrationSection({super.key, required this.logic});
  final GstRegistrationLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final e = logic.isEditing;
        final a = TaxGstColors.card01Accent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            TaxGstSectionHeader(
              title:       TaxGstStrings.card01SectionTitle,
              subtitle:    TaxGstStrings.card01SectionSub,
              accentColor: a,
              isEditing:   e,
              isSaving:    logic.isSaving,
              onEdit:      logic.beginEdit,
              onCancel:    logic.cancelEdit,
              onSave: () async {
                final ok = await logic.save();
                if (context.mounted) {
                  _showSnack(context, ok
                      ? TaxGstStrings.snackSaved
                      : TaxGstStrings.snackSaveError,
                      isError: !ok);
                }
              },
            ),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // Row 1: GSTIN + Legal Name
            TaxGstFieldRow(children: [
              _field(context,
                ctrl:    logic.gstinCtrl,
                label:   TaxGstStrings.labelGstin,
                hint:    TaxGstStrings.hintGstin,
                icon:    TaxGstIcons.fieldGstin,
                accent:  a,
                locked:  !e,
                caps:    TextCapitalization.characters,
                error:   logic.gstinError,
              ),
              _field(context,
                ctrl:   logic.legalNameCtrl,
                label:  TaxGstStrings.labelLegalName,
                hint:   TaxGstStrings.hintLegalName,
                icon:   TaxGstIcons.fieldLegalName,
                accent: a,
                locked: !e,
              ),
            ]),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // Row 2: PAN + TAN
            TaxGstFieldRow(children: [
              _field(context,
                ctrl:   logic.panCtrl,
                label:  TaxGstStrings.labelPan,
                hint:   TaxGstStrings.hintPan,
                icon:   TaxGstIcons.fieldPan,
                accent: a,
                locked: !e,
                caps:   TextCapitalization.characters,
                error:  logic.panError,
              ),
              _field(context,
                ctrl:   logic.tanCtrl,
                label:  TaxGstStrings.labelTan,
                hint:   TaxGstStrings.hintTan,
                icon:   TaxGstIcons.fieldTan,
                accent: a,
                locked: !e,
                caps:   TextCapitalization.characters,
              ),
            ]),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // Row 3: Reg Date + Taxpayer Type + State
            TaxGstFieldRow(children: [
              // Date picker field
              _DateField(
                ctrl:   logic.regDateCtrl,
                label:  TaxGstStrings.labelRegDate,
                accent: a,
                locked: !e,
              ),
              // Dropdown
              _DropdownField(
                label:    TaxGstStrings.labelTaxpayerType,
                value:    logic.taxpayerType,
                options:  TaxGstStrings.taxpayerTypes,
                accent:   a,
                locked:   !e,
                onChanged: logic.setTaxpayerType,
              ),
            ]),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // State Code (full width)
            _field(context,
              ctrl:   logic.stateCtrl,
              label:  TaxGstStrings.labelStateCode,
              hint:   TaxGstStrings.hintState,
              icon:   TaxGstIcons.fieldState,
              accent: a,
              locked: !e,
            ),

            const SizedBox(height: TaxGstStyles.spaceMD),

            TaxGstInfoBanner(
              accentColor: a,
              message:     TaxGstStrings.infoGstin,
            ),
          ],
        );
      },
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController ctrl,
    required String label,
    required String hint,
    IconData? icon,
    required Color accent,
    required bool locked,
    TextCapitalization caps = TextCapitalization.none,
    String? error,
  }) {
    return TextFormField(
      controller:          ctrl,
      enabled:             !locked,
      textCapitalization:  caps,
      style:               TaxGstStyles.inputText(context),
      decoration: TaxGstStyles.inputDecoration(
        context,
        labelText:   label,
        hintText:    hint,
        prefixIcon:  icon,
        accentColor: accent,
        isLocked:    locked,
        hasError:    error != null,
        errorText:   error,
      ),
    );
  }
}

// ── Date picker field ─────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  const _DateField({
    required this.ctrl,
    required this.label,
    required this.accent,
    required this.locked,
  });

  final TextEditingController ctrl;
  final String label;
  final Color  accent;
  final bool   locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked
          ? null
          : () async {
              final picked = await showDatePicker(
                context:     context,
                initialDate: DateTime.now(),
                firstDate:   DateTime(2000),
                lastDate:    DateTime(2100),
                builder: (context, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(
                      primary: accent,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                ctrl.text =
                    '${picked.day.toString().padLeft(2, '0')}/'
                    '${picked.month.toString().padLeft(2, '0')}/'
                    '${picked.year}';
              }
            },
      child: AbsorbPointer(
        child: TextFormField(
          controller: ctrl,
          enabled:    !locked,
          style:      const TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w500,
            color: TaxGstColors.textPrimary,
          ),
          decoration: TaxGstStyles.inputDecoration(
            context,
            labelText:   label,
            hintText:    TaxGstStrings.hintDate,
            prefixIcon:  TaxGstIcons.fieldDate,
            accentColor: accent,
            isLocked:    locked,
            suffixWidget: locked
                ? null
                : Icon(TaxGstIcons.calendarPick,
                    size: 16, color: accent.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.accent,
    required this.locked,
    required this.onChanged,
  });

  final String         label;
  final String         value;
  final List<String>   options;
  final Color          accent;
  final bool           locked;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      style: TaxGstStyles.inputText(context),
      decoration: TaxGstStyles.inputDecoration(
        context,
        labelText:   label,
        hintText:    '',
        prefixIcon:  TaxGstIcons.fieldTaxType,
        accentColor: accent,
        isLocked:    locked,
      ).copyWith(
        fillColor: locked
            ? TaxGstColors.inputSurfaceLocked
            : TaxGstColors.inputSurface,
      ),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: locked ? null : (v) => onChanged(v ?? options.first),
      dropdownColor: TaxGstColors.cardSurface,
      borderRadius: BorderRadius.circular(TaxGstStyles.radiusInput),
      icon: Icon(TaxGstIcons.dropdownArrow,
          color: locked ? TaxGstColors.textDisabled : accent),
    );
  }
}

// ── Snackbar helper ───────────────────────────────────────────────────────────
void _showSnack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? TaxGstIcons.statusError : TaxGstIcons.statusSuccess,
          color: Colors.white, size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ]),
      backgroundColor:
          isError ? TaxGstColors.statusDanger : TaxGstColors.btnSave,
      behavior:  SnackBarBehavior.floating,
      shape:     RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TaxGstStyles.radiusButton)),
      margin:    const EdgeInsets.all(16),
      duration:  const Duration(seconds: 3),
    ));
}
