import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/reports/gst_report/data/gst_report_repository.dart';
import 'package:lotus_erp/features/reports/gst_report/domain/gst_report_models.dart';

void main() {
  late AppDatabase db;
  late GstReportRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GstReportRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('fetch builds dashboard, GSTR-1, GSTR-3B and HSN summaries', () async {
    await db.into(db.shopProfiles).insert(
          ShopProfilesCompanion.insert(
            shopName: const drift.Value('Anjali Jewellers'),
            legalName: const drift.Value('Anjali Jewellers Private Limited'),
            state: const drift.Value('Bihar'),
            gstin: const drift.Value('10ABCDE1234F1Z5'),
          ),
        );

    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Soni Traders',
            mobile: '9304479436',
            gstNumber: const drift.Value('10AAAAA0000A1Z5'),
            state: const drift.Value('Bihar'),
          ),
        );

    final b2bBillId = await _insertBill(
      db,
      billNo: 'TAX-AJ-2026-0001',
      customerId: customerId,
      customerName: 'Soni Traders',
      customerGstin: '10AAAAA0000A1Z5',
      placeOfSupply: 'Bihar',
      shopGstin: '10ABCDE1234F1Z5',
      shopStateCode: '10',
      customerStateCode: '10',
      billDate: DateTime(2026, 8, 6, 11),
      taxableAmount: 10000,
      cgstAmount: 150,
      sgstAmount: 150,
      gstAmount: 300,
      finalAmount: 10300,
    );
    await _insertItem(
      db,
      billId: b2bBillId,
      hsnCode: '7113',
      quantity: 2,
      taxableAmount: 10000,
      cgstAmount: 150,
      sgstAmount: 150,
      gstAmount: 300,
      gstRate: 3,
      itemTotal: 10300,
    );

    final b2cBillId = await _insertBill(
      db,
      billNo: 'TAX-AJ-2026-0002',
      customerName: 'Walk-in Customer',
      placeOfSupply: 'Maharashtra',
      shopGstin: '10ABCDE1234F1Z5',
      shopStateCode: '10',
      customerStateCode: '27',
      billDate: DateTime(2026, 8, 7, 13),
      taxableAmount: 1200,
      igstAmount: 36,
      gstAmount: 36,
      finalAmount: 1236,
    );
    await _insertItem(
      db,
      billId: b2cBillId,
      hsnCode: '7113',
      quantity: 1,
      taxableAmount: 1200,
      igstAmount: 36,
      gstAmount: 36,
      gstRate: 3,
      itemTotal: 1236,
    );

    await _insertBill(
      db,
      billNo: 'INV-AJ-2026-0003',
      billType: 'NORMAL',
      customerName: 'Estimate Customer',
      placeOfSupply: 'Bihar',
      shopGstin: '10ABCDE1234F1Z5',
      shopStateCode: '10',
      customerStateCode: '10',
      billDate: DateTime(2026, 8, 8, 15),
      taxableAmount: 0,
      gstAmount: 0,
      finalAmount: 5000,
    );

    final snapshot = await repository.fetch(
      GstReportPeriod.forMonth(DateTime(2026, 8)),
    );

    expect(snapshot.identity.shopName, 'Anjali Jewellers Private Limited');
    expect(snapshot.identity.gstin, '10ABCDE1234F1Z5');
    expect(snapshot.dashboard.totalInvoices, 3);
    expect(snapshot.dashboard.gstInvoiceCount, 2);
    expect(snapshot.dashboard.nonGstInvoiceCount, 1);
    expect(snapshot.dashboard.nonGstSalesEstimate, 5000);
    expect(snapshot.dashboard.taxableSales, 11200);
    expect(snapshot.dashboard.cgstAmount, 150);
    expect(snapshot.dashboard.sgstAmount, 150);
    expect(snapshot.dashboard.igstAmount, 36);
    expect(snapshot.dashboard.totalGst, 336);
    expect(snapshot.gstr1B2bInvoices, hasLength(1));
    expect(snapshot.gstr1B2cInvoices, hasLength(1));
    expect(snapshot.gstr3b.netTaxPayable, 336);
    expect(snapshot.hsnSummary, hasLength(2));

    final b2bHsn = snapshot.hsnSummary.singleWhere(
      (row) => row.invoiceType == 'B2B',
    );
    expect(b2bHsn.hsnCode, '7113');
    expect(b2bHsn.quantity, 2);
    expect(b2bHsn.taxableAmount, 10000);
    expect(b2bHsn.cgstAmount, 150);
    expect(b2bHsn.sgstAmount, 150);

    final b2cHsn = snapshot.hsnSummary.singleWhere(
      (row) => row.invoiceType == 'B2C',
    );
    expect(b2cHsn.igstAmount, 36);
    expect(
      snapshot.auditFindings.single.severity,
      GstAuditSeverity.info,
    );
  });

  test('filing workflow status persists monthly and quarterly snapshots',
      () async {
    final august = GstReportPeriod.forMonth(DateTime(2026, 8));

    await repository.setFilingTaskCompletion(
      period: august,
      task: GstFilingTask.monthlyTaxPayment,
      completed: true,
      amountSnapshot: 510.05,
      invoiceCountSnapshot: 2,
    );

    final monthlyWorkflow =
        await repository.fetchFilingWorkflowSnapshot(august);
    final monthlyStatus = monthlyWorkflow.statusFor(
      GstFilingTask.monthlyTaxPayment,
    );

    expect(monthlyStatus.completed, isTrue);
    expect(monthlyStatus.amountSnapshot, 510.05);
    expect(monthlyStatus.invoiceCountSnapshot, 2);
    expect(monthlyStatus.completedAt, isNotNull);

    await repository.setFilingTaskCompletion(
      period: GstReportPeriod.forMonth(DateTime(2026, 9)),
      task: GstFilingTask.quarterReturnFiled,
      completed: true,
      amountSnapshot: 1510.75,
      invoiceCountSnapshot: 9,
    );

    final quarterWorkflow = await repository.fetchFilingWorkflowSnapshot(
      GstReportPeriod.forMonth(DateTime(2026, 8)),
    );

    expect(quarterWorkflow.isQuarterComplete('FY2026-Q2'), isTrue);
    expect(
      quarterWorkflow.statusFor(GstFilingTask.quarterReturnFiled).completed,
      isTrue,
    );
    expect(
      quarterWorkflow
          .statusFor(GstFilingTask.quarterReturnFiled)
          .amountSnapshot,
      1510.75,
    );
  });
}

