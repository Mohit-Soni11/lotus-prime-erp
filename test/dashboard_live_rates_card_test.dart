import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/ui/dashboard/live_rates_card.dart';

void main() {
  final rates = LiveRatesModel(
    state: LiveRateState.available,
    gold24k: '1,52,000',
    gold22k: '1,39,230',
    gold18k: '1,14,000',
    gold24kPerGram: '15,200',
    gold22kPerGram: '13,923',
    gold18kPerGram: '11,400',
    silverRateKg: '2,65,000',
    silverJewellery: '2,451.3',
    silverIdols: '2,650',
    silver999PerGram: '265',
    silver925PerGram: '245.13',
    silver925RateKg: '2,45,130',
    oldGold24kBuy: '1,48,000',
    oldGold22kBuy: '1,34,000',
    oldGold18kBuy: '1,09,000',
    oldSilverBuy: '2,550',
    rateDate: DateTime(2026, 11, 15),
    source: 'Manual Rate Master',
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
    expect(find.text('₹15,200/g'), findsOneWidget);
    expect(find.text('₹2,45,130/kg'), findsOneWidget);
    expect(find.textContaining('Change (vs yesterday)'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('View Purchase Rates'));
    await tester.pump();
    expect(find.text('Hide Purchase Rates'), findsOneWidget);
    expect(find.textContaining('₹1,48,000/10g'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(600, 700);
    await tester.pump();
    expect(find.text('Per kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
