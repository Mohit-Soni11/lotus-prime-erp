import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/pos_invoice_unit_editor.dart';

void main() {
  testWidgets('stock-linked sale edits only the invoice unit name',
      (tester) async {
    final item = SaleItemModel(metal: MetalType.silver);
    addTearDown(item.dispose);
    item.setStoredUnitProfile(PosItemUnitProfile.packet);
    item.attachStockReference(stockItemId: 42, sku: 'SILVER-PACKET-42');

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: PosInvoiceUnitEditor(item: item, color: Colors.amber),
      ),
    ));
    await tester.tap(find.text('PACK'));
    await tester.pumpAndSettle();
    expect(find.text('Stock unit: Packet'), findsOneWidget);
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).backgroundColor,
      Colors.white,
    );
    expect(
      tester.widget<Text>(find.text('Invoice unit')).style?.color,
      const Color(0xFF0B1220),
    );
    expect(
      tester.widget<Text>(find.text('Invoice unit')).style?.fontWeight,
      FontWeight.w900,
    );
    expect(
      tester
          .widget<TextField>(find.byType(TextField).last)
          .decoration
          ?.helperStyle
          ?.color,
      const Color(0xFF0B1220),
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .style
          ?.foregroundColor
          ?.resolve({}),
      const Color(0xFF0B1220),
    );

    await tester.enterText(find.byType(TextField).last, 'Custom Bundle');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(item.unitShortName, 'PACK');
    expect(item.invoiceUnitLabel, 'Custom Bundle');
    expect(item.linkedStockItemId, 42);
  });
}
