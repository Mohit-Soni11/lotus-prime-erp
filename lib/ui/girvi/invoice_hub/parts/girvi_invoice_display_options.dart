part of '../girvi_invoice_hub_screen.dart';

const _girviInvoiceFieldOptions = <_GirviInvoiceFieldOption>[
  _GirviInvoiceFieldOption(
    key: 'serial',
    title: 'Serial Number',
    subtitle: 'Item row number',
    icon: Icons.format_list_numbered_rounded,
    group: 'Item Identity',
  ),
  _GirviInvoiceFieldOption(
    key: 'metal',
    title: 'Metal',
    subtitle: 'Gold, silver, diamond or platinum',
    icon: Icons.category_outlined,
    group: 'Item Identity',
  ),
  _GirviInvoiceFieldOption(
    key: 'item',
    title: 'Item Name',
    subtitle: 'Pledged item description',
    icon: Icons.inventory_2_outlined,
    group: 'Item Identity',
  ),
  _GirviInvoiceFieldOption(
    key: 'pieces',
    title: 'Pieces',
    subtitle: 'Pledged item quantity',
    icon: Icons.numbers_rounded,
    group: 'Item Identity',
  ),
  _GirviInvoiceFieldOption(
    key: 'huid',
    title: 'HUID',
    subtitle: 'Hallmark identification number',
    icon: Icons.fingerprint_rounded,
    group: 'Item Identity',
  ),
  _GirviInvoiceFieldOption(
    key: 'purity',
    title: 'Purity',
    subtitle: 'Entered purity or tunch',
    icon: Icons.diamond_outlined,
    group: 'Weight Details',
  ),
  _GirviInvoiceFieldOption(
    key: 'gross',
    title: 'Gross Weight',
    subtitle: 'Total item weight',
    icon: Icons.scale_outlined,
    group: 'Weight Details',
  ),
  _GirviInvoiceFieldOption(
    key: 'less',
    title: 'Less Weight',
    subtitle: 'Stone and non-metal deduction',
    icon: Icons.remove_circle_outline_rounded,
    group: 'Weight Details',
  ),
  _GirviInvoiceFieldOption(
    key: 'net',
    title: 'Net Weight',
    subtitle: 'Weight after deductions',
    icon: Icons.balance_outlined,
    group: 'Weight Details',
  ),
  _GirviInvoiceFieldOption(
    key: 'valuationPurity',
    title: 'Valuation Purity',
    subtitle: 'Purity percentage used for valuation',
    icon: Icons.percent_rounded,
    group: 'Valuation',
  ),
  _GirviInvoiceFieldOption(
    key: 'fineWeight',
    title: 'Fine Weight',
    subtitle: 'Calculated fine metal weight',
    icon: Icons.calculate_outlined,
    group: 'Valuation',
  ),
  _GirviInvoiceFieldOption(
    key: 'ratePerGram',
    title: 'Valuation Rate / Gram',
    subtitle: 'Rate used for pledged value',
    icon: Icons.trending_up_rounded,
    group: 'Valuation',
  ),
  _GirviInvoiceFieldOption(
    key: 'valuationAmount',
    title: 'Item Valuation Amount',
    subtitle: 'Calculated item value',
    icon: Icons.currency_rupee_rounded,
    group: 'Valuation',
  ),
  _GirviInvoiceFieldOption(
    key: 'photos',
    title: 'Item Photos',
    subtitle: 'Attached pledged-item photos',
    icon: Icons.photo_camera_outlined,
    group: 'Media',
  ),
];

const _girviInvoiceDocumentOptions = <_GirviInvoiceFieldOption>[
  _GirviInvoiceFieldOption(
    key: 'customerMobile',
    title: 'Customer Mobile',
    subtitle: 'Selected customer mobile number',
    icon: Icons.phone_outlined,
    group: 'Customer Details',
  ),
  _GirviInvoiceFieldOption(
    key: 'customerCity',
    title: 'Customer Address',
    subtitle: 'Full address saved in the customer profile',
    icon: Icons.location_on_outlined,
    group: 'Customer Details',
  ),
  _GirviInvoiceFieldOption(
    key: 'loanAmount',
    title: 'Loan Amount',
    subtitle: 'Principal paid against the pledge',
    icon: Icons.account_balance_wallet_outlined,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'interestRate',
    title: 'Monthly Interest Rate',
    subtitle: 'Interest percentage per month',
    icon: Icons.percent_rounded,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'duration',
    title: 'Loan Duration',
    subtitle: 'Duration in months',
    icon: Icons.timelapse_rounded,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'startDate',
    title: 'Start Date',
    subtitle: 'Loan start date',
    icon: Icons.event_available_outlined,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'maturityDate',
    title: 'Maturity Date',
    subtitle: 'Calculated maturity date',
    icon: Icons.event_busy_outlined,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'monthlyInterest',
    title: 'Monthly Interest Amount',
    subtitle: 'One month interest amount',
    icon: Icons.calendar_view_month_outlined,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'totalInterest',
    title: 'Total Interest',
    subtitle: 'Estimated interest at maturity',
    icon: Icons.show_chart_rounded,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'totalValuation',
    title: 'Total Pledged Valuation',
    subtitle: 'Combined value of all pledged items',
    icon: Icons.price_check_outlined,
    group: 'Loan & Interest',
  ),
  _GirviInvoiceFieldOption(
    key: 'disbursement',
    title: 'Disbursement Breakdown',
    subtitle: 'Cash, UPI, bank and cheque split',
    icon: Icons.account_balance_outlined,
    group: 'Payment & Verification',
  ),
  _GirviInvoiceFieldOption(
    key: 'kycDetails',
    title: 'KYC Type & Number',
    subtitle: 'Identity document details',
    icon: Icons.badge_outlined,
    group: 'Payment & Verification',
  ),
  _GirviInvoiceFieldOption(
    key: 'kycPhoto',
    title: 'KYC Card Photo',
    subtitle: 'Attached identity document image',
    icon: Icons.document_scanner_outlined,
    group: 'Payment & Verification',
  ),
  _GirviInvoiceFieldOption(
    key: 'notes',
    title: 'Notes & Remarks',
    subtitle: 'Entered ticket remarks',
    icon: Icons.notes_rounded,
    group: 'Payment & Verification',
  ),
  _GirviInvoiceFieldOption(
    key: 'terms',
    title: 'Terms & Conditions',
    subtitle: 'Bilingual Girvi terms',
    icon: Icons.gavel_outlined,
    group: 'Print Content',
  ),
  _GirviInvoiceFieldOption(
    key: 'declaration',
    title: 'Customer Declaration',
    subtitle: 'Bilingual declaration above signatures',
    icon: Icons.fact_check_outlined,
    group: 'Print Content',
  ),
  _GirviInvoiceFieldOption(
    key: 'footer',
    title: 'Footer Message',
    subtitle: 'Optional saved footer message',
    icon: Icons.vertical_align_bottom_rounded,
    group: 'Print Content',
  ),
];

class _GirviInvoiceFieldOption {
  const _GirviInvoiceFieldOption({
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
