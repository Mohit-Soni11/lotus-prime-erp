import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/helpers/add_customer_/add_customer_form_validation.dart';
import 'package:lotus_erp/logic/customer/add_customer_logic.dart';
import 'package:lotus_erp/models/customer/add_customer/add_customer_form_model.dart';
import 'package:lotus_erp/models/customer/customer_enums/add_customer_enums.dart';
import 'package:lotus_erp/models/customer/customer_enums/customer_list_enums.dart';
import 'package:lotus_erp/repositories/customer/add_customer_repository.dart';
import 'package:lotus_erp/repositories/customer/customer_media_store.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';

void main() {
  test('form validation reports every invalid optional field on its own field',
      () {
    final result = AddCustomerFormValidation.apply(
      const AddCustomerFormModel(
        entityType: CustomerEntityType.corporate,
        companyName: 'A',
        whatsapp: '123',
        alternateContact: '456',
        idProofNumber: '1234',
        gstNumber: 'INVALID',
        pincode: 'ABCDEF',
      ),
    );
    expect(result.companyNameError, isNotNull);
    expect(result.firstNameError, isNull);
    expect(result.whatsappError, isNotNull);
    expect(result.alternateContactError, isNotNull);
    expect(result.idProofError, isNotNull);
    expect(result.gstError, isNotNull);
    expect(result.pincodeError, isNotNull);
    expect(result.hasErrors, isTrue);
  });

  test('postal code follows the selected country', () {
    final usForm = AddCustomerFormValidation.apply(
      const AddCustomerFormModel(
        firstName: 'Taylor',
        country: 'USA',
        pincode: '10001',
      ),
    );
    expect(usForm.pincodeError, isNull);
    final indianForm = AddCustomerFormValidation.apply(
      const AddCustomerFormModel(
        firstName: 'Aman',
        country: 'India',
        pincode: 'ABCDEF',
      ),
    );
    expect(indianForm.pincodeError, isNotNull);
  });

  test('KYC fields are optional for Individual and Corporate customers', () {
    for (final entity in CustomerEntityType.values) {
      final form = AddCustomerFormValidation.apply(AddCustomerFormModel(
        entityType: entity,
        firstName: entity == CustomerEntityType.individual ? 'Aman' : '',
        companyName:
            entity == CustomerEntityType.corporate ? 'Aman Traders' : '',
      ));
      expect(form.panError, isNull);
      expect(form.idProofError, isNull);
      expect(form.gstError, isNull);
      expect(form.hasErrors, isFalse);
    }
  });

  test('repository rejects invalid GST before writing any row', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(db: db);
    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(firstName: 'Aman', gstNumber: 'BAD'),
      ),
      SaveResult.error,
    );
    expect(await db.select(db.customers).get(), isEmpty);
  });

  test('duplicate mobile error clears after edit and reset', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(db: db);
    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(firstName: 'Existing', mobile: '9000000001'),
      ),
      SaveResult.success,
    );
    final logic = AddCustomerLogic(repo: repository);
    addTearDown(logic.dispose);
    logic.onFirstNameChanged('New Customer');
    logic.onMobileChanged('9000000001');
    await Future<void>.delayed(const Duration(milliseconds: 750));
    expect(logic.form.mobileError, 'Mobile already registered');
    logic.onMobileChanged('9000000002');
    expect(logic.form.mobileError, isNull);
    logic.resetForm();
    expect(logic.form.mobileError, isNull);
  });

  test('late duplicate lookup cannot mark a different mobile as duplicate',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _DelayedCustomerRepository(db: db);
    final logic = AddCustomerLogic(repo: repository);
    addTearDown(logic.dispose);
    logic.onMobileChanged('9000000001');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    logic.onMobileChanged('9000000002');
    repository.completeLookup(true);
    await Future<void>.delayed(Duration.zero);
    expect(logic.form.mobile, '9000000002');
    expect(logic.form.mobileError, isNull);
  });

  test('new customers have an automatic Standard category and no membership ID',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(db: db);
    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(
            firstName: 'First', customerTier: CustomerType.elite),
      ),
      SaveResult.success,
    );
    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(firstName: 'Second'),
      ),
      SaveResult.success,
    );
    final rows = await db.select(db.customers).get();
    expect(rows.every((row) => row.membershipId == null), isTrue);
    expect(rows.every((row) => row.type == 'Standard'), isTrue);
    final first = rows.first;
    final form = await repository.fetchCustomerForEdit(first.id);
    expect(
      await repository.saveCustomer(
        form!.copyWith(city: 'Patna'),
        customerId: first.id,
      ),
      SaveResult.success,
    );
    final updated = await (db.select(db.customers)
          ..where((row) => row.id.equals(first.id)))
        .getSingle();
    expect(updated.membershipId, isNull);
    expect(updated.customerTier, 'Standard');
  });

  test('editing a customer replaces legacy categories with computed Standard',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(db: db);
    expect(
        await repository.saveCustomer(
          const AddCustomerFormModel(firstName: 'Aman'),
        ),
        SaveResult.success);
    final saved = await db.select(db.customers).getSingle();
    await (db.update(db.customers)..where((row) => row.id.equals(saved.id)))
        .write(const CustomersCompanion(type: Value('Gold')));
    final loaded = await repository.fetchCustomerForEdit(saved.id);
    expect(loaded!.customerTier, CustomerType.standard);
    expect(
        await repository.saveCustomer(
          loaded.copyWith(customerTier: CustomerType.elite),
          customerId: saved.id,
        ),
        SaveResult.success);
    final updated = await db.select(db.customers).getSingle();
    expect(updated.type, 'Standard');
    expect(updated.customerTier, 'Standard');
  });

  test('v67 migration removes opening balance and repairs duplicate IDs',
      () async {
    final root = await Directory.systemTemp.createTemp('lotus_migration_test_');
    addTearDown(() => root.delete(recursive: true));
    final databaseFile =
        File('${root.path}${Platform.pathSeparator}legacy.sqlite');
    final seed = AppDatabase.forTesting(NativeDatabase(databaseFile));
    final repository = AddCustomerRepository(db: seed);
    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(firstName: 'First'),
      ),
      SaveResult.success,
    );
    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(firstName: 'Second'),
      ),
      SaveResult.success,
    );
    await seed.customStatement('DROP INDEX "idx_customers_membership_id"');
    await seed.customStatement(
      'UPDATE "customers" SET "membership_id" = \'LTMP-DUPLICATE\'',
    );
    await seed.customStatement(
      'ALTER TABLE "customers" ADD COLUMN "opening_balance" REAL NOT NULL DEFAULT 0',
    );
    await seed.customStatement('PRAGMA user_version = 66');
    await seed.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(upgraded.close);
    final customers = await upgraded.select(upgraded.customers).get();
    expect(customers, hasLength(2));
    expect(customers.map((row) => row.membershipId).toSet(), hasLength(2));
    final columns =
        await upgraded.customSelect('PRAGMA table_info("customers")').get();
    expect(columns.map((row) => row.read<String>('name')),
        isNot(contains('opening_balance')));
  });

  test('customer media is copied to owned storage and removed on deletion',
      () async {
    final root = await Directory.systemTemp.createTemp('lotus_customer_test_');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}${Platform.pathSeparator}source.png');
    await source.writeAsBytes([137, 80, 78, 71]);
    final mediaStore = CustomerMediaStore(root: root);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(db: db, mediaStore: mediaStore);
    expect(
      await repository.saveCustomer(
        AddCustomerFormModel(
            firstName: 'Image Customer', profileImagePath: source.path),
      ),
      SaveResult.success,
    );
    final saved = await db.select(db.customers).getSingle();
    expect(saved.profileImagePath, isNot(source.path));
    expect(await File(saved.profileImagePath!).exists(), isTrue);
    expect(await mediaStore.isOwned(saved.profileImagePath!), isTrue);

    final replacement =
        File('${root.path}${Platform.pathSeparator}replacement.png');
    await replacement.writeAsBytes([137, 80, 78, 71, 1]);
    final loaded = await repository.fetchCustomerForEdit(saved.id);
    expect(
      await repository.saveCustomer(
        loaded!.copyWith(profileImagePath: replacement.path),
        customerId: saved.id,
      ),
      SaveResult.success,
    );
    final updated = await (db.select(db.customers)
          ..where((row) => row.id.equals(saved.id)))
        .getSingle();
    expect(await File(saved.profileImagePath!).exists(), isFalse);
    expect(await File(updated.profileImagePath!).exists(), isTrue);

    final profile = CustomerProfileRepository(db: db, mediaStore: mediaStore);
    expect((await profile.deleteCustomer(saved.id)).deleted, isTrue);
    expect(await File(updated.profileImagePath!).exists(), isFalse);
    expect(await source.exists(), isTrue);
    expect(await replacement.exists(), isTrue);
  });

  test('missing identity image rolls back customer and copied photo', () async {
    final root = await Directory.systemTemp.createTemp('lotus_customer_test_');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}${Platform.pathSeparator}source.png');
    await source.writeAsBytes([137, 80, 78, 71]);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(
      db: db,
      mediaStore: CustomerMediaStore(root: root),
    );
    expect(
      await repository.saveCustomer(
        AddCustomerFormModel(
          firstName: 'Rollback Customer',
          profileImagePath: source.path,
          idProofDocPath: '${root.path}${Platform.pathSeparator}missing.png',
        ),
      ),
      SaveResult.error,
    );
    expect(await db.select(db.customers).get(), isEmpty);
    final mediaRoot =
        Directory('${root.path}${Platform.pathSeparator}customer_media');
    final ownedFiles = await mediaRoot
        .list(recursive: true)
        .where((entity) => entity is File)
        .toList();
    expect(ownedFiles, isEmpty);
  });
}

class _DelayedCustomerRepository extends AddCustomerRepository {
  _DelayedCustomerRepository({required super.db});

  final Completer<bool> _lookup = Completer<bool>();

  @override
  Future<bool> isMobileDuplicate(String mobile, {int? excludeCustomerId}) {
    return _lookup.future;
  }

  void completeLookup(bool duplicate) => _lookup.complete(duplicate);
}
