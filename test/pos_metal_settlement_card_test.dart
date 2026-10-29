import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/payment_summary/pos_payment_summary_cards.dart';

void main() {
  const allocations = [
    PosInvoiceMetalPaymentAllocation(
      metal: MetalType.gold,
      grossAmount: 6000,
      discountAmount: 100,
      netPayable: 5900,
      cashPaid: 5900,
      settleFirst: true,
    ),
    PosInvoiceMetalPaymentAllocation(
      metal: MetalType.silver,
      grossAmount: 2000,
      discountAmount: 200,
      netPayable: 1800,
      cashPaid: 600,
    ),
  ];

  testWidgets('settlement card fits the POS panel and exposes manual mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool manualMode = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PosMetalPaymentAllocationCard(
            allocations: allocations,
            settleFirstMetals: const {MetalType.gold},
            onToggle: (_) {},
            metalDiscounts: const {MetalType.gold: 100, MetalType.silver: 200},
            onDiscountChanged: (_, __) {},
            manualMode: manualMode,
            onManualModeChanged: (value) => manualMode = value,
            manualPaidByMetal: const {},
            onManualPaidChanged: (_, __) {},
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('GOLD first'), findsOneWidget);
    expect(find.text('SILVER first'), findsOneWidget);
    expect(find.text('Net Bill'), findsNWidgets(2));
    await tester.tap(find.text('Enter paid amounts manually'));
    expect(manualMode, isTrue);
  });

  testWidgets('manual paid amount remains fully visible at POS panel width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PosMetalPaymentAllocationCard(
            allocations: [
              PosInvoiceMetalPaymentAllocation(
                metal: MetalType.gold,
                netPayable: 258884.64,
                cashPaid: 258884.64,
              ),
              PosInvoiceMetalPaymentAllocation(
                metal: MetalType.silver,
                netPayable: 9000,
                cashPaid: 1115.36,
              ),
            ],
            settleFirstMetals: {},
            onToggle: _noopMetal,
            metalDiscounts: {},
            onDiscountChanged: _noopAmount,
            manualMode: true,
            onManualModeChanged: _noopBool,
            manualPaidByMetal: {
              MetalType.gold: 258884.64,
              MetalType.silver: 1115.36,
            },
            onManualPaidChanged: _noopAmount,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('258884.64'), findsOneWidget);
    expect(find.text('Use settle-first order'), findsOneWidget);
  });
}

void _noopMetal(MetalType _) {}
void _noopAmount(MetalType _, double __) {}
void _noopBool(bool _) {}
