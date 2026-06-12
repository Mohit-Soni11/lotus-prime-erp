import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/customer/add_customer/add_customer_form_model.dart';
import 'package:lotus_erp/models/customer/customer_enums/add_customer_enums.dart';
import 'package:lotus_erp/repositories/customer/add_customer_repository.dart';

void main() {
  test('Add Customer edit mode loads and updates the existing customer row',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(db: db);

    const original = AddCustomerFormModel(
      firstName: 'Aman',
      lastName: 'Kumar',
      mobile: '9876543210',
      whatsapp: '9876543210',
      sameAsWhatsApp: true,
      email: 'aman@example.com',
      alternateContact: '9123456780',
      panNumber: 'ABCDE1234F',
      idProofType: IdProofType.aadhar,
      idProofNumber: '123456789012',
      addressLine1: 'Main Road',
      state: 'Bihar',
      city: 'Gaya',
      pincode: '823001',
      creditLimit: 50000,
      customerTier: CustomerTier.gold,
      membershipId: 'LTMP-202606-0001',
      ringSize: RingSize.size12,
      notes: 'Preferred customer',
    );

    expect(await repository.saveCustomer(original), SaveResult.success);
    final saved = await db.select(db.customers).getSingle();

    final loaded = await repository.fetchCustomerForEdit(saved.id);
    expect(loaded, isNotNull);
    expect(loaded!.firstName, 'Aman');
    expect(loaded.lastName, 'Kumar');
    expect(loaded.sameAsWhatsApp, isTrue);
    expect(loaded.idProofNumber, '123456789012');
    expect(loaded.customerTier, CustomerTier.gold);
    expect(loaded.ringSize, RingSize.size12);

    final updated = loaded.copyWith(
      firstName: 'Aman Raj',
      city: 'Patna',
      creditLimit: 75000,
      customerTier: CustomerTier.vip,
      notes: 'Updated from customer profile',
    );
    expect(
      await repository.saveCustomer(updated, customerId: saved.id),
      SaveResult.success,
    );

    final rows = await db.select(db.customers).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Aman Raj Kumar');
    expect(rows.single.mobile, '9876543210');
    expect(rows.single.city, 'Patna');
    expect(rows.single.creditLimit, 75000);
    expect(rows.single.customerTier, 'VIP');
    expect(rows.single.notes, 'Updated from customer profile');
  });

  test('Edit mode blocks a mobile number owned by another customer', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = AddCustomerRepository(db: db);

    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(
          firstName: 'First',
          mobile: '9000000001',
        ),
      ),
      SaveResult.success,
    );
    expect(
      await repository.saveCustomer(
        const AddCustomerFormModel(
          firstName: 'Second',
          mobile: '9000000002',
        ),
      ),
      SaveResult.success,
    );

    final rows = await db.select(db.customers).get();
    final first = rows.firstWhere((row) => row.mobile == '9000000001');
    final firstForm = await repository.fetchCustomerForEdit(first.id);

    expect(
      await repository.saveCustomer(
        firstForm!.copyWith(mobile: '9000000002'),
        customerId: first.id,
      ),
      SaveResult.duplicate,
    );
    expect(await db.select(db.customers).get(), hasLength(2));
  });
}
