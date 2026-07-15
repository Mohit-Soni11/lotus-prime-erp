part of '../../inventory_screen.dart';

class _InventoryBatchGroup {
  final String batchCode;
  final String supplierName;
  final String supplierMobile;
  final String supplierGstNumber;
  final String taxType;
  final String supplierInvoiceNo;
  final int createdAt;
  final List<_InventoryGradeUnit> units;
  final int totalItems;
  final int availableItems;
  final double grossWeight;
  final double netWeight;
  final double actualFine;
  final double wastageFine;
  final double valuationFine;
  final double makingAmount;
  final double stockValue;
  final _InventoryPaymentSummary payment;

  const _InventoryBatchGroup({
    required this.batchCode,
    required this.supplierName,
    required this.supplierMobile,
    required this.supplierGstNumber,
    required this.taxType,
    required this.supplierInvoiceNo,
    required this.createdAt,
    required this.units,
    required this.totalItems,
    required this.availableItems,
    required this.grossWeight,
    required this.netWeight,
    required this.actualFine,
    required this.wastageFine,
    required this.valuationFine,
    required this.makingAmount,
    required this.stockValue,
    required this.payment,
  });

  bool get isGst => taxType.toUpperCase().contains('GST');

  String get searchText {
    return [
      batchCode,
      supplierName,
      supplierInvoiceNo,
      taxType,
      payment.paymentStatus,
      for (final unit in units) ...[
        unit.itemName,
        unit.itemType,
        unit.segment,
        unit.huid,
        unit.unitCode,
      ],
    ].join(' ').toLowerCase();
  }

  factory _InventoryBatchGroup.fromUnits(
    String batchCode,
    List<_InventoryGradeUnit> units,
  ) {
    final first = units.first;
    return _InventoryBatchGroup(
      batchCode: batchCode,
      supplierName: first.supplierName,
      supplierMobile: first.supplierMobile,
      supplierGstNumber: first.supplierGstNumber,
      taxType: first.taxType,
      supplierInvoiceNo: first.supplierInvoiceNo,
      createdAt: first.batchCreatedAt,
      units: units,
      totalItems: units.length,
      availableItems: units
          .where((unit) => unit.status.toLowerCase() == 'available')
          .length,
      grossWeight: units.fold(0.0, (sum, unit) => sum + unit.grossWeight),
      netWeight: units.fold(0.0, (sum, unit) => sum + unit.netWeight),
      actualFine: units.fold(0.0, (sum, unit) => sum + unit.actualFine),
      wastageFine: units.fold(0.0, (sum, unit) => sum + unit.wastageFine),
      valuationFine: units.fold(0.0, (sum, unit) => sum + unit.valuationFine),
      makingAmount: units.fold(0.0, (sum, unit) => sum + unit.makingAmount),
      stockValue: units.fold(0.0, (sum, unit) => sum + unit.unitCost),
      payment: _InventoryPaymentSummary.fromUnit(first),
    );
  }

  double get purityPercent {
    if (netWeight <= 0) return 0.0;
    return (actualFine / netWeight) * 100;
  }

  double get wastagePercent {
    if (netWeight <= 0) return 0.0;
    return (wastageFine / netWeight) * 100;
  }

  double get valuationPurityPercent => purityPercent + wastagePercent;
}

class _InventoryPaymentSummary {
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final double metalPaidFine;
  final double metalPaidValue;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double fineDueWeight;
  final double fineDueValue;
  final double fineReturnWeight;
  final double fineReturnValue;
  final double supplierCreditValue;
  final String paymentStatus;
  final String dueMode;
  final String excessMode;
  final String attachmentPath;
  final String paymentMode;
  final String balanceLabel;

  const _InventoryPaymentSummary({
    required this.grandTotal,
    required this.totalPaid,
    required this.balanceDue,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankPaid,
    required this.cardPaid,
    required this.metalPaidFine,
    required this.metalPaidValue,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.fineDueWeight,
    required this.fineDueValue,
    required this.fineReturnWeight,
    required this.fineReturnValue,
    required this.supplierCreditValue,
    required this.paymentStatus,
    required this.dueMode,
    required this.excessMode,
    required this.attachmentPath,
    required this.paymentMode,
    required this.balanceLabel,
  });

