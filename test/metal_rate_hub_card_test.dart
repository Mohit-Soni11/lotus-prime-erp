import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/ui/settings/metal_rate/widgets/metal_rate_hub_card.dart';

void main() {
  testWidgets('metal card keeps rates readable across desktop widths',
      (tester) async {
    final base = MetalRateProfile.defaultFor(MetalRateMetal.gold);
    final profile = base.copyWith(
      physicalMarketRatePer10g: 150000,
      purityPlans: [
        base.purityPlans.first.copyWith(
          manualDisplayRatePer10g: 152000,
          buyRatePer10g: 147000,
        ),
        ...base.purityPlans.skip(1),
      ],
    );
    var opened = false;

    for (final width in [560.0, 350.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: MetalRateHubCard(
                  profile: profile,
                  onTap: () => opened = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('Market base'), findsOneWidget);
      expect(find.text('Selling rate'), findsOneWidget);
      expect(find.text('Old-metal buy'), findsOneWidget);
      expect(find.text('₹1,52,000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.text('Gold'));
    expect(opened, isTrue);
  });
}
