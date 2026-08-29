import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_metal_cards/customer_metal_purchase_metal_card_grid.dart';

void main() {
  testWidgets('metal report card hides pending metric when nothing is due',
      (tester) async {
    final animationController = AnimationController(vsync: tester);
    addTearDown(animationController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            child: CustomerMetalPurchaseMetalCardGrid(
              periodLabel: 'August 2026',
              summaries: {
                CustomerMetalPurchaseMetal.gold: _summary(
                  metal: CustomerMetalPurchaseMetal.gold,
                  pendingAmount: 0,
                ),
              },
              selectedMetal: null,
              animationController: animationController,
              onMetalSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('metal report card shows pending metric only when amount is due',
      (tester) async {
    final animationController = AnimationController(vsync: tester);
    addTearDown(animationController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            child: CustomerMetalPurchaseMetalCardGrid(
              periodLabel: 'August 2026',
              summaries: {
                CustomerMetalPurchaseMetal.silver: _summary(
                  metal: CustomerMetalPurchaseMetal.silver,
                  pendingAmount: 2460,
                ),
              },
              selectedMetal: CustomerMetalPurchaseMetal.silver,
              animationController: animationController,
              onMetalSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Silver'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('₹2,460'), findsOneWidget);
  });
}

CustomerMetalPurchaseMetalSummary _summary({
  required CustomerMetalPurchaseMetal metal,
  required double pendingAmount,
}) {
  return CustomerMetalPurchaseMetalSummary(
    metal: metal,
    grossWeight: 16.12,
    netWeight: 16.12,
    fineWeight: 11.56,
    amount: 167635,
    paidAmount: 52435,
    pendingAmount: pendingAmount,
    cashPaid: 52435,
    upiPaid: 0,
    bankPaid: 0,
    cardPaid: 0,
    entryCount: 7,
    customerCount: 1,
    directPurchaseCount: 7,
    tradeInCount: 0,
    refundCount: 0,
  );
}
