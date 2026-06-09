import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/theme/girvi/girvi_theme.dart';
import 'package:lotus_erp/ui/girvi/shared/girvi_shared_widgets.dart';

void main() {
  testWidgets('Girvi multiline field preserves Enter as a paragraph break',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 560,
            child: GirviInputField(
              label: 'Staff Remarks',
              hint: 'Add a remark',
              icon: GirviIcons.notes,
              controller: controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.minLines, 1);
    expect(field.maxLines, 5);
    expect(field.textInputAction, TextInputAction.newline);

    await tester.enterText(
        find.byType(TextFormField), 'First line\nSecond line');
    await tester.pump();

    expect(controller.text, 'First line\nSecond line');
  });
}
