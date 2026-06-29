// ============================================================
// FILE  : lib/ui/settings/tax_gst/sections/bis_hallmark_section.dart
// MODULE: Tax & GST â€” Card 07
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../../logic/setting/tax_gst/sections/bis_hallmark_logic.dart';
import '../widgets/tax_gst_section_header.dart';
import '../widgets/tax_gst_info_banner.dart';
import '../widgets/tax_gst_field_row.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class BisHallmarkSection extends StatelessWidget {
  const BisHallmarkSection({super.key, required this.logic});
  final BisHallmarkLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final e = logic.isEditing;
        const a = TaxGstColors.card07Accent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaxGstSectionHeader(
              title: TaxGstStrings.card07SectionTitle,
              subtitle: TaxGstStrings.card07SectionSub,
              accentColor: a,
              isEditing: e,
              isSaving: logic.isSaving,
              onEdit: logic.beginEdit,
              onCancel: logic.cancelEdit,
              onSave: () async {
                final ok = await logic.save();
                if (context.mounted) _showFeedback(context, ok);
              },
            ),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // Row 1: BIS License + HUID
            TaxGstFieldRow(children: [
              _field(
                context,
                ctrl: logic.bisLicenseCtrl,
                label: TaxGstStrings.labelBisLicense,
                hint: TaxGstStrings.hintBisLicense,
                icon: TaxGstIcons.fieldBisLicense,
                accent: a,
                locked: !e,
              ),
              _field(
                context,
                ctrl: logic.huidCtrl,
                label: TaxGstStrings.labelHuid,
                hint: TaxGstStrings.hintHuid,
                icon: TaxGstIcons.fieldHuid,
                accent: a,
                locked: !e,
              ),
            ]),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // Row 2: Valid From + Valid Upto (date pickers)
            TaxGstFieldRow(children: [
              _DatePickerField(
                ctrl: logic.bisValidFromCtrl,
                label: TaxGstStrings.labelBisValidFrom,
                accent: a,
                locked: !e,
              ),
              _DatePickerField(
                ctrl: logic.bisValidUptoCtrl,
                label: TaxGstStrings.labelBisValidUpto,
                accent: a,
                locked: !e,
              ),
            ]),

            const SizedBox(height: TaxGstStyles.spaceMD),

            const TaxGstInfoBanner(
              accentColor: a,
              message: TaxGstStrings.infoBis,
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
  }) =>
      TextFormField(
        controller: ctrl,
        enabled: !locked,
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

// â”€â”€ Date picker field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.ctrl,
    required this.label,
    required this.accent,
    required this.locked,
  });

  final TextEditingController ctrl;
  final String label;
  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: locked
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
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
                  ctrl.text = '${picked.day.toString().padLeft(2, '0')}/'
                      '${picked.month.toString().padLeft(2, '0')}/'
                      '${picked.year}';
                }
              },
        child: AbsorbPointer(
          child: TextFormField(
            controller: ctrl,
            enabled: !locked,
            style: TaxGstStyles.inputText(context),
            decoration: TaxGstStyles.inputDecoration(
              context,
              labelText: label,
              hintText: TaxGstStrings.hintDate,
              prefixIcon: TaxGstIcons.fieldDate,
              accentColor: accent,
              isLocked: locked,
              suffixWidget: locked
                  ? null
                  : Icon(TaxGstIcons.calendarPick,
                      size: 16, color: accent.withValues(alpha: 0.7)),
            ),
          ),
        ),
      );
}

void _showFeedback(BuildContext ctx, bool ok) => AppFeedback.show(
      ctx,
      type: AppFeedbackType.error,
      message:
          ok ? TaxGstStrings.feedbackSaved : TaxGstStrings.feedbackSaveError,
    );
