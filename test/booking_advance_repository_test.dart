import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/booking_advance/booking_advance_controller.dart';
import 'package:lotus_erp/repositories/booking_advance/booking_advance_repository.dart';

void main() {
  late AppDatabase database;
  late BookingAdvanceRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BookingAdvanceRepository(db: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('controller creates a customer before saving a typed booking', () async {
    final controller = BookingAdvanceController(repo: repository);
    addTearDown(controller.dispose);

    await _waitForBookingNumber(controller);

    controller.nameCtrl.text = 'Aarav Mehta';
    controller.mobileCtrl.text = '9876543210';
    controller.cityCtrl.text = 'Mumbai';
    controller.cashCtrl.text = '2500';
    controller.addBookingItem();

    final item = controller.bookingItems.single;
    item.descCtrl.text = 'Gold Ring';
    item.grossCtrl.text = '12.500';
    item.lessCtrl.text = '0.500';
    item.rateCtrl.text = '6000';

    final result = await controller.saveBooking();

    expect(result.success, isTrue);

    final customers = await database.select(database.customers).get();
    final orders = await database.select(database.salesOrders).get();
    final advances = await database.select(database.orderAdvances).get();

    expect(customers, hasLength(1));
    expect(customers.single.name, 'Aarav Mehta');
    expect(customers.single.mobile, '9876543210');
    expect(customers.single.city, 'Mumbai');
    expect(orders, hasLength(1));
    expect(orders.single.customerId, customers.single.id);
    expect(orders.single.orderNo, matches(RegExp(r'^SH-BK-\d{2}-0001$')));
    expect(orders.single.itemName, 'Gold Ring');
    expect(orders.single.approxWeight, 12);
    expect(advances, hasLength(1));
    expect(advances.single.amountPaid, 2500);
  });

  test('booking sequence uses the highest financial-year booking number',
      () async {
    final customerId = await _insertCustomer(database);
    final financialYear = repository.getCurrentFinancialYear();
    final previousFinancialYear = _previousFinancialYear(financialYear);
    final yearToken = repository.getCurrentDocumentYearToken();

    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'BK-AJ-$financialYear-0099',
            customerId: customerId,
            itemName: 'Existing Booking',
          ),
        );
    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'AJ-BK-$yearToken-0104',
            customerId: customerId,
            itemName: 'Current Format Booking',
          ),
        );
    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'BK-AJ-$previousFinancialYear-9999',
            customerId: customerId,
            itemName: 'Previous Year Booking',
          ),
        );

    final nextSequence = await repository.getNextBookingSequence(
      shopCode: 'AJ',
      yearToken: yearToken,
    );

    expect(nextSequence, 105);
    expect(
      repository.formatBookingNumber(
        shopCode: 'AJ',
        yearToken: yearToken,
        sequence: nextSequence,
      ),
      'AJ-BK-$yearToken-0105',
    );
  });

  test('booking sequence continues after old hardcoded shop-code records',
      () async {
    final customerId = await _insertCustomer(database);
    final financialYear = repository.getCurrentFinancialYear();
    final yearToken = repository.getCurrentDocumentYearToken();

    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'BK-LJ-$financialYear-0050',
            customerId: customerId,
            itemName: 'Legacy Hardcoded Booking',
          ),
        );

    final nextSequence = await repository.getNextBookingSequence(
      shopCode: 'AJ',
      yearToken: yearToken,
    );

    expect(nextSequence, 51);
    expect(
      repository.formatBookingNumber(
        shopCode: 'AJ',
        yearToken: yearToken,
        sequence: nextSequence,
      ),
      'AJ-BK-$yearToken-0051',
    );
  });

  test('booking sequence continues if the shop name changes inside one year',
      () async {
    final customerId = await _insertCustomer(database);
    final yearToken = repository.getCurrentDocumentYearToken();

    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'LJ-BK-$yearToken-0075',
            customerId: customerId,
            itemName: 'Previous Shop Code Booking',
          ),
        );

    final nextSequence = await repository.getNextBookingSequence(
      shopCode: 'AJ',
      yearToken: yearToken,
    );

    expect(nextSequence, 76);
  });

  test('booking sequence resets when the financial-year token changes',
      () async {
    final customerId = await _insertCustomer(database);

    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'AJ-BK-26-0099',
            customerId: customerId,
            itemName: 'Previous Token Booking',
          ),
        );
    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'BK-AJ-2627-0100',
            customerId: customerId,
            itemName: 'Legacy Previous Token Booking',
          ),
        );

    final nextSequence = await repository.getNextBookingSequence(
      shopCode: 'AJ',
      yearToken: '27',
    );

    expect(nextSequence, 1);
    expect(
      repository.formatBookingNumber(
        shopCode: 'AJ',
        yearToken: '27',
        sequence: nextSequence,
      ),
      'AJ-BK-27-0001',
    );
  });

  test('customer resolver reuses an existing mobile number', () async {
    final existingCustomerId = await _insertCustomer(
      database,
      name: 'Existing Customer',
      mobile: '9000011111',
    );

    final resolvedCustomerId = await repository.resolveCustomerForBooking(
      customerName: 'Updated Name',
      customerMobile: '9000011111',
      city: 'Jaipur',
      panNumber: 'ABCDE1234F',
      gstNumber: '',
    );

    final customers = await database.select(database.customers).get();

    expect(resolvedCustomerId, existingCustomerId);
    expect(customers, hasLength(1));
    expect(customers.single.name, 'Existing Customer');
  });

  test('manual customer edits clear the selected customer identity', () async {
    final existingCustomerId = await _insertCustomer(
      database,
      name: 'Existing Customer',
      mobile: '9000011111',
    );
    final controller = BookingAdvanceController(repo: repository);
    await _waitForBookingNumber(controller);

    controller.selectCustomerFromSearch({
      'id': existingCustomerId,
      'name': 'Existing Customer',
      'mobile': '9000011111',
      'city': 'Jaipur',
    });
    controller.nameCtrl.text = 'Changed Customer';
    controller.handleCustomerLookupInput('C');

    expect(controller.selectedCustomerId, isNull);
    controller.dispose();
  });
}

Future<void> _waitForBookingNumber(BookingAdvanceController controller) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (!controller.isNumberLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Booking number did not initialize.');
}

Future<int> _insertCustomer(
  AppDatabase database, {
  String name = 'Test Customer',
  String mobile = '9000000000',
}) {
  return database.into(database.customers).insert(
        CustomersCompanion(
          name: drift.Value(name),
          mobile: drift.Value(mobile),
        ),
      );
}

String _previousFinancialYear(String financialYear) {
  final start = int.tryParse(financialYear.substring(0, 2)) ?? 0;
  final end = int.tryParse(financialYear.substring(2, 4)) ?? 0;
  return '${((start + 99) % 100).toString().padLeft(2, '0')}'
      '${((end + 99) % 100).toString().padLeft(2, '0')}';
}