Future<int> _insertBill(
  AppDatabase db, {
  required String billNo,
  String billType = 'GST',
  int? customerId,
  required String customerName,
  String customerGstin = '',
  required String placeOfSupply,
  required String shopGstin,
  required String shopStateCode,
  required String customerStateCode,
  required DateTime billDate,
  required double taxableAmount,
  double cgstAmount = 0,
  double sgstAmount = 0,
  double igstAmount = 0,
  required double gstAmount,
  required double finalAmount,
}) {
  return db.into(db.bills).insert(
        BillsCompanion.insert(
          billNo: billNo,
          customerId: drift.Value<int?>(customerId),
          customerName: drift.Value(customerName),
          customerGstinSnapshot: drift.Value(customerGstin),
          placeOfSupplySnapshot: drift.Value(placeOfSupply),
          customerStateCodeSnapshot: drift.Value(customerStateCode),
          shopGstinSnapshot: drift.Value(shopGstin),
          shopStateCodeSnapshot: drift.Value(shopStateCode),
          billType: drift.Value(billType),
          paymentStatus: const drift.Value('PAID'),
          totalAmount: drift.Value(finalAmount),
          taxableAmount: drift.Value(taxableAmount),
          cgstAmount: drift.Value(cgstAmount),
          sgstAmount: drift.Value(sgstAmount),
          igstAmount: drift.Value(igstAmount),
          gstAmount: drift.Value(gstAmount),
          finalAmount: drift.Value(finalAmount),
          paidAmount: drift.Value(finalAmount),
          billDate: drift.Value(billDate),
          status: const drift.Value('ACTIVE'),
        ),
      );
}

Future<int> _insertItem(
  AppDatabase db, {
  required int billId,
  required String hsnCode,
  required int quantity,
  required double taxableAmount,
  double cgstAmount = 0,
  double sgstAmount = 0,
  double igstAmount = 0,
  required double gstAmount,
  required double gstRate,
  required double itemTotal,
}) {
  return db.into(db.billItems).insert(
        BillItemsCompanion.insert(
          billId: billId,
          lineNo: const drift.Value(1),
          metalType: const drift.Value('GOLD'),
          itemName: 'Gold Ring',
          hsnCode: drift.Value(hsnCode),
          quantity: drift.Value(quantity),
          itemTotal: drift.Value(itemTotal),
          taxableAmountSnapshot: drift.Value(taxableAmount),
          gstRateSnapshot: drift.Value(gstRate),
          cgstAmountSnapshot: drift.Value(cgstAmount),
          sgstAmountSnapshot: drift.Value(sgstAmount),
          igstAmountSnapshot: drift.Value(igstAmount),
          gstAmountSnapshot: drift.Value(gstAmount),
        ),
      );
}
