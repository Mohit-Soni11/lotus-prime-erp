import 'package:flutter/material.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

import '../../../../logic/setting/tax_gst/sections/hsn_code_logic.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../widgets/tax_gst_info_banner.dart';
import 'hsn_classification_widgets.dart';

class HsnCodeSection extends StatefulWidget {
  const HsnCodeSection({super.key, required this.logic});

  final HsnCodeLogic logic;

  @override
  State<HsnCodeSection> createState() => _HsnCodeSectionState();
}

class _HsnCodeSectionState extends State<HsnCodeSection> {
  bool _showForm = false;
  final Color _accent = TaxGstColors.card03Accent;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(),
            const SizedBox(height: TaxGstStyles.fieldGapV),
            _TableHeader(),
            const Divider(
              height: 1,
              thickness: 1,
              color: TaxGstColors.dividerColor,
            ),
            const SizedBox(height: 4),
            if (widget.logic.codes.isEmpty)
              _EmptyHsnState(accentColor: _accent)
            else
              ...widget.logic.codes.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: HsnClassificationRow(
                        index: entry.key,
                        entry: entry.value,
                        accent: _accent,
                        onEdit: () {
                          widget.logic.startEdit(entry.key);
                          setState(() => _showForm = true);
                        },
                        onDelete: () {
                          widget.logic.removeCode(entry.key);
                          _showFeedback(
                            context,
                            TaxGstStrings.feedbackHsnRemoved,
                          );
                        },
                      ),
                    ),
                  ),
            const SizedBox(height: TaxGstStyles.spaceMD),
            AnimatedCrossFade(
              duration: TaxGstStyles.animNormal,
              crossFadeState: _showForm
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _AddButton(
                accent: _accent,
                onTap: () => setState(() => _showForm = true),
              ),
              secondChild: HsnClassificationForm(
                logic: widget.logic,
                accent: _accent,
                onSubmit: () {
                  final wasEditing = widget.logic.isEditing;
                  widget.logic.saveDraft();
                  setState(() => _showForm = false);
                  _showFeedback(
                    context,
                    wasEditing
                        ? TaxGstStrings.feedbackHsnUpdated
                        : TaxGstStrings.feedbackHsnAdded,
                  );
                },
                onCancel: () {
                  widget.logic.resetAddForm();
                  setState(() => _showForm = false);
                },
              ),
            ),
            const SizedBox(height: TaxGstStyles.spaceMD),
            TaxGstInfoBanner(
              accentColor: _accent,
              message: TaxGstStrings.infoHsn,
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TaxGstStrings.card03SectionTitle,
                style: TaxGstStyles.sectionTitle(context),
              ),
              const SizedBox(height: 3),
              Text(
                TaxGstStrings.card03SectionSub,
                style: TaxGstStyles.sectionSubtitle(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              TaxGstStrings.hsnColCategory,
              style: TaxGstStyles.hsnTableHeader(context),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              TaxGstStrings.hsnColCode,
              style: TaxGstStyles.hsnTableHeader(context),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'POS GROUP',
              style: TaxGstStyles.hsnTableHeader(context),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              TaxGstStrings.hsnColRate,
              style: TaxGstStyles.hsnTableHeader(context),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _AddButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(TaxGstStyles.radiusButton),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TaxGstIcons.actionAdd, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              TaxGstStrings.btnAddHsn,
              style: TaxGstStyles.btnText(context, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHsnState extends StatelessWidget {
  final Color accentColor;

  const _EmptyHsnState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              TaxGstIcons.card03,
              size: 36,
              color: accentColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              TaxGstStrings.emptyHsnTitle,
              style: TaxGstStyles.sectionTitle(context).copyWith(
                fontSize: 13,
                color: TaxGstColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TaxGstStrings.emptyHsnSub,
              style: TaxGstStyles.sectionSubtitle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void _showFeedback(BuildContext context, String message) {
  AppFeedback.show(
    context,
    type: AppFeedbackType.info,
    message: message,
  );
}
