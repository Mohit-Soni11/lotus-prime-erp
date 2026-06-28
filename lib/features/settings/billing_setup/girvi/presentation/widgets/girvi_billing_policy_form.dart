import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_options.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_policy_input.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_colors.dart';
import 'package:lotus_erp/ui/settings/billing_setup/girvi_invoice_display_editor.dart';

import 'girvi_billing_section_card.dart';

class GirviBillingPolicyForm extends StatelessWidget {
  final GirviBillingModel model;
  final GirviBillingPolicyInput input;
  final String selectedInvoiceMetal;
  final TextEditingController prefixController;
  final TextEditingController startingNumberController;
  final TextEditingController interestRateController;
  final TextEditingController gracePeriodController;
  final TextEditingController reminderDaysController;
  final TextEditingController noticeDaysController;
  final TextEditingController termsController;
  final TextEditingController termsHindiController;
  final TextEditingController declarationController;
  final TextEditingController declarationHindiController;
  final TextEditingController footerController;
  final ValueChanged<GirviBillingPolicyInput> onInputChanged;
  final ValueChanged<GirviBillingModel> onModelChanged;
  final ValueChanged<String> onInvoiceMetalChanged;
  final ValueChanged<String> onInterestTypeChanged;
  final ValueChanged<String> onDefaultDurationChanged;
  final ValueChanged<String> onTemplateChanged;
  final ValueChanged<bool> onAutoPrintChanged;

  const GirviBillingPolicyForm({
    super.key,
    required this.model,
    required this.input,
    required this.selectedInvoiceMetal,
    required this.prefixController,
    required this.startingNumberController,
    required this.interestRateController,
    required this.gracePeriodController,
    required this.reminderDaysController,
    required this.noticeDaysController,
    required this.termsController,
    required this.termsHindiController,
    required this.declarationController,
    required this.declarationHindiController,
    required this.footerController,
    required this.onInputChanged,
    required this.onModelChanged,
    required this.onInvoiceMetalChanged,
    required this.onInterestTypeChanged,
    required this.onDefaultDurationChanged,
    required this.onTemplateChanged,
    required this.onAutoPrintChanged,
  });

  @override
  Widget build(BuildContext context) {
    final templates = PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.girviReceipt,
    );

    return Column(
      children: [
        GirviBillingSectionCard(
          title: 'Ticket Numbering',
          subtitle: 'Set the next Girvi ticket prefix, sequence and template',
          icon: Icons.confirmation_number_outlined,
          accent: BillingSetupColors.girviBrand,
          child: _ResponsiveFields(
            children: [
              _InputField(
                label: 'Ticket Prefix',
                hint: 'e.g. GRV-',
                subtitle: 'Printed before the ticket number',
                controller: prefixController,
                accent: BillingSetupColors.girviBrand,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => onInputChanged(
                  input.copyWith(girviPrefix: value),
                ),
              ),
              _InputField(
                label: 'Starting Number',
                hint: 'e.g. 1',
                subtitle: 'Next Girvi sequence',
                controller: startingNumberController,
                accent: BillingSetupColors.girviBrand,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onInputChanged(
                  input.copyWith(startingNumber: value),
                ),
              ),
              _DropdownField(
                label: 'Receipt Template',
                value: PrintTemplateRegistry.byId(model.selectedTemplate).id,
                items: templates.map((template) => template.id).toList(),
                labelFor: PrintTemplateRegistry.labelFor,
                accent: BillingSetupColors.girviBrand,
                onChanged: onTemplateChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GirviBillingSectionCard(
          title: 'Interest Rules',
          subtitle: 'Define how pledge interest is calculated',
          icon: Icons.percent_rounded,
          accent: BillingSetupColors.grvInterest,
          child: Column(
            children: [
              _ResponsiveFields(
                children: [
                  _InputField(
                    label: 'Interest Rate (% / month)',
                    hint: 'e.g. 1.5',
                    controller: interestRateController,
                    accent: BillingSetupColors.grvInterest,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => onInputChanged(
                      input.copyWith(defaultInterestRate: value),
                    ),
                  ),
                  _DropdownField(
                    label: 'Interest Type',
                    value: model.interestType,
                    items: GirviBillingOptions.interestTypes,
                    accent: BillingSetupColors.grvInterest,
                    onChanged: onInterestTypeChanged,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ResponsiveFields(
                children: [
                  _InputField(
                    label: 'Grace Period (Days)',
                    hint: 'e.g. 3',
                    subtitle: 'Extra days after due date',
                    controller: gracePeriodController,
                    accent: BillingSetupColors.grvInterest,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => onInputChanged(
                      input.copyWith(gracePeriodDays: value),
                    ),
                  ),
                  _DropdownField(
                    label: 'Default Loan Duration',
                    value: model.defaultDuration,
                    items: GirviBillingOptions.durations,
                    accent: BillingSetupColors.grvInterest,
                    onChanged: onDefaultDurationChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GirviBillingSectionCard(
          title: 'Reminder & Notice Period',
          subtitle: 'Set reminder timing and legal notice window',
          icon: Icons.notifications_outlined,
          accent: BillingSetupColors.grvNotice,
          child: _ResponsiveFields(
            children: [
              _InputField(
                label: 'Reminder Days',
                hint: 'e.g. 15',
                subtitle: 'Before maturity',
                controller: reminderDaysController,
                accent: BillingSetupColors.grvNotice,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onInputChanged(
                  input.copyWith(reminderDays: value),
                ),
              ),
              _InputField(
                label: 'Notice Days',
                hint: 'e.g. 30',
                subtitle: 'After maturity',
                controller: noticeDaysController,
                accent: BillingSetupColors.grvNotice,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onInputChanged(
                  input.copyWith(noticeDays: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 320)
            .floor()
            .clamp(1, children.length)
            .toInt();
        const gap = 14.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final String? subtitle;
  final TextEditingController controller;
  final Color accent;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String> onChanged;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.accent,
    required this.onChanged,
    this.subtitle,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BillingSetupColors.textBody,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '- $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: BillingSetupColors.textHint,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
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

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final String Function(String value)? labelFor;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.accent,
    required this.onChanged,
    this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValue = items.contains(value) ? value : items.first;

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
        DropdownButtonFormField<String>(
          initialValue: resolvedValue,
          isExpanded: true,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(labelFor == null ? item : labelFor!(item)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          style: GoogleFonts.inter(
            fontSize: 13,
            color: BillingSetupColors.textDark,
          ),
          decoration: InputDecoration(
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
