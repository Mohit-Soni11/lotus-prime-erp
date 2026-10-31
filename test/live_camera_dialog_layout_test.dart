import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/shared/live_camera_dialog.dart';

void main() {
  testWidgets('camera controls stay visible and Cancel closes the dialog',
      (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const LiveCameraDialog(
                        title: 'Capture Customer Photo',
                        guidance: 'Select a camera and take a photo.',
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                )),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Capture Customer Photo'), findsOneWidget);
    expect(find.text('Flip Camera'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Capture Photo'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(480, 500);
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Capture Customer Photo'), findsNothing);
  });
}
