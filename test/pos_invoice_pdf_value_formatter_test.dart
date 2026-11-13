import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_pdf_value_formatter.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('money and weights omit only redundant fractional zeros', () {
    expect(PosInvoicePdfValueFormatter.rupees(159936), 'Rs 1,59,936');
    expect(PosInvoicePdfValueFormatter.rupees(9936.75), 'Rs 9,936.75');
    expect(PosInvoicePdfValueFormatter.rupees(12.5), 'Rs 12.50');
    expect(PosInvoicePdfValueFormatter.grams(50.620), '50.62');
    expect(PosInvoicePdfValueFormatter.grams(12), '12');
    expect(PosInvoicePdfValueFormatter.ratePerGram(11900), 'Rs 11,900/g');
  });

  test('making labels identify the actual calculation basis', () {
    for (final (type, input, expected) in [
      (MakingChargeType.percentage, '12', '12%'),
      (MakingChargeType.perGram, '20', 'Rs 20/g'),
      (MakingChargeType.perKg, '350', 'Rs 350/kg'),
      (MakingChargeType.perPiece, '500', 'Flat Rs 500'),
    ]) {
      final item = SaleItemModel(metal: MetalType.gold, makingChargeType: type);
      item.grossCtrl.text = '12';
      item.rateCtrl.text = '11900';
      item.makingCtrl.text = input;
      final settings = BillSettings(showMakingType: true);
      expect(
        PosInvoicePdfValueFormatter.making(
          item,
          settings,
          isWholesale: false,
        ),
        expected,
      );
      final amountOnly = BillSettings(showMakingType: false);
      expect(
        PosInvoicePdfValueFormatter.making(
          item,
          amountOnly,
          isWholesale: false,
        ),
        contains('($expected)'),
      );
      item.dispose();
    }
  });

  test('fixed making uses one label across units and shows quantity', () {
    final item = SaleItemModel(
      metal: MetalType.gold,
      makingChargeType: MakingChargeType.perPiece,
    );
    addTearDown(item.dispose);
    item.setUnitProfile(PosItemUnitProfile.pair);
    item.makingCtrl.text = '500';

    expect(PosInvoicePdfValueFormatter.makingRate(item), 'Flat Rs 500');
    item.pcsCtrl.text = '2';
    expect(PosInvoicePdfValueFormatter.makingRate(item), 'Flat Rs 500 × 2');
    item.setUnitProfile(PosItemUnitProfile.packet);
    expect(PosInvoicePdfValueFormatter.makingRate(item), 'Flat Rs 500 × 2');
  });
}
