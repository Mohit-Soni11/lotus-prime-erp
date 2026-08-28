import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/purchase/purchase_entry/purchase_item_model.dart';

void main() {
  test(
      'gross weight draft entry does not show inline error while rate is empty',
      () {
    final item = PurchaseItemModel();
    addTearDown(item.dispose);

    item.grossCtrl.text = '10';

    expect(item.hasContent, isTrue);
    expect(item.isValidEntry, isFalse);
    expect(item.hasInlineValidationError, isFalse);
  });

  test('inline validation catches impossible less weight', () {
    final item = PurchaseItemModel();
    addTearDown(item.dispose);

    item.grossCtrl.text = '10';
    item.lessCtrl.text = '10';

    expect(item.hasInlineValidationError, isTrue);
  });

  test('complete valid purchase item has no inline validation error', () {
    final item = PurchaseItemModel();
    addTearDown(item.dispose);

    item.grossCtrl.text = '10';
    item.lessCtrl.text = '1';
    item.rateCtrl.text = '1000';

    expect(item.isValidEntry, isTrue);
    expect(item.hasInlineValidationError, isFalse);
  });
}
