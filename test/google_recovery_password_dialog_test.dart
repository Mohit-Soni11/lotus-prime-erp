import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/presentation/google_recovery_password_dialog.dart';

void main() {
  testWidgets('backup connection requires the current Lotus ERP password',
      (tester) async {
    String? password;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () async {
                    password = await showGoogleRecoveryPasswordDialog(context);
                  },
                  child: const Text('Connect'),
                )),
      ),
    ));
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Drive backups and password recovery'),
        findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your current password.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'owner-password');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(password, 'owner-password');
  });
}
