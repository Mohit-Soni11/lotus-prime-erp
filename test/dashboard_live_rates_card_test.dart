import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/ui/dashboard/live_rates_card.dart';

void main() {
  final rates = LiveRatesModel(
    state: LiveRateState.available,
    oldGoldBuy: '1,48,000',
    oldSilverBuy: '2,55,000',
    rateDate: DateTime(2026, 11, 15),
    source: 'Manual Rate Master',
    goldRates: const [
      LiveMetalRate(purity: '24K', perGram: '15,200', perBaseUnit: '1,52,000'),
      LiveMetalRate(purity: '22K', perGram: '13,923', perBaseUnit: '1,39,230'),
      LiveMetalRate(purity: '18K', perGram: '11,400', perBaseUnit: '1,14,000'),
      LiveMetalRate(purity: '14K', perGram: '8,900', perBaseUnit: '89,000'),
      LiveMetalRate(purity: '9K', perGram: '5,800', perBaseUnit: '58,000'),
    ],
    silverRates: const [
      LiveMetalRate(purity: '999', perGram: '265', perBaseUnit: '2,65,000'),
      LiveMetalRate(purity: '925', perGram: '245.13', perBaseUnit: '2,45,130'),
      LiveMetalRate(purity: '800', perGram: '212', perBaseUnit: '2,12,000'),
      LiveMetalRate(
          purity: '700',
          perGram: '190',
          perBaseUnit: '1,90,000',
          description: 'Local Jewellery'),
    ],
  );

  testWidgets('shows compact gold and silver rates and expandable buy rates',
      (tester) async {
    tester.view.physicalSize = const Size(1050, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveRatesCard(ratesStream: Stream.value(rates)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Today's Metal Rates"), findsOneWidget);
    expect(find.text('Live Rate'), findsOneWidget);
    expect(find.text('Per gram'), findsNWidgets(2));
    expect(find.text('Per 10g'), findsOneWidget);
    expect(find.text('Per kg'), findsOneWidget);
    expect(find.text('₹15,200'), findsOneWidget);
    expect(find.text('₹2,45,130'), findsOneWidget);
    expect(find.text('14K'), findsNothing);
    expect(find.text('800'), findsNothing);
    expect(find.text('Local Jewellery'), findsOneWidget);
    expect(find.text('₹1,90,000'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gold-rates-expand')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('14K'), findsOneWidget);
    expect(find.text('9K'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('silver-rates-expand')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('800'), findsOneWidget);
    expect(find.text('Local Jewellery'), findsOneWidget);
    expect(find.textContaining('Change (vs yesterday)'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('View Purchase Rates'));
    await tester.pump();
    expect(find.text('Hide Purchase Rates'), findsOneWidget);
    expect(find.text('₹1,48,000'), findsOneWidget);
    expect(find.text('₹2,55,000'), findsOneWidget);
    expect(find.text('Gold Old Metal Purchase'), findsOneWidget);
    expect(find.text('Silver Old Metal Purchase'), findsOneWidget);
    expect(find.textContaining('₹1,34,000'), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(600, 700);
    await tester.pump();
    expect(find.text('Per kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
