// =============================================================================
// FILE        : supplier_repository.dart
// MODULE      : Supplier
// LAYER       : Repository
// DESCRIPTION : All DB read/write operations for Suppliers.
//               Single source of truth — pattern mirrors karigar_repository.dart.
// =============================================================================

import 'package:drift/drift.dart' as drift;

import '../../database/db/app_database.dart';
import '../../models/stock/supplier_model/supplier_model.dart';
import '../../models/stock/supplier_model/supplier_enums.dart';

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
          ..where((s) =>
              s.businessName.lower().contains(q) |
              s.mobile.contains(q) |
              s.contactPersonName.lower().contains(q))
          ..orderBy([(s) => drift.OrderingTerm.asc(s.businessName)]))
        .get();
    return rows.map(_toListItem).toList();
  }

  /// Filter by supplier type
  Future<List<SupplierListItemModel>> getByType(SupplierType type) async {
    final rows = await (_db.select(_db.suppliers)
          ..where((s) =>
              s.supplierType.equals(type.label) &
              s.status.equals(SupplierStatus.active.label))
          ..orderBy([(s) => drift.OrderingTerm.asc(s.businessName)]))
        .get();
    return rows.map(_toListItem).toList();
  }

  /// Full supplier record for profile / edit
  Future<SupplierModel?> getById(int id) async {
    final row = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toModel(row) : null;
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
        total: active, todayCount: todayNew, manufacturerCount: manufacturer);
  }

  // ── WRITE ───────────────────────────────────────────────────────────────

  Future<int> addSupplier(SupplierModel m) async {
    return _db.into(_db.suppliers).insert(_toCompanion(m));
  }

  Future<bool> updateSupplier(SupplierModel m) async {
    if (m.id == null) return false;
    final n = await (_db.update(_db.suppliers)
          ..where((s) => s.id.equals(m.id!)))
        .write(_toCompanionUpdate(m));
    return n > 0;
  }

  /// Soft delete — mark Inactive
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
