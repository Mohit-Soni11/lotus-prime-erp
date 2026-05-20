// ============================================================
// FILE    : lib/theme/settings/tax_gst/tax_gst_strings.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// ============================================================

/// All text constants for the Tax & GST Settings module.
/// Zero strings are hardcoded in UI or Logic files.
abstract final class TaxGstStrings {
  TaxGstStrings._();

  // ── AppBar ──────────────────────────────────────────────────
  static const String appBarTitle = 'Tax & GST';
  static const String appBarSubtitle =
      'GST registration, rates, HSN codes & compliance';
  static const String moduleBadgeLabel = 'TAX & GST';
  static const String systemOnlineLabel = 'SYSTEM ONLINE';

  // ── Hub Screen ───────────────────────────────────────────────
  static const String hubSectionLabel = 'CONFIGURATION SECTIONS';
  static const String hubTapHint = 'Tap a section to configure';

  // ── Sync Banner ──────────────────────────────────────────────
  static const String syncBannerTitle = 'Linked with Shop Profile';
  static const String syncBannerBody =
      'All changes here automatically sync with '
      'Shop Profile → GST & Legal. '
      'Update from either screen — single source of truth.';
  static const String syncBannerTag = 'LIVE SYNC ACTIVE';

  // ── Card 01 — GST Registration ───────────────────────────────
  static const String card01Title = 'GST Registration';
  static const String card01Subtitle =
      'GSTIN, legal name, taxpayer type & registration details';
  static const String card01Tag = 'GSTIN · PAN · TAN · Taxpayer Type';
  static const String card01SectionTitle = 'GST Registration & Identity';
  static const String card01SectionSub =
      'Your official GST registration details printed on every invoice';

  // ── Card 02 — GST Slabs ──────────────────────────────────────
  static const String card02Title = 'GST Slabs & Rates';
  static const String card02Subtitle =
      'Configure applicable GST rates per jewellery category';
  static const String card02Tag = 'Gold 3% · Making 5% · Repair 18%';
  static const String card02SectionTitle = 'GST Rate Configuration';
  static const String card02SectionSub =
      'Category-wise GST rates — auto-applied during billing';

  // ── Card 03 — HSN Codes ──────────────────────────────────────
  static const String card03Title = 'HSN Code Manager';
  static const String card03Subtitle =
      'Map HSN/SAC codes to your product categories';
  static const String card03Tag = '71131910 · 71131120 · 99889900';
  static const String card03SectionTitle = 'HSN / SAC Code Mapping';
  static const String card03SectionSub =
      'Required for GST returns — maps to item categories on bill';

  // ── Card 04 — Tax Preferences ────────────────────────────────
  static const String card04Title = 'Tax Computation';
  static const String card04Subtitle =
      'IGST auto-split, inclusive pricing & rounding rules';
  static const String card04Tag = 'Auto-split · Round-off · Pricing Mode';
  static const String card04SectionTitle = 'Tax Computation Preferences';
  static const String card04SectionSub =
      'Controls how GST is calculated and displayed on bills';

  // ── Card 05 — TCS / TDS ──────────────────────────────────────
  static const String card05Title = 'TCS & TDS';
  static const String card05Subtitle =
      'Section 206C TCS on jewellery sales above threshold';
  static const String card05Tag = 'TCS 1% · ₹2L Threshold · Sec 206C';
  static const String card05SectionTitle = 'TCS & TDS Configuration';
  static const String card05SectionSub =
      'Auto-collect TCS on high-value jewellery transactions';

  // ── Card 06 — E-Invoice ──────────────────────────────────────
  static const String card06Title = 'E-Invoice & Compliance';
  static const String card06Subtitle =
      'E-invoicing threshold, IRP API & filing reminders';
  static const String card06Tag = 'IRN · QR Code · GSTR-1 · GSTR-3B';
  static const String card06SectionTitle = 'E-Invoice & GST Compliance';
  static const String card06SectionSub =
      'Configure IRP integration and automated filing reminders';

  // ── Card 07 — BIS Hallmarking ─────────────────────────────────
  static const String card07Title = 'BIS & Hallmarking';
  static const String card07Subtitle =
      'BIS license number, HUID settings & validity tracker';
  static const String card07Tag = 'BIS License · HUID · Validity';
  static const String card07SectionTitle = 'BIS Hallmarking & Certification';
  static const String card07SectionSub =
      'Mandatory for hallmarked gold jewellery — printed on every bill';

