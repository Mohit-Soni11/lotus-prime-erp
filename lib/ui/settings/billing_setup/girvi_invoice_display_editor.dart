import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/setting/billing_setup/girvi_billing_model.dart';
import '../../../../theme/settings/billing_setup/billing_setup_colors.dart';

class GirviInvoiceDisplayEditor extends StatelessWidget {
  const GirviInvoiceDisplayEditor({
    super.key,
    required this.model,
    required this.selectedMetal,
    required this.onMetalChanged,
    required this.onChanged,
  });

  final GirviBillingModel model;
  final String selectedMetal;
  final ValueChanged<String> onMetalChanged;
  final ValueChanged<GirviBillingModel> onChanged;

  static const options = <GirviDisplayOption>[
    GirviDisplayOption(
      key: 'serial',
      title: 'Serial Number',
      subtitle: 'Pledged item row number',
      icon: Icons.format_list_numbered_rounded,
      group: 'Item Identity',
    ),
    GirviDisplayOption(
      key: 'metal',
      title: 'Metal',
      subtitle: 'Gold, silver, diamond or platinum',
      icon: Icons.category_outlined,
      group: 'Item Identity',
    ),
    GirviDisplayOption(
      key: 'item',
      title: 'Item Description',
      subtitle: 'Name and description entered on New Girvi',
      icon: Icons.inventory_2_outlined,
      group: 'Item Identity',
    ),
    GirviDisplayOption(
      key: 'pieces',
      title: 'Pieces (Pcs)',
      subtitle: 'Number of pledged pieces',
      icon: Icons.numbers_rounded,
      group: 'Item Identity',
    ),
    GirviDisplayOption(
      key: 'huid',
      title: 'HUID / Hallmark Number',
      subtitle: 'Hallmark, certificate or tag number',
      icon: Icons.fingerprint_rounded,
      group: 'Item Identity',
    ),
    GirviDisplayOption(
      key: 'purity',
      title: 'Purity / Tunch',
      subtitle: 'Entered metal purity such as 22K or 925',
      icon: Icons.diamond_outlined,
      group: 'Weight Details',
    ),
    GirviDisplayOption(
      key: 'gross',
      title: 'Gross Weight',
      subtitle: 'Total weight before deductions',
      icon: Icons.scale_outlined,
      group: 'Weight Details',
    ),
    GirviDisplayOption(
      key: 'less',
      title: 'Less / Stone Weight',
      subtitle: 'Stone and non-metal weight deducted',
      icon: Icons.remove_circle_outline_rounded,
      group: 'Weight Details',
    ),
    GirviDisplayOption(
      key: 'net',
      title: 'Net Weight',
      subtitle: 'Gross weight minus less weight',
      icon: Icons.balance_outlined,
      group: 'Weight Details',
    ),
    GirviDisplayOption(
      key: 'valuationPurity',
      title: 'Valuation Purity',
      subtitle: 'Purity percentage used for loan valuation',
      icon: Icons.percent_rounded,
      group: 'Valuation',
    ),
    GirviDisplayOption(
      key: 'fineWeight',
      title: 'Fine Weight',
      subtitle: 'Net weight multiplied by valuation purity',
      icon: Icons.calculate_outlined,
      group: 'Valuation',
    ),
    GirviDisplayOption(
      key: 'ratePerGram',
      title: 'Valuation Rate / Gram',
      subtitle: 'Rate used to calculate pledged value',
      icon: Icons.trending_up_rounded,
      group: 'Valuation',
    ),
    GirviDisplayOption(
      key: 'valuationAmount',
      title: 'Item Valuation Amount',
      subtitle: 'Calculated value of each pledged item',
      icon: Icons.currency_rupee_rounded,
      group: 'Valuation',
    ),
    GirviDisplayOption(
      key: 'photos',
      title: 'Pledged Item Photos',
      subtitle: 'Photos attached from the item ledger',
      icon: Icons.photo_camera_outlined,
      group: 'Media',
    ),
  ];

