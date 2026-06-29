// ============================================================
// FILE    : lib/ui/settings/tax_gst/sections/hsn_code_section.dart
// MODULE  : Tax & GST â€” Card 03
// ============================================================
import 'package:flutter/material.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';
import '../../../../logic/setting/tax_gst/sections/hsn_code_logic.dart';
import '../widgets/tax_gst_info_banner.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class HsnCodeSection extends StatefulWidget {
  const HsnCodeSection({super.key, required this.logic});
  final HsnCodeLogic logic;

  @override
  State<HsnCodeSection> createState() => _HsnCodeSectionState();
}

class _HsnCodeSectionState extends State<HsnCodeSection> {
  bool _showAddForm = false;
  final Color a = TaxGstColors.card03Accent;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Section Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(TaxGstStrings.card03SectionTitle,
                          style: TaxGstStyles.sectionTitle(context)),
                      const SizedBox(height: 3),
                      Text(TaxGstStrings.card03SectionSub,
                          style: TaxGstStyles.sectionSubtitle(context)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TaxGstStyles.fieldGapV),

            // â”€â”€ Table Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: Text(TaxGstStrings.hsnColCategory,
                        style: TaxGstStyles.hsnTableHeader(context))),
                Expanded(
                    flex: 2,
                    child: Text(TaxGstStrings.hsnColCode,
                        style: TaxGstStyles.hsnTableHeader(context))),
                SizedBox(
                    width: 52,
                    child: Text(TaxGstStrings.hsnColRate,
                        style: TaxGstStyles.hsnTableHeader(context),
                        textAlign: TextAlign.center)),
                const SizedBox(width: 32),
              ]),
            ),
            const Divider(
                height: 1, thickness: 1, color: TaxGstColors.dividerColor),

            const SizedBox(height: 4),

            // â”€â”€ HSN Rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (widget.logic.codes.isEmpty)
              _EmptyHsnState(accentColor: a)
            else
              ...widget.logic.codes.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _HsnRow(
                    index: entry.key,
                    entry: entry.value,
                    accent: a,
                    onDelete: () {
                      widget.logic.removeCode(entry.key);
                      _showFeedback(context, TaxGstStrings.feedbackHsnRemoved);
                    },
                  ),
                );
              }),

            const SizedBox(height: TaxGstStyles.spaceMD),

            // â”€â”€ Add Form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            AnimatedCrossFade(
              duration: TaxGstStyles.animNormal,
              crossFadeState: _showAddForm
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _AddButton(
                accent: a,
                onTap: () => setState(() => _showAddForm = true),
              ),
              secondChild: _AddHsnForm(
                logic: widget.logic,
                accent: a,
                onAdd: () {
                  widget.logic.addCode();
                  setState(() => _showAddForm = false);
                  _showFeedback(context, TaxGstStrings.feedbackHsnAdded);
                },
                onCancel: () {
                  widget.logic.resetAddForm();
                  setState(() => _showAddForm = false);
                },
              ),
            ),

            const SizedBox(height: TaxGstStyles.spaceMD),

            TaxGstInfoBanner(accentColor: a, message: TaxGstStrings.infoHsn),
          ],
        );
      },
    );
  }
}

class _HsnRow extends StatelessWidget {
  const _HsnRow({
    required this.index,
    required this.entry,
    required this.accent,
    required this.onDelete,
  });

  final int index;
  final dynamic entry; // HsnCodeModel
  final Color accent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: TaxGstStyles.hsnRowDecoration(index.isEven),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(entry.category, style: TaxGstStyles.hsnCategory(context)),
        ),
        Expanded(
          flex: 2,
          child: Text(entry.hsnCode, style: TaxGstStyles.hsnCode(context)),
        ),
        SizedBox(
          width: 52,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration:
                  TaxGstStyles.ratePillDecoration(TaxGstColors.accentPrimary),
              child: Text(
                entry.gstRate,
                style: TaxGstStyles.hsnRate(context,
                    color: TaxGstColors.accentPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: IconButton(
            onPressed: onDelete,
            icon: Icon(TaxGstIcons.actionDelete,
                size: 16,
                color: TaxGstColors.statusDanger.withValues(alpha: 0.7)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ]),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.accent, required this.onTap});
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(TaxGstStyles.radiusButton),
          border: Border.all(
            color: accent.withValues(alpha: 0.30),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(TaxGstIcons.actionAdd, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(TaxGstStrings.btnAddHsn,
              style: TaxGstStyles.btnText(context, color: accent)),
        ]),
      ),
    );
  }
}

class _AddHsnForm extends StatelessWidget {
  const _AddHsnForm({
    required this.logic,
    required this.accent,
    required this.onAdd,
    required this.onCancel,
  });

  final HsnCodeLogic logic;
  final Color accent;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(TaxGstStyles.radiusSection),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TaxGstStrings.dialogAddHsnTitle,
              style: TaxGstStyles.sectionTitle(context).copyWith(fontSize: 13)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: logic.addCategoryCtrl,
                style: TaxGstStyles.inputText(context),
                decoration: TaxGstStyles.inputDecoration(context,
                    labelText: TaxGstStrings.labelItemCategory,
                    hintText: TaxGstStrings.hintCategory,
                    accentColor: accent),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: logic.addHsnCtrl,
                style: TaxGstStyles.inputText(context),
                decoration: TaxGstStyles.inputDecoration(context,
                    labelText: TaxGstStrings.labelHsnCode,
                    hintText: TaxGstStrings.hintHsnCode,
                    accentColor: accent),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                initialValue: logic.addRateValue,
                decoration: TaxGstStyles.inputDecoration(context,
                    labelText: TaxGstStrings.labelGstRate,
                    hintText: '',
                    accentColor: accent),
                items: TaxGstStrings.gstRateOptions
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ))
                    .toList(),
                onChanged: (v) => logic.setAddRate(v ?? '3%'),
                dropdownColor: TaxGstColors.cardSurface,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: onCancel,
              child: Text(TaxGstStrings.btnCancelDialog,
                  style: TaxGstStyles.btnText(context,
                      color: TaxGstColors.btnCancel)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(TaxGstIcons.actionAdd,
                  size: 14, color: Colors.white),
              label: const Text(TaxGstStrings.btnAddHsnDialog,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(TaxGstStyles.radiusButton)),
                elevation: 0,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _EmptyHsnState extends StatelessWidget {
  const _EmptyHsnState({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(TaxGstIcons.card03,
                size: 36, color: accentColor.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(TaxGstStrings.emptyHsnTitle,
                style: TaxGstStyles.sectionTitle(context)
                    .copyWith(fontSize: 13, color: TaxGstColors.textMuted)),
            const SizedBox(height: 4),
            Text(TaxGstStrings.emptyHsnSub,
                style: TaxGstStyles.sectionSubtitle(context),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

void _showFeedback(BuildContext ctx, String msg) {
  AppFeedback.show(
    ctx,
    type: AppFeedbackType.info,
    message: msg,
  );
}
