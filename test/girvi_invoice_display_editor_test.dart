import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/ui/settings/billing_setup/girvi_invoice_display_editor.dart';

void main() {
  testWidgets('Girvi invoice display editor is editable for every metal',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _EditorHarness()));

    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Silver'), findsOneWidget);
    expect(find.text('Diamond'), findsOneWidget);
    expect(find.text('Platinum'), findsOneWidget);
    expect(find.text('EDITABLE'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    expect(find.byType(Switch), findsNWidgets(14));
    expect(find.text('Valuation Purity'), findsOneWidget);
    expect(find.text('Fine Weight'), findsOneWidget);
    expect(find.text('Valuation Rate / Gram'), findsOneWidget);
    expect(find.text('Item Valuation Amount'), findsOneWidget);

    await tester.tap(find.text('Silver'));
    await tester.pumpAndSettle();

    expect(find.text('Silver Girvi Invoice'), findsOneWidget);
  });

  testWidgets('Girvi customer receipt editor exposes every New Girvi section',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _DocumentEditorHarness()),
    );

    expect(find.text('Customer Receipt Sections'), findsOneWidget);
    expect(find.text('Customer Mobile'), findsOneWidget);
    expect(find.text('Loan Amount'), findsOneWidget);
    expect(find.text('Monthly Interest Amount'), findsOneWidget);
    expect(find.text('Total Pledged Valuation'), findsOneWidget);
    expect(find.text('Disbursement Breakdown'), findsOneWidget);
    expect(find.text('KYC Type & Number'), findsOneWidget);
    expect(find.text('KYC Card Photo'), findsOneWidget);
    expect(find.text('Notes & Remarks'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Customer Declaration'), findsOneWidget);
    expect(find.text('Footer Message'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(18));
  });
}

class _DocumentEditorHarness extends StatefulWidget {
  const _DocumentEditorHarness();

  @override
  State<_DocumentEditorHarness> createState() => _DocumentEditorHarnessState();
}

class _DocumentEditorHarnessState extends State<_DocumentEditorHarness> {
  GirviBillingModel model = GirviBillingModel.defaults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: GirviInvoiceDocumentEditor(
          model: model,
          onChanged: (value) => setState(() => model = value),
        ),
      ),
    );
  }
}

class _EditorHarness extends StatefulWidget {
  const _EditorHarness();

  @override
  State<_EditorHarness> createState() => _EditorHarnessState();
}

class _EditorHarnessState extends State<_EditorHarness> {
  GirviBillingModel model = GirviBillingModel.defaults;
  String metal = GirviBillingMetal.gold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: GirviInvoiceDisplayEditor(
          model: model,
          selectedMetal: metal,
          onMetalChanged: (value) => setState(() => metal = value),
          onChanged: (value) => setState(() => model = value),
        ),
      ),
    );
  }
}
