import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/settings/shop_setup/tabs/address_card_tab.dart';
import 'package:lotus_erp/ui/settings/shop_setup/tabs/banking_tab.dart';
import 'package:lotus_erp/ui/settings/shop_setup/tabs/basic_info_tab.dart';
import 'package:lotus_erp/ui/settings/shop_setup/tabs/branding_tab.dart';

void main() {
  testWidgets('Shop Profile tabs render in a compact workspace without errors',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(820, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const tabs = <Widget>[
      BasicInfoTab(),
      AddressTab(),
      BankingTab(),
      BrandingTab(),
    ];

    for (final tab in tabs) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(child: tab),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull,
          reason: '${tab.runtimeType} should not produce a layout exception');
    }
  });
}
