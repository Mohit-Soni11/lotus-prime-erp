import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../../../../../../theme/settings/billing_setup/billing_setup_strings.dart';
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
  final ValueChanged<bool> onPrintTermsChanged;
  final ValueChanged<bool> onPrintReturnPolicyChanged;
  final ValueChanged<bool> onPrintBuybackPolicyChanged;
  final ValueChanged<bool> onPrintFooterChanged;
  final ValueChanged<String> onTemplateChanged;

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
    required this.onPrintTermsChanged,
    required this.onPrintReturnPolicyChanged,
    required this.onPrintBuybackPolicyChanged,
    required this.onPrintFooterChanged,
    required this.onTemplateChanged,
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
          subtitle:
              'Control eligibility, deductions, settlement mode and bilingual invoice copy',
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
          title: 'Bilingual Terms & Footer',
          subtitle:
              'English and Hindi customer copy printed line by line on the bill',
          icon: Icons.article_outlined,
          accent: accent,
          child: _TermsAndPrintFields(
            model: model,
            input: input,
            accent: accent,
            termsController: termsController,
            footerController: footerController,
            onInputChanged: onInputChanged,
            onPrintTermsChanged: onPrintTermsChanged,
            onPrintReturnPolicyChanged: onPrintReturnPolicyChanged,
            onPrintBuybackPolicyChanged: onPrintBuybackPolicyChanged,
            onPrintFooterChanged: onPrintFooterChanged,
          ),
        ),
        const SizedBox(height: 16),
        SalesBillingSectionCard(
          title: 'Invoice Design Template',
          subtitle: 'Choose the default PDF layout used by new sales invoices',
          icon: Icons.design_services_outlined,
          accent: accent,
          child: _TemplateFields(
            model: model,
            accent: accent,
            onTemplateChanged: onTemplateChanged,
          ),
        ),
      ],
    );
  }
}

class _TemplateFields extends StatelessWidget {
  final SalesBillingModel model;
  final Color accent;
  final ValueChanged<String> onTemplateChanged;