  static const groups = [
    'Item Identity',
    'Weight Details',
    'Valuation',
    'Media',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = model.settingsForMetal(selectedMetal);
    final accent = BillingSetupColors.metalAccent(selectedMetal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: GirviBillingMetal.supported
              .map(
                (metal) => _MetalButton(
                  metal: metal,
                  selected: metal == selectedMetal,
                  onTap: () => onMetalChanged(metal),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        _EditorSummary(
          title:
              '${GirviBillingMetal.displayName(selectedMetal)} Girvi Invoice',
          subtitle:
              '${settings.activeFieldCount} of ${options.length} fields enabled',
          accent: accent,
        ),
        const SizedBox(height: 12),
        for (final group in groups) ...[
          _GroupLabel(label: group, accent: accent),
          const SizedBox(height: 7),
          _OptionGrid(
            options: options.where((option) => option.group == group).toList(),
            accent: accent,
            valueFor: (key) => readGirviItemSetting(settings, key),
            onChanged: (key, value) {
              onChanged(
                model.withMetalSettings(
                  selectedMetal,
                  writeGirviItemSetting(settings, key, value),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: BillingSetupColors.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: BillingSetupColors.warning.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            'Valuation fields start OFF. Enable only the valuation details '
            'you want the customer to see on the printed Girvi receipt.',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: BillingSetupColors.textMuted,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class GirviInvoiceDocumentEditor extends StatelessWidget {
  const GirviInvoiceDocumentEditor({
    super.key,
    required this.model,
    required this.onChanged,
  });

  final GirviBillingModel model;
  final ValueChanged<GirviBillingModel> onChanged;

  static const options = <GirviDisplayOption>[
    GirviDisplayOption(
      key: 'customerMobile',
      title: 'Customer Mobile',
      subtitle: 'Selected customer mobile number',
      icon: Icons.phone_outlined,
      group: 'Customer Details',
    ),
    GirviDisplayOption(
      key: 'customerCity',
      title: 'Customer City',
      subtitle: 'Selected customer city or location',
      icon: Icons.location_city_outlined,
      group: 'Customer Details',
    ),
    GirviDisplayOption(
      key: 'loanAmount',
      title: 'Loan Amount',
      subtitle: 'Principal amount paid against the pledge',
      icon: Icons.account_balance_wallet_outlined,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'interestRate',
      title: 'Monthly Interest Rate',
      subtitle: 'Interest percentage per month',
      icon: Icons.percent_rounded,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'duration',
      title: 'Loan Duration',
      subtitle: 'Configured duration in months',
      icon: Icons.timelapse_rounded,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'startDate',
      title: 'Start Date',
      subtitle: 'Date from which the loan begins',
      icon: Icons.event_available_outlined,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'maturityDate',
      title: 'Maturity Date',
      subtitle: 'System-calculated loan maturity date',
      icon: Icons.event_busy_outlined,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'monthlyInterest',
      title: 'Monthly Interest Amount',
      subtitle: 'Interest amount payable for one month',
      icon: Icons.calendar_view_month_outlined,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'totalInterest',
      title: 'Total Interest at Maturity',
      subtitle: 'Estimated interest for the full duration',
      icon: Icons.show_chart_rounded,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'totalDue',
      title: 'Total Amount Due',
      subtitle: 'Principal plus estimated total interest',
      icon: Icons.payments_outlined,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'totalValuation',
      title: 'Total Pledged Valuation',
      subtitle: 'Combined valuation of all pledged items',
      icon: Icons.price_check_outlined,
      group: 'Loan & Interest',
    ),
    GirviDisplayOption(
      key: 'disbursement',
      title: 'Disbursement Breakdown',
      subtitle: 'Cash, UPI, bank and cheque split',
      icon: Icons.account_balance_outlined,
      group: 'Payment & Verification',
    ),
    GirviDisplayOption(
      key: 'kycDetails',
      title: 'KYC Type & Number',
      subtitle: 'Identity document name and card number',
      icon: Icons.badge_outlined,
      group: 'Payment & Verification',
    ),
    GirviDisplayOption(
      key: 'kycPhoto',
      title: 'KYC Card Photo',
      subtitle: 'Attached identity document image',
      icon: Icons.document_scanner_outlined,
      group: 'Payment & Verification',
    ),
    GirviDisplayOption(
      key: 'notes',
      title: 'Notes & Remarks',
      subtitle: 'Print entered remarks on the customer receipt',
      icon: Icons.notes_rounded,
      group: 'Payment & Verification',
    ),
    GirviDisplayOption(
      key: 'terms',
      title: 'Terms & Conditions',
      subtitle: 'Print bilingual Girvi terms line by line',
      icon: Icons.gavel_outlined,
      group: 'Print Content',
    ),
    GirviDisplayOption(
      key: 'declaration',
      title: 'Customer Declaration',
      subtitle: 'Print bilingual declaration above the signature area',
      icon: Icons.fact_check_outlined,
      group: 'Print Content',
    ),
    GirviDisplayOption(
      key: 'footer',
      title: 'Footer Message',
      subtitle: 'Print the optional saved footer message',
      icon: Icons.vertical_align_bottom_rounded,
      group: 'Print Content',
    ),
  ];

  static const groups = [
    'Customer Details',
    'Loan & Interest',
    'Payment & Verification',
    'Print Content',
  ];

  @override
  Widget build(BuildContext context) {
    const accent = BillingSetupColors.grvTerms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditorSummary(
          title: 'Customer Receipt Sections',
          subtitle:
              '${model.visibleDocumentFieldCount} of ${options.length} fields enabled',
          accent: accent,
        ),
        const SizedBox(height: 12),
        for (final group in groups) ...[
          _GroupLabel(label: group, accent: accent),
          const SizedBox(height: 7),
          _OptionGrid(
            options: options.where((option) => option.group == group).toList(),
            accent: accent,
            valueFor: (key) => readGirviDocumentSetting(model, key),
            onChanged: (key, value) =>
                onChanged(writeGirviDocumentSetting(model, key, value)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

bool readGirviItemSetting(
  GirviInvoiceFieldSettings settings,
  String key,
) {
  switch (key) {
    case 'serial':
      return settings.showSerialNumber;
    case 'metal':
      return settings.showMetal;
    case 'item':
      return settings.showItemName;
    case 'pieces':
      return settings.showPieces;
    case 'huid':
      return settings.showHuid;
    case 'purity':
      return settings.showPurity;
    case 'gross':
      return settings.showGrossWeight;
    case 'less':
      return settings.showLessWeight;
    case 'net':
      return settings.showNetWeight;
    case 'valuationPurity':
      return settings.showValuationPurity;
    case 'fineWeight':
      return settings.showFineWeight;
    case 'ratePerGram':
      return settings.showRatePerGram;
    case 'valuationAmount':
      return settings.showValuationAmount;
    case 'photos':
      return settings.showItemPhotos;
    default:
      return false;
  }
}

GirviInvoiceFieldSettings writeGirviItemSetting(
  GirviInvoiceFieldSettings settings,
  String key,
  bool value,
) {
  switch (key) {
    case 'serial':
      return settings.copyWith(showSerialNumber: value);
    case 'metal':
      return settings.copyWith(showMetal: value);
    case 'item':
      return settings.copyWith(showItemName: value);
    case 'pieces':
      return settings.copyWith(showPieces: value);
    case 'huid':
      return settings.copyWith(showHuid: value);
    case 'purity':
      return settings.copyWith(showPurity: value);
    case 'gross':
      return settings.copyWith(showGrossWeight: value);
    case 'less':
      return settings.copyWith(showLessWeight: value);
    case 'net':
      return settings.copyWith(showNetWeight: value);
    case 'valuationPurity':
      return settings.copyWith(showValuationPurity: value);
    case 'fineWeight':
      return settings.copyWith(showFineWeight: value);
    case 'ratePerGram':
      return settings.copyWith(showRatePerGram: value);
    case 'valuationAmount':
      return settings.copyWith(showValuationAmount: value);
    case 'photos':
      return settings.copyWith(showItemPhotos: value);
    default:
      return settings;
  }
}

bool readGirviDocumentSetting(GirviBillingModel model, String key) {
  switch (key) {
    case 'customerMobile':
      return model.showCustomerMobile;
    case 'customerCity':
      return model.showCustomerCity;
    case 'loanAmount':
      return model.showLoanAmount;
    case 'interestRate':
      return model.showInterestRate;
    case 'duration':
      return model.showDuration;
    case 'startDate':
      return model.showStartDate;
    case 'maturityDate':
      return model.showMaturityDate;
    case 'monthlyInterest':
      return model.showMonthlyInterest;
    case 'totalInterest':
      return model.showTotalInterest;
    case 'totalDue':
      return model.showTotalDue;
    case 'totalValuation':
      return model.showTotalValue;
    case 'disbursement':
      return model.showDisbursementDetails;
    case 'kycDetails':
      return model.showKycDetails;
    case 'kycPhoto':
      return model.showKycPhoto;
    case 'notes':
      return model.showNotes;
    case 'terms':
      return model.printTermsAndConditions;
    case 'declaration':
      return model.printCustomerDeclaration;
    case 'footer':
      return model.printFooterMessage;
    default:
      return false;
  }
}

GirviBillingModel writeGirviDocumentSetting(
  GirviBillingModel model,
  String key,
  bool value,
) {
  switch (key) {
    case 'customerMobile':
      return model.copyWith(showCustomerMobile: value);
    case 'customerCity':
      return model.copyWith(showCustomerCity: value);
    case 'loanAmount':
      return model.copyWith(showLoanAmount: value);
    case 'interestRate':
      return model.copyWith(showInterestRate: value);
    case 'duration':
      return model.copyWith(showDuration: value);
    case 'startDate':
      return model.copyWith(showStartDate: value);
    case 'maturityDate':
      return model.copyWith(showMaturityDate: value);
    case 'monthlyInterest':
      return model.copyWith(showMonthlyInterest: value);
    case 'totalInterest':
      return model.copyWith(showTotalInterest: value);
    case 'totalDue':
      return model.copyWith(showTotalDue: value);
    case 'totalValuation':
      return model.copyWith(showTotalValue: value);
    case 'disbursement':
      return model.copyWith(showDisbursementDetails: value);
    case 'kycDetails':
      return model.copyWith(showKycDetails: value);
    case 'kycPhoto':
      return model.copyWith(showKycPhoto: value);
    case 'notes':
      return model.copyWith(showNotes: value);
    case 'terms':
      return model.copyWith(printTermsAndConditions: value);
    case 'declaration':
      return model.copyWith(printCustomerDeclaration: value);
    case 'footer':
      return model.copyWith(printFooterMessage: value);
    default:
      return model;
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.accent,
    required this.valueFor,
    required this.onChanged,
  });

  final List<GirviDisplayOption> options;
  final Color accent;
  final bool Function(String key) valueFor;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        const gap = 10.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: options
              .map(
                (option) => SizedBox(
                  width: width,
                  child: _FieldTile(
                    option: option,
                    value: valueFor(option.key),
                    accent: accent,
                    onChanged: (value) => onChanged(option.key, value),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _EditorSummary extends StatelessWidget {
  const _EditorSummary({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: BillingSetupColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: BillingSetupColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'EDITABLE',
              style: GoogleFonts.inter(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: BillingSetupColors.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.55,
          ),
        ),
      ],
    );
  }
}

class _MetalButton extends StatelessWidget {
  const _MetalButton({
    required this.metal,
    required this.selected,
    required this.onTap,
  });

  final String metal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = BillingSetupColors.metalAccent(metal);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.10)
              : BillingSetupColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : BillingSetupColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          GirviBillingMetal.displayName(metal),
          style: GoogleFonts.inter(
            color: selected ? accent : BillingSetupColors.textBody,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.option,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final GirviDisplayOption option;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color:
            value ? accent.withValues(alpha: 0.05) : BillingSetupColors.inputBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: value
              ? accent.withValues(alpha: 0.22)
              : BillingSetupColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            option.icon,
            color: value ? accent : BillingSetupColors.textHint,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: BillingSetupColors.textBody,
                  ),
                ),
                Text(
                  option.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: BillingSetupColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accent,
          ),
        ],
      ),
    );
  }
}

class GirviDisplayOption {
  const GirviDisplayOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.group,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String group;
}
