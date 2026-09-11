class SalesReportBillTaxClassifier {
  SalesReportBillTaxClassifier._();

  static const double _moneyTolerance = 0.005;

  static const Set<String> _gstBillTypes = {
    'GST',
    'TAX',
    'TAX_INVOICE',
  };

  static const Set<String> _normalBillTypes = {
    'NORMAL',
    'NON_GST',
    'NON_GST_BILL',
    'NON_GST_INVOICE',
    'SALES_INVOICE',
    'ESTIMATE',
  };

  static const Set<String> _nonGstTaxTreatments = {
    'NON_GST',
    'NON_GST_SALE',
    'NO_GST',
    'EXEMPT',
  };

  static const Set<String> _gstTaxTreatments = {
    'GST',
    'TAXABLE_SUPPLY',
  };

  static bool isGstInvoice({
    required String billNo,
    required String billType,
    required String taxTreatment,
    required double gstAmount,
    required double cgstAmount,
    required double sgstAmount,
    required double igstAmount,
    required double outputGstLiabilityAmount,
  }) {
    final normalizedBillType = _normalize(billType);
    final normalizedTaxTreatment = _normalize(taxTreatment);

    if (_normalBillTypes.contains(normalizedBillType) ||
        _nonGstTaxTreatments.contains(normalizedTaxTreatment)) {
      return false;
    }

    if (_gstBillTypes.contains(normalizedBillType)) {
      return true;
    }

    final hasRecordedTax = gstAmount.abs() > _moneyTolerance ||
        cgstAmount.abs() > _moneyTolerance ||
        sgstAmount.abs() > _moneyTolerance ||
        igstAmount.abs() > _moneyTolerance ||
        outputGstLiabilityAmount.abs() > _moneyTolerance;

    if (hasRecordedTax) {
      return true;
    }

    if (_gstTaxTreatments.contains(normalizedTaxTreatment) &&
        normalizedBillType.isEmpty) {
      return true;
    }

    return normalizedBillType.isEmpty &&
        normalizedTaxTreatment.isEmpty &&
        billNo.trim().toUpperCase().startsWith('TAX-');
  }

  static String _normalize(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }
}
