import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/pos_stock_lookup_field.dart';

void main() {
  testWidgets('stock lookup popup renders long HUID rows without overflow',
      (tester) async {
    final controller = TextEditingController(text: 'j');
    final signal = ValueNotifier<int>(0);
    final suggestions = [
      const PosStockLookupModel(
        stockItemId: 1,
        stockUnitId: 11,
        sku: 'PUR-GOLD-1784618320944-1234567890-U001',
        itemName: 'Jhumka Premium Long Name',
        description: '',
        huid: 'HUID-LONG-1234567890-ABCDE',
        huids: ['HUID-LONG-1234567890-ABCDE', 'HUID-LONG-0987654321-ZYXWV'],
        purity: '22KT',
        metal: MetalType.gold,
        categoryLabel: 'Jhumka',
        companyName: 'Raj Ornaments',
        grossWeight: 12.456,
        lessWeight: 0,
        netWeight: 12.456,
        quantity: 2,
        status: 'Available',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: PosStockLookupField(
                listenable: signal,
                controller: controller,
                hint: 'Description',
                overlayWidth: 320,
                onSearch: (_) async {},
                getSuggestions: () => suggestions,
                onSelected: (_) {},
                onClearSuggestions: () {},
              ),
            ),
          ),
        ),
      ),
    );

    signal.value++;
    await tester.pumpAndSettle();

    expect(find.text('Jhumka Premium Long Name'), findsOneWidget);
    expect(find.text('Jhumka'), findsOneWidget);
    expect(find.text('Raj Ornaments'), findsOneWidget);
    expect(find.text('HUID-LONG-1234567890-ABCDE'), findsOneWidget);
    expect(find.text('HUID-LONG-0987654321-ZYXWV'), findsOneWidget);
    expect(tester.takeException(), isNull);

    controller.dispose();
    signal.dispose();
  });
}
