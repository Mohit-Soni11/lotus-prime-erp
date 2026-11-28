import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/auth/widgets/company_creation_panel.dart';
import 'package:lotus_erp/ui/auth/widgets/company_registration_input.dart';

void main() {
  testWidgets('company form validates and submits the email login',
      (tester) async {
    CompanyRegistrationInput? submitted;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 740,
          height: 706,
          child: CompanyCreationPanel(
            isLoading: false,
            onSubmit: (value) async => submitted = value,
            onBackToSignIn: () {},
          ),
        ),
      ),
    ));

    expect(find.text('Create Company'), findsWidgets);
    expect(find.text('Back to Sign In'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Company'));
    await tester.pump();
    expect(submitted, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Shop Owner');
    await tester.enterText(fields.at(1), '9876543210');
    await tester.enterText(fields.at(2), 'Lotus Jewellers');
    await tester.enterText(fields.at(3), 'OWNER@EXAMPLE.COM');
    await tester.enterText(fields.at(4), 'SecurePass123');
    await tester.enterText(fields.at(5), 'SecurePass123');
    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'Create Company'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Company'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(submitted?.email, 'owner@example.com');
    expect(submitted?.companyName, 'Lotus Jewellers');
    expect(submitted?.mobile, '9876543210');
  });
}
