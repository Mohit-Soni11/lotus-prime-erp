import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_stock_receipt.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_stock_receipt_repository.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_stock_receipt_validator.dart';

final class GoldStockReceiptValidationException implements Exception {
  final List<String> errors;

  const GoldStockReceiptValidationException(this.errors);

  @override
  String toString() => errors.join(' ');
}

final class DriftGoldStockReceiptRepository
    implements GoldStockReceiptRepository {
  final AppDatabase _database;
  final GoldStockReceiptValidator _validator;

  const DriftGoldStockReceiptRepository(
    this._database, {
    GoldStockReceiptValidator validator = const GoldStockReceiptValidator(),
  }) : _validator = validator;

  @override
  Future<GoldStockReceiptPersistenceResult> record(
    GoldStockReceipt receipt,
  ) async {
    final errors = _validator.validate(receipt);
    if (errors.isNotEmpty) {
      throw GoldStockReceiptValidationException(errors);
    }

    return _database.transaction(() async {
      final receiptId = await _database
          .into(_database.goldStockReceipts)
          .insert(
            GoldStockReceiptsCompanion.insert(
              receiptNumber: receipt.receiptNumber.trim(),
              source: receipt.source.name,
              supplierId: receipt.supplierId,
              supplierName: receipt.supplierName.trim(),
              supplierInvoiceNumber: Value(
                _nullableText(receipt.supplierInvoiceNumber),
              ),
              totalGrossWeightMilligrams: receipt.totalGrossWeight.milligrams,
              totalFineWeightMilligrams: receipt.totalFineWeight.milligrams,
              totalCostPaise: receipt.totalCost.paise,
              currencyCode: Value(receipt.totalCost.currencyCode),
              receivedAt: receipt.receivedAt,
              createdByUserId: Value(_nullableText(receipt.createdByUserId)),
            ),
          );

      for (var index = 0; index < receipt.lines.length; index++) {
        final line = receipt.lines[index];
        final stone = line.stoneDetails;
        await _database.into(_database.goldStockReceiptLines).insert(
              GoldStockReceiptLinesCompanion.insert(
                receiptId: receiptId,
                lineNumber: index + 1,
                lineIdentifier: line.lineId.trim(),
                category: line.category.name,
                itemName: line.itemName.trim(),
                quantity: line.quantity,
                grossWeightMilligrams: line.grossWeight.milligrams,
                stoneWeightMilligrams: line.stoneWeight.milligrams,
                netWeightMilligrams: line.netWeight.milligrams,
                fineWeightMilligrams: line.fineWeight.milligrams,
                purityPartsPerThousand: line.purity.partsPerThousand,
                ratePerGramPaise: line.ratePerGram.paise,
                makingChargePaise: line.makingCharge.paise,
                makingChargeMethod: line.makingChargeMethod.name,
                metalValuePaise: line.metalValue.paise,
                makingValuePaise: line.totalMakingCharge.paise,
                stoneValuePaise: Value(line.totalStoneValue.paise),
                totalCostPaise: line.totalCost.paise,
                hallmarkUniqueId: Value(_nullableText(line.hallmarkUniqueId)),
                stoneType: Value(_nullableText(stone?.stoneType)),
                stoneQuantity: Value(stone?.quantity ?? 0),
                stoneCaratPoints: Value(stone?.totalCaratPoints ?? 0),
                stoneCertificateNumber: Value(
                  _nullableText(stone?.certificateNumber),
                ),
              ),
            );
      }

      await _database.into(_database.goldReceiptAuditEvents).insert(
            GoldReceiptAuditEventsCompanion.insert(
              receiptId: receiptId,
              eventType: 'RECEIPT_POSTED',
              actorUserId: Value(_nullableText(receipt.createdByUserId)),
              occurredAt: receipt.receivedAt,
            ),
          );

      return GoldStockReceiptPersistenceResult(
        receiptId: receiptId,
        receiptNumber: receipt.receiptNumber,
        lineCount: receipt.lines.length,
      );
    });
  }

  String? _nullableText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
