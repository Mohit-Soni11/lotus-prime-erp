import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
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
  final TextEditingController lateReclaimPenaltyController;
  final TextEditingController highValueThresholdController;
  final TextEditingController highValuePenaltyPercentController;
  final TextEditingController termsController;
  final TextEditingController sellerDeclarationController;
  final TextEditingController returnPolicyController;
  final TextEditingController buybackPolicyController;
  final TextEditingController footerController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;
  final void Function(PurchaseBillingFieldKey key, bool value) onFieldChanged;

  const PurchaseBillingPolicyForm({
    super.key,
    required this.model,
    required this.input,
    required this.returnWindowController,
    required this.lateReclaimPenaltyController,
    required this.highValueThresholdController,
    required this.highValuePenaltyPercentController,
    required this.termsController,
    required this.sellerDeclarationController,
    required this.returnPolicyController,
    required this.buybackPolicyController,
    required this.footerController,
    required this.onInputChanged,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PurchaseBillingVisuals.accentFor(model.metal);

    return Column(
      children: [
        PurchaseBillingSectionCard(
          title: 'Customer Metal Purchase Display',
          subtitle: 'Choose the fields printed on each metal purchase row',
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
          title: 'Customer Metal Purchase Policy',
          subtitle: 'Control reclaim limits, penalty rules and valuation copy',
          icon: Icons.verified_user_outlined,
          accent: accent,
          child: _PolicyFields(
            input: input,
            returnWindowController: returnWindowController,
            lateReclaimPenaltyController: lateReclaimPenaltyController,
            highValueThresholdController: highValueThresholdController,
            highValuePenaltyPercentController:
                highValuePenaltyPercentController,
            returnPolicyController: returnPolicyController,
            buybackPolicyController: buybackPolicyController,
            onInputChanged: onInputChanged,
          ),
        ),
        const SizedBox(height: 16),
        PurchaseBillingSectionCard(
          title: 'Bilingual Terms & Declaration',
          subtitle:
              'English and Hindi seller declaration, ownership transfer and footer copy',
          icon: Icons.article_outlined,
          accent: accent,
          child: _TermsAndFooterFields(
            input: input,
            termsController: termsController,
            sellerDeclarationController: sellerDeclarationController,
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
  final PurchaseBillingPolicyInput input;
  final TextEditingController returnWindowController;
  final TextEditingController lateReclaimPenaltyController;
  final TextEditingController highValueThresholdController;
  final TextEditingController highValuePenaltyPercentController;
  final TextEditingController returnPolicyController;
  final TextEditingController buybackPolicyController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;

  const _PolicyFields({
    required this.input,
    required this.returnWindowController,
    required this.lateReclaimPenaltyController,
    required this.highValueThresholdController,
    required this.highValuePenaltyPercentController,
    required this.returnPolicyController,
    required this.buybackPolicyController,
    required this.onInputChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PolicyControlGrid(
          children: [
            _TextInput(
              label: 'Seller Reclaim Window',
              helper: 'Sold item reclaim allowed only within this period',
              suffix: 'days',
              controller: returnWindowController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => onInputChanged(
                input.copyWith(returnWindowDays: value),
              ),
            ),
            _TextInput(
              label: 'Flat Late Penalty',
              helper: 'Low-value late reclaim exception charge',
              prefix: 'Rs.',
              controller: lateReclaimPenaltyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [
                _DecimalInputFormatter(maxIntegerDigits: 10),
              ],
              onChanged: (value) => onInputChanged(
                input.copyWith(lateReclaimPenaltyAmount: value),
              ),
            ),
            _TextInput(
              label: 'High-Value Threshold',
              helper: 'Above this payout, percentage penalty applies',
              prefix: 'Rs.',
              controller: highValueThresholdController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [
                _DecimalInputFormatter(maxIntegerDigits: 10),
              ],
              onChanged: (value) => onInputChanged(
                input.copyWith(highValueReclaimThreshold: value),
              ),
            ),
            _TextInput(
              label: 'High-Value Penalty',
              helper: 'Penalty percentage for high-value late reclaim',
              suffix: '%',
              controller: highValuePenaltyPercentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [
                _DecimalInputFormatter(maxIntegerDigits: 3),
              ],
              onChanged: (value) => onInputChanged(
                input.copyWith(highValueReclaimPenaltyPercent: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ResponsivePair(
          first: _TextInput(
            label: 'Seller Reclaim Policy',
            helper: '1-day sold item reclaim policy and penalty terms',
            hintText:
                'Example:\nSeller may request return of the sold item only within 1 day from the voucher date.\nविक्रेता voucher date से सिर्फ 1 दिन के अंदर sold item return request कर सकता/सकती है.\n\nAfter 1 day, the item will not be returned. Approved exception will attract the configured penalty.\n1 दिन के बाद item return नहीं होगा. Approved exception पर configured penalty लगेगी.',
            controller: returnPolicyController,
            maxLines: 8,
            onChanged: (value) => onInputChanged(
              input.copyWith(returnPolicyText: value),
            ),
          ),
          second: _TextInput(
            label: 'Valuation & Payout Note',
            helper:
                'Dynamic item-wise valuation copy, no fixed deduction promise',
            hintText:
                'Example:\nFinal payout is based on verified fine weight, purchase rate, item condition and applicable item-wise deductions.\nFinal payout verified fine weight, purchase rate, item condition और applicable deductions पर based होगा.\n\nStone, dust, wax, thread, non-metal parts, testing loss or melting loss may be deducted before payout.\nPayout से पहले stone, dust, wax, thread, non-metal parts, testing loss या melting loss deduct हो सकता है.',
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
}

class _TermsAndFooterFields extends StatelessWidget {
  final PurchaseBillingPolicyInput input;
  final TextEditingController termsController;
  final TextEditingController sellerDeclarationController;
  final TextEditingController footerController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;

  const _TermsAndFooterFields({
    required this.input,
    required this.termsController,
    required this.sellerDeclarationController,
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
          label: 'Seller Ownership Declaration',
          helper:
              'Separate customer declaration for ownership, police and legal responsibility',
          hintText:
              'Example:\nSeller declares that the item is lawful property and free from theft, dispute, pledge or third-party claim.\nविक्रेता घोषणा करता/करती है कि item उसका वैध स्वामित्व है और theft, dispute, pledge या third-party claim से मुक्त है.\n\nIf the item is later found stolen or disputed, seller accepts full responsibility and will cooperate with police/legal authorities.\nयदि item बाद में stolen या disputed पाया जाता है, तो पूरी जिम्मेदारी विक्रेता की होगी और वह police/legal authorities के साथ cooperate करेगा/करेगी.',
          controller: sellerDeclarationController,
          maxLines: 9,
          onChanged: (value) => onInputChanged(
            input.copyWith(sellerDeclarationText: value),
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
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 820
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
  final String? prefix;
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
    this.prefix,
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
            prefixText: prefix,
            prefixStyle: GoogleFonts.inter(
              color: BillingSetupColors.textDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
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

class _DecimalInputFormatter extends TextInputFormatter {
  final int maxIntegerDigits;

  const _DecimalInputFormatter({
    required this.maxIntegerDigits,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final pattern = RegExp(
      '^\\d{0,$maxIntegerDigits}(\\.\\d{0,2})?\$',
    );
    if (pattern.hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}
