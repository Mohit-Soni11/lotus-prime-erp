// =============================================================================
// FILE        : supplier_repository.dart
// MODULE      : Supplier
// LAYER       : Repository
// DESCRIPTION : All DB read/write operations for Suppliers.
//               Single source of truth — pattern mirrors karigar_repository.dart.
// =============================================================================

import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';

class SupplierRepository {
  final AppDatabase _db;
  SupplierRepository(this._db);

  // ── READ ────────────────────────────────────────────────────────────────

  /// All active suppliers ordered by business name
  Future<List<SupplierListItemModel>> getAllSuppliers() async {
    final rows = await (_db.select(_db.suppliers)
          ..where((s) => s.status.equals(SupplierStatus.active.label))
          ..orderBy([(s) => drift.OrderingTerm.asc(s.businessName)]))
        .get();
    return rows.map(_toListItem).toList();
  }

  /// Search by name or mobile
  Future<List<SupplierListItemModel>> searchSuppliers(String query) async {
    if (query.trim().isEmpty) return getAllSuppliers();
    final q = query.trim().toLowerCase();
    final rows = await (_db.select(_db.suppliers)
          ..where(
            (s) =>
                s.businessName.lower().contains(q) |
                s.mobile.contains(q) |
                s.contactPersonName.lower().contains(q),
          )
          ..orderBy([(s) => drift.OrderingTerm.asc(s.businessName)]))
        .get();
    return rows.map(_toListItem).toList();
  }

  /// Filter by supplier type
  Future<List<SupplierListItemModel>> getByType(SupplierType type) async {
    final rows = await (_db.select(_db.suppliers)
          ..where(
            (s) =>
                s.supplierType.equals(type.label) &
                s.status.equals(SupplierStatus.active.label),
          )
          ..orderBy([(s) => drift.OrderingTerm.asc(s.businessName)]))
        .get();
    return rows.map(_toListItem).toList();
  }

