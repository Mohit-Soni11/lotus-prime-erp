// ============================================================
// FILE  : lib/ui/settings/tax_gst/sections/tax_preferences_section.dart
// MODULE: Tax & GST — Card 04
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../../logic/setting/tax_gst/sections/tax_preferences_logic.dart';
import '../widgets/tax_gst_section_header.dart';
import '../widgets/tax_gst_toggle_row.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class TaxPreferencesSection extends StatelessWidget {
  const TaxPreferencesSection({super.key, required this.logic});
  final TaxPreferencesLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final e = logic.isEditing;
        const a = TaxGstColors.card04Accent;
        return Column(children: [
          TaxGstSectionHeader(
            title: TaxGstStrings.card04SectionTitle,
            subtitle: TaxGstStrings.card04SectionSub,
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
          TaxGstToggleRow(
            icon: TaxGstIcons.linkSync,
            title: TaxGstStrings.toggleAutoSplitTitle,
            subtitle: TaxGstStrings.toggleAutoSplitSub,
            value: logic.autoSplitIgst,
            accentColor: a,
            isEnabled: e,
            onChanged: (v) => logic.toggle('autoSplit', v),
          ),
          TaxGstToggleRow(
            icon: TaxGstIcons.statusSuccess,
            title: TaxGstStrings.toggleRoundOffTitle,
            subtitle: TaxGstStrings.toggleRoundOffSub,
            value: logic.roundOffGstAmount,
            accentColor: a,
            isEnabled: e,
            onChanged: (v) => logic.toggle('roundOff', v),
          ),
          TaxGstToggleRow(
            icon: TaxGstIcons.card06,
            title: TaxGstStrings.toggleShowOnBillTitle,
            subtitle: TaxGstStrings.toggleShowOnBillSub,
            value: logic.showGstBreakup,
            accentColor: a,
            isEnabled: e,
            onChanged: (v) => logic.toggle('showBreakup', v),
          ),
          TaxGstToggleRow(
            icon: TaxGstIcons.card03,
            title: TaxGstStrings.toggleCompositeTitle,
            subtitle: TaxGstStrings.toggleCompositeSub,
            value: logic.compositeSupply,
            accentColor: a,
            isEnabled: e,
            showDivider: false,
            onChanged: (v) => logic.toggle('composite', v),
          ),
        ]);
      },
    );
  }
}

void _showFeedback(BuildContext ctx, bool ok) => AppFeedback.show(
      ctx,
      type: AppFeedbackType.error,
      message:
          ok ? TaxGstStrings.feedbackSaved : TaxGstStrings.feedbackSaveError,
    );
