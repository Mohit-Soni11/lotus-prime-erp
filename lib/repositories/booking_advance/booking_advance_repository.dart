// =============================================================================
// FILE        : booking_advance_repository.dart
// MODULE      : Sales / Booking & Advance
// LAYER       : Repository / Database
// DESCRIPTION : All database operations for the Booking & Advance module.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/features/customer/domain/services/customer_contact_value.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_invoice_series_formatter.dart';
import 'package:lotus_erp/helpers/search/fuzzy_search_helper.dart';
import 'package:lotus_erp/models/setting/billing_setup/booking_advance_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/booking_advance_billing_repo.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_setup_repository.dart';

part 'booking_advance_repository_helpers.dart';

class EditableBookingAdvance {
  const EditableBookingAdvance({
    required this.order,
    required this.customer,
    required this.advances,
  });

  final SalesOrder order;
  final Customer? customer;
  final List<OrderAdvance> advances;
}

class BookingAdvanceLineDraft {
  const BookingAdvanceLineDraft({
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.approxWeight,
    required this.bookingType,
    required this.lockedRate,
    required this.deliveryDate,
    required this.notes,
    required this.advanceAmount,
    required this.rateOnDate,
  });

  final String itemName;
  final String metalType;
  final String purity;
  final double approxWeight;
  final String bookingType;
  final double lockedRate;
  final DateTime? deliveryDate;
  final String? notes;
  final double advanceAmount;
  final double rateOnDate;
}

class SavedBookingAdvanceDocument {
  const SavedBookingAdvanceDocument({
    required this.bookingNo,
    required this.orderIds,
  });

  final String bookingNo;
  final List<int> orderIds;
}

class BookingAdvanceRepository {
  final AppDatabase _db;
  ShopSetupRepository? _shopRepository;
  BookingAdvanceBillingRepo? _billingSettingsRepository;

  BookingAdvanceRepository({
    AppDatabase? db,
    ShopSetupRepository? shopRepository,
    BookingAdvanceBillingRepo? billingSettingsRepository,
  })  : _db = db ?? AppDatabase(),
        _shopRepository = shopRepository,
        _billingSettingsRepository = billingSettingsRepository;

  ShopSetupRepository get _effectiveShopRepository =>
      _shopRepository ??= ShopSetupRepository();

  BookingAdvanceBillingRepo get _effectiveBillingSettingsRepository =>
      _billingSettingsRepository ??= BookingAdvanceBillingRepo(db: _db);

  Future<BookingAdvanceBillingModel> fetchBillingSettings() {
    return _effectiveBillingSettingsRepository.fetch();
  }

  /// Returns the current Indian financial year string.
  /// Example: April 2025 to March 2026 is represented as "2526".
  String getCurrentFinancialYear() {
    final now = DateTime.now();
    final startYear = now.month < 4 ? now.year - 1 : now.year;
    final endYear = startYear + 1;
    return '${(startYear % 100).toString().padLeft(2, '0')}'
        '${(endYear % 100).toString().padLeft(2, '0')}';
  }

  String getCurrentDocumentYearToken([DateTime? date]) {
    return PosInvoiceSeriesFormatter.financialYearToken(date ?? DateTime.now());
  }

  String formatBookingNumber({
    required String shopCode,
    required String yearToken,
    required int sequence,
    String documentPrefix = BookingAdvanceBillingModel.defaultDocumentPrefix,
  }) {
    final normalizedPrefix = documentPrefix
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return '${PosInvoiceSeriesFormatter.normalizeBusinessCode(shopCode)}-'
        '${normalizedPrefix.isEmpty ? BookingAdvanceBillingModel.defaultDocumentPrefix : normalizedPrefix}-'
        '${PosInvoiceSeriesFormatter.normalizeFinancialYearToken(yearToken)}-'
        '${sequence < 1 ? '0001' : sequence.toString().padLeft(4, '0')}';
  }

