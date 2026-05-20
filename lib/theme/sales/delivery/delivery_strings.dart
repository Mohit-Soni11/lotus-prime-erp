// =============================================================================
// FILE        : delivery_strings.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Theme / Strings
// =============================================================================

class DeliveryStrings {
  DeliveryStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String appBarTitle = 'DELIVERY MANAGEMENT';
  static const String systemOnline = 'System Online';

  // ── TABS ──────────────────────────────────────────────────────────────────
  static const String tabActiveOrders = 'Active Orders';
  static const String tabActionRequired = 'Action Required';
  static const String tabDueLedger = 'Due Ledger';
  static const String tabCompleted = 'Completed Bills';

  // ── HEADER STATS ──────────────────────────────────────────────────────────
  static const String statTotalActive = 'Total Active';
  static const String statActionRequired = 'Action Required';
  static const String statDueLedger = 'Due Ledger';
  static const String statCompleted = 'Completed';
  static const String statTotalDue = 'Total Due';

  // ── SEARCH ────────────────────────────────────────────────────────────────
  static const String searchHint = 'Search by name, mobile, order no...';

  // ── ORDER CARD ────────────────────────────────────────────────────────────
  static const String labelDeliveryNo = 'Delivery No.';
  static const String labelCustomer = 'Customer';
  static const String labelItem = 'Item';
  static const String labelMetal = 'Metal';
  static const String labelWeight = 'Weight';
  static const String labelAdvance = 'Advance Paid';
  static const String labelDue = 'Due Amount';
  static const String labelDeliveryDate = 'Delivery Date';
  static const String labelKarigar = 'Karigar';
  static const String labelBillNo = 'Bill No.';
  static const String labelStatus = 'Status';
  static const String labelPayment = 'Payment';

  // ── STATUS LABELS ─────────────────────────────────────────────────────────
  static const String statusBooked = 'Booked';
  static const String statusInMaking = 'In Making';
  static const String statusReady = 'Ready';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';

  // ── URGENCY ───────────────────────────────────────────────────────────────
  static const String urgencyOverdue = 'OVERDUE';
  static const String urgencyToday = 'TODAY';
  static const String urgencyTomorrow = 'TOMORROW';

  // ── PAYMENT STATUS ────────────────────────────────────────────────────────
  static const String paymentPaid = 'PAID';
  static const String paymentPartial = 'PARTIAL DUE';
  static const String paymentUnpaid = 'UNPAID';

  // ── DETAIL PANEL ──────────────────────────────────────────────────────────
  static const String panelOrderDetails = 'ORDER DETAILS';
  static const String panelItems = 'ITEMS';
  static const String panelFinancials = 'FINANCIALS';
  static const String panelDeliverOrder = 'DELIVER ORDER';
  static const String panelCollectDue = 'COLLECT DUE';
  static const String panelActions = 'QUICK ACTIONS';

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────
  static const String btnMarkInMaking = 'Mark In Making';
  static const String btnMarkReady = 'Mark Ready';
  static const String btnDeliver = 'DELIVER ORDER';
  static const String btnPartialDeliver = 'Partial Deliver';
  static const String btnCollectDue = 'COLLECT DUE';
  static const String btnWhatsApp = 'WhatsApp';
  static const String btnCancel = 'Cancel Order';
  static const String btnClose = 'Close';

  // ── DELIVER FORM ─────────────────────────────────────────────────────────
  static const String lblFinalAmount = 'FINAL BILL AMOUNT';
  static const String lblPaidNow = 'AMOUNT PAID NOW';
  static const String lblAdvancePaid = 'ADVANCE ALREADY PAID';
  static const String lblDueAfter = 'DUE AFTER THIS DELIVERY';
  static const String hintAmount = '0.00';

  // ── PARTIAL DELIVERY ──────────────────────────────────────────────────────
  static const String partialTitle = 'SELECT ITEMS TO DELIVER';
  static const String partialSubtitle =
      'Tick the items that are ready to deliver now';
  static const String partialSelectAll = 'Select All Ready';

  // ── DUE LEDGER ───────────────────────────────────────────────────────────
  static const String dueLedgerTitle = 'DUE COLLECTION';
  static const String dueLedgerSubtitle = 'Items delivered, payment pending';
  static const String lblAmountCollect = 'AMOUNT TO COLLECT';

  // ── WHATSAPP MESSAGES ─────────────────────────────────────────────────────
  static String whatsAppReadyMsg(String name, String item, String deliveryNo) =>
      'Namaste $name ji! 🙏\n\nAapka order taiyaar ho gaya hai.\n'
      '📦 Item: $item\n🔖 Order No: $deliveryNo\n\n'
      'Aap convenient time par aa kar le ja sakte hain.\n\n'
      'Dhanyavaad! 🙏\n– Lotus Jewellers';

  static String whatsAppDueMsg(String name, String amount, String deliveryNo) =>
      'Namaste $name ji! 🙏\n\nAapka ₹$amount ka due payment pending hai.\n'
      '🔖 Order No: $deliveryNo\n\n'
      'Kripya jald se jald payment karein.\n\n'
      'Dhanyavaad! 🙏\n– Lotus Jewellers';

  // ── EMPTY STATES ──────────────────────────────────────────────────────────
  static const String emptyActiveOrders = 'Koi active order nahi hai';
  static const String emptyActionRequired = 'Sab orders on track hain! 🎉';
  static const String emptyDueLedger = 'Koi due payment nahi hai 👍';
  static const String emptyCompleted =
      'Abhi tak koi delivery complete nahi hui';
  static const String emptySubtitle = 'Naya order booking se add karein';

  // ── CONFIRM DIALOGS ───────────────────────────────────────────────────────
  static const String confirmCancelTitle = 'Order Cancel Karein?';
  static const String confirmCancelMsg =
      'Kya aap waqai is order ko cancel karna chahte hain? Yeh action undo nahi ho sakta.';
  static const String confirmDeliverTitle = 'Order Deliver Karein?';
  static const String btnConfirm = 'Confirm';
  static const String btnCancel2 = 'Wapas Jao';

  // ── SNACKBAR ──────────────────────────────────────────────────────────────
  static const String snackDelivered = '✅ Order successfully deliver ho gaya!';
  static const String snackReadyMarked = '✅ Order Ready mark ho gaya!';
  static const String snackInMaking = '✅ Order In Making mark ho gaya!';
  static const String snackDueCollected = '✅ Due payment collect ho gaya!';
  static const String snackCancelled = 'Order cancel ho gaya.';
  static const String snackError = '❌ Kuch error aaya, dobara try karein.';
}
