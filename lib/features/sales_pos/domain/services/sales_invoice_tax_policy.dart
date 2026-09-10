import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

class SalesInvoiceTaxPolicy {
  const SalesInvoiceTaxPolicy._();

  static const BillType defaultBillType = BillType.normal;
  static const GstPricingMode defaultGstPricingMode = GstPricingMode.exclusive;

  static bool appliesGst(BillType billType) => billType == BillType.gst;

  static BillType billTypeFromStorage(String value) {
    final normalized = value.trim().toUpperCase();
    return normalized == 'GST' ||
            normalized == 'TAX' ||
            normalized == 'TAX_INVOICE'
        ? BillType.gst
        : BillType.normal;
  }

  static String billTypeStorage(BillType billType) {
    return appliesGst(billType) ? 'GST' : 'NORMAL';
  }

  static String taxTreatmentStorage(BillType billType) {
    return appliesGst(billType) ? 'TAXABLE_SUPPLY' : 'NON_GST_SALE';
  }

  static GstPricingMode gstPricingModeFor(BillType billType) {
    return appliesGst(billType) ? defaultGstPricingMode : defaultGstPricingMode;
  }

  static SalesDocumentType documentTypeFor(BillType billType) {
    return SalesDocumentType.taxInvoice;
  }

  static String title(BillType billType) {
    return appliesGst(billType) ? 'GST Invoice' : 'Normal Bill';
  }

  static String statusLabel(BillType billType) {
    return appliesGst(billType) ? 'GST ACTIVE' : 'NORMAL';
  }

  static String supportingLabel(BillType billType) {
    return appliesGst(billType) ? 'GST shown separately' : 'GST not applied';
  }
}
