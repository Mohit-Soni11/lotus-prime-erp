import '../entities/gold_stock_receipt.dart';

final class GoldStockReceiptValidator {
  const GoldStockReceiptValidator();

  List<String> validate(GoldStockReceipt receipt) {
    final errors = <String>[];

    if (receipt.receiptNumber.trim().isEmpty) {
      errors.add('Receipt number is required.');
    }
    if (receipt.supplierId <= 0) {
      errors.add('A saved supplier profile is required.');
    }
    if (receipt.supplierName.trim().isEmpty) {
      errors.add('Supplier name is required.');
    }
    if (receipt.lines.isEmpty) {
      errors.add('At least one Gold receipt line is required.');
    }

    final seenHallmarkIds = <String>{};
    for (var index = 0; index < receipt.lines.length; index++) {
      final line = receipt.lines[index];
      final prefix = 'Line ${index + 1}';
      final hallmarkId = line.hallmarkUniqueId?.trim().toUpperCase();

      if (line.lineId.trim().isEmpty) {
        errors.add('$prefix requires a line identifier.');
      }
      if (line.itemName.trim().length < 2) {
        errors.add('$prefix requires an item name of at least 2 characters.');
      }
      if (line.quantity < 1) {
        errors.add('$prefix quantity must be at least 1.');
      }
      if (line.grossWeight.isZero || line.grossWeight.isNegative) {
        errors.add('$prefix gross weight must be greater than zero.');
      }
      if (line.stoneWeight.isNegative ||
          line.stoneWeight.compareTo(line.grossWeight) > 0) {
        errors
            .add('$prefix stone weight must be between zero and gross weight.');
      }
      if (line.netWeight.isZero || line.netWeight.isNegative) {
        errors.add('$prefix net weight must be greater than zero.');
      }
      if (line.purity.isZero) {
        errors.add('$prefix purity must be greater than zero.');
      }
      if (line.ratePerGram.isNegative) {
        errors.add('$prefix rate per gram must not be negative.');
      }
      if (line.makingCharge.isNegative) {
        errors.add('$prefix making charge must not be negative.');
      }
      if (hallmarkId != null && hallmarkId.isNotEmpty) {
        if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(hallmarkId)) {
          errors.add('$prefix HUID must contain exactly 6 letters or digits.');
        }
        if (line.quantity != 1) {
          errors.add('$prefix with a HUID must have quantity 1.');
        }
        if (!seenHallmarkIds.add(hallmarkId)) {
          errors.add('$prefix repeats HUID $hallmarkId in this receipt.');
        }
      }
      final stones = line.stoneDetails;
      if (stones != null) {
        if (stones.stoneType.trim().isEmpty) {
          errors
              .add('$prefix stone type is required when stone details exist.');
        }
        if (stones.quantity < 1) {
          errors.add('$prefix stone quantity must be at least 1.');
        }
        if (stones.totalCaratPoints < 0 || stones.totalValue.isNegative) {
          errors.add('$prefix stone values must not be negative.');
        }
      }
    }

    return List.unmodifiable(errors);
  }
}
