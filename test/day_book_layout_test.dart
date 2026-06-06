import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_theme.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_sections.dart';

void main() {
  testWidgets('day book sections render without overflow on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _DayBookLayoutHarness());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Opening Gold'), findsOneWidget);
    expect(find.text('Closing Silver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day book sections render without overflow on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _DayBookLayoutHarness());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Opening Cash'), findsOneWidget);
    expect(find.text('Net Cash Flow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metal cards open the selected purity-wise movement',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: DayBookStyles.theme,
        home: Scaffold(
          backgroundColor: DayBookColors.bodyBg,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MetalMovementPanel(summary: _summary),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Silver'), findsOneWidget);
    expect(find.text('Diamond'), findsOneWidget);
    expect(find.text('Platinum'), findsOneWidget);
    expect(find.text('20K'), findsOneWidget);

    await tester.tap(find.text('Platinum'));
    await tester.pumpAndSettle();

    expect(find.text('Platinum Purity-wise Movement'), findsOneWidget);
    expect(find.text('950'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DayBookLayoutHarness extends StatelessWidget {
  const _DayBookLayoutHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DayBookStyles.theme,
      home: Scaffold(
        backgroundColor: DayBookColors.bodyBg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sales = SalesTaxPanel(summary: _summary);
              final payments = PaymentMixPanel(summary: _summary);
              final splitPanels = constraints.maxWidth >= 860
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: sales),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: payments),
                      ],
                    )
                  : Column(
                      children: [
                        sales,
                        const SizedBox(height: 12),
                        payments,
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DayBookOpeningPosition(summary: _summary),
                  const SizedBox(height: 12),
                  DayBookOverview(summary: _summary),
                  const SizedBox(height: 12),
                  CashMovementPanel(summary: _summary),
                  const SizedBox(height: 12),
                  splitPanels,
                  const SizedBox(height: 12),
                  MetalMovementPanel(summary: _summary),
                  const SizedBox(height: 12),
                  DayBookClosingPosition(summary: _summary),
                  const SizedBox(height: 12),
                  ForecastPanel(prediction: _summary.prediction!),
                  const SizedBox(height: 12),
                  DayBookClosePanel(
                    summary: _summary,
                    isToday: true,
                    onReconcile: _noop,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

void _noop() {}

final _summary = DayBookSummary(
  date: DateTime(2026, 6, 6),
  openingCash: 285000,
  openingGoldGrams: 4875.425,
  openingSilverGrams: 18340.750,
  cashIn: const CashInflow(
    gstSales: GstBillSummary(
      billCount: 14,
      taxableAmount: 412340,
      cgst: 6185.10,
      sgst: 6185.10,
      finalAmount: 424710.20,
    ),
    nonGstSales: NonGstBillSummary(
      billCount: 9,
      totalAmount: 183600,
    ),
    dueCollection: 48000,
    advance: 25000,
    orderDelivery: 76500,
    girviReturn: 19000,
    loanReceived: 35000,
    interestRec: 4200,
    miscIncome: 2750,
  ),
  cashOut: const CashOutflow(
    shopRent: 45000,
    staffSalary: 68000,
    electricity: 12400,
    purchasePayment: 216000,
    girviGiven: 75000,
    maintenance: 6200,
    advertising: 8500,
    transport: 3750,
    bankCharges: 960,
    govtFees: 2400,
    miscExpense: 1250,
  ),
  metalIn: const MetalInflow(
    karigarFinishedGoods: MetalWeight(
      gold22k: 248.765,
      gold18k: 74.450,
      silver: 860.250,
      additionalEntries: {
        'Gold::20K': 18.750,
        'Platinum::950': 12.400,
        'Diamond::VS': 3.250,
      },
    ),
    girviSecurityDeposit: MetalWeight(
      gold22k: 42.800,
      silver: 320.500,
    ),
    urdPurchase: MetalWeight(gold22k: 31.625),
    salesReturnReversal: MetalWeight(gold18k: 8.250),
  ),
  metalOut: const MetalOutflow(
    retailDispatch: MetalWeight(
      gold22k: 186.875,
      gold18k: 53.225,
      silver: 710.425,
      additionalEntries: {
        'Gold::20K': 7.500,
        'Platinum::950': 4.100,
        'Diamond::VS': 1.200,
      },
    ),
    karigarIssue: MetalWeight(
      gold22k: 92.450,
      gold18k: 24.775,
      silver: 180.900,
    ),
  ),
  paymentBreakup: const PaymentBreakup(
    cash: 245000,
    upi: 174500,
    card: 92500,
    bank: 86400,
    cheque: 9900,
  ),
  prediction: const PredictedClosing(
    predictedCash: 727435.20,
    vsYesterdayPct: 8.4,
  ),
);
