import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/purchase/purchase_entry_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('customer metal purchase invoice requires payout and commitment date',
      () {
    final controller = PurchaseEntryController();
    addTearDown(controller.dispose);

    controller.nameCtrl.text = 'Reyansh Soni';
    controller.addItem();
    final item = controller.items.single;
    item.descCtrl.text = 'Old Gold Ring';
    item.grossCtrl.text = '10';
    item.rateCtrl.text = '100';

    expect(
      controller.invoiceReadinessError,
      'Enter at least one seller payout amount before generating invoice.',
    );

    controller.cashCtrl.text = '500';
    expect(
      controller.invoiceReadinessError,
      'Select payout commitment date for remaining seller payout.',
    );

    controller.setPayoutCommitmentDate(DateTime(2026, 8, 26));
    expect(controller.invoiceReadinessError, isNull);
  });
}
