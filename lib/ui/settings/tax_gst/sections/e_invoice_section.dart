// ============================================================
// FILE  : lib/ui/settings/tax_gst/sections/e_invoice_section.dart
// MODULE: Tax & GST — Card 06
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../../logic/setting/tax_gst/sections/e_invoice_logic.dart';
import '../widgets/tax_gst_section_header.dart';
import '../widgets/tax_gst_toggle_row.dart';
import '../widgets/tax_gst_field_row.dart';

class EInvoiceSection extends StatelessWidget {
  const EInvoiceSection({super.key, required this.logic});
  final EInvoiceLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final e = logic.isEditing;
        final a = TaxGstColors.card06Accent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaxGstSectionHeader(
              title: TaxGstStrings.card06SectionTitle,
              subtitle: TaxGstStrings.card06SectionSub,
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

            // E-Invoicing master toggle
            TaxGstToggleRow(
              icon: TaxGstIcons.card06,
              title: TaxGstStrings.toggleEInvoiceTitle,
              subtitle: TaxGstStrings.toggleEInvoiceSub,
              value: logic.eInvoicingEnabled,
              accentColor: a,
              isEnabled: e,
              showDivider: logic.eInvoicingEnabled,
              onChanged: logic.setEnabled,
            ),

            // IRP & threshold — only when e-invoicing is on
            if (logic.eInvoicingEnabled) ...[
              const SizedBox(height: TaxGstStyles.fieldGapV),

              // Turnover limit dropdown
              DropdownButtonFormField<String>(
                value: logic.turnoverLimit,
                style: TaxGstStyles.inputText(context),
                decoration: TaxGstStyles.inputDecoration(
                  context,
                  labelText: TaxGstStrings.labelEInvThreshold,
                  hintText: '',
                  accentColor: a,
                  isLocked: !e,
                ),
                items: TaxGstStrings.eInvoiceThresholds
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged:
                    e ? (v) => logic.setTurnoverLimit(v ?? '₹5 Crore') : null,
                dropdownColor: TaxGstColors.cardSurface,
                borderRadius: BorderRadius.circular(TaxGstStyles.radiusInput),
                icon: Icon(TaxGstIcons.dropdownArrow,
                    color: e ? a : TaxGstColors.textDisabled),
              ),

              const SizedBox(height: TaxGstStyles.fieldGapV),

              // IRP credentials side-by-side
              TaxGstFieldRow(children: [
                TextFormField(
                  controller: logic.irpUserCtrl,
                  enabled: e,
                  style: TaxGstStyles.inputText(context),
                  decoration: TaxGstStyles.inputDecoration(
                    context,
                    labelText: TaxGstStrings.labelIrpUsername,
                    hintText: '',
                    prefixIcon: TaxGstIcons.fieldApiUser,
                    accentColor: a,
                    isLocked: !e,
                  ),
                ),
                TextFormField(
                  controller: logic.irpPassCtrl,
                  enabled: e,
                  obscureText: !logic.irpPassVisible,
                  style: TaxGstStyles.inputText(context),
                  decoration: TaxGstStyles.inputDecoration(
                    context,
                    labelText: TaxGstStrings.labelIrpPassword,
                    hintText: '',
                    prefixIcon: TaxGstIcons.fieldApiPass,
                    accentColor: a,
                    isLocked: !e,
                    suffixWidget: e
                        ? IconButton(
                            icon: Icon(
                              logic.irpPassVisible
                                  ? TaxGstIcons.passwordVisible
                                  : TaxGstIcons.passwordHidden,
                              size: 17,
                              color: a.withOpacity(0.7),
                            ),
                            onPressed: logic.togglePassVisibility,
                          )
                        : null,
                  ),
                ),
              ]),
            ],

            const SizedBox(height: TaxGstStyles.spaceMD),

            // Filing reminders (always visible)
            TaxGstToggleRow(
              icon: TaxGstIcons.statusSuccess,
              title: TaxGstStrings.toggleGstr1Title,
              subtitle: TaxGstStrings.toggleGstr1Sub,
              value: logic.gstr1Reminder,
              accentColor: a,
              isEnabled: e,
              onChanged: logic.setGstr1Reminder,
            ),
            TaxGstToggleRow(
              icon: TaxGstIcons.statusSuccess,
              title: TaxGstStrings.toggleGstr3bTitle,
              subtitle: TaxGstStrings.toggleGstr3bSub,
              value: logic.gstr3bReminder,
              accentColor: a,
              isEnabled: e,
              showDivider: false,
              onChanged: logic.setGstr3bReminder,
            ),
          ],
        );
      },
    );
  }
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
