// ============================================================
// FILE    : lib/ui/settings/tax_gst/widgets/tax_gst_section_header.dart
// MODULE  : Tax & GST Configuration
// DESC    : Per-section Edit / Save / Cancel header row.
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import 'tax_gst_action_button.dart';

class TaxGstSectionHeader extends StatelessWidget {
  const TaxGstSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.showEditButton = true,
  });

  final String      title;
  final String      subtitle;
  final Color       accentColor;
  final bool        isEditing;
  final bool        isSaving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool        showEditButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,    style: TaxGstStyles.sectionTitle(context)),
              const SizedBox(height: 3),
              Text(subtitle, style: TaxGstStyles.sectionSubtitle(context)),
            ],
          ),
        ),

        if (showEditButton) ...[
          const SizedBox(width: 12),

          // Edit or Save/Cancel
          if (!isEditing)
            TaxGstActionButton(
              label:       TaxGstStrings.btnEdit,
              icon:        TaxGstIcons.actionEdit,
              accentColor: accentColor,
              onTap:       onEdit,
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TaxGstActionButton(
                  label:       TaxGstStrings.btnCancel,
                  icon:        TaxGstIcons.actionCancel,
                  accentColor: TaxGstColors.btnCancel,
                  onTap:       onCancel,
                ),
                const SizedBox(width: 8),
                TaxGstActionButton(
                  label:       isSaving
                      ? TaxGstStrings.btnSaving
                      : TaxGstStrings.btnSave,
                  icon:        TaxGstIcons.actionSave,
                  accentColor: TaxGstColors.btnSave,
                  isFilled:    true,
                  isSaving:    isSaving,
                  onTap:       isSaving ? null : onSave,
                ),
              ],
            ),
        ],
      ],
    );
  }
}
