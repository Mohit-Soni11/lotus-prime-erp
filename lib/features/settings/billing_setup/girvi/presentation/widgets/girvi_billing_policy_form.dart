import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_policy_input.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_colors.dart';
import 'package:lotus_erp/ui/settings/billing_setup/girvi_invoice_display_editor.dart';

import 'girvi_billing_section_card.dart';

class GirviBillingPolicyForm extends StatelessWidget {
  final GirviBillingModel model;
  final GirviBillingPolicyInput input;
  final String selectedInvoiceMetal;
  final TextEditingController termsController;
  final TextEditingController termsHindiController;
  final TextEditingController declarationController;
  final TextEditingController declarationHindiController;
  final TextEditingController footerController;
  final ValueChanged<GirviBillingPolicyInput> onInputChanged;
  final ValueChanged<GirviBillingModel> onModelChanged;
  final ValueChanged<String> onInvoiceMetalChanged;
  final ValueChanged<bool> onAutoPrintChanged;

  const GirviBillingPolicyForm({
    super.key,
    required this.model,
    required this.input,
    required this.selectedInvoiceMetal,
    required this.termsController,
    required this.termsHindiController,
    required this.declarationController,
    required this.declarationHindiController,
    required this.footerController,
    required this.onInputChanged,
    required this.onModelChanged,
    required this.onInvoiceMetalChanged,
    required this.onAutoPrintChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GirviBillingSectionCard(
          title: 'Invoice Item Display',
          subtitle:
              'Choose every item, weight and valuation field separately for each metal',
          icon: Icons.view_column_outlined,
          accent: BillingSetupColors.girviBrand,
          child: GirviInvoiceDisplayEditor(
            model: model,
            selectedMetal: selectedInvoiceMetal,
            onMetalChanged: onInvoiceMetalChanged,
            onChanged: onModelChanged,
          ),
        ),
        const SizedBox(height: 20),
        GirviBillingSectionCard(
          title: 'Customer Receipt Display',
          subtitle: 'Choose customer, loan, payment, KYC and remarks sections',
          icon: Icons.receipt_long_outlined,
          accent: BillingSetupColors.grvTerms,
          child: GirviInvoiceDocumentEditor(
            model: model,
            onChanged: onModelChanged,
          ),
        ),
        const SizedBox(height: 20),
        GirviBillingSectionCard(
          title: 'Terms, Footer & Operations',
          subtitle: 'Customer-facing print text and automatic printing',
          icon: Icons.article_outlined,
          accent: BillingSetupColors.grvTerms,
          child: Column(
            children: [
              _InputField(
                label: 'Terms & Conditions - English',
                hint: 'Enter one English condition per line...',
                controller: termsController,
                accent: BillingSetupColors.grvTerms,
                maxLines: 7,
                onChanged: (value) => onInputChanged(
                  input.copyWith(termsAndConditions: value),
                ),
              ),
              const SizedBox(height: 14),
              _InputField(
                label: 'Terms & Conditions - Hindi',
                hint:
                    'Enter matching Hindi conditions in the same line order...',
                controller: termsHindiController,
                accent: BillingSetupColors.grvTerms,
                maxLines: 7,
                onChanged: (value) => onInputChanged(
                  input.copyWith(termsAndConditionsHindi: value),
                ),
              ),
              const SizedBox(height: 14),
              _InputField(
                label: 'Customer Declaration - English',
                hint:
                    'Declaration acknowledged by the customer before signing...',
                controller: declarationController,
                accent: BillingSetupColors.grvTerms,
                maxLines: 5,
                onChanged: (value) => onInputChanged(
                  input.copyWith(customerDeclaration: value),
                ),
              ),
              const SizedBox(height: 14),
              _InputField(
                label: 'Customer Declaration - Hindi',
                hint: 'Customer declaration in Hindi for bilingual printing...',
                controller: declarationHindiController,
                accent: BillingSetupColors.grvTerms,
                maxLines: 5,
                onChanged: (value) => onInputChanged(
                  input.copyWith(customerDeclarationHindi: value),
                ),
              ),
              const SizedBox(height: 14),
              _InputField(
                label: 'Footer Message',
                hint:
                    'Optional customer message printed when Footer Message is enabled',
                controller: footerController,
                accent: BillingSetupColors.grvTerms,
                maxLines: 3,
                onChanged: (value) => onInputChanged(
                  input.copyWith(footerMessage: value),
                ),
              ),
              const SizedBox(height: 14),
              _AutoPrintTile(
                value: model.autoPrint,
                onChanged: onAutoPrintChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Color accent;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.accent,
    required this.onChanged,
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: BillingSetupColors.textBody,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: BillingSetupColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFD1D5DB),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            filled: true,
            fillColor: BillingSetupColors.inputBg,
          ),
        ),
      ],
    );
  }
}

class _AutoPrintTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AutoPrintTile({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto Print',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BillingSetupColors.textDark,
                ),
              ),
              Text(
                'Print the pledge ticket immediately after saving',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: BillingSetupColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: BillingSetupColors.grvTerms,
        ),
      ],
    );
  }
}