  factory _InventoryPaymentSummary.fromUnit(_InventoryGradeUnit unit) {
    final meta = _decodePaymentMeta(unit.paymentMeta);
    return _InventoryPaymentSummary(
      grandTotal: unit.grandTotal,
      totalPaid: unit.totalPaid,
      balanceDue: unit.balanceDue,
      cashPaid: unit.cashPaid,
      upiPaid: unit.upiPaid,
      bankPaid: unit.bankPaid,
      cardPaid: unit.cardPaid,
      metalPaidFine: unit.metalPaidFine,
      metalPaidValue: unit.metalPaidValue,
      gstAmount: unit.gstAmount,
      cgstAmount: unit.cgstAmount,
      sgstAmount: unit.sgstAmount,
      fineDueWeight: _metaDouble(meta, 'fineDueWeight'),
      fineDueValue: _metaDouble(meta, 'fineDueValue'),
      fineReturnWeight: _metaDouble(meta, 'fineReturnWeight'),
      fineReturnValue: _metaDouble(meta, 'fineReturnValue'),
      supplierCreditValue: _metaDouble(meta, 'supplierCreditValue'),
      paymentStatus: unit.paymentStatus,
      dueMode: unit.dueMode,
      excessMode: unit.excessMode,
      attachmentPath: _metaString(meta, 'supplierBillAttachmentPath'),
      paymentMode: _metaString(meta, 'mode'),
      balanceLabel: _metaString(meta, 'balanceLabel'),
    );
  }

  bool get hasAttachment => attachmentPath.trim().isNotEmpty;
}

class _InventoryGradeUnit {
  final int unitId;
  final String unitCode;
  final String batchCode;
  final String itemType;
  final String segment;
  final String itemName;
  final String huid;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purityPercent;
  final double actualFine;
  final double wastageFine;
  final double valuationFine;
  final double ratePerGram;
  final double makingAmount;
  final double unitCost;
  final String supplierName;
  final String supplierMobile;
  final String supplierGstNumber;
  final String taxType;
  final String supplierInvoiceNo;
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final double metalPaidFine;
  final double metalPaidValue;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final String paymentStatus;
  final String dueMode;
  final String excessMode;
  final String paymentMeta;
  final int batchCreatedAt;
  final String status;

  const _InventoryGradeUnit({
    required this.unitId,
    required this.unitCode,
    required this.batchCode,
    required this.itemType,
    required this.segment,
    required this.itemName,
    required this.huid,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purityPercent,
    required this.actualFine,
    required this.wastageFine,
    required this.valuationFine,
    required this.ratePerGram,
    required this.makingAmount,
    required this.unitCost,
    required this.supplierName,
    required this.supplierMobile,
    required this.supplierGstNumber,
    required this.taxType,
    required this.supplierInvoiceNo,
    required this.grandTotal,
    required this.totalPaid,
    required this.balanceDue,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankPaid,
    required this.cardPaid,
    required this.metalPaidFine,
    required this.metalPaidValue,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.paymentStatus,
    required this.dueMode,
    required this.excessMode,
    required this.paymentMeta,
    required this.batchCreatedAt,
    required this.status,
  });

  factory _InventoryGradeUnit.fromRow(QueryRow row) {
    String text(String column) {
      final value = row.data[column];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return '';
    }

    double number(String column) {
      final value = row.data[column];
      if (value is num) return value.toDouble();
      return 0.0;
    }

    int integer(String column) {
      final value = row.data[column];
      if (value is num) return value.toInt();
      return 0;
    }

    return _InventoryGradeUnit(
      unitId: integer('unit_id'),
      unitCode: text('unit_code'),
      batchCode: text('batch_code'),
      itemType: text('item_type'),
      segment: text('segment'),
      itemName: text('item_name'),
      huid: text('huid'),
      grossWeight: number('gross_weight'),
      lessWeight: number('less_weight'),
      netWeight: number('net_weight'),
      purityPercent: number('purity_percent'),
      actualFine: number('actual_fine'),
      wastageFine: number('wastage_fine'),
      valuationFine: number('valuation_fine'),
      ratePerGram: number('rate_per_gram'),
      makingAmount: number('making_amount'),
      unitCost: number('unit_cost'),
      supplierName: text('supplier_name'),
      supplierMobile: text('supplier_mobile'),
      supplierGstNumber: text('supplier_gst_number'),
      taxType: text('tax_type'),
      supplierInvoiceNo: text('supplier_invoice_no'),
      grandTotal: number('grand_total'),
      totalPaid: number('total_paid'),
      balanceDue: number('balance_due'),
      cashPaid: number('cash_paid'),
      upiPaid: number('upi_paid'),
      bankPaid: number('bank_paid'),
      cardPaid: number('card_paid'),
      metalPaidFine: number('metal_paid_fine'),
      metalPaidValue: number('metal_paid_value'),
      gstAmount: number('gst_amount'),
      cgstAmount: number('cgst_amount'),
      sgstAmount: number('sgst_amount'),
      paymentStatus: text('payment_status'),
      dueMode: text('due_mode'),
      excessMode: text('excess_mode'),
      paymentMeta: text('payment_meta'),
      batchCreatedAt: integer('batch_created_at'),
      status: text('status'),
    );
  }

  double get wastagePercent {
    if (netWeight <= 0) return 0.0;
    return (wastageFine / netWeight) * 100;
  }

  double get totalPurityPercent => purityPercent + wastagePercent;
}
