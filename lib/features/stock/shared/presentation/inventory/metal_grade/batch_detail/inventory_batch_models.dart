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
  int get soldItems => totalItems - availableItems;
  bool get hasAvailableStock => availableItems > 0;
  bool get isSoldOut => totalItems > 0 && availableItems == 0;
  bool get isPartiallySold => availableItems > 0 && soldItems > 0;
  String get sourceItemPreview {
    final seen = <String>{};
    final names = <String>[];
    for (final raw in units.first.sourceItemNames.split(',')) {
      final name = _titleCase(raw);
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      names.add(name);
    }
    if (names.isEmpty) {
      for (final unit in units) {
        final name = _titleCase(unit.itemName);
        if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
        names.add(name);
      }
    }
    if (names.isEmpty) return 'No item names recorded';
    final preview = names.take(3).join(', ');
    if (names.length <= 3) return preview;
    return '$preview +${names.length - 3} more';
  }

  String get sourceDocumentLabel {
    final invoice = supplierInvoiceNo.trim();
    if (invoice.isNotEmpty) return invoice;
    return batchCode;
  }

  int get sourceInvoiceItemCount {
    final seen = <String>{};
    for (final raw in units.first.sourceItemNames.split(',')) {
      final name = raw.trim().toLowerCase();
      if (name.isNotEmpty) seen.add(name);
    }
    if (seen.isNotEmpty) return seen.length;
    for (final unit in units) {
      final name = unit.itemName.trim().toLowerCase();
      if (name.isNotEmpty) seen.add(name);
    }
    return seen.isEmpty ? totalItems : seen.length;
  }

  String get dossierSubtitle {
    final parts = <String>[
      supplierName.isEmpty ? 'Supplier not linked' : supplierName,
      if (supplierInvoiceNo.isNotEmpty) 'Invoice $supplierInvoiceNo',
      if (createdAt > 0)
        DateFormat('dd MMM yyyy').format(
          DateTime.fromMillisecondsSinceEpoch(createdAt),
        ),
      sourceItemPreview,
    ];
    return parts.join(' - ');
  }

  String get totalStockUnitsLabel => _stockUnitCountText(totalItems);
  String get availableStockUnitsLabel => _stockUnitCountText(availableItems);
  String get soldStockUnitsLabel => _stockUnitCountText(soldItems);
  String get stockUnitBalanceLabel =>
      '$availableItems/$totalItems ${totalItems == 1 ? 'unit' : 'units'}';
  double get totalDisplayQuantity =>
      units.fold(0.0, (sum, unit) => sum + unit.displayTotalQuantity);
  double get availableDisplayQuantity =>
      units.fold(0.0, (sum, unit) => sum + unit.displayAvailableQuantity);
  double get soldDisplayQuantity =>
      units.fold(0.0, (sum, unit) => sum + unit.displaySoldQuantity);
  double get availableNetWeight =>
      units.fold(0.0, (sum, unit) => sum + unit.displayAvailableNetWeight);
  double get soldNetWeight =>
      units.fold(0.0, (sum, unit) => sum + unit.soldNetWeight);
  double get totalNetWeight =>
      units.fold(0.0, (sum, unit) => sum + unit.displayTotalNetWeight);
  double get totalGrossWeight =>
      units.fold(0.0, (sum, unit) => sum + unit.displayTotalGrossWeight);
  String get displayUnitSingular {
    final unitsSeen = <String>{};
    for (final unit in units) {
      unitsSeen.add(unit.displayUnitLabel);
    }
    return unitsSeen.length == 1
        ? _inventoryQuantityUnitName(unitsSeen.first, plural: false)
            .toLowerCase()
        : 'unit';
  }

  String get displayUnitPlural {
    final unitsSeen = <String>{};
    for (final unit in units) {
      unitsSeen.add(unit.displayUnitLabel);
    }
    return unitsSeen.length == 1
        ? _inventoryQuantityUnitName(unitsSeen.first, plural: true)
            .toLowerCase()
        : 'units';
  }

  String get displayUnitLabel {
    final unitsSeen = <String>{};
    for (final unit in units) {
      unitsSeen.add(unit.displayUnitLabel);
    }
    return unitsSeen.length == 1 ? unitsSeen.first : 'pcs';
  }

  String get totalQuantityLabel =>
      _inventoryDisplayQuantityText(totalDisplayQuantity, displayUnitLabel);
  String get availableQuantityLabel =>
      _inventoryDisplayQuantityText(availableDisplayQuantity, displayUnitLabel);
  String get soldQuantityLabel =>
      _inventoryDisplayQuantityText(soldDisplayQuantity, displayUnitLabel);
  String get quantityBalanceLabel =>
      '${_quantityNumber(availableDisplayQuantity)}/${_quantityNumber(totalDisplayQuantity)} $displayUnitPlural';

  String get stockStatusLabel {
    if (isSoldOut) return 'Sold Out';
    if (isPartiallySold) return 'Partially Sold';
    return 'Available';
  }

  String get searchText {
    return [
      batchCode,
      supplierName,
      supplierInvoiceNo,
      taxType,
      payment.paymentStatus,
      stockStatusLabel,
      for (final unit in units) ...[
        unit.itemName,
        unit.itemType,
        unit.companyName,
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

String _stockUnitCountText(int count) {
  return '$count ${count == 1 ? 'unit' : 'units'}';
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
  final String quantityMode;
  final int packetCount;
  final int piecesPerPacket;
  final String companyName;
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
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final double totalGrossWeight;
  final double totalNetWeight;
  final double availableGrossWeight;
  final double availableNetWeight;
  final double soldNetWeight;
  final int soldQuantity;
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
  final String sourceItemNames;

  const _InventoryGradeUnit({
    required this.unitId,
    required this.unitCode,
    required this.batchCode,
    required this.itemType,
    required this.quantityMode,
    required this.packetCount,
    required this.piecesPerPacket,
    required this.companyName,
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
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.totalGrossWeight,
    required this.totalNetWeight,
    required this.availableGrossWeight,
    required this.availableNetWeight,
    required this.soldNetWeight,
    required this.soldQuantity,
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
    required this.sourceItemNames,
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
      quantityMode: text('quantity_mode'),
      packetCount: integer('packet_count'),
      piecesPerPacket: integer('pieces_per_packet'),
      companyName: text('company_name'),
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
      totalPieces: integer('total_pieces'),
      availablePieces: integer('available_pieces'),
      soldPieces: integer('sold_pieces'),
      totalGrossWeight: number('total_gross_weight'),
      totalNetWeight: number('total_net_weight'),
      availableGrossWeight: number('available_gross_weight'),
      availableNetWeight: number('available_net_weight'),
      soldNetWeight: number('sold_net_weight'),
      soldQuantity: integer('sold_quantity'),
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
      sourceItemNames: text('source_item_names'),
    );
  }

  double get wastagePercent {
    if (netWeight <= 0) return 0.0;
    return (wastageFine / netWeight) * 100;
  }

  double get totalPurityPercent => purityPercent + wastagePercent;

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isLotStock =>
      unitCode.toLowerCase().contains('lot') && huid.trim().isEmpty;

  String get displayUnitLabel => _inventoryQuantityUnitLabel(this);

  String get displayUnitSingular =>
      _inventoryQuantityUnitName(displayUnitLabel, plural: false).toLowerCase();

  String get displayUnitPlural =>
      _inventoryQuantityUnitName(displayUnitLabel, plural: true).toLowerCase();

  double get displayTotalQuantity => _inventoryTotalDisplayUnits(this);

  double get displayAvailableQuantity => _inventoryAvailableDisplayUnits(this);

  double get displaySoldQuantity => _inventorySoldDisplayUnits(this);

  double get displayTotalNetWeight =>
      totalNetWeight > 0 ? totalNetWeight : netWeight;

  double get displayTotalGrossWeight =>
      totalGrossWeight > 0 ? totalGrossWeight : grossWeight;

  double get displayAvailableNetWeight => availableNetWeight > 0
      ? availableNetWeight
      : (isAvailable ? netWeight : 0.0);

  String get totalQuantityLabel => _quantityText(
      displayTotalQuantity, displayUnitSingular, displayUnitPlural);
  String get availableQuantityLabel => _quantityText(
      displayAvailableQuantity, displayUnitSingular, displayUnitPlural);
  String get soldQuantityLabel => _quantityText(
      displaySoldQuantity, displayUnitSingular, displayUnitPlural);
  String get quantityBalanceLabel =>
      '${_quantityNumber(displayAvailableQuantity)}/${_quantityNumber(displayTotalQuantity)} $displayUnitPlural';
}

String _quantityText(double quantity, String singular, String plural) {
  return '${_quantityNumber(quantity)} ${quantity == 1 ? singular : plural}';
}

String _quantityNumber(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.001) return rounded.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
