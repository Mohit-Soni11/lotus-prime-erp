import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../domain/sales_billing_metal_profile.dart';
import '../../domain/sales_billing_policy_input.dart';
import 'sales_billing_section_card.dart';
import 'sales_billing_toggle_tile.dart';
import 'sales_billing_visuals.dart';

class SalesBillingPolicyForm extends StatelessWidget {
  final SalesBillingModel model;
  final SalesBillingPolicyInput input;
  final TextEditingController returnWindowController;
  final TextEditingController handlingChargeController;
  final TextEditingController buybackRateController;
  final TextEditingController purityDeductionController;
  final TextEditingController termsController;
  final TextEditingController returnPolicyController;
  final TextEditingController buybackPolicyController;
  final TextEditingController footerController;
  final ValueChanged<SalesBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onReturnModeChanged;
  final void Function(SalesBillingFieldKey key, bool value) onFieldChanged;
  final ValueChanged<String> onTemplateChanged;
  final ValueChanged<bool> onPrintTermsChanged;
  final ValueChanged<bool> onPrintReturnPolicyChanged;
  final ValueChanged<bool> onPrintBuybackPolicyChanged;
  final ValueChanged<bool> onPrintFooterChanged;

  const SalesBillingPolicyForm({
    super.key,
    required this.model,
    required this.input,
    required this.returnWindowController,
    required this.handlingChargeController,
    required this.buybackRateController,
    required this.purityDeductionController,
    required this.termsController,
    required this.returnPolicyController,
    required this.buybackPolicyController,
    required this.footerController,
    required this.onInputChanged,
    required this.onReturnModeChanged,
    required this.onFieldChanged,
    required this.onTemplateChanged,
    required this.onPrintTermsChanged,
    required this.onPrintReturnPolicyChanged,
    required this.onPrintBuybackPolicyChanged,
    required this.onPrintFooterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = SalesBillingVisuals.accentFor(model.metal);

    return Column(
      children: [
        SalesBillingSectionCard(
          title: 'Invoice Item Display',
          subtitle: 'Choose the fields printed on every item row',
          icon: Icons.receipt_long_rounded,
          accent: accent,
          child: _DisplayFieldGrid(
            model: model,
            accent: accent,
            onFieldChanged: onFieldChanged,
          ),
        ),
        const SizedBox(height: 16),
        SalesBillingSectionCard(
          title: 'Return & Buyback Policy',
          subtitle: 'Control eligibility, deductions and settlement mode',
          icon: Icons.swap_horiz_rounded,
          accent: accent,
          child: _PolicyFields(
            model: model,
            input: input,
            accent: accent,
            returnWindowController: returnWindowController,
            handlingChargeController: handlingChargeController,
            buybackRateController: buybackRateController,
            purityDeductionController: purityDeductionController,
            returnPolicyController: returnPolicyController,
            buybackPolicyController: buybackPolicyController,
            onInputChanged: onInputChanged,
            onReturnModeChanged: onReturnModeChanged,
          ),
        ),
        const SizedBox(height: 16),
        SalesBillingSectionCard(
          title: 'Terms & Conditions',
          subtitle:
              'Footer copy printed on every ${BillingMetal.displayName(model.metal)} bill',
          icon: Icons.article_outlined,
          accent: accent,
          child: _TermsAndPrintFields(
            model: model,
            input: input,
            accent: accent,
            termsController: termsController,
            footerController: footerController,
            onInputChanged: onInputChanged,
            onTemplateChanged: onTemplateChanged,
            onPrintTermsChanged: onPrintTermsChanged,
            onPrintReturnPolicyChanged: onPrintReturnPolicyChanged,
            onPrintBuybackPolicyChanged: onPrintBuybackPolicyChanged,
            onPrintFooterChanged: onPrintFooterChanged,
          ),
        ),
      ],
    );
  }
}

class _DisplayFieldGrid extends StatelessWidget {
  final SalesBillingModel model;
  final Color accent;
  final void Function(SalesBillingFieldKey key, bool value) onFieldChanged;