  /// Full supplier record for profile / edit
  Future<SupplierModel?> getById(int id) async {
    final row = await (_db.select(
      _db.suppliers,
    )..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toModel(row) : null;
  }

  Future<SupplierLedgerSnapshot> getLedgerSnapshot(int supplierId) async {
    final supplier = await getById(supplierId);
    final rows = await _db.customSelect(
      '''
      SELECT
        id,
        voucher_no,
        supplier_invoice_no,
        tax_type,
        party_name,
        gross_amount,
        grand_total,
        total_paid,
        balance_due,
        rate_per_kg,
        metal_paid_gross_weight,
        metal_paid_purity,
        metal_paid_fine,
        metal_paid_value,
        due_mode,
        excess_mode,
        promise_date,
        payment_meta,
        payment_status,
        stock_entry_count,
        created_at
      FROM purchase_vouchers
      WHERE supplier_id = ?
      ORDER BY created_at DESC
      ''',
      variables: [drift.Variable<int>(supplierId)],
      readsFrom: {_db.suppliers},
    ).get();

    final history = rows.map(_toPurchaseHistoryItem).toList(growable: false);
    final openingBalance = supplier?.openingBalance ?? 0.0;
    final voucherDue = history.fold<double>(
      0.0,
      (sum, item) => sum + item.balanceDue,
    );
    final oldDueAdjusted = history.fold<double>(
      0.0,
      (sum, item) => sum + item.oldDueAdjustedAmount,
    );
    final outstanding = (openingBalance + voucherDue - oldDueAdjusted).clamp(
      0.0,
      double.infinity,
    );

    return SupplierLedgerSnapshot(
      supplierId: supplierId,
      supplierName: supplier?.businessName ?? '',
      openingBalance: openingBalance,
      voucherDueTotal: voucherDue,
      oldDueAdjustedTotal: oldDueAdjusted,
      outstandingDue: outstanding.toDouble(),
      history: history,
    );
  }

  /// Stats for header strip
  Future<SupplierStats> getStats() async {
    final all = await (_db.select(_db.suppliers)).get();
    final active = all.where((s) => s.status == 'Active').length;
    final manufacturer =
        all.where((s) => s.supplierType == 'Manufacturer').length;
    final today = DateTime.now();
    final todayNew = all.where((s) {
      final d = s.createdAt;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;
    return SupplierStats(
      total: active,
      todayCount: todayNew,
      manufacturerCount: manufacturer,
    );
  }

  // ── WRITE ───────────────────────────────────────────────────────────────

  Future<int> addSupplier(SupplierModel m) async {
    return _db.into(_db.suppliers).insert(_toCompanion(m));
  }

  Future<bool> updateSupplier(SupplierModel m) async {
    if (m.id == null) return false;
    final n = await (_db.update(
      _db.suppliers,
    )..where((s) => s.id.equals(m.id!)))
        .write(_toCompanionUpdate(m));
    return n > 0;
  }

  /// Soft delete — mark Inactive
  Future<bool> isMobileDuplicate(
    String mobile, {
    int? excludeSupplierId,
  }) async {
    final normalized = mobile.trim();
    if (normalized.isEmpty) return false;

    final rows = await (_db.select(
      _db.suppliers,
    )..where((s) => s.mobile.equals(normalized)))
        .get();
    return rows.any((row) => row.id != excludeSupplierId);
  }

  Future<bool> deactivateSupplier(int id) async {
    final n = await (_db.update(_db.suppliers)..where((s) => s.id.equals(id)))
        .write(const SuppliersCompanion(status: drift.Value('Inactive')));
    return n > 0;
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────

  SupplierListItemModel _toListItem(Supplier row) => SupplierListItemModel(
        id: row.id,
        businessName: row.businessName,
        contactPersonName: row.contactPersonName,
        mobile: row.mobile,
        gstNumber: row.gstNumber,
        supplierType: SupplierType.fromLabel(row.supplierType),
        status: SupplierStatus.fromLabel(row.status),
        createdAt: row.createdAt,
      );

  SupplierModel _toModel(Supplier row) => SupplierModel(
        id: row.id,
        businessName: row.businessName,
        contactPersonName: row.contactPersonName,
        supplierType: SupplierType.fromLabel(row.supplierType),
        mobile: row.mobile,
        whatsapp: row.whatsapp,
        email: row.email,
        alternateContact: row.alternateContact,
        panNumber: row.panNumber,
        gstNumber: row.gstNumber,
        addressLine1: row.addressLine1,
        addressLine2: row.addressLine2,
        state: row.state,
        pincode: row.pincode,
        country: row.country,
        openingBalance: row.openingBalance,
        notes: row.notes,
        status: SupplierStatus.fromLabel(row.status),
        createdAt: row.createdAt,
      );

  SupplierPurchaseHistoryItem _toPurchaseHistoryItem(drift.QueryRow row) {
    final meta = _decodeMeta(row.readNullable<String>('payment_meta'));
    return SupplierPurchaseHistoryItem(
      voucherId: row.read<int>('id'),
      voucherNo: row.read<String>('voucher_no'),
      supplierInvoiceNo: row.readNullable<String>('supplier_invoice_no'),
      taxType: row.readNullable<String>('tax_type') ?? 'NORMAL',
      purchaseCategory: (meta['purchaseCategory'] as String?) ??
          _categoryFromTaxType(
            row.readNullable<String>('tax_type'),
          ),
      inputCreditStatus: (meta['inputCreditStatus'] as String?) ??
          _creditStatusFromTaxType(row.readNullable<String>('tax_type')),
      partyName: row.read<String>('party_name'),
      grossAmount: row.read<double>('gross_amount'),
      grandTotal: row.read<double>('grand_total'),
      totalPaid: row.read<double>('total_paid'),
      balanceDue: row.read<double>('balance_due'),
      ratePerKg: row.read<double>('rate_per_kg'),
      metalPaidGrossWeight: row.read<double>('metal_paid_gross_weight'),
      metalPaidPurity: row.read<double>('metal_paid_purity'),
      metalPaidFine: row.read<double>('metal_paid_fine'),
      metalPaidValue: row.read<double>('metal_paid_value'),
      dueMode: row.readNullable<String>('due_mode'),
      excessMode: row.readNullable<String>('excess_mode'),
      promiseDate: _dateFromMillis(row.readNullable<int>('promise_date')),
      paymentStatus: row.read<String>('payment_status'),
      stockEntryCount: row.read<int>('stock_entry_count'),
      createdAt: _dateFromMillis(row.read<int>('created_at')) ?? DateTime.now(),
      billPhotoPath: (meta['supplierBillAttachmentPath'] as String?) ??
          meta['billPhotoPath'] as String?,
      oldDueBefore: _readDouble(meta['oldDueBefore']),
      oldDueAdjustedAmount: _readDouble(meta['oldDueAdjustedAmount']),
      metalLineCount: (meta['metalLines'] as List?)?.length ?? 0,
    );
  }

  Map<String, dynamic> _decodeMeta(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String _categoryFromTaxType(String? taxType) {
    return taxType?.trim().toUpperCase() == 'GST'
        ? 'GST_PURCHASE'
        : 'NON_GST_PURCHASE';
  }

  String _creditStatusFromTaxType(String? taxType) {
    return taxType?.trim().toUpperCase() == 'GST' ? 'ITC_ELIGIBLE' : 'NO_ITC';
  }

  DateTime? _dateFromMillis(int? millis) {
    if (millis == null || millis <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  SuppliersCompanion _toCompanion(SupplierModel m) => SuppliersCompanion.insert(
        businessName: m.businessName.trim(),
        contactPersonName: drift.Value(m.contactPersonName?.trim()),
        supplierType: drift.Value(m.supplierType.label),
        mobile: m.mobile.trim(),
        whatsapp: drift.Value(m.whatsapp?.trim()),
        email: drift.Value(m.email?.trim()),
        alternateContact: drift.Value(m.alternateContact?.trim()),
        panNumber: drift.Value(m.panNumber?.trim().toUpperCase()),
        gstNumber: drift.Value(m.gstNumber?.trim().toUpperCase()),
        addressLine1: drift.Value(m.addressLine1?.trim()),
        addressLine2: drift.Value(m.addressLine2?.trim()),
        state: drift.Value(m.state?.trim()),
        pincode: drift.Value(m.pincode?.trim()),
        country: drift.Value(m.country),
        openingBalance: drift.Value(m.openingBalance),
        notes: drift.Value(m.notes?.trim()),
        status: drift.Value(m.status.label),
      );

  SuppliersCompanion _toCompanionUpdate(SupplierModel m) => SuppliersCompanion(
        businessName: drift.Value(m.businessName.trim()),
        contactPersonName: drift.Value(m.contactPersonName?.trim()),
        supplierType: drift.Value(m.supplierType.label),
        mobile: drift.Value(m.mobile.trim()),
        whatsapp: drift.Value(m.whatsapp?.trim()),
        email: drift.Value(m.email?.trim()),
        alternateContact: drift.Value(m.alternateContact?.trim()),
        panNumber: drift.Value(m.panNumber?.trim().toUpperCase()),
        gstNumber: drift.Value(m.gstNumber?.trim().toUpperCase()),
        addressLine1: drift.Value(m.addressLine1?.trim()),
        addressLine2: drift.Value(m.addressLine2?.trim()),
        state: drift.Value(m.state?.trim()),
        pincode: drift.Value(m.pincode?.trim()),
        country: drift.Value(m.country),
        openingBalance: drift.Value(m.openingBalance),
        notes: drift.Value(m.notes?.trim()),
        status: drift.Value(m.status.label),
        updatedAt: drift.Value(DateTime.now()),
      );
}

// ── Stats model ───────────────────────────────────────────────────────────────

class SupplierStats {
  final int total;
  final int todayCount;
  final int manufacturerCount;
  final bool isLoading;

  const SupplierStats({
    this.total = 0,
    this.todayCount = 0,
    this.manufacturerCount = 0,
    this.isLoading = false,
  });

  static const loading = SupplierStats(isLoading: true);
}

class SupplierLedgerSnapshot {
  final int supplierId;
  final String supplierName;
  final double openingBalance;
  final double voucherDueTotal;
  final double oldDueAdjustedTotal;
  final double outstandingDue;
  final List<SupplierPurchaseHistoryItem> history;

  const SupplierLedgerSnapshot({
    required this.supplierId,
    required this.supplierName,
    required this.openingBalance,
    required this.voucherDueTotal,
    required this.oldDueAdjustedTotal,
    required this.outstandingDue,
    required this.history,
  });

  bool get hasOutstandingDue => outstandingDue > 0.005;
}

class SupplierPurchaseHistoryItem {
  final int voucherId;
  final String voucherNo;
  final String? supplierInvoiceNo;
  final String taxType;
  final String purchaseCategory;
  final String inputCreditStatus;
  final String partyName;
  final double grossAmount;
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;
  final double ratePerKg;
  final double metalPaidGrossWeight;
  final double metalPaidPurity;
  final double metalPaidFine;
  final double metalPaidValue;
  final String? dueMode;
  final String? excessMode;
  final DateTime? promiseDate;
  final String paymentStatus;
  final int stockEntryCount;
  final DateTime createdAt;
  final String? billPhotoPath;
  final double oldDueBefore;
  final double oldDueAdjustedAmount;
  final int metalLineCount;

  const SupplierPurchaseHistoryItem({
    required this.voucherId,
    required this.voucherNo,
    this.supplierInvoiceNo,
    required this.taxType,
    required this.purchaseCategory,
    required this.inputCreditStatus,
    required this.partyName,
    required this.grossAmount,
    required this.grandTotal,
    required this.totalPaid,
    required this.balanceDue,
    required this.ratePerKg,
    required this.metalPaidGrossWeight,
    required this.metalPaidPurity,
    required this.metalPaidFine,
    required this.metalPaidValue,
    this.dueMode,
    this.excessMode,
    this.promiseDate,
    required this.paymentStatus,
    required this.stockEntryCount,
    required this.createdAt,
    this.billPhotoPath,
    this.oldDueBefore = 0.0,
    this.oldDueAdjustedAmount = 0.0,
    this.metalLineCount = 0,
  });

  bool get hasBillPhoto => billPhotoPath != null && billPhotoPath!.isNotEmpty;
  bool get isGstPurchase =>
      purchaseCategory.trim().toUpperCase() == 'GST_PURCHASE' ||
      taxType.trim().toUpperCase() == 'GST';
  bool get isInputCreditEligible =>
      inputCreditStatus.trim().toUpperCase() == 'ITC_ELIGIBLE';
}
