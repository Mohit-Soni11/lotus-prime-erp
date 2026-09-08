import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/logic/booking_advance/booking_advance_controller.dart';
import 'package:lotus_erp/logic/booking_advance/booking_invoice_pdf_service.dart';
import 'package:lotus_erp/models/booking_advance/booking_advance/booking_advance_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
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
    expect(result.orderIds, hasLength(1));

    final customers = await database.select(database.customers).get();
    final orders = await database.select(database.salesOrders).get();
    final advances = await database.select(database.orderAdvances).get();

    expect(customers, hasLength(1));
    expect(customers.single.name, 'Aarav Mehta');
    expect(customers.single.mobile, '9876543210');
    expect(customers.single.city, isNull);
    expect(customers.single.addressLine1, 'Mumbai');
    expect(orders, hasLength(1));
    expect(orders.single.customerId, customers.single.id);
    expect(orders.single.orderNo, matches(RegExp(r'^SH-BK-\d{2}-0001$')));
    expect(orders.single.itemName, 'Gold Ring');
    expect(orders.single.approxWeight, 12);
    expect(advances, hasLength(1));
    expect(advances.single.amountPaid, 2500);
  });

  test('printable booking fetch returns saved order and advance details',
      () async {
    final controller = BookingAdvanceController(repo: repository);
    addTearDown(controller.dispose);

    await _waitForBookingNumber(controller);

    controller.nameCtrl.text = 'Nisha Verma';
    controller.mobileCtrl.text = '9123456780';
    controller.cityCtrl.text = 'Ashok Nagar';
    controller.cashCtrl.text = '5000';
    controller.addBookingItem();

    final item = controller.bookingItems.single;
    item.descCtrl.text = 'Diamond Ring';
    item.grossCtrl.text = '3.500';
    item.rateCtrl.text = '42000';

    final result = await controller.saveBooking();
    final printable = await repository.fetchPrintableBookings(result.orderIds);

    expect(result.success, isTrue);
    expect(printable, hasLength(1));
    expect(printable.single.order.itemName, 'Diamond Ring');
    expect(printable.single.customer?.name, 'Nisha Verma');
    expect(printable.single.advances.single.amountPaid, 5000);

    const pdfService = BookingInvoicePdfService();
    final pdfBytes = await pdfService.buildInvoice(
      shopName: 'Anjali Jewellers',
      bookings: printable,
      generatedAt: DateTime(2026, 9, 8, 12),
    );

    expect(pdfBytes, isNotEmpty);
    expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
  });

  test('booking invoice builds every supported invoice design', () async {
    final controller = BookingAdvanceController(repo: repository);
    addTearDown(controller.dispose);

    await _waitForBookingNumber(controller);

    controller.nameCtrl.text = 'Reyansh Soni';
    controller.mobileCtrl.text = '9304479436';
    controller.cityCtrl.text = 'East Lakshmi Nagar Khemnichak';
    controller.cashCtrl.text = '50000';
    controller.addBookingItem();

    final item = controller.bookingItems.single;
    item.descCtrl.text = 'Gold Ring';
    item.grossCtrl.text = '15';
    item.rateCtrl.text = '12200';

    final result = await controller.saveBooking();
    final printable = await repository.fetchPrintableBookings(result.orderIds);
    const pdfService = BookingInvoicePdfService();

    for (final template in PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.bookingAdvance,
    )) {
      final pdfBytes = await pdfService.buildInvoice(
        shopName: 'Anjali Jewellers',
        bookings: printable,
        options: BookingInvoicePrintOptions(
          format: PrintFormat.a4,
          templateId: template.id,
          includeDuplicateStamp: true,
          copies: 2,
        ),
        generatedAt: DateTime(2026, 9, 8, 12),
      );

      expect(pdfBytes.length, greaterThan(1000), reason: template.id);
      expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
    }
  });

  test('metal rate automatically switches booking preference to locked',
      () async {
    for (final metal in MetalType.values) {
      final controller = BookingAdvanceController(repo: repository);
      addTearDown(controller.dispose);

      await _waitForBookingNumber(controller);

      controller.addBookingItem();
      final item = controller.bookingItems.single;
      item.updateMetal(metal);
      item.rateCtrl.text = '6500';

      expect(
        controller.bookingType,
        BookingType.locked,
        reason: '${metal.displayName} rate should lock the booking.',
      );
      expect(controller.lockedRateCtrl.text, '6500');
    }
  });

  test('advance-only entry keeps booking preference open', () async {
    final controller = BookingAdvanceController(repo: repository);
    addTearDown(controller.dispose);

    await _waitForBookingNumber(controller);

    controller.addBookingItem();
    controller.toggleBookingType(BookingType.locked);
    controller.cashCtrl.text = '5000';

    expect(controller.bookingType, BookingType.open);
    expect(controller.lockedRateCtrl.text, isEmpty);
  });

  test('clearing all metal rates restores open booking preference', () async {
    final controller = BookingAdvanceController(repo: repository);
    addTearDown(controller.dispose);

    await _waitForBookingNumber(controller);

    controller.addBookingItem();
    final item = controller.bookingItems.single;
    item.rateCtrl.text = '6500';

    expect(controller.bookingType, BookingType.locked);

    item.rateCtrl.clear();

    expect(controller.bookingType, BookingType.open);
    expect(controller.lockedRateCtrl.text, isEmpty);
  });

  test('metal change refreshes booking item data for the selected metal', () {
    final item = BookingItemModel();
    addTearDown(item.dispose);

    item.descCtrl.text = 'Gold Ring';
    item.pcsCtrl.text = '2';
    item.purityCtrl.text = '22KT';
    item.grossCtrl.text = '5.325';
    item.lessCtrl.text = '0.100';
    item.rateCtrl.text = '12000';
    item.makingCtrl.text = '12';

    expect(item.totalValue, greaterThan(0));

    item.updateMetal(MetalType.silver);

    expect(item.metal, MetalType.silver);
    expect(item.descCtrl.text, isEmpty);
    expect(item.pcsCtrl.text, '1');
    expect(item.purityCtrl.text, '999');
    expect(item.grossCtrl.text, isEmpty);
    expect(item.lessCtrl.text, isEmpty);
    expect(item.rateCtrl.text, isEmpty);
    expect(item.makingCtrl.text, isEmpty);
    expect(item.netWt, 0);
    expect(item.rate, 0);
    expect(item.totalValue, 0);
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
      address: 'Jaipur',
      panNumber: 'ABCDE1234F',
      gstNumber: '',
    );

    final customers = await database.select(database.customers).get();

    expect(resolvedCustomerId, existingCustomerId);
    expect(customers, hasLength(1));
    expect(customers.single.name, 'Existing Customer');
  });

  test('customer search returns booking address without city or state',
      () async {
    await _insertCustomer(
      database,
      name: 'Ravi Kumar',
      mobile: '9000011111',
      addressLine1: 'Main Road',
      addressLine2: 'Near Clock Tower',
      city: 'Patna',
      state: 'Bihar',
      pincode: '800001',
    );

    final results = await repository.searchCustomers('9000011111');

    expect(results, hasLength(1));
    expect(results.single['address'], 'Main Road, Near Clock Tower');
    expect(results.single['city'], 'Main Road, Near Clock Tower');
  });

  test('customer lookup exposes not found state for unknown customers',
      () async {
    final controller = BookingAdvanceController(repo: repository);
    await _waitForBookingNumber(controller);

    controller.searchCustomer('9999999999');
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(controller.customerResults, isEmpty);
    expect(controller.customerNotFound, isTrue);
    controller.dispose();
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
      'address': 'Main Road',
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
  String? addressLine1,
  String? addressLine2,
  String? city,
  String? state,
  String? pincode,
}) {
  return database.into(database.customers).insert(
        CustomersCompanion(
          name: drift.Value(name),
          mobile: drift.Value(mobile),
          addressLine1: drift.Value(addressLine1),
          addressLine2: drift.Value(addressLine2),
          city: drift.Value(city),
          state: drift.Value(state),
          pincode: drift.Value(pincode),
        ),
      );
}

String _previousFinancialYear(String financialYear) {
  final start = int.tryParse(financialYear.substring(0, 2)) ?? 0;
  final end = int.tryParse(financialYear.substring(2, 4)) ?? 0;
  return '${((start + 99) % 100).toString().padLeft(2, '0')}'
      '${((end + 99) % 100).toString().padLeft(2, '0')}';
}
