part of 'sales_report_pdf_builder.dart';

class _PdfGstBreakup {
  final double cgst;
  final double sgst;
  final double igst;

  const _PdfGstBreakup({
    required this.cgst,
    required this.sgst,
    required this.igst,
  });
}

class _PdfCustomerSalesAccumulator {
  final String customerName;
  final String mobile;
  final Set<int> invoiceIds = <int>{};
  final Set<String> businessTypes = <String>{};
  final Set<String> gstins = <String>{};
  double grossAmount = 0;
  double discountAmount = 0;
  double taxableAmount = 0;
  double gstAmount = 0;
  double finalAmount = 0;
  double paidAmount = 0;
  double dueAmount = 0;
  double advanceAmount = 0;
  double tradeInDeduction = 0;

  _PdfCustomerSalesAccumulator({
    required this.customerName,
    required this.mobile,
  });

  _PdfCustomerSalesRow toRow() {
    final normalizedBusinessTypes = businessTypes
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final normalizedGstins = gstins
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    return _PdfCustomerSalesRow(
      customerName: customerName,
      mobile: mobile,
      gstin: normalizedGstins.isEmpty
          ? ''
          : normalizedGstins.length == 1
              ? normalizedGstins.first
              : 'MULTIPLE',
      businessType: normalizedBusinessTypes.length == 1
          ? normalizedBusinessTypes.first
          : 'MIXED',
      invoiceCount: invoiceIds.length,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      advanceAmount: advanceAmount,
      tradeInDeduction: tradeInDeduction,
    );
  }
}

class _PdfCustomerSalesRow {
  final String customerName;
  final String mobile;
  final String gstin;
  final String businessType;
  final int invoiceCount;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double finalAmount;
  final double paidAmount;
  final double dueAmount;
  final double advanceAmount;
  final double tradeInDeduction;

  const _PdfCustomerSalesRow({
    required this.customerName,
    required this.mobile,
    required this.gstin,
    required this.businessType,
    required this.invoiceCount,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.advanceAmount,
    required this.tradeInDeduction,
  });
}

class _PdfHsnGstAccumulator {
  final String hsnCode;
  final double gstRate;
  final Set<int> invoiceIds = <int>{};
  int lineItemCount = 0;
  int pieces = 0;
  double taxableAmount = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double gstAmount = 0;
  double invoiceAmount = 0;

  _PdfHsnGstAccumulator({
    required this.hsnCode,
    required this.gstRate,
  });
}

class _PdfMetalGradeAccumulator {
  final String metalType;
  final String purity;
  final Set<int> invoiceIds = <int>{};
  int lineItemCount = 0;
  int pieces = 0;
  double grossWeight = 0;
  double netWeight = 0;
  double itemAmount = 0;
  double makingAmount = 0;

  _PdfMetalGradeAccumulator({
    required this.metalType,
    required this.purity,
  });
}
