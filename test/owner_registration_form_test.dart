import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/auth/widgets/auth_field_validator.dart';
import 'package:lotus_erp/ui/auth/widgets/auth_forms.dart';

void main() {
  test('owner form validates a confirmed password without trimming it', () {
    expect(AuthFieldValidator.confirmPassword(' pass', ' pass'), isNull);
    expect(
      AuthFieldValidator.confirmPassword('pass', ' pass'),
      'Passwords do not match.',
    );
  });

  testWidgets('owner registration asks for one shop account', (tester) async {
    final controllers = List.generate(5, (_) => TextEditingController());
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Form(
              child: OwnerRegistrationForm(
                nameController: controllers[0],
                mobileController: controllers[1],
                usernameController: controllers[2],
                passwordController: controllers[3],
                confirmPasswordController: controllers[4],
                isLoading: false,
                passwordVisible: false,
                onTogglePassword: () {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      ),
    ));

    expect(find.text('Owner Name'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Company Name'), findsNothing);
    expect(find.textContaining('Branch'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
