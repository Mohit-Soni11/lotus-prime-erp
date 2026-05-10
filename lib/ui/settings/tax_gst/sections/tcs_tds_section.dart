// ============================================================
// FILE  : lib/ui/settings/tax_gst/sections/tcs_tds_section.dart
// MODULE: Tax & GST — Card 05
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../../logic/setting/tax_gst/sections/tcs_tds_logic.dart';
import '../widgets/tax_gst_section_header.dart';
import '../widgets/tax_gst_toggle_row.dart';
import '../widgets/tax_gst_info_banner.dart';
import '../widgets/tax_gst_field_row.dart';

class TcsTdsSection extends StatelessWidget {
  const TcsTdsSection({super.key, required this.logic});
  final TcsTdsLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final e = logic.isEditing;
        final a = TaxGstColors.card05Accent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaxGstSectionHeader(
              title: TaxGstStrings.card05SectionTitle,
              subtitle: TaxGstStrings.card05SectionSub,
              accentColor: a,
              isEditing: e,
              isSaving: logic.isSaving,
              onEdit: logic.beginEdit,
              onCancel: logic.cancelEdit,
              onSave: () async {
                final ok = await logic.save();
                if (context.mounted) _snack(context, ok);
              },
            ),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // TCS Toggle
            TaxGstToggleRow(
              icon: TaxGstIcons.card05,
              title: TaxGstStrings.toggleTcsTitle,
              subtitle: TaxGstStrings.toggleTcsSub,
              value: logic.tcsEnabled,
              accentColor: a,
              isEnabled: e,
              showDivider: logic.tcsEnabled,
              onChanged: logic.setTcsEnabled,
            ),

            // TCS fields — only when enabled
            if (logic.tcsEnabled) ...[
              const SizedBox(height: TaxGstStyles.fieldGapV),
              TaxGstFieldRow(children: [
                _inputField(
                  context,
                  ctrl: logic.tcsThresholdCtrl,
                  label: TaxGstStrings.labelTcsThreshold,
                  hint: TaxGstStrings.hintTcsThreshold,
                  icon: TaxGstIcons.fieldThreshold,
                  accent: a,
                  locked: !e,
                  keyboardType: TextInputType.number,
                ),
                _inputField(
                  context,
                  ctrl: logic.tcsRateCtrl,
                  label: TaxGstStrings.labelTcsRate,
                  hint: TaxGstStrings.hintTcsRate,
                  icon: TaxGstIcons.fieldRate,
                  accent: a,
                  locked: !e,
                  keyboardType: TextInputType.number,
                ),
              ]),
            ],

            const SizedBox(height: TaxGstStyles.spaceMD),

            // TDS Toggle
            TaxGstToggleRow(
              icon: TaxGstIcons.card05,
              title: TaxGstStrings.toggleTdsTitle,
              subtitle: TaxGstStrings.toggleTdsSub,
              value: logic.tdsEnabled,
              accentColor: a,
              isEnabled: e,
              showDivider: logic.tdsEnabled,
              onChanged: logic.setTdsEnabled,
            ),

            // TDS Rate — only when enabled
            if (logic.tdsEnabled) ...[
              const SizedBox(height: TaxGstStyles.fieldGapV),
              _inputField(
                context,
                ctrl: logic.tdsRateCtrl,
                label: TaxGstStrings.labelTdsRate,
                hint: TaxGstStrings.hintTcsRate,
                icon: TaxGstIcons.fieldRate,
                accent: a,
                locked: !e,
                keyboardType: TextInputType.number,
              ),
            ],

            const SizedBox(height: TaxGstStyles.spaceMD),

            TaxGstInfoBanner(
              accentColor: a,
              message: TaxGstStrings.infoTcs,
            ),
          ],
        );
      },
    );
  }

  Widget _inputField(
    BuildContext context, {
    required TextEditingController ctrl,
    required String label,
    required String hint,
    IconData? icon,
    required Color accent,
    required bool locked,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: ctrl,
        enabled: !locked,
        keyboardType: keyboardType,
        style: TaxGstStyles.inputText(context),
        decoration: TaxGstStyles.inputDecoration(
          context,
          labelText: label,
          hintText: hint,
          prefixIcon: icon,
          accentColor: accent,
          isLocked: locked,
        ),
      );
}

void _snack(BuildContext ctx, bool ok) => ScaffoldMessenger.of(ctx)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(
    content: Text(ok ? TaxGstStrings.snackSaved : TaxGstStrings.snackSaveError),
    backgroundColor: ok ? TaxGstColors.btnSave : TaxGstColors.statusDanger,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TaxGstStyles.radiusButton)),
    margin: const EdgeInsets.all(16),
  ));
