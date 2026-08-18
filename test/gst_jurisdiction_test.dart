import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/tax/gst_jurisdiction.dart';

void main() {
  test('resolves intra-state supply from GSTIN and state text', () {
    final jurisdiction = GstJurisdictionResolver.resolve(
      shopGstin: '10ABCDE1234F1Z5',
      shopStateCode: '',
      shopStateName: 'Bihar',
      customerGstin: '',
      customerStateCode: '',
      customerStateName: '',
      placeOfSupply: 'Patna, Bihar',
    );

    expect(jurisdiction.isResolved, isTrue);
    expect(jurisdiction.shopStateCode, '10');
    expect(jurisdiction.placeOfSupplyStateCode, '10');
    expect(jurisdiction.isInterState, isFalse);
  });

  test('resolves inter-state supply from customer GSTIN', () {
    final jurisdiction = GstJurisdictionResolver.resolve(
      shopGstin: '10ABCDE1234F1Z5',
      shopStateCode: '',
      shopStateName: 'Bihar',
      customerGstin: '27AAAAA0000A1Z5',
      customerStateCode: '',
      customerStateName: '',
      placeOfSupply: '',
    );

    expect(jurisdiction.isResolved, isTrue);
    expect(jurisdiction.placeOfSupplyStateCode, '27');
    expect(jurisdiction.isInterState, isTrue);
  });

  test('splits output GST by resolved jurisdiction', () {
    final intraState = GstJurisdictionResolver.splitOutputTax(
      totalGst: 300,
      jurisdiction: const GstJurisdiction(
        shopStateCode: '10',
        placeOfSupplyStateCode: '10',
        placeOfSupplyName: 'Bihar',
        isInterState: false,
        isResolved: true,
      ),
    );
    final interState = GstJurisdictionResolver.splitOutputTax(
      totalGst: 300,
      jurisdiction: const GstJurisdiction(
        shopStateCode: '10',
        placeOfSupplyStateCode: '27',
        placeOfSupplyName: 'Maharashtra',
        isInterState: true,
        isResolved: true,
      ),
    );

    expect(intraState.cgst, 150);
    expect(intraState.sgst, 150);
    expect(intraState.igst, 0);
    expect(interState.cgst, 0);
    expect(interState.sgst, 0);
    expect(interState.igst, 300);
  });
}
