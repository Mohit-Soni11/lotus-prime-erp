import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/market_refill_report/market_refill_report_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('market purchase PDF builds a list style document', () async {
    final now = DateTime(2026, 7, 21, 14, 48);
    final report = MarketRefillReport(
      range: MarketRefillDateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
        label: 'Active Purchase List',
      ),
      summary: const MarketRefillSummary(
        soldQuantity: 3,
        availableQuantity: 0,
        refillQuantity: 3,
        itemGroups: 2,
        metalGroups: 2,
        soldNetWeight: 0,
        availableNetWeight: 0,
      ),
      metals: const [
        MarketRefillMetalSummary(
          metal: 'Gold',
          soldQuantity: 2,
          availableQuantity: 0,
          refillQuantity: 2,
          itemGroups: 1,
          soldNetWeight: 0,
          availableNetWeight: 0,
        ),
        MarketRefillMetalSummary(
          metal: 'Silver',
          soldQuantity: 1,
          availableQuantity: 0,
          refillQuantity: 1,
          itemGroups: 1,
          soldNetWeight: 0,
          availableNetWeight: 0,
        ),
      ],
      rows: [
        MarketRefillItemRow(
          rowKey: 'gold|18kt|company|jhumka|pair',
          metal: 'Gold',
          gradeLabel: '18KT (75%)',
          companyName: '',
          itemType: 'Jhumka',
          unitLabel: 'pair',
          soldQuantity: 2,
          availableQuantity: 0,
          refillQuantity: 2,
          soldNetWeight: 0,
          availableNetWeight: 0,
          billCount: 1,
          latestInvoice: 'INV-001',
          lastSoldAt: now,
          companyNames: const [],
          itemNames: const ['3 TALA JHUMKA'],
          boughtQuantity: 2,
          purchaseDone: false,
        ),
        MarketRefillItemRow(
          rowKey: 'silver|80|raj|rakhi|pcs',
          metal: 'Silver',
          gradeLabel: '80% Silver',
          companyName: 'Raj',
          itemType: 'Rakhi',
          unitLabel: 'pcs',
          soldQuantity: 1,
          availableQuantity: 0,
          refillQuantity: 1,
          soldNetWeight: 0,
          availableNetWeight: 0,
          billCount: 1,
          latestInvoice: 'INV-002',
          lastSoldAt: now,
          companyNames: const ['Raj'],
          itemNames: const ['FANCY RAKHI'],
          boughtQuantity: 1,
          purchaseDone: true,
        ),
      ],
    );

    final bytes = await const MarketPurchasePdfService().build(report);
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));

    final raw = latin1.decode(bytes, allowInvalid: true);
    expect(raw.contains('Sold Net'), isFalse);
  });
}
