import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/ui/settings/metal_rate/widgets/metal_rate_hub_card.dart';

void main() {
  testWidgets('metal selection names the purity of its selling rate',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 700,
          child: MetalRateHubCard(
            profile: MetalRateProfile.defaultFor(MetalRateMetal.gold),
            onTap: () {},
          ),
        ),
      ),
    ));

    expect(find.text('24K Selling Rate'), findsOneWidget);
    expect(find.text('Selling rate'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('silver selection shows the market rate per kilogram',
      (tester) async {
    final base = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 700,
          child: MetalRateHubCard(
            profile: base.copyWith(
              physicalMarketRatePer10g: 265000,
              marketRatePer10g: 265000,
            ),
            onTap: () {},
          ),
        ),
      ),
    ));

    expect(find.text('999 Selling Rate'), findsOneWidget);
    expect(find.text('₹2,65,000'), findsWidgets);
    expect(find.text('/kg'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
