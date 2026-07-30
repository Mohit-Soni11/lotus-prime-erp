import 'package:flutter/material.dart';

import '../../../../logic/setting/tax_gst/sections/hsn_code_logic.dart';
import '../../../../models/setting/tax_gst/hsn_code_model.dart';
import '../../../../theme/settings/tax_gst/tax_gst_theme.dart';

class HsnClassificationRow extends StatelessWidget {
  final int index;
  final HsnCodeModel entry;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HsnClassificationRow({
    super.key,
    required this.index,
    required this.entry,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: TaxGstStyles.hsnRowDecoration(index.isEven),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.category, style: TaxGstStyles.hsnCategory(context)),
                const SizedBox(height: 3),
                Text(
                  entry.appliesTo,
                  style: TaxGstStyles.sectionSubtitle(context)
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(entry.hsnCode, style: TaxGstStyles.hsnCode(context)),
          ),
          SizedBox(
            width: 72,
            child: Text(
              entry.billingDisplayCode,
              style: TaxGstStyles.hsnTableHeader(context),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 58,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: TaxGstStyles.ratePillDecoration(accent),
                child: Text(
                  entry.gstRate,
                  style: TaxGstStyles.hsnRate(context, color: accent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    TaxGstIcons.actionEdit,
                    size: 16,
                    color: accent.withValues(alpha: 0.85),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    TaxGstIcons.actionDelete,
                    size: 16,
                    color: TaxGstColors.statusDanger.withValues(alpha: 0.7),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HsnClassificationForm extends StatelessWidget {
  final HsnCodeLogic logic;
  final Color accent;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const HsnClassificationForm({
    super.key,
    required this.logic,
    required this.accent,
    required this.onSubmit,
    required this.onCancel,
  });

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
          Text(
            logic.isEditing
                ? TaxGstStrings.dialogEditHsnTitle
                : TaxGstStrings.dialogAddHsnTitle,
            style: TaxGstStyles.sectionTitle(context).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _input(
                  context,
                  controller: logic.addCategoryCtrl,
                  label: TaxGstStrings.labelItemCategory,
                  hint: TaxGstStrings.hintCategory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _input(
                  context,
                  controller: logic.addHsnCtrl,
                  label: TaxGstStrings.labelHsnCode,
                  hint: TaxGstStrings.hintHsnCode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _input(
                  context,
                  controller: logic.addDisplayCodeCtrl,
                  label: TaxGstStrings.labelBillingDisplayCode,
                  hint: TaxGstStrings.hintBillingDisplayCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: logic.addAppliesToValue,
                  decoration: TaxGstStyles.inputDecoration(
                    context,
                    labelText: TaxGstStrings.labelAppliesTo,
                    hintText: '',
                    accentColor: accent,
                  ),
                  items: TaxGstStrings.hsnAppliesToOptions
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => logic.setAddAppliesTo(
                    value ?? TaxGstStrings.hsnAppliesProductSale,
                  ),
                  dropdownColor: TaxGstColors.cardSurface,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(
                  initialValue: logic.addRateValue,
                  decoration: TaxGstStyles.inputDecoration(
                    context,
                    labelText: TaxGstStrings.labelGstRate,
                    hintText: '',
                    accentColor: accent,
                  ),
                  items: TaxGstStrings.gstRateOptions
                      .map(
                        (rate) => DropdownMenuItem<String>(
                          value: rate,
                          child: Text(rate),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => logic.setAddRate(value ?? '3%'),
                  dropdownColor: TaxGstColors.cardSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _input(
                  context,
                  controller: logic.addEffectiveFromCtrl,
                  label: TaxGstStrings.labelEffectiveFrom,
                  hint: TaxGstStrings.hintEffectiveFrom,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(
                  TaxGstStrings.btnCancelDialog,
                  style: TaxGstStyles.btnText(
                    context,
                    color: TaxGstColors.btnCancel,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(
                  TaxGstIcons.actionAdd,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  logic.isEditing
                      ? TaxGstStrings.btnSave
                      : TaxGstStrings.btnAddHsnDialog,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(TaxGstStyles.radiusButton),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _input(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      style: TaxGstStyles.inputText(context),
      decoration: TaxGstStyles.inputDecoration(
        context,
        labelText: label,
        hintText: hint,
        accentColor: accent,
      ),
    );
  }
}
