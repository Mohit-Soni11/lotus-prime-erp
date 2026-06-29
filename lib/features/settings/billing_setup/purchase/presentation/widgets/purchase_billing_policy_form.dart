import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../../../../../theme/settings/billing_setup/billing_setup_colors.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final accent = PurchaseBillingVisuals.accentFor(model.metal);

    return Column(
      children: [
        PurchaseBillingSectionCard(
          title: 'Purchase Voucher Display',
          subtitle: 'Choose the fields printed on each purchase row',
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
          title: 'Seller Purchase Policy',
          subtitle:
              'Control KYC, ownership checks, purity deductions and payout copy',
          icon: Icons.verified_user_outlined,
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
          title: 'Bilingual Terms & Footer',
          subtitle:
              'English and Hindi purchase voucher copy, written line by line',
          icon: Icons.article_outlined,
          accent: accent,
          child: _TermsAndFooterFields(
            input: input,
            termsController: termsController,
            footerController: footerController,
            onInputChanged: onInputChanged,
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
        _PolicyControlGrid(
          children: [
            _TextInput(
              label: 'Verification Window',
              helper: 'Time allowed for ownership, purity and payout review',
              suffix: 'days',
              controller: returnWindowController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => onInputChanged(
                input.copyWith(returnWindowDays: value),
              ),
            ),
            _SelectInput(
              label: 'Settlement Mode',
              helper: 'Customer payout or adjustment method',
              value: model.returnMode,
              items: PurchaseReturnModeOptions.all,
              itemLabel: _purchaseReturnModeLabel,
              accent: accent,
              onChanged: onReturnModeChanged,
            ),
            _TextInput(
              label: 'Purity / Melting Deduction',
              helper: 'Testing, melting or impurity deduction',
              suffix: '%',
              controller: purityDeductionController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_DecimalInputFormatter()],
              onChanged: (value) => onInputChanged(
                input.copyWith(purityDeductPercent: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ResponsivePair(
          first: _TextInput(
            label: 'Ownership & Verification Note',
            helper: 'English and Hindi print copy for customer-sold jewellery',
            hintText:
                'Example:\nSeller confirms that the jewellery is legally owned and free from dispute.\nविक्रेता पुष्टि करता है कि आभूषण उसका वैध स्वामित्व है और किसी विवाद से मुक्त है.\n\nFinal acceptance is subject to KYC, weight and purity verification.\nअंतिम स्वीकृति KYC, वजन और शुद्धता जांच के बाद होगी.',
            controller: returnPolicyController,
            maxLines: 8,
            onChanged: (value) => onInputChanged(
              input.copyWith(returnPolicyText: value),
            ),
          ),
          second: _TextInput(
            label: 'Valuation & Payout Note',
            helper:
                'English and Hindi print copy for rate, deduction and payout',
            hintText:
                'Example:\nPurchase value is calculated on verified net weight, purity and live purchase rate.\nखरीद मूल्य verified net weight, शुद्धता और live purchase rate के आधार पर calculated होगा.\n\nTesting, melting, stone, dust or impurity deductions may apply before payout.\nPayout से पहले testing, melting, stone, dust या impurity deduction लागू हो सकती है.',
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

  String _purchaseReturnModeLabel(String value) {
    switch (value) {
      case PurchaseReturnModeOptions.exchange:
        return 'Exchange against new jewellery';
      case PurchaseReturnModeOptions.creditNote:
        return 'Store credit / customer ledger';
      case PurchaseReturnModeOptions.cashRefund:
        return 'Cash or bank payout';
      default:
        return value;
    }
  }
}

class _TermsAndFooterFields extends StatelessWidget {
  final PurchaseBillingPolicyInput input;
  final TextEditingController termsController;
  final TextEditingController footerController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;

  const _TermsAndFooterFields({
    required this.input,
    required this.termsController,
    required this.footerController,
    required this.onInputChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextInput(
          label: 'Terms and Conditions',
          helper: 'English and Hindi print copy, one point per line',
          hintText:
              'Example:\nSeller must provide valid identity proof before payout.\nPayout से पहले विक्रेता को valid identity proof देना आवश्यक है.\n\nOnce payment is completed, the purchase is treated as final.\nभुगतान पूरा होने के बाद purchase final माना जाएगा.',
          controller: termsController,
          maxLines: 9,
          onChanged: (value) => onInputChanged(
            input.copyWith(termsAndConditions: value),
          ),
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Footer Message',
          helper: 'Short English and Hindi footer printed at voucher bottom',
          hintText:
              'Thank you for trusting us.\nहम पर भरोसा करने के लिए धन्यवाद.',
          controller: footerController,
          maxLines: 4,
          onChanged: (value) => onInputChanged(
            input.copyWith(footerMessage: value),
          ),
        ),
      ],
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
        final columns = constraints.maxWidth >= 900
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
                color: BillingSetupColors.purchaseBrand,
                width: 1.6,
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
                    style: GoogleFonts.inter(
                      color: BillingSetupColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