  // ── Field Labels ─────────────────────────────────────────────
  static const String labelGstin = 'GSTIN';
  static const String labelLegalName = 'Legal Business Name';
  static const String labelPan = 'PAN Number';
  static const String labelTan = 'TAN Number';
  static const String labelRegDate = 'GST Registration Date';
  static const String labelTaxpayerType = 'Taxpayer Type';
  static const String labelStateCode = 'State / UT';
  static const String labelGstRate = 'GST Rate';
  static const String labelHsnCode = 'HSN / SAC Code';
  static const String labelItemCategory = 'Item Category';
  static const String labelTcsThreshold = 'TCS Threshold Amount';
  static const String labelTcsRate = 'TCS Rate (%)';
  static const String labelTdsRate = 'TDS Rate (%)';
  static const String labelEInvThreshold = 'E-Invoice Turnover Limit';
  static const String labelIrpUsername = 'IRP API Username';
  static const String labelIrpPassword = 'IRP API Password';
  static const String labelBisLicense = 'BIS License Number';
  static const String labelHuid = 'HUID Number';
  static const String labelBisValidFrom = 'BIS License Valid From';
  static const String labelBisValidUpto = 'BIS License Valid Upto';

  // ── Field Hints ──────────────────────────────────────────────
  static const String hintGstin = 'e.g. 27AAAAA0000A1Z5';
  static const String hintLegalName = 'As registered with GST department';
  static const String hintPan = 'e.g. AAAAA0000A';
  static const String hintTan = 'e.g. MUMA99999A';
  static const String hintDate = 'DD / MM / YYYY';
  static const String hintState = 'e.g. Maharashtra — MH (27)';
  static const String hintHsnCode = 'e.g. 71131910';
  static const String hintCategory = 'e.g. Gold Jewellery';
  static const String hintTcsThreshold = 'e.g. 200000';
  static const String hintTcsRate = 'e.g. 1.0';
  static const String hintBisLicense = 'e.g. CM/L-XXXXXXX';
  static const String hintHuid = '6-digit alphanumeric';

  // ── Dropdowns ────────────────────────────────────────────────
  static const List<String> taxpayerTypes = [
    'Regular',
    'Composition Scheme',
    'Unregistered',
    'Consumer',
    'Deemed Export',
    'SEZ Unit',
    'SEZ Developer',
  ];

  static const List<String> gstRateOptions = [
    '0%',
    '0.25%',
    '1.5%',
    '3%',
    '5%',
    '12%',
    '18%',
    '28%',
  ];

  static const List<String> eInvoiceThresholds = [
    '₹5 Crore',
    '₹10 Crore',
    '₹20 Crore',
    '₹50 Crore',
  ];

  // ── Toggle Labels ─────────────────────────────────────────────
  static const String toggleAutoSplitTitle = 'Auto-split IGST → CGST + SGST';
  static const String toggleAutoSplitSub =
      'Automatically applies for intra-state transactions';
  static const String toggleTaxInclusiveTitle = 'Tax-Inclusive Pricing';
  static const String toggleTaxInclusiveSub =
      'Item prices on bill include GST (MRP pricing model)';
  static const String toggleRoundOffTitle = 'Round-off GST Amount';
  static const String toggleRoundOffSub =
      'Round total GST to nearest rupee on invoice';
  static const String toggleShowOnBillTitle = 'Show GST Breakup on Bill';
  static const String toggleShowOnBillSub =
      'Print CGST / SGST / IGST breakdown on customer invoice';
  static const String toggleCompositeTitle = 'Composite Supply Treatment';
  static const String toggleCompositeSub =
      'Treat jewellery + making charge as composite supply';
  static const String toggleTcsTitle = 'Enable TCS Collection (Sec 206C)';
  static const String toggleTcsSub =
      'Collect 1% TCS on jewellery sales above threshold — mandatory';
  static const String toggleTdsTitle = 'Enable TDS Deduction';
  static const String toggleTdsSub =
      'Deduct TDS on applicable purchase transactions';
  static const String toggleEInvoiceTitle = 'Enable E-Invoicing';
  static const String toggleEInvoiceSub =
      'Generate IRN & QR code for all B2B invoices via IRP portal';
  static const String toggleGstr1Title = 'GSTR-1 Filing Reminder';
  static const String toggleGstr1Sub =
      'Monthly notification on 10th for outward supply filing';
  static const String toggleGstr3bTitle = 'GSTR-3B Filing Reminder';
  static const String toggleGstr3bSub =
      'Monthly notification on 20th for summary return filing';

