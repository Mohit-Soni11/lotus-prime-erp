import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_options.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_policy_input.dart';
import 'package:lotus_erp/features/settings/billing_setup/presentation/theme/billing_setup_design_tokens.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/ui/settings/billing_setup/girvi_invoice_display_editor.dart';

import 'girvi_billing_section_card.dart';
import 'girvi_billing_toggle_tile.dart';

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
    const accent = BillingSetupDesignTokens.girvi;

    return Column(
      children: [
        GirviBillingSectionCard(
          title: 'Ticket and Interest Policy',
          subtitle:
              'Configure default pledge numbering, monthly interest, maturity, and notice rules.',
          icon: Icons.receipt_long_outlined,
          accent: accent,
          child: _TicketAndInterestFields(
            model: model,
            input: input,
            prefixController: prefixController,
            startingNumberController: startingNumberController,
            interestRateController: interestRateController,
            gracePeriodController: gracePeriodController,
            reminderDaysController: reminderDaysController,
            noticeDaysController: noticeDaysController,
            onInputChanged: onInputChanged,
            onInterestTypeChanged: onInterestTypeChanged,
            onDefaultDurationChanged: onDefaultDurationChanged,
          ),
        ),
        const SizedBox(height: 16),
        GirviBillingSectionCard(
          title: 'Pledged Item Table',
          subtitle:
              'Select item-level fields for each metal on the printed Girvi receipt.',
          icon: Icons.view_column_outlined,
          accent: const Color(0xFFD97706),
          child: GirviInvoiceDisplayEditor(
            model: model,
            selectedMetal: selectedInvoiceMetal,
            onMetalChanged: onInvoiceMetalChanged,
            onChanged: onModelChanged,
          ),
        ),
        const SizedBox(height: 16),
        GirviBillingSectionCard(
          title: 'Customer Receipt Sections',
          subtitle:
              'Control loan, payment, verification, terms, declaration, and footer visibility.',
          icon: Icons.fact_check_outlined,
          accent: const Color(0xFF374151),
          child: GirviInvoiceDocumentEditor(
            model: model,
            onChanged: onModelChanged,
          ),
        ),
        const SizedBox(height: 16),
        GirviBillingSectionCard(
          title: 'Legal Copy and Print Defaults',
          subtitle:
              'Maintain receipt terms, customer declaration, footer copy, template, and auto-print behavior.',
          icon: Icons.gavel_outlined,
          accent: const Color(0xFF9333EA),
          child: _LegalAndPrintFields(
            model: model,
            input: input,
            termsController: termsController,
            termsHindiController: termsHindiController,
            declarationController: declarationController,
            declarationHindiController: declarationHindiController,
            footerController: footerController,
            onInputChanged: onInputChanged,
            onTemplateChanged: onTemplateChanged,
            onAutoPrintChanged: onAutoPrintChanged,
          ),
        ),
      ],
    );
  }
}

class _TicketAndInterestFields extends StatelessWidget {
  final GirviBillingModel model;
  final GirviBillingPolicyInput input;
  final TextEditingController prefixController;
  final TextEditingController startingNumberController;
  final TextEditingController interestRateController;
  final TextEditingController gracePeriodController;
  final TextEditingController reminderDaysController;
  final TextEditingController noticeDaysController;
  final ValueChanged<GirviBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onInterestTypeChanged;
  final ValueChanged<String> onDefaultDurationChanged;

