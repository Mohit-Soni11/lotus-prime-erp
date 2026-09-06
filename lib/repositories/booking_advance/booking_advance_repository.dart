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
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_setup_repository.dart';

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

class BookingAdvanceRepository {
  final AppDatabase _db;
  ShopSetupRepository? _shopRepository;

  BookingAdvanceRepository({
    AppDatabase? db,
    ShopSetupRepository? shopRepository,
  })  : _db = db ?? AppDatabase(),
        _shopRepository = shopRepository;

  ShopSetupRepository get _effectiveShopRepository =>
      _shopRepository ??= ShopSetupRepository();

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
  }) {
    return '${PosInvoiceSeriesFormatter.normalizeBusinessCode(shopCode)}-'
        'BK-'
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
  }) async {
    final normalizedYearToken =
        PosInvoiceSeriesFormatter.normalizeFinancialYearToken(
      yearToken ?? getCurrentDocumentYearToken(),
    );
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
        Variable.withString('%-BK-$normalizedYearToken-%'),
        Variable.withString('BK-%-$legacyFinancialYear-%'),
        Variable.withString('BK-%-$legacyCalendarYear-%'),
      ],
      readsFrom: {_db.salesOrders},
    ).get();

    var maxSequence = 0;
    for (final row in rows) {
      final sequence = _bookingDocumentSequence(
        row.read<String>('order_no'),
        yearToken: normalizedYearToken,
      );
      if (sequence > maxSequence) maxSequence = sequence;
    }

    return maxSequence + 1;
  }

  Future<int> resolveCustomerForBooking({
    int? selectedCustomerId,
    required String customerName,
    required String customerMobile,
    required String city,
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
            city: Value(_nullable(city)),
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
    return _db.transaction(() async {
      final orderNo = await _nextOrderNumber();
      final orderId = await _db.into(_db.salesOrders).insert(
            SalesOrdersCompanion.insert(
              orderNo: orderNo,
              customerId: customerId,
              itemName: itemName,
              metalType: Value(metalType),
              purity: Value(purity),
              approxWeight: Value(approxWeight),
              bookingType: Value(bookingType),
              lockedRate: Value(lockedRate),
              status: const Value('PENDING'),
              deliveryDate: Value(deliveryDate),
              notes: Value(notes),
            ),
          );

      if (totalAdvance > 0) {
        await _db.into(_db.orderAdvances).insert(
              OrderAdvancesCompanion.insert(
                orderId: orderId,
                amountPaid: Value(totalAdvance),
                rateOnDate: Value(goldRate),
              ),
            );
      }

      AppLogger.debug('Booking saved: $orderNo | Advance: $totalAdvance');
      return orderId;
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
    if (query.trim().length < 2) return [];
    final results = await (_db.select(_db.customers)
          ..where((t) => t.name.contains(query) | t.mobile.contains(query))
          ..limit(8))
        .get();
    return results
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'mobile': CustomerContactValue.displayMobile(c.mobile),
              'city': c.city ?? '',
            })
        .toList();
  }

  Future<String> _nextOrderNumber() async {
    final shopCode = await resolveShopDocumentCode();
    final yearToken = getCurrentDocumentYearToken();
    final sequence = await getNextBookingSequence(
      shopCode: shopCode,
      yearToken: yearToken,
    );
    return formatBookingNumber(
      shopCode: shopCode,
      yearToken: yearToken,
      sequence: sequence,
    );
  }

  int _bookingDocumentSequence(
    String orderNo, {
    required String yearToken,
  }) {
    final normalized = orderNo.trim().toUpperCase();
    final current = RegExp(
      '^[A-Z0-9]{2,6}-BK-${RegExp.escape(yearToken)}-(\\d+)\$',
    ).firstMatch(normalized);
    if (current != null) {
      return int.tryParse(current.group(1) ?? '') ?? 0;
    }

    final legacy = RegExp(
      '^BK-[A-Z0-9]{1,8}-(\\d{4})-(\\d+)\$',
    ).firstMatch(normalized);
    if (legacy != null &&
        _legacyFinancialYearStartToken(legacy.group(1) ?? '') == yearToken) {
      return int.tryParse(legacy.group(2) ?? '') ?? 0;
    }

    return 0;
  }

  String _legacyFinancialYearStartToken(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 4) {
      final first = int.tryParse(digits.substring(0, 2));
      final second = int.tryParse(digits.substring(2, 4));
      if (first != null && second != null) {
        return (second - first + 100) % 100 == 1
            ? digits.substring(0, 2)
            : digits.substring(2, 4);
      }
    }
    if (digits.length >= 2) {
      return digits.substring(0, 2);
    }
    return PosInvoiceSeriesFormatter.normalizeFinancialYearToken(value);
  }

  String _legacyFinancialYearSpan(String yearToken) {
    final start = int.tryParse(yearToken) ?? 0;
    final end = (start + 1) % 100;
    return '${start.toString().padLeft(2, '0')}'
        '${end.toString().padLeft(2, '0')}';
  }

  String _legacyCalendarYear(String yearToken) {
    return '20${yearToken.padLeft(2, '0')}';
  }

  String _shopNameFromSetup(Map<String, dynamic>? shopData) {
    final basicInfo = shopData?['basic_info'] as Map<String, dynamic>?;
    return [
      basicInfo?['brand_display_name'],
      basicInfo?['display_name'],
      basicInfo?['legal_name'],
    ]
        .map((value) => value?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _nullableUpper(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed.toUpperCase();
  }
}
