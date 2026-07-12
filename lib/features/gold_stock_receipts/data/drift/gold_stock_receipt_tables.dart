import 'package:drift/drift.dart';
import 'package:lotus_erp/database/tables/base_table.dart';
import 'package:lotus_erp/database/tables/stock/suppliers.dart';

@DataClassName('GoldStockReceiptRecord')
@TableIndex(name: 'idx_gold_receipt_supplier', columns: {#supplierId})
@TableIndex(name: 'idx_gold_receipt_received_at', columns: {#receivedAt})
class GoldStockReceipts extends Table with BaseTable {
  TextColumn get receiptNumber => text().unique()();
  TextColumn get source => text()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get supplierName => text()();
  TextColumn get supplierInvoiceNumber => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('POSTED'))();
  IntColumn get totalGrossWeightMilligrams => integer()();
  IntColumn get totalFineWeightMilligrams => integer()();
  IntColumn get totalCostPaise => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get createdByUserId => text().nullable()();
}

@DataClassName('GoldStockReceiptLineRecord')
@TableIndex(
  name: 'idx_gold_receipt_line_order',
  columns: {#receiptId, #lineNumber},
  unique: true,
)
@TableIndex(
  name: 'idx_gold_receipt_line_huid',
  columns: {#hallmarkUniqueId},
  unique: true,
)
class GoldStockReceiptLines extends Table with BaseTable {
  IntColumn get receiptId => integer()
      .references(GoldStockReceipts, #id, onDelete: KeyAction.cascade)();

  IntColumn get lineNumber => integer()();
  TextColumn get lineIdentifier => text()();
  TextColumn get category => text()();
  TextColumn get itemName => text()();
  IntColumn get quantity => integer()();
  IntColumn get grossWeightMilligrams => integer()();
  IntColumn get stoneWeightMilligrams => integer()();
  IntColumn get netWeightMilligrams => integer()();
  IntColumn get fineWeightMilligrams => integer()();
  IntColumn get purityPartsPerThousand => integer()();
  IntColumn get ratePerGramPaise => integer()();
  IntColumn get makingChargePaise => integer()();
  TextColumn get makingChargeMethod => text()();
  IntColumn get metalValuePaise => integer()();
  IntColumn get makingValuePaise => integer()();
  IntColumn get stoneValuePaise => integer().withDefault(const Constant(0))();
  IntColumn get totalCostPaise => integer()();
  TextColumn get hallmarkUniqueId => text().nullable()();
  TextColumn get stoneType => text().nullable()();
  IntColumn get stoneQuantity => integer().withDefault(const Constant(0))();
  IntColumn get stoneCaratPoints => integer().withDefault(const Constant(0))();
  TextColumn get stoneCertificateNumber => text().nullable()();
}

@DataClassName('GoldReceiptSettlementRecord')
@TableIndex(
  name: 'idx_gold_receipt_settlement_order',
  columns: {#receiptId, #sequenceNumber},
  unique: true,
)
class GoldReceiptSettlements extends Table with BaseTable {
  IntColumn get receiptId => integer()
      .references(GoldStockReceipts, #id, onDelete: KeyAction.cascade)();

  IntColumn get sequenceNumber => integer()();
  TextColumn get settlementMethod => text()();
  IntColumn get amountPaise => integer().withDefault(const Constant(0))();
  IntColumn get metalWeightMilligrams =>
      integer().withDefault(const Constant(0))();
  IntColumn get metalPurityPartsPerThousand =>
      integer().withDefault(const Constant(0))();
  IntColumn get metalFineWeightMilligrams =>
      integer().withDefault(const Constant(0))();
  IntColumn get bankAccountId => integer().nullable()();
  TextColumn get referenceNumber => text().nullable()();
  DateTimeColumn get settledAt => dateTime()();
}

@DataClassName('GoldReceiptAttachmentRecord')
@TableIndex(name: 'idx_gold_receipt_attachment_receipt', columns: {#receiptId})
class GoldReceiptAttachments extends Table with BaseTable {
  IntColumn get receiptId => integer()
      .references(GoldStockReceipts, #id, onDelete: KeyAction.cascade)();

  TextColumn get storagePath => text()();
  TextColumn get originalFileName => text()();
  TextColumn get contentType => text()();
  TextColumn get contentChecksum => text().nullable()();
  IntColumn get byteSize => integer().nullable()();
}

@DataClassName('GoldReceiptAuditEventRecord')
@TableIndex(
  name: 'idx_gold_receipt_audit_order',
  columns: {#receiptId, #occurredAt},
)
class GoldReceiptAuditEvents extends Table with BaseTable {
  IntColumn get receiptId => integer()
      .references(GoldStockReceipts, #id, onDelete: KeyAction.cascade)();

  TextColumn get eventType => text()();
  TextColumn get actorUserId => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
}