  const _TemplateFields({
    required this.model,
    required this.accent,
    required this.onTemplateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SelectInput(
          label: BillingSetupStrings.lblTemplate,
          helper:
              'Saved per metal and applied automatically in New Sales invoice preview.',
          value: model.selectedTemplate,
          items: TemplateOptions.all,
          itemLabel: TemplateOptions.labelFor,
          accent: accent,
          onChanged: onTemplateChanged,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TemplateOptions.all
              .map(
                (templateId) => _TemplateStatusChip(
                  label: TemplateOptions.labelFor(templateId),
                  selected: templateId == model.selectedTemplate,
                  accent: accent,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _TemplateStatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;

  const _TemplateStatusChip({
    required this.label,
    required this.selected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.42)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: selected ? accent : BillingSetupColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? accent : BillingSetupColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
        _PolicyControlGrid(
          children: [
            _TextInput(
              label: 'Return Window',
              helper: 'Operational return period',
              suffix: 'days',
              controller: returnWindowController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => onInputChanged(
                input.copyWith(returnWindowDays: value),
              ),
            ),
            _SelectInput(
              label: 'Return Mode',
              helper: 'Customer settlement option',
              value: model.returnMode,
              items: ReturnModeOptions.all,
              itemLabel: _returnModeLabel,
              accent: accent,
              onChanged: onReturnModeChanged,
            ),
            _TextInput(
              label: 'Handling Charge',
              helper: 'Making or restocking deduction',
              suffix: '%',
              controller: handlingChargeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_DecimalInputFormatter()],
              onChanged: (value) => onInputChanged(
                input.copyWith(handlingChargePercent: value),
              ),
            ),
            _TextInput(
              label: 'Buyback Rate',
              helper: 'Market-rate settlement value',
              suffix: '%',
              controller: buybackRateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_DecimalInputFormatter()],
              onChanged: (value) => onInputChanged(
                input.copyWith(buybackRatePercent: value),
              ),
            ),
            _TextInput(
              label: 'Purity Deduction',
              helper: 'Testing or refining deduction',
              suffix: '%',
              controller: purityDeductionController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_DecimalInputFormatter()],
              onChanged: (value) => onInputChanged(
                input.copyWith(buybackPurityDeductPercent: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ResponsivePair(
          first: _TextInput(
            label: 'Return Policy Note',
            helper: 'English and Hindi print copy for return rules',
            hintText:
                'Example:\nExchange and refund both are available within 24 hours.\n24 घंटे के अंदर एक्सचेंज और रिफंड दोनों उपलब्ध हैं.\n\nDamaged items may attract making charge deduction.\nटूटी हुई वस्तु पर मेकिंग चार्ज काटा जा सकता है.',
            controller: returnPolicyController,
            maxLines: 8,
            onChanged: (value) => onInputChanged(
              input.copyWith(returnPolicyText: value),
            ),
          ),
          second: _TextInput(
            label: 'Buyback Policy Note',
            helper: 'English and Hindi print copy for buyback rules',
            hintText:
                'Example:\nBuyback value depends on purity, rate and item condition.\nबायबैक मूल्य शुद्धता, दर और वस्तु की स्थिति पर निर्भर करेगा.\n\nFinal settlement is confirmed after inspection.\nअंतिम भुगतान जांच के बाद तय होगा.',
            controller: buybackPolicyController,
            maxLines: 8,
            onChanged: (value) => onInputChanged(
              input.copyWith(buybackPolicyText: value),
            ),
          ),
        ),
      ],
    );
  }

  String _returnModeLabel(String value) {
    switch (value) {
      case ReturnModeOptions.exchangeOnly:
        return 'Exchange only';
      case ReturnModeOptions.refund:
        return 'Refund available';
      case ReturnModeOptions.both:
        return 'Exchange and refund both are available';
      default:
        return value;
    }
  }
}

class _TermsAndPrintFields extends StatelessWidget {
  final SalesBillingModel model;
  final SalesBillingPolicyInput input;
  final Color accent;
  final TextEditingController termsController;
  final TextEditingController footerController;
  final ValueChanged<SalesBillingPolicyInput> onInputChanged;
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
          helper: 'English and Hindi print copy, one point per line',
          hintText:
              'Example:\nOriginal bill is mandatory for service claims.\nसेवा दावे के लिए मूल बिल आवश्यक है.\n\nItems damaged after purchase are not eligible for return.\nखरीद के बाद क्षतिग्रस्त वस्तु रिटर्न के लिए मान्य नहीं होगी.',
          controller: termsController,
          maxLines: 9,
          onChanged: (value) => onInputChanged(
            input.copyWith(termsAndConditions: value),
          ),
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Footer Message',
          helper: 'Short English and Hindi footer printed at bill bottom',
          hintText:
              'Thank you for shopping with us! Visit us again.\nखरीदारी के लिए धन्यवाद! फिर पधारें.',
          controller: footerController,
          maxLines: 4,
          onChanged: (value) => onInputChanged(
            input.copyWith(footerMessage: value),
          ),
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

class _PolicyControlGrid extends StatelessWidget {
  final List<Widget> children;

  const _PolicyControlGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 5
            : constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 620
                    ? 2
                    : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: _PolicyControlCard(child: child),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PolicyControlCard extends StatelessWidget {
  final Widget child;

  const _PolicyControlCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: child,
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
  final String? hintText;
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
    this.hintText,
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
              color: const Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            color: BillingSetupColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            suffixText: suffix,
            suffixStyle: GoogleFonts.inter(
              color: BillingSetupColors.textDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: BillingSetupColors.salesBrand, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectInput extends StatelessWidget {
  final String label;
  final String? helper;
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
    this.helper,
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
        if (helper != null) ...[
          const SizedBox(height: 3),
          Text(
            helper!,
            style: GoogleFonts.inter(
              color: const Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          isExpanded: true,
          dropdownColor: Colors.white,
          menuMaxHeight: 320,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
          style: GoogleFonts.inter(
            color: BillingSetupColors.textDark,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
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
                  child: Text(
                    itemLabel?.call(item) ?? item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: BillingSetupColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          selectedItemBuilder: (context) {
            return items
                .map(
                  (item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      itemLabel?.call(item) ?? item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: BillingSetupColors.textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(growable: false);
          },
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
