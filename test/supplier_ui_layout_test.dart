import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/add_supplier/add_supplier_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/supplier_list/supplier_list_app_bar.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/supplier_list/supplier_list_card.dart';
import 'package:lotus_erp/features/stock/shared/presentation/supplier/supplier_list/supplier_list_toolbar.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_list/supplier_list_theme.dart';

void main() {
  testWidgets(
      'Add Supplier uses one visible type selector and no financial entry',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester
        .pumpWidget(MaterialApp(home: AddSupplierScreen(onBack: () {})));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('ADD NEW SUPPLIER'), findsOneWidget);
    expect(find.text('LOTUS PRIME ERP'), findsNothing);
    expect(find.text('Financial Details'), findsNothing);
    expect(find.textContaining('Opening Rs'), findsNothing);
    expect(find.text('Additional Notes'), findsNothing);
    final typeDropdown = tester.widget<DropdownButton<SupplierType>>(
        find.byType(DropdownButton<SupplierType>));
    expect(typeDropdown.dropdownColor, Colors.white);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Supplier List card and title fit a compact desktop window',
      (tester) async {
    tester.view.physicalSize = const Size(650, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      appBar: SupplierListAppBar(onBack: () {}),
      body: SupplierListCard(
        supplier: const SupplierListItemModel(
          id: 1,
          businessName: 'Royal Metals',
          mobile: '9876543210',
          supplierType: SupplierType.wholesaler,
          status: SupplierStatus.active,
        ),
        onTap: () {},
      ),
    )));
    expect(find.text('SUPPLIER LIST'), findsOneWidget);
    expect(find.text('Royal Metals'), findsOneWidget);
    expect(find.text('Open Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supplier contact details stay with the name on a wide card',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SupplierListCard(
          supplier: const SupplierListItemModel(
            id: 1,
            businessName: 'Royal Metals',
            contactPersonName: 'Alex',
            mobile: '9876543210',
            supplierType: SupplierType.wholesaler,
            status: SupplierStatus.active,
          ),
          onTap: () {},
        ),
      ),
    ));
    final card = tester.getRect(find.byType(SupplierListCard));
    expect(tester.getTopLeft(find.text('Mobile: 9876543210')).dx,
        lessThan(card.center.dx));
    expect(tester.getTopLeft(find.text('Contact Person: Alex')).dx,
        lessThan(card.center.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('supplier filters use a light selected state with black text',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SupplierFilterButton(
            filter: SupplierFilter.manufacturer,
            selected: true,
            onPressed: () {},
          ),
        ),
      ),
    ));
    final manufacturer = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Manufacturer'),
    );
    expect(
      manufacturer.style!.backgroundColor!.resolve(<WidgetState>{}),
      SupplierListColors.brandGold.withValues(alpha: 0.2),
    );
    expect(tester.takeException(), isNull);
  });
}
