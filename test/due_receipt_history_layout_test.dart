import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import 'package:lotus_erp/models/finance/due_receipt_history/due_receipt_history_model.dart';
import 'package:lotus_erp/repositories/finance/due_receipt_history_repository.dart';
import 'package:lotus_erp/ui/finance/due_receipt_history/due_receipt_history_app_bar.dart';
import 'package:lotus_erp/ui/finance/due_receipt_history/due_receipt_history_body.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

class _ReceiptFixture extends DueReceiptHistoryRepository {
  _ReceiptFixture(AppDatabase db, this.items) : super(db: db);

  final List<DueReceiptModel> items;

  @override
  Stream<List<DueReceiptModel>> watchReceipts() => Stream.value(items);
}

void main() {
  testWidgets('receipt history fits desktop, medium and narrow windows',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = DueReceiptHistoryController(
      repository: _ReceiptFixture(db, [
        DueReceiptModel(
          id: 'CASH:1',
          ledgerId: 1,
          ledgerSource: 'CASH',
          receiptNo: 'TXN-2026-0001',
          billNo: 'AJ-26-001',
          billId: 1,
          customerId: 1,
          customerName: 'Reyansh Soni',
          mobile: '9304479436',
          city: 'Patna',
          address: 'East Lakshmi Nagar, Patna',
          receiptDate: DateTime.now(),
          billDate: DateTime.now(),
          amount: 5142,
          paymentMode: 'CASH',
          channelLabel: 'Cash Book',
          bankAccountName: null,
          description: 'Due collection',
          referenceId: 'AJ-26-001#DUE#CASH',
          billAmount: 262484,
          billPaid: 262484,
          currentDue: 0,
          billPaymentStatus: 'SETTLED',
        ),
      ]),
    );
    addTearDown(() async {
      controller.dispose();
      await db.close();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(1920, 1080),
      const Size(850, 750),
      const Size(360, 700),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: DueReceiptHistoryAppBar(
            onBack: () {},
            status: SystemStatus.online,
          ),
          body: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => DueReceiptHistoryBody(
              ctrl: controller,
              onPrint: () {},
              onExport: () {},
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('DUE RECEIPT HISTORY'), findsOneWidget);
      expect(find.text('Total Collected'), findsOneWidget);
    }

    controller.searchCtrl.text = 'missing receipt';
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No receipts found'), findsOneWidget);
    expect(find.text('Receipt Details'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
