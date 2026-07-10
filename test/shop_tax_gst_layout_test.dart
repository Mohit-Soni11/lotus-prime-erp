import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/shop_setup/enums/basic_info_enums.dart';
import 'package:lotus_erp/models/setting/shop_setup/shop_step_model.dart';
import 'package:lotus_erp/ui/settings/shop_setup/layout/shop_setup_layout.dart';
import 'package:lotus_erp/ui/settings/shop_setup/tabs/tax_gst_tab.dart';

void main() {
  testWidgets('Tax GST tab renders in narrow layout without layout exceptions',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(820, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: TaxGstTab(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Statutory & Tax Compliance'), findsOneWidget);
    expect(find.text('Bureau of Indian Standards'), findsOneWidget);
    expect(find.text('BIS Registration No.'), findsOneWidget);
    expect(find.text('Applicable GST Structure'), findsNothing);
    expect(find.textContaining('BIS hallmarking covers'), findsNothing);
    expect(find.text('Valid From'), findsNothing);
    expect(find.text('Valid Upto'), findsNothing);
  });

  testWidgets('Shop setup shell gives GST step a bounded layout',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const steps = [
      ShopStepModel(
        id: 1,
        title: 'Basic Info',
        subTitle: 'Identity',
        icon: Icons.store_rounded,
        status: StepStatus.completed,
      ),
      ShopStepModel(
        id: 2,
        title: 'Address',
        subTitle: 'Location',
        icon: Icons.location_on_rounded,
        status: StepStatus.completed,
      ),
      ShopStepModel(
        id: 3,
        title: 'GST & Legal',
        subTitle: 'Tax Compliance',
        icon: Icons.receipt_long_rounded,
        status: StepStatus.active,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ShopSetupLayout(
          currentStep: 3,
          steps: steps,
          onBack: () {},
          onNext: () {},
          onJumpToStep: (_) {},
          child: const IndexedStack(
            index: 2,
            children: [
              SizedBox.shrink(),
              SizedBox.shrink(),
              TaxGstTab(),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Statutory & Tax Compliance'), findsOneWidget);
    expect(find.text('Bureau of Indian Standards'), findsOneWidget);
    expect(find.text('Applicable GST Structure'), findsNothing);
  });
}