  Future<String> resolveShopDocumentCode() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final shopData =
          await _effectiveShopRepository.fetchExistingSetup(tenantId);
      final shopName = _shopNameFromSetup(shopData);
      return PosInvoiceSeriesFormatter.businessCode(shopName);
    } catch (error) {
      AppLogger.debug('Booking shop code sync failed: $error');
      return PosInvoiceSeriesFormatter.businessCode('');
    }
  }

  /// Returns the next available sequence for the active financial year.
  Future<int> getNextBookingSequence({
    String? shopCode,
    String? yearToken,
    String documentPrefix = BookingAdvanceBillingModel.defaultDocumentPrefix,
  }) async {
    final normalizedYearToken =
        PosInvoiceSeriesFormatter.normalizeFinancialYearToken(
      yearToken ?? getCurrentDocumentYearToken(),
    );
    final normalizedPrefix = documentPrefix
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final prefix = normalizedPrefix.isEmpty
        ? BookingAdvanceBillingModel.defaultDocumentPrefix
        : normalizedPrefix;
    final legacyFinancialYear = _legacyFinancialYearSpan(normalizedYearToken);
    final legacyCalendarYear = _legacyCalendarYear(normalizedYearToken);
    final rows = await _db.customSelect(
      '''
      SELECT order_no
      FROM sales_orders
      WHERE order_no LIKE ?
         OR order_no LIKE ?
         OR order_no LIKE ?
      ''',
      variables: [
        Variable.withString('%-$prefix-$normalizedYearToken-%'),
        Variable.withString('$prefix-%-$legacyFinancialYear-%'),
        Variable.withString('$prefix-%-$legacyCalendarYear-%'),
      ],
      readsFrom: {_db.salesOrders},
    ).get();

    var maxSequence = 0;
    for (final row in rows) {
      final sequence = _bookingDocumentSequence(
        row.read<String>('order_no'),
        yearToken: normalizedYearToken,
        documentPrefix: prefix,
      );
      if (sequence > maxSequence) maxSequence = sequence;
    }

    return maxSequence + 1;
  }

  Future<int> resolveCustomerForBooking({
    int? selectedCustomerId,
    required String customerName,
    required String customerMobile,
    required String address,
    required String panNumber,
    required String gstNumber,
  }) async {
    if (selectedCustomerId != null && selectedCustomerId > 0) {
      final existing = await (_db.select(_db.customers)
            ..where((tbl) => tbl.id.equals(selectedCustomerId)))
          .getSingleOrNull();
      if (existing != null) return existing.id;
    }

    final cleanMobile = customerMobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanMobile.isNotEmpty) {
      final existing = await (_db.select(_db.customers)
            ..where((tbl) => tbl.mobile.equals(cleanMobile)))
          .getSingleOrNull();
      if (existing != null) return existing.id;
    }

    final displayName = customerName.trim().isEmpty
        ? cleanMobile.isEmpty
            ? 'Walk-in Customer'
            : 'Customer ${cleanMobile.substring(cleanMobile.length - 4)}'
        : customerName.trim();

    return _db.into(_db.customers).insert(
          CustomersCompanion(
            name: Value(displayName),
            firstName: Value(displayName),
            mobile: Value(CustomerContactValue.storageMobile(cleanMobile)),
            addressLine1: Value(_nullable(address)),
            panNumber: Value(_nullableUpper(panNumber)),
            gstNumber: Value(_nullableUpper(gstNumber)),
            type: const Value('Regular'),
            customerTier: const Value('Regular'),
            notes: cleanMobile.isEmpty
                ? const Value('Created from Booking & Advance quick entry.')
                : const Value.absent(),
          ),
        );
  }

  // ===========================================================================
  // SAVE NEW BOOKING
  // ===========================================================================

  Future<int> saveNewBooking({
    required int customerId,
    required String customerName,
    required String customerMobile,
    required String itemName,
    required String itemDesc,
    required String metalType,
    required String purity,
    required double approxWeight,
    required String bookingType,
    required double lockedRate,
    required DateTime? deliveryDate,
    required String? notes,
    required double totalAdvance,
    required double goldRate,
    required bool isGst,
  }) async {
    final document = await saveBookingDocument(
      customerId: customerId,
      lines: [
        BookingAdvanceLineDraft(
          itemName: itemName,
          metalType: metalType,
          purity: purity,
          approxWeight: approxWeight,
          bookingType: bookingType,
          lockedRate: lockedRate,
          deliveryDate: deliveryDate,
          notes: notes,
          advanceAmount: totalAdvance,
          rateOnDate: goldRate,
        ),
      ],
    );
    return document.orderIds.single;
  }

  Future<SavedBookingAdvanceDocument> saveBookingDocument({
    required int customerId,
    required List<BookingAdvanceLineDraft> lines,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError.value(lines, 'lines', 'No booking lines to save.');
    }

    final shopCode = await resolveShopDocumentCode();
    final yearToken = getCurrentDocumentYearToken();
    final settings = await fetchBillingSettings();

    return _db.transaction(() async {
      final firstSequence = await getNextBookingSequence(
        shopCode: shopCode,
        yearToken: yearToken,
        documentPrefix: settings.documentPrefix,
      );
      final orderIds = <int>[];
      final orderNos = <String>[];

      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final orderNo = formatBookingNumber(
          shopCode: shopCode,
          yearToken: yearToken,
          sequence: firstSequence + index,
          documentPrefix: settings.documentPrefix,
        );
        final orderId = await _db.into(_db.salesOrders).insert(
              SalesOrdersCompanion.insert(
                orderNo: orderNo,
                customerId: customerId,
                itemName: line.itemName,
                metalType: Value(line.metalType),
                purity: Value(line.purity),
                approxWeight: Value(line.approxWeight),
                bookingType: Value(line.bookingType),
                lockedRate: Value(line.lockedRate),
                status: const Value('PENDING'),
                deliveryDate: Value(line.deliveryDate),
                notes: Value(line.notes),
              ),
            );

        if (line.advanceAmount > 0) {
          await _db.into(_db.orderAdvances).insert(
                OrderAdvancesCompanion.insert(
                  orderId: orderId,
                  amountPaid: Value(line.advanceAmount),
                  rateOnDate: Value(line.rateOnDate),
                ),
              );
        }

        orderIds.add(orderId);
        orderNos.add(orderNo);
      }

      final bookingNo = orderNos.length == 1
          ? orderNos.single
          : '${orderNos.first} +${orderNos.length - 1}';
      AppLogger.debug(
        'Booking saved: $bookingNo | Lines: ${orderIds.length}',
      );
      return SavedBookingAdvanceDocument(
        bookingNo: bookingNo,
        orderIds: List<int>.unmodifiable(orderIds),
      );
    });
  }

  Future<EditableBookingAdvance?> fetchEditableBooking(int orderId) async {
    final order = await (_db.select(_db.salesOrders)
          ..where((tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
    if (order == null) return null;

    final customer = await (_db.select(_db.customers)
          ..where((tbl) => tbl.id.equals(order.customerId)))
        .getSingleOrNull();
    final advances = await (_db.select(_db.orderAdvances)
          ..where((tbl) => tbl.orderId.equals(orderId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.paymentDate)]))
        .get();

    return EditableBookingAdvance(
      order: order,
      customer: customer,
      advances: advances,
    );
  }

  Future<List<EditableBookingAdvance>> fetchPrintableBookings(
    List<int> orderIds,
  ) async {
    final printableBookings = <EditableBookingAdvance>[];
    for (final orderId in orderIds) {
      final booking = await fetchEditableBooking(orderId);
      if (booking != null) {
        printableBookings.add(booking);
      }
    }
    return List.unmodifiable(printableBookings);
  }

  Future<String> resolveShopDisplayName() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final shopData =
          await _effectiveShopRepository.fetchExistingSetup(tenantId);
      final shopName = _shopNameFromSetup(shopData);
      return shopName.isEmpty ? 'Shop Name Not Set' : shopName;
    } catch (error) {
      AppLogger.debug('Booking shop profile sync failed: $error');
      return 'Shop Name Not Set';
    }
  }

  Future<void> updateBooking({
    required int orderId,
    required int customerId,
    required String itemName,
    required String metalType,
    required String purity,
    required double approxWeight,
    required String bookingType,
    required double lockedRate,
    required DateTime? deliveryDate,
    required String? notes,
    required double totalAdvance,
    required double rateOnDate,
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.salesOrders)
            ..where((tbl) => tbl.id.equals(orderId)))
          .write(
        SalesOrdersCompanion(
          customerId: Value(customerId),
          itemName: Value(itemName),
          metalType: Value(metalType),
          purity: Value(purity),
          approxWeight: Value(approxWeight),
          bookingType: Value(bookingType),
          lockedRate: Value(lockedRate),
          deliveryDate: Value(deliveryDate),
          notes: Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (_db.delete(_db.orderAdvances)
            ..where((tbl) => tbl.orderId.equals(orderId)))
          .go();

      if (totalAdvance > 0) {
        await _db.into(_db.orderAdvances).insert(
              OrderAdvancesCompanion.insert(
                orderId: orderId,
                amountPaid: Value(totalAdvance),
                rateOnDate: Value(rateOnDate),
              ),
            );
      }
    });
  }

  Future<bool> markConvertedToSale({
    required int orderId,
    required String invoiceNumber,
  }) async {
    final updated = await (_db.update(_db.salesOrders)
          ..where((tbl) => tbl.id.equals(orderId)))
        .write(
      SalesOrdersCompanion(
        status: const Value('DELIVERED'),
        notes: Value('Converted to sales invoice $invoiceNumber'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return updated > 0;
  }

  // ===========================================================================
  // CUSTOMER SEARCH
  // ===========================================================================

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final term = query.trim();
    if (term.length < 2) return [];

    final rows = await _db.select(_db.customers).get();
    final isNumeric = RegExp(r'^\d+$').hasMatch(term);
    final normalizedTerm = term.toLowerCase();
    final results = isNumeric
        ? rows
            .where((row) => CustomerContactValue.displayMobile(row.mobile)
                .contains(normalizedTerm))
            .take(8)
            .toList(growable: false)
        : FuzzySearchHelper.searchObjects(
            items: rows,
            query: normalizedTerm,
            getSearchText: (row) =>
                '${row.name} ${CustomerContactValue.displayMobile(row.mobile)}',
            maxResults: 8,
            threshold: 0.30,
          );

    return results
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'mobile': CustomerContactValue.displayMobile(c.mobile),
              'address': customerAddressForBooking(c),
              'city': customerAddressForBooking(c),
            })
        .toList();
  }

  String customerAddressForBooking(Customer row) {
    final parts = <String>[
      row.addressLine1 ?? '',
      row.addressLine2 ?? '',
    ];
    final uniqueParts = <String>[];
    for (final part in parts) {
      final clean = part.trim();
      if (clean.isNotEmpty && !uniqueParts.contains(clean)) {
        uniqueParts.add(clean);
      }
    }
    return uniqueParts.join(', ');
  }
}
