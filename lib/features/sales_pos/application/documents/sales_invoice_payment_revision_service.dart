import '../../../../core/documents/issued_invoice_archive.dart';
import '../../../../database/db/app_database.dart';
import '../../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../../repositories/sales_orders/pos/pos_metal_settlement_repository.dart';
import 'sales_invoice_due_payment_date_repository.dart';
import '../pdf/pos_invoice_pdf_builder.dart';

/// Saves a new issued PDF when a later due collection changes the bill.
/// The original issued file remains untouched in the archive.
class SalesInvoicePaymentRevisionService {
  SalesInvoicePaymentRevisionService({
    AppDatabase? database,
    IssuedInvoiceArchive archive = const IssuedInvoiceArchive(),
  })  : _database = database ?? AppDatabase(),
        _archive = archive;

  final AppDatabase _database;
  final IssuedInvoiceArchive _archive;

  Future<bool> synchronize(int billId, String billNo) async {
    final bill = await (_database.select(_database.bills)
          ..where((row) => row.id.equals(billId)))
        .getSingleOrNull();
    if (bill == null || bill.billNo != billNo) return false;

    final metadata = await _archive.readMetadata(
      IssuedInvoiceKind.sales,
      billId,
      billNo,
    );
    final recordedPaid = (metadata?['paidAmount'] as num?)?.toDouble();
    final recordedDue = (metadata?['dueAmount'] as num?)?.toDouble();
    final lastDuePaymentAt = await SalesInvoiceDuePaymentDateRepository(
      _database,
    ).latestForBill(billNo);
    final paymentDateText = lastDuePaymentAt?.toIso8601String();
    final recordedPaymentDate = metadata?['lastDuePaymentAt'] as String?;
    final revisionVersion =
        (metadata?['paymentRevisionVersion'] as num?)?.toInt() ?? 0;
    final issuedPayment =
        bill.cashPaid + bill.upiPaid + bill.cardPaid + bill.advancePaid;
    final laterCollection = (bill.paidAmount - issuedPayment)
        .clamp(0.0, double.infinity)
        .toDouble();
    if (recordedPaid != null &&
        recordedDue != null &&
        (recordedPaid - bill.paidAmount).abs() < 0.005 &&
        (recordedDue - bill.dueAmount).abs() < 0.005 &&
        (revisionVersion >= 3 || laterCollection < 0.005) &&
        recordedPaymentDate == paymentDateText) {
      return false;
    }

    if (metadata == null && laterCollection < 0.005) return false;

    final issuedPdf = await _archive.read(
      IssuedInvoiceKind.sales,
      billId,
      billNo,
    );
    if (issuedPdf == null) return false;

    final billing = PosBillingController(
      database: _database,
      initializeWorkspace: false,
    );
    final invoiceController = PosInvoiceController(
      billing: billing,
      database: _database,
      issuedInvoiceArchive: _archive,
    );
    try {
      if (!await billing.initializeForEdit(billId)) {
        throw StateError(
            'Sales bill $billNo could not be loaded for PDF revision.');
      }
      await invoiceController.generateInvoice();
      final invoice = invoiceController.invoice;
      if (invoice == null ||
          invoiceController.genState != InvoiceGenState.ready) {
        throw StateError('Sales bill $billNo could not be rendered.');
      }

      final templateId = metadata?['templateId'] as String? ??
          invoiceController.selectedTemplateId;
      final formatName = metadata?['format'] as String?;
      final format = PrintFormat.values
              .where((item) => item.name == formatName)
              .firstOrNull ??
          PrintFormat.a4;
      final revisedInvoice = invoice.copyWith(
        invoiceNumber: bill.billNo,
        invoiceDate: bill.billDate,
        customerName: bill.customerName ?? invoice.customerName,
        customerMobile: bill.mobile ?? invoice.customerMobile,
        customerGstin: bill.customerGstinSnapshot ?? invoice.customerGstin,
        customerStateCode:
            bill.customerStateCodeSnapshot ?? invoice.customerStateCode,
        placeOfSupply: bill.placeOfSupplySnapshot ?? invoice.placeOfSupply,
        shopGstin: bill.shopGstinSnapshot ?? invoice.shopGstin,
        shopStateCode: bill.shopStateCodeSnapshot ?? invoice.shopStateCode,
        dueCollectionPaid: laterCollection,
        lastDuePaymentAt: lastDuePaymentAt,
        balanceDue: bill.dueAmount,
        metalPaymentAllocations:
            await PosMetalSettlementRepository(_database).load(billId),
      );
      final bytes = await const PosInvoicePdfBuilder().build(
        invoice: revisedInvoice,
        options: PosInvoicePdfBuildOptions(
          format: format,
          copies: 1,
          includeDuplicateStamp: false,
          templateId: templateId,
          includeAllMetals: true,
          metalPrintSettings: invoiceController.metalPrintSettings,
        ),
      );
      await _archive.saveRevision(
        IssuedInvoiceKind.sales,
        billId,
        billNo,
        bytes,
      );
      await _archive.saveMetadata(
        IssuedInvoiceKind.sales,
        billId,
        billNo,
        {
          'templateId': templateId,
          'format': format.name,
          'paidAmount': bill.paidAmount,
          'dueAmount': bill.dueAmount,
          'lastDuePaymentAt': paymentDateText,
          'paymentRevisionVersion': 3,
        },
      );
      return true;
    } finally {
      invoiceController.dispose();
      billing.dispose();
    }
  }
}
