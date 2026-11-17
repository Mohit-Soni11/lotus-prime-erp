import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/settings/metal_rate/metal_rate_hub_screen.dart';
import 'package:lotus_erp/ui/settings/settings_dashboard/settings_screen.dart';

void main() {
  testWidgets('Metal Rate Master opens above the shell and returns to Settings',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const SizedBox(
                  width: 180, child: ColoredBox(color: Colors.black)),
              Expanded(
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(onNavigate: (_) {}),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final settingsCard = find.text('Metal Rate Master');
    await tester.ensureVisible(settingsCard);
    await tester.tap(settingsCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final hub = find.byType(MetalRateHubScreen);
    expect(hub, findsOneWidget);
    expect(find.text('SYSTEM ONLINE'), findsOneWidget);
    expect(tester.getTopLeft(hub).dx, 0);
    expect(tester.getSize(hub).width, 1200);

    await tester.tap(find.descendant(
      of: hub,
      matching: find.byIcon(Icons.arrow_back_rounded),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(hub, findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
