import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/add_supplier_logic.dart';
import 'package:lotus_erp/features/stock/shared/application/supplier_list_logic.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/helpers/add_supplier/add_supplier_validator.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';

void main() {
  test(
      'Supplier List refreshes after a supplier is added and filters correctly',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = SupplierRepository(database);
    final logic = SupplierListLogic(repository: repository, database: database);
    addTearDown(() async {
      logic.dispose();
      await database.close();
    });
    await logic.refresh();
    expect(logic.totalSuppliers, 0);

    final changed = Completer<void>();
    logic.addListener(() {
      if (logic.totalSuppliers == 1 && !changed.isCompleted) {
        changed.complete();
      }
    });
    await repository.addSupplier(const SupplierModel(
      businessName: 'Royal Metals',
      mobile: '9876543210',
      supplierType: SupplierType.wholesaler,
    ));
    await changed.future.timeout(const Duration(seconds: 3));
    expect(logic.suppliers.single.businessName, 'Royal Metals');
    logic.setFilter(SupplierFilter.manufacturer);
    expect(logic.suppliers, isEmpty);
    logic.setFilter(SupplierFilter.wholesaler);
    expect(logic.suppliers, hasLength(1));
    logic.onSearchChanged('not present');
    expect(logic.suppliers, isEmpty);
    logic.onSearchChanged('royal');
    expect(logic.suppliers, hasLength(1));
  });

  test('supplier edits preserve existing opening balance', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = SupplierRepository(database);
    final id = await repository.addSupplier(const SupplierModel(
      businessName: 'Metal House',
      mobile: '9876543210',
      openingBalance: 1250,
    ));
    final existing = await repository.getById(id);
    final logic = AddSupplierLogic(existing: existing, repo: repository);
    addTearDown(logic.dispose);
    logic.onBusinessNameChanged('Metal House Updated');
    expect(await logic.save(), isTrue);
    final updated = await repository.getById(id);
    expect(updated?.businessName, 'Metal House Updated');
    expect(updated?.openingBalance, 1250);
  });

  test('supplier postal code follows selected country', () {
    expect(AddSupplierValidator.validatePostalCode('800001', country: 'India'),
        isNull);
    expect(AddSupplierValidator.validatePostalCode('AB1 2CD', country: 'UK'),
        isNull);
    expect(AddSupplierValidator.validatePostalCode('ABC', country: 'India'),
        isNotNull);
  });

  test('supplier contact numbers reject invalid characters and lengths', () {
    expect(AddSupplierValidator.validateMobile('9876543210'), isNull);
    expect(AddSupplierValidator.validateMobile('abc9876543210'), isNotNull);
    expect(AddSupplierValidator.validateMobile('98765432101'), isNotNull);
    expect(AddSupplierValidator.validateWhatsapp('9876543210'), isNull);
    expect(AddSupplierValidator.validateWhatsapp('98765abc10'), isNotNull);
  });
}
