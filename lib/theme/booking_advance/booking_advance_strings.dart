// =============================================================================
// FILE        : booking_advance_strings.dart
// MODULE      : Sales → Booking & Advance
// LAYER       : Theme / Strings
// =============================================================================

class BookingAdvanceStrings {
  BookingAdvanceStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String appBarTitle = 'BOOKING & ADVANCE';
  static const String systemOnline = 'System Online';

  // ── TOP CONTROL BAR ───────────────────────────────────────────────────────
  static const String sectionPreferences = 'BOOKING PREFERENCES';
  static const String openRate = 'OPEN RATE';
  static const String lockedRate = 'LOCKED RATE';
  static const String taxStatusLabel = 'TAX STATUS';
  static const String normalBill = 'NORMAL';
  static const String gstInvoice = 'GST INVOICE';
  static const String nrmShort = 'NRM';
  static const String taxShort = 'TAX';
  static const String gstActive = 'GST ACTIVE';
  static const String statusNormal = 'NORMAL';
  static const String normalBillSub = 'Normal Bill';
  static const String gstBillSub = 'GST Invoice';

  // ── STATUS BAR ────────────────────────────────────────────────────────────
  static const String sectionBookingNo = 'BOOKING NUMBER';
  static const String bookingNoLabel = 'BOOKING NO.';
  static const String standardBooking = 'Standard Booking';
  static const String gstBooking = 'GST Booking';
  static const String gstBookingBadge = 'GST BOOKING';
  static const String bookingBadge = 'BOOKING';
  static const String dateLabel = 'DATE';
  static const String timeLabel = 'TIME';

  // ── CUSTOMER PANEL ────────────────────────────────────────────────────────
  static const String sectionCustomer = 'CUSTOMER DETAILS';
  static const String customerSubtitle = 'Search or enter customer details';
  static const String bookingSession = 'Booking Session';
  static const String lblMobile = 'MOBILE';
  static const String hintMobile = '10-digit';
  static const String lblName = 'CUSTOMER NAME';
  static const String hintName = 'Enter full name';
  static const String lblCity = 'CITY / AREA';
  static const String hintCity = 'Enter city';
  static const String lblPan = 'PAN / AADHAR';
  static const String hintPan = 'Document ID';
  static const String lblGst = 'GST NUMBER';
  static const String hintGst = '15-digit GSTIN';
  static const String btnSearch = 'Search';
  static const String btnClear = 'Clear';

  // ── ITEM PANEL ────────────────────────────────────────────────────────────
  static const String sectionItem = 'ITEM DETAILS';
  static const String itemSubtitle = 'Enter booking item details';
  static const String lblItemName = 'ITEM NAME *';
  static const String hintItemName = 'e.g. Gold Necklace, Diamond Ring';
  static const String lblItemDesc = 'ITEM DESCRIPTION';
  static const String hintItemDesc =
      'Design details, size, special instructions...';
  static const String lblMetalType = 'METAL TYPE';
  static const String lblPurity = 'PURITY';
  static const String lblWeight = 'APPROX. WEIGHT';
  static const String hintWeight = '0.000';
  static const String weightUnit = 'g';
  static const String lblGoldRate = "TODAY'S GOLD RATE";
  static const String goldRateUnit = '/10g';
  static const String lblLockedRate = 'LOCKED RATE';
  static const String lblDeliveryDate = 'EXPECTED DELIVERY DATE';
  static const String hintDeliveryDate = 'Select delivery date';
  static const String lblNotes = 'NOTES / REMARKS';
  static const String hintNotes = 'Any special instructions...';

  // ── METAL TYPES & PURITIES ────────────────────────────────────────────────
  static const List<String> metalTypes = [
    'GOLD',
    'SILVER',
    'PLATINUM',
    'DIAMOND'
  ];
  static const List<String> goldPurities = ['24K', '22K', '18K', '14K', '10K'];
  static const List<String> silverPurities = ['999', '925', '900', '800'];
  static const List<String> platinumPurities = ['950', '900', '850'];
  static const List<String> diamondPurities = ['18K', '14K'];

  // ── RIGHT PANEL ───────────────────────────────────────────────────────────
  static const String sectionSummary = 'BOOKING SUMMARY';
  static const String summarySubtitle = 'Order overview';
  static const String sectionPayment = 'ADVANCE PAYMENT';
  static const String paymentSubtitle = 'Enter amount received';
  static const String lblTotalAdvance = 'TOTAL ADVANCE';
  static const String lblAdvanceTotal = 'ADVANCE TOTAL';
  static const String advanceReceived = '✓  Advance received';
  static const String lblCash = 'CASH';
  static const String lblUpi = 'UPI / ONLINE';
  static const String lblCard = 'CARD';
  static const String btnSaveBooking = 'SAVE BOOKING';
  static const String btnClearAll = 'CLEAR ALL';
  static const String lockedBadge = '🔒 Locked Rate';
  static const String openBadge = '🔓 Open Rate';
}
