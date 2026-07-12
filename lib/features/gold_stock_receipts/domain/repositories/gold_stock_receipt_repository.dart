import '../entities/gold_stock_receipt.dart';

final class GoldStockReceiptPersistenceResult {
  final int receiptId;
  final String receiptNumber;
  final int lineCount;

  const GoldStockReceiptPersistenceResult({
    required this.receiptId,
    required this.receiptNumber,
    required this.lineCount,
  });
}

abstract interface class GoldStockReceiptRepository {
  Future<GoldStockReceiptPersistenceResult> record(
    GoldStockReceipt receipt,
  );
}
