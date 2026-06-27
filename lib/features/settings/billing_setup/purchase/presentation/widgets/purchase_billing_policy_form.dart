import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../presentation/theme/billing_setup_design_tokens.dart';
import '../../domain/purchase_billing_metal_profile.dart';
import '../../domain/purchase_billing_policy_input.dart';
import 'purchase_billing_section_card.dart';
import 'purchase_billing_toggle_tile.dart';
import 'purchase_billing_visuals.dart';

class PurchaseBillingPolicyForm extends StatelessWidget {
  final PurchaseBillingModel model;
  final PurchaseBillingPolicyInput input;
  final TextEditingController returnWindowController;
  final TextEditingController purityDeductionController;
  final TextEditingController termsController;
  final TextEditingController returnPolicyController;
  final TextEditingController buybackPolicyController;
  final TextEditingController footerController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onReturnModeChanged;
  final void Function(PurchaseBillingFieldKey key, bool value) onFieldChanged;
  final ValueChanged<String> onTemplateChanged;

  const PurchaseBillingPolicyForm({
    super.key,
    required this.model,
    required this.input,
    required this.returnWindowController,
    required this.purityDeductionController,
    required this.termsController,
    required this.returnPolicyController,
    required this.buybackPolicyController,
    required this.footerController,
    required this.onInputChanged,
    required this.onReturnModeChanged,
    required this.onFieldChanged,
    required this.onTemplateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PurchaseBillingVisuals.accentFor(model.metal);

    return Column(
      children: [
        PurchaseBillingSectionCard(
          title: 'Purchase Voucher Display',
          subtitle:
              'Choose the fields printed on ${BillingMetal.displayName(model.metal)} purchase vouchers.',
          icon: Icons.request_quote_outlined,
          accent: accent,
          child: _DisplayFieldGrid(
            model: model,
            accent: accent,
            onFieldChanged: onFieldChanged,
          ),
        ),
        const SizedBox(height: 16),
        PurchaseBillingSectionCard(
          title: 'Return and Purity Policy',
          subtitle:
              'Control return mode, deduction rules, and settlement policy copy.',
          icon: Icons.assignment_return_outlined,
          accent: accent,
          child: _PolicyFields(
            model: model,
            input: input,
            accent: accent,
            returnWindowController: returnWindowController,
            purityDeductionController: purityDeductionController,
            returnPolicyController: returnPolicyController,
            buybackPolicyController: buybackPolicyController,
            onInputChanged: onInputChanged,
            onReturnModeChanged: onReturnModeChanged,
          ),
        ),
        const SizedBox(height: 16),
        PurchaseBillingSectionCard(
          title: 'Terms, Footer, and Template',
          subtitle:
              'Manage purchase voucher terms, footer copy, and print template.',
          icon: Icons.article_outlined,
          accent: accent,
          child: _TermsAndTemplateFields(
            model: model,
            input: input,
            accent: accent,
            termsController: termsController,
            footerController: footerController,
            onInputChanged: onInputChanged,
            onTemplateChanged: onTemplateChanged,
          ),
        ),
      ],
    );
  }
}

class _DisplayFieldGrid extends StatelessWidget {
  final PurchaseBillingModel model;
  final Color accent;
  final void Function(PurchaseBillingFieldKey key, bool value) onFieldChanged;

  const _DisplayFieldGrid({
    required this.model,
    required this.accent,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fields = PurchaseBillingMetalProfiles.fieldsFor(model.metal);

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
                  child: PurchaseBillingToggleTile(
                    label: field.label,
                    description: field.description,
                    value: PurchaseBillingMetalProfiles.valueFor(
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
  final PurchaseBillingModel model;
  final PurchaseBillingPolicyInput input;
  final Color accent;
  final TextEditingController returnWindowController;
  final TextEditingController purityDeductionController;
  final TextEditingController returnPolicyController;
  final TextEditingController buybackPolicyController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onReturnModeChanged;

  const _PolicyFields({
    required this.model,
    required this.input,
    required this.accent,
    required this.returnWindowController,
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
            helper: '0 means no purchase return allowed',
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
            items: PurchaseReturnModeOptions.all,
            accent: accent,
            onChanged: onReturnModeChanged,
          ),
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Purity Deduction',
          helper: 'Quality, testing, or refining deduction on settlement',
          suffix: '%',
          controller: purityDeductionController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_DecimalInputFormatter()],
          onChanged: (value) => onInputChanged(
            input.copyWith(purityDeductPercent: value),
          ),
        ),
        const SizedBox(height: 14),
        _ResponsivePair(
          first: _TextInput(
            label: 'Return Policy Note',
            helper: 'Printed or referenced for purchase return handling',
            controller: returnPolicyController,
            maxLines: 4,
            onChanged: (value) => onInputChanged(
              input.copyWith(returnPolicyText: value),
            ),
          ),
          second: _TextInput(
            label: 'Settlement Policy Note',
            helper: 'Supplier-facing settlement or buyback terms',
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

class _TermsAndTemplateFields extends StatelessWidget {
  final PurchaseBillingModel model;
  final PurchaseBillingPolicyInput input;
  final Color accent;
  final TextEditingController termsController;
  final TextEditingController footerController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onTemplateChanged;

  const _TermsAndTemplateFields({
    required this.model,
    required this.input,
    required this.accent,
    required this.termsController,
    required this.footerController,
    required this.onInputChanged,
    required this.onTemplateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextInput(
          label: 'Terms and Conditions',
          helper: 'Printed on the selected metal purchase voucher',
          controller: termsController,
          maxLines: 5,
          onChanged: (value) => onInputChanged(
            input.copyWith(termsAndConditions: value),
          ),
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Footer Message',
          helper: 'Optional voucher footer message',
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
      ],
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
          style: const TextStyle(
            color: BillingSetupDesignTokens.textStrong,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 3),
          Text(
            helper!,
            style: const TextStyle(
              color: BillingSetupDesignTokens.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
          style: const TextStyle(
            color: BillingSetupDesignTokens.textStrong,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            suffixText: suffix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: BillingSetupDesignTokens.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: BillingSetupDesignTokens.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: BillingSetupDesignTokens.purchase,
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
          style: const TextStyle(
            color: BillingSetupDesignTokens.textStrong,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: BillingSetupDesignTokens.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: BillingSetupDesignTokens.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
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
