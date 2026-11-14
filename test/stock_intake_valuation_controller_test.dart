import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_intake_valuation_controller.dart';

void main() {
  test('Gold intake values fine weight, making and GST without payment data',
      () {
    final valuation = StockIntakeValuationController(gramsPerRate: 10);
    addTearDown(valuation.dispose);

    valuation.setRatePerBase(120000);
    valuation.updateTotals(fineWeight: 5, makingAmount: 1000);
    valuation.setGstEnabled(true);

    expect(valuation.ratePerGram, 12000);
    expect(valuation.metalValue, 60000);
    expect(valuation.subtotalAmount, 61000);
    expect(valuation.gstAmount, 1830);
    expect(valuation.totalAmount, 62830);

    valuation.gstPercentCtrl.text = '5';
    expect(valuation.configuredGstPercent, 5);
    expect(valuation.totalAmount, 64050);

    valuation.setGstEnabled(false);
    expect(valuation.totalAmount, 61000);
  });

  test('Silver intake applies the invoice rate per kilogram', () {
    final valuation = StockIntakeValuationController(gramsPerRate: 1000);
    addTearDown(valuation.dispose);

    valuation.setRatePerBase(100000);
    valuation.updateTotals(fineWeight: 250, makingAmount: 500);

    expect(valuation.ratePerGram, 100);
    expect(valuation.totalAmount, 25500);
  });
}