  const _TicketAndInterestFields({
    required this.model,
    required this.input,
    required this.prefixController,
    required this.startingNumberController,
    required this.interestRateController,
    required this.gracePeriodController,
    required this.reminderDaysController,
    required this.noticeDaysController,
    required this.onInputChanged,
    required this.onInterestTypeChanged,
    required this.onDefaultDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveFields(
          children: [
            _TextInput(
              label: 'Ticket Prefix',
              helper: 'Short code printed before the Girvi number',
              controller: prefixController,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => onInputChanged(
                input.copyWith(girviPrefix: value),
              ),
            ),
            _TextInput(
              label: 'Starting Ticket Number',
              helper: 'Next sequence used for new Girvi tickets',
              controller: startingNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => onInputChanged(
                input.copyWith(startingNumber: value),
              ),
            ),
            _TextInput(
              label: 'Monthly Interest Rate',
              helper: 'Default rate applied on new Girvi entries',
              suffix: '%',
              controller: interestRateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => onInputChanged(
                input.copyWith(defaultInterestRate: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ResponsiveFields(
          children: [
            _SelectInput(
              label: 'Interest Type',
              value: model.interestType,
              items: GirviBillingOptions.interestTypes,
              onChanged: onInterestTypeChanged,
            ),
            _SelectInput(
              label: 'Default Loan Duration',
              value: model.defaultDuration,
              items: GirviBillingOptions.durations,
              onChanged: onDefaultDurationChanged,
            ),
            _TextInput(
              label: 'Grace Period',
              helper: 'Extra days after maturity before escalation',
              suffix: 'days',
              controller: gracePeriodController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => onInputChanged(
                input.copyWith(gracePeriodDays: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ResponsiveFields(
          children: [
            _TextInput(
              label: 'Reminder Window',
              helper: 'Days before maturity to start reminders',
              suffix: 'days',
              controller: reminderDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => onInputChanged(
                input.copyWith(reminderDays: value),
              ),
            ),
            _TextInput(
              label: 'Auction Notice Window',
              helper: 'Notice days before auction action',
              suffix: 'days',
              controller: noticeDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => onInputChanged(
                input.copyWith(noticeDays: value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegalAndPrintFields extends StatelessWidget {
  final GirviBillingModel model;
  final GirviBillingPolicyInput input;
  final TextEditingController termsController;
  final TextEditingController termsHindiController;
  final TextEditingController declarationController;
  final TextEditingController declarationHindiController;
  final TextEditingController footerController;
  final ValueChanged<GirviBillingPolicyInput> onInputChanged;
  final ValueChanged<String> onTemplateChanged;
  final ValueChanged<bool> onAutoPrintChanged;

  const _LegalAndPrintFields({
    required this.model,
    required this.input,
    required this.termsController,
    required this.termsHindiController,
    required this.declarationController,
    required this.declarationHindiController,
    required this.footerController,
    required this.onInputChanged,
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
        _ResponsiveFields(
          minItemWidth: 320,
          children: [
            _TextInput(
              label: 'English Terms and Conditions',
              helper: 'Printed when terms are enabled on the receipt',
              controller: termsController,
              maxLines: 5,
              onChanged: (value) => onInputChanged(
                input.copyWith(termsAndConditions: value),
              ),
            ),
            _TextInput(
              label: 'Hindi Terms and Conditions',
              helper: 'Bilingual copy for Hindi receipt terms',
              controller: termsHindiController,
              maxLines: 5,
              onChanged: (value) => onInputChanged(
                input.copyWith(termsAndConditionsHindi: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ResponsiveFields(
          minItemWidth: 320,
          children: [
            _TextInput(
              label: 'English Customer Declaration',
              helper: 'Customer acknowledgement shown before signatures',
              controller: declarationController,
              maxLines: 5,
              onChanged: (value) => onInputChanged(
                input.copyWith(customerDeclaration: value),
              ),
            ),
            _TextInput(
              label: 'Hindi Customer Declaration',
              helper: 'Bilingual acknowledgement for customer receipts',
              controller: declarationHindiController,
              maxLines: 5,
              onChanged: (value) => onInputChanged(
                input.copyWith(customerDeclarationHindi: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TextInput(
          label: 'Footer Message',
          helper: 'Optional closing note printed at the bottom of the receipt',
          controller: footerController,
          maxLines: 3,
          onChanged: (value) => onInputChanged(
            input.copyWith(footerMessage: value),
          ),
        ),
        const SizedBox(height: 14),
        _ResponsiveFields(
          children: [
            _SelectInput(
              label: 'Receipt Template',
              value: PrintTemplateRegistry.byId(model.selectedTemplate).id,
              items: templates.map((template) => template.id).toList(),
              labelFor: PrintTemplateRegistry.labelFor,
              onChanged: onTemplateChanged,
            ),
            GirviBillingToggleTile(
              label: 'Auto Print Receipt',
              description:
                  'Open print flow automatically after a Girvi ticket is saved',
              value: model.autoPrint,
              accent: BillingSetupDesignTokens.girvi,
              onChanged: onAutoPrintChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;

  const _ResponsiveFields({
    required this.children,
    this.minItemWidth = 250,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minItemWidth)
            .floor()
            .clamp(1, children.length)
            .toInt();
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
                  child: child,
                ),
              )
              .toList(growable: false),
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
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String> onChanged;

  const _TextInput({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.helper,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(
        color: BillingSetupDesignTokens.textStrong,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        suffixText: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BillingSetupDesignTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BillingSetupDesignTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BillingSetupDesignTokens.girvi,
            width: 1.4,
          ),
        ),
        helperMaxLines: 2,
      ),
    );
  }
}

class _SelectInput extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final String Function(String value)? labelFor;
  final ValueChanged<String> onChanged;

  const _SelectInput({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValue = items.contains(value) ? value : items.first;

    return DropdownButtonFormField<String>(
      initialValue: resolvedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BillingSetupDesignTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BillingSetupDesignTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BillingSetupDesignTokens.girvi,
            width: 1.4,
          ),
        ),
      ),
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
    );
  }
}
