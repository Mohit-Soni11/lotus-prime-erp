import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/invoice_center/data/invoice_center_repository.dart';
import 'package:lotus_erp/features/invoice_center/domain/invoice_center_models.dart';

void main() {
  late AppDatabase db;
  late DriftInvoiceCenterRepository repository;
  final november = DateTime(2026, 11);
  final octoberDate = DateTime(2026, 10, 18).millisecondsSinceEpoch ~/ 1000;
  final novemberDate = DateTime(2026, 11, 24).millisecondsSinceEpoch ~/ 1000;

  InvoiceCenterQuery query(
    InvoiceCenterTab tab, {
    int page = 1,
    int pageSize = 8,
    String search = '',
    String metal = '',
  }) =>
      InvoiceCenterQuery(
        tab: tab,
        month: november,
        page: page,
        pageSize: pageSize,
        search: search,
        metal: metal,
      );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftInvoiceCenterRepository(db);
  });

  tearDown(() async => db.close());

  Future<void> seed() async {
    await db.customStatement(
      "INSERT INTO customers (name, mobile) VALUES ('Suman Verma', '9876543210')",
    );
    await db.customStatement('''
      INSERT INTO bills
        (bill_no, bill_date, customer_name, mobile, bill_type,
         payment_status, final_amount, paid_amount, due_amount, status)
      VALUES ('INV-OLD', ?, 'Amit Kumar', '9123456780', 'NORMAL',
              'PARTIAL', 1000, 400, 600, 'ACTIVE')
    ''', [octoberDate]);
    await db.customStatement('''
      INSERT INTO bills
        (bill_no, bill_date, customer_name, bill_type, gst_amount,
         payment_status, final_amount, paid_amount, due_amount, status)
      VALUES ('GST-NEW', ?, 'Priya Singh', 'GST', 50,
              'PAID', 1050, 1050, 0, 'ACTIVE')
    ''', [novemberDate]);
    await db.customStatement('''
      INSERT INTO bill_items (bill_id, item_name, metal_type)
      VALUES (2, 'Silver Ring', 'SILVER')
    ''');
    await db.customStatement('''
      INSERT INTO sales_orders
        (order_no, customer_id, item_name, metal_type, status, created_at)
      VALUES ('ADV-OLD', 1, 'Ring', 'GOLD', 'PENDING', ?)
    ''', [octoberDate]);
    await db.customStatement('''
      INSERT INTO order_advances (order_id, amount_paid)
      VALUES (1, 250)
    ''');
    await db.ensureReturnReversalSchema();
    await db.customStatement('''
      INSERT INTO return_vouchers
        (voucher_no, operation_type, source_type, source_id, source_number,
         customer_id, settlement_mode, return_value, created_at)
      VALUES ('CAN-001', 'BOOKING_CANCELLATION', 'ADVANCE_BOOKING', 9,
              'ADV-OTHER', 1, 'CASH', 120, ?)
    ''', [DateTime(2026, 11, 22).millisecondsSinceEpoch]);
  }

  test('monthly sales and cancellation totals use persisted document numbers',
      () async {
    await seed();
    final all = await repository.load(query(InvoiceCenterTab.all));
    expect(all.totalRows, 2);
    expect(
        all.rows.map((row) => row.number), containsAll(['GST-NEW', 'CAN-001']));
    expect(all.summary.forTab(InvoiceCenterTab.regular).count, 0);
    expect(all.summary.forTab(InvoiceCenterTab.gst).count, 1);
    expect(all.summary.forTab(InvoiceCenterTab.cancelled).count, 1);
    expect(all.rows.firstWhere((row) => row.number == 'CAN-001').kind,
        InvoiceCenterDocumentKind.cancellation);
  });

  test('due and advance stay visible across months, then leave when resolved',
      () async {
    await seed();
    final due = await repository.load(query(InvoiceCenterTab.due));
    final advance = await repository.load(query(InvoiceCenterTab.advance));
    expect(due.rows.single.number, 'INV-OLD');
    expect(due.summary.forTab(InvoiceCenterTab.due).amount, 600);
    expect(advance.rows.single.number, 'ADV-OLD');
    expect(advance.summary.forTab(InvoiceCenterTab.advance).amount, 250);

    await db.customStatement('''
      UPDATE bills SET paid_amount = 1000, due_amount = 0,
        payment_status = 'PAID' WHERE bill_no = 'INV-OLD'
    ''');
    await db.customStatement(
      "UPDATE sales_orders SET status = 'DELIVERED' WHERE order_no = 'ADV-OLD'",
    );
    expect((await repository.load(query(InvoiceCenterTab.due))).totalRows, 0);
    expect(
        (await repository.load(query(InvoiceCenterTab.advance))).totalRows, 0);
  });

  test('search and pagination run on real invoice records', () async {
    await seed();
    final searched = await repository.load(
      query(InvoiceCenterTab.due, search: '912345'),
    );
    expect(searched.rows.single.number, 'INV-OLD');
    final firstPage = await repository.load(
      query(InvoiceCenterTab.all, pageSize: 1),
    );
    final secondPage = await repository.load(
      query(InvoiceCenterTab.all, page: 2, pageSize: 1),
    );
    expect(firstPage.totalRows, 2);
    expect(firstPage.rows.single.number, isNot(secondPage.rows.single.number));
    final silver = await repository.load(
      query(InvoiceCenterTab.all, metal: 'SILVER'),
    );
    expect(silver.rows.single.number, 'GST-NEW');
    expect(silver.metals, contains('SILVER'));
  });
}