  // ── Info Banners ─────────────────────────────────────────────
  static const String infoGstin =
      'GSTIN format: 2-digit state code + 10-char PAN + 3-char suffix '
      '(e.g. 27AAAAA0000A1Z5). Taxpayer type determines whether '
      'CGST+SGST or Composition levy applies on your bills.';
  static const String infoSlabs =
      'As per GST Act: Gold/Silver/Diamond jewellery → 3%, '
      'Making charges → 5%, Repair services → 18%, '
      'Imitation jewellery → 3%. Composition scheme: flat 1% on turnover.';
  static const String infoHsn =
      'HSN codes are mandatory on invoices above ₹5L. '
      'These codes map directly to GSTR-1 outward supply columns.';
  static const String infoTcs =
      'Section 206C(1F) of Income Tax Act: Collect 1% TCS on sale of '
      'jewellery exceeding ₹2,00,000 per transaction. '
      'Deposit collected TCS by 7th of the following month.';
  static const String infoBis =
      'BIS Hallmarking is mandatory for gold jewellery above 14K under '
      'BIS (Amendment) Order 2021. HUID (Hallmark Unique ID) must be '
      'printed on all hallmarked jewellery bills and HUID portal.';

  // ── HSN Column Headers ───────────────────────────────────────
  static const String hsnColCategory = 'CATEGORY';
  static const String hsnColCode = 'HSN / SAC';
  static const String hsnColRate = 'RATE';
  static const String hsnColActions = '';

  // ── Buttons ──────────────────────────────────────────────────
  static const String btnEdit = 'Edit';
  static const String btnSave = 'Save Changes';
  static const String btnSaving = 'Saving…';
  static const String btnCancel = 'Cancel';
  static const String btnAddHsn = 'Add HSN Code';
  static const String btnAddHsnDialog = 'Add';
  static const String btnCancelDialog = 'Cancel';

  // ── Dialog ───────────────────────────────────────────────────
  static const String dialogAddHsnTitle = 'Add HSN Code';

  // ── Snackbar Messages ────────────────────────────────────────
  static const String snackSaved = 'Changes saved & synced with Shop Profile';
  static const String snackSaveError = 'Save failed. Please try again.';
  static const String snackValidationError =
      'Please fix the errors before saving.';
  static const String snackHsnAdded = 'HSN code added successfully';
  static const String snackHsnRemoved = 'HSN code removed';

  // ── Validation Messages ──────────────────────────────────────
  static const String validGstinFormat =
      'Invalid GSTIN format (e.g. 27AAAAA0000A1Z5)';
  static const String validPanFormat = 'Invalid PAN format (e.g. AAAAA0000A)';
  static const String validRequired = 'This field is required';

  // ── Empty States ─────────────────────────────────────────────
  static const String emptyHsnTitle = 'No HSN Codes Configured';
  static const String emptyHsnSub =
      'Add HSN codes to map product categories for GST returns';

  // ── Default HSN Data ─────────────────────────────────────────
  static const List<Map<String, String>> defaultHsnCodes = [
    {'category': 'Gold Jewellery', 'hsn': '71131910', 'rate': '3%'},
    {'category': 'Silver Jewellery', 'hsn': '71131120', 'rate': '3%'},
    {'category': 'Diamond/Gemstones', 'hsn': '71023910', 'rate': '3%'},
    {'category': 'Platinum Jewellery', 'hsn': '71131990', 'rate': '3%'},
    {'category': 'Imitation Jewellery', 'hsn': '71171990', 'rate': '3%'},
    {'category': 'Making Charges', 'hsn': '99889900', 'rate': '5%'},
    {'category': 'Coins & Bars', 'hsn': '71081310', 'rate': '3%'},
  ];

  // ── Default GST Slabs ─────────────────────────────────────────
  static const List<Map<String, String>> defaultGstSlabs = [
    {'category': 'Gold Jewellery', 'rate': '3%'},
    {'category': 'Silver Jewellery', 'rate': '3%'},
    {'category': 'Diamond/Gemstones', 'rate': '3%'},
    {'category': 'Platinum Jewellery', 'rate': '3%'},
    {'category': 'Imitation Jewellery', 'rate': '3%'},
    {'category': 'Making Charges', 'rate': '5%'},
    {'category': 'Coins & Bars', 'rate': '3%'},
    {'category': 'Repair Services', 'rate': '18%'},
    {'category': 'Other Services', 'rate': '18%'},
  ];
}