  const _DisplayFieldGrid({
    required this.model,
    required this.accent,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fields = SalesBillingMetalProfiles.fieldsFor(model.metal);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: fields
              .map(
                (field) => SizedBox(
                  width: itemWidth,
                  child: SalesBillingToggleTile(
                    label: field.label,
                    description: field.description,
                    value: SalesBillingMetalProfiles.valueFor(
                      model,
                      field.key,
                    ),
                    accent: accent,
                    onChanged: (value) => onFieldChanged(field.key, value),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PolicyFields extends StatelessWidget {
  final SalesBillingModel model;
  final SalesBillingPolicyInput input;
  final Color accent;
  final TextEditingController returnWindowController;
  final TextEditingController handlingChargeController;
  final TextEditingController buybackRateController;
  final TextEditingController purityDeductionController;
  final TextEditingController returnPolicyController;
  final TextEditingController buybackPolicyController;
  final ValueChanged<SalesBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onReturnModeChanged;

  const _PolicyFields({
    required this.model,
    required this.input,
    required this.accent,
    required this.returnWindowController,
    required this.handlingChargeController,
    required this.buybackRateController,
    required this.purityDeductionController,
    required this.returnPolicyController,
    required this.buybackPolicyController,
    required this.onInputChanged,
    required this.onReturnModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsivePair(
          first: _TextInput(
            label: 'Return Window',
            helper: '0 means no return allowed',
            suffix: 'days',
            controller: returnWindowController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => onInputChanged(
              input.copyWith(returnWindowDays: value),
            ),
          ),
          second: _SelectInput(
            label: 'Return Mode',
            value: model.returnMode,
            items: ReturnModeOptions.all,
            accent: accent,
            onChanged: onReturnModeChanged,
          ),
        ),
        const SizedBox(height: 14),
        _ResponsivePair(
          first: _TextInput(
            label: 'Handling Charge',
            helper: 'Deducted during return settlement',
            suffix: '%',
            controller: handlingChargeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalInputFormatter()],
            onChanged: (value) => onInputChanged(
              input.copyWith(handlingChargePercent: value),
            ),
          ),
          second: _TextInput(
            label: 'Buyback Rate',
            helper: 'Percentage of the current market rate',
            suffix: '%',
            controller: buybackRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalInputFormatter()],
            onChanged: (value) => onInputChanged(
              input.copyWith(buybackRatePercent: value),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Purity Deduction',
          helper: 'Testing or refining loss deducted during buyback',
          suffix: '%',
          controller: purityDeductionController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_DecimalInputFormatter()],
          onChanged: (value) => onInputChanged(
            input.copyWith(buybackPurityDeductPercent: value),
          ),
        ),
        const SizedBox(height: 14),
        _ResponsivePair(
          first: _TextInput(
            label: 'Return Policy Note',
            helper: 'Printed or referenced for return handling',
            controller: returnPolicyController,
            maxLines: 4,
            onChanged: (value) => onInputChanged(
              input.copyWith(returnPolicyText: value),
            ),
          ),
          second: _TextInput(
            label: 'Buyback Policy Note',
            helper: 'Customer-facing buyback terms',
            controller: buybackPolicyController,
            maxLines: 4,
            onChanged: (value) => onInputChanged(
              input.copyWith(buybackPolicyText: value),
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsAndPrintFields extends StatelessWidget {
  final SalesBillingModel model;
  final SalesBillingPolicyInput input;
  final Color accent;
  final TextEditingController termsController;
  final TextEditingController footerController;
  final ValueChanged<SalesBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onTemplateChanged;
  final ValueChanged<bool> onPrintTermsChanged;
  final ValueChanged<bool> onPrintReturnPolicyChanged;
  final ValueChanged<bool> onPrintBuybackPolicyChanged;
  final ValueChanged<bool> onPrintFooterChanged;

  const _TermsAndPrintFields({
    required this.model,
    required this.input,
    required this.accent,
    required this.termsController,
    required this.footerController,
    required this.onInputChanged,
    required this.onTemplateChanged,
    required this.onPrintTermsChanged,
    required this.onPrintReturnPolicyChanged,
    required this.onPrintBuybackPolicyChanged,
    required this.onPrintFooterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextInput(
          label: 'Terms and Conditions',
          helper: 'Printed on the selected metal invoice',
          controller: termsController,
          maxLines: 5,
          onChanged: (value) => onInputChanged(
            input.copyWith(termsAndConditions: value),
          ),
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Footer Message',
          helper: 'Customer-facing message at the bottom of the invoice',
          controller: footerController,
          maxLines: 2,
          onChanged: (value) => onInputChanged(
            input.copyWith(footerMessage: value),
          ),
        ),
        const SizedBox(height: 14),
        _SelectInput(
          label: 'Print Template',
          value: model.selectedTemplate,
          items: TemplateOptions.all,
          itemLabel: TemplateOptions.labelFor,
          accent: accent,
          onChanged: onTemplateChanged,
        ),
        const SizedBox(height: 14),
        _PrintVisibilityGrid(
          model: model,
          accent: accent,
          onPrintTermsChanged: onPrintTermsChanged,
          onPrintReturnPolicyChanged: onPrintReturnPolicyChanged,
          onPrintBuybackPolicyChanged: onPrintBuybackPolicyChanged,
          onPrintFooterChanged: onPrintFooterChanged,
        ),
      ],
    );
  }
}

class _PrintVisibilityGrid extends StatelessWidget {
  final SalesBillingModel model;
  final Color accent;
  final ValueChanged<bool> onPrintTermsChanged;
  final ValueChanged<bool> onPrintReturnPolicyChanged;
  final ValueChanged<bool> onPrintBuybackPolicyChanged;
  final ValueChanged<bool> onPrintFooterChanged;

  const _PrintVisibilityGrid({
    required this.model,
    required this.accent,
    required this.onPrintTermsChanged,
    required this.onPrintReturnPolicyChanged,
    required this.onPrintBuybackPolicyChanged,
    required this.onPrintFooterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      SalesBillingToggleTile(
        label: 'Print Terms',
        description: 'Include terms and conditions on invoice print.',
        value: model.printTermsAndConditions,
        accent: accent,
        onChanged: onPrintTermsChanged,
      ),
      SalesBillingToggleTile(
        label: 'Print Return Policy',
        description: 'Include return policy copy on invoice print.',
        value: model.printReturnPolicy,
        accent: accent,
        onChanged: onPrintReturnPolicyChanged,
      ),
      SalesBillingToggleTile(
        label: 'Print Buyback Policy',
        description: 'Include buyback policy copy on invoice print.',
        value: model.printBuybackPolicy,
        accent: accent,
        onChanged: onPrintBuybackPolicyChanged,
      ),
      SalesBillingToggleTile(
        label: 'Print Footer',
        description: 'Include footer message on invoice print.',
        value: model.printFooterMessage,
        accent: accent,
        onChanged: onPrintFooterChanged,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 660 ? 2 : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map((item) => SizedBox(width: itemWidth, child: item))
              .toList(growable: false),
        );
      },
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsivePair({
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 660) {
          return Column(
            children: [
              first,
              const SizedBox(height: 14),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  final String label;
  final String? helper;
  final String? suffix;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _TextInput({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.helper,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: BillingSetupColors.textBody,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 3),
          Text(
            helper!,
            style: GoogleFonts.inter(
              color: BillingSetupColors.textHint,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            color: BillingSetupColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            suffixText: suffix,
            filled: true,
            fillColor: BillingSetupColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BillingSetupColors.salesBrand,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectInput extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final String Function(String value)? itemLabel;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _SelectInput({
    required this.label,
    required this.value,
    required this.items,
    required this.accent,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: BillingSetupColors.textBody,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: BillingSetupColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.4),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(itemLabel?.call(item) ?? item),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (RegExp(r'^\d{0,3}(\.\d{0,2})?$').hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}
