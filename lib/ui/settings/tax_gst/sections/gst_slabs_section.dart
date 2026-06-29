// ============================================================
// FILE    : lib/ui/settings/tax_gst/sections/gst_slabs_section.dart
// MODULE  : Tax & GST â€” Card 02
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../../logic/setting/tax_gst/sections/gst_slabs_logic.dart';
import '../widgets/tax_gst_section_header.dart';
import '../widgets/tax_gst_info_banner.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class GstSlabsSection extends StatelessWidget {
  const GstSlabsSection({super.key, required this.logic});
  final GstSlabsLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final e = logic.isEditing;
        const a = TaxGstColors.card02Accent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaxGstSectionHeader(
              title: TaxGstStrings.card02SectionTitle,
              subtitle: TaxGstStrings.card02SectionSub,
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

            // Slab rows
            ...logic.slabs.asMap().entries.map((entry) {
              final i = entry.key;
              final slab = entry.value;
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: TaxGstStyles.spaceXS + 4),
                child: _SlabRow(
                  category: slab.category,
                  rate: slab.rate,
                  accent: a,
                  isEditing: e,
                  isEven: i.isEven,
                  onChanged: (rate) => logic.updateRate(i, rate),
                ),
              );
            }),

            const SizedBox(height: TaxGstStyles.spaceMD),

            const TaxGstInfoBanner(
              accentColor: a,
              message: TaxGstStrings.infoSlabs,
            ),
          ],
        );
      },
    );
  }
}

class _SlabRow extends StatelessWidget {
  const _SlabRow({
    required this.category,
    required this.rate,
    required this.accent,
    required this.isEditing,
    required this.isEven,
    required this.onChanged,
  });

  final String category;
  final String rate;
  final Color accent;
  final bool isEditing;
  final bool isEven;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: TaxGstStyles.animFast,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isEven ? TaxGstColors.inputSurface : TaxGstColors.cardSurface,
        borderRadius: BorderRadius.circular(TaxGstStyles.radiusChip + 2),
        border: Border.all(
          color: isEditing
              ? accent.withValues(alpha: 0.25)
              : TaxGstColors.cardBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          // Category
          Expanded(
            child: Text(
              category,
              style: TaxGstStyles.hsnCategory(context),
            ),
          ),

          // Rate pill or dropdown
          if (!isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: TaxGstStyles.ratePillDecoration(accent),
              child: Text(
                rate,
                style: TaxGstStyles.hsnRate(context, color: accent),
              ),
            )
          else
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                initialValue: rate,
                isDense: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide:
                        BorderSide(color: accent.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide:
                        BorderSide(color: accent.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  fillColor: TaxGstColors.cardSurface,
                  filled: true,
                ),
                items: TaxGstStrings.gstRateOptions
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r,
                              style:
                                  TaxGstStyles.hsnRate(context, color: accent)),
                        ))
                    .toList(),
                onChanged: (v) => onChanged(v ?? '3%'),
                dropdownColor: TaxGstColors.cardSurface,
                icon: Icon(TaxGstIcons.dropdownArrow, size: 18, color: accent),
              ),
            ),
        ],
      ),
    );
  }
}

void _showFeedback(BuildContext context, bool ok) {
  AppFeedback.show(
    context,
    type: AppFeedbackType.error,
    message: ok ? TaxGstStrings.feedbackSaved : TaxGstStrings.feedbackSaveError,
  );
}
