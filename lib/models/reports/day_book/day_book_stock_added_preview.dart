import 'day_book_stock_added_batch.dart';

/// Design-only batches; never used by repositories, balances or exports.
class DayBookStockAddedPreview {
  const DayBookStockAddedPreview._();

  static List<DayBookStockAddedBatch> forDate(DateTime date) => [
        DayBookStockAddedBatch(
          voucherId: -1,
          batchCode: 'STK-26-001473',
          metal: 'Gold',
          postedAt: DateTime(date.year, date.month, date.day, 10, 6),
          pieces: 2,
          netWeightGrams: 12,
          ratePerGram: 5450,
          makingTotal: 3600,
          purchaseValue: 69000,
        ),
        DayBookStockAddedBatch(
          voucherId: -2,
          batchCode: 'STK-26-001474',
          metal: 'Gold',
          postedAt: DateTime(date.year, date.month, date.day, 11, 18),
          pieces: 1,
          netWeightGrams: 18.5,
          ratePerGram: 6250,
          makingTotal: 5200,
          purchaseValue: 120825,
        ),
        DayBookStockAddedBatch(
          voucherId: -3,
          batchCode: 'STK-26-001475',
          metal: 'Silver',
          postedAt: DateTime(date.year, date.month, date.day, 12, 7),
          pieces: 3,
          netWeightGrams: 85,
          ratePerGram: 82,
          makingTotal: 1150,
          purchaseValue: 8120,
        ),
        DayBookStockAddedBatch(
          voucherId: -4,
          batchCode: 'STK-26-001476',
          metal: 'Silver',
          postedAt: DateTime(date.year, date.month, date.day, 12, 46),
          pieces: 2,
          netWeightGrams: 36,
          ratePerGram: 82,
          makingTotal: 920,
          purchaseValue: 3872,
        ),
      ];
}
