// =============================================================================
// FILE        : add_customer_repository.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Repository / Data
// VERSION     : 2.0 — Full expansion
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/customer/add_customer/add_customer_form_model.dart';

class AddCustomerRepository {
  final AppDatabase _db;
  AddCustomerRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ── SAVE ─────────────────────────────────────────────────────────────────
  Future<SaveResult> saveCustomer(AddCustomerFormModel f) async {
    try {
      final exists = await _checkMobileExists(f.mobile.trim());
      if (exists) return SaveResult.duplicate;

      final String displayName = f.isCorporate
          ? f.companyName.trim()
          : '${f.firstName.trim()} ${f.lastName.trim()}'.trim();

      await _db.into(_db.customers).insert(
            CustomersCompanion.insert(
              // Legacy
              name: displayName.isEmpty ? f.mobile : displayName,
              mobile: f.mobile.trim(),
              city: drift.Value(f.city.trim().isEmpty ? null : f.city.trim()),
              type: drift.Value(f.customerTier.label),

              // Entity
              entityType: drift.Value(f.entityType.label),

              // Personal
              firstName: drift.Value(_n(f.firstName)),
              lastName: drift.Value(_n(f.lastName)),
              companyName: drift.Value(_n(f.companyName)),
              contactPersonName: drift.Value(_n(f.contactPersonName)),
              dateOfBirth: drift.Value(f.dateOfBirth?.toIso8601String()),
              gender: drift.Value(f.gender?.label),
              anniversaryDate:
                  drift.Value(f.anniversaryDate?.toIso8601String()),

              // Contact
              whatsapp: drift.Value(_n(f.whatsapp)),
              email: drift.Value(_n(f.email)),
              alternateContact: drift.Value(_n(f.alternateContact)),

              // KYC
              panNumber: drift.Value(_n(f.panNumber)),
              idProofType: drift.Value(f.idProofType?.label),
              idProofNumber: drift.Value(_n(f.idProofNumber)),
              idProofDocPath: drift.Value(f.idProofDocPath),
              gstNumber: drift.Value(_n(f.gstNumber)),

              // Address
              addressLine1: drift.Value(_n(f.addressLine1)),
              addressLine2: drift.Value(_n(f.addressLine2)),
              country: drift.Value(f.country),
              state: drift.Value(_n(f.state)),
              pincode: drift.Value(_n(f.pincode)),

              // Billing
              openingBalance: drift.Value(f.openingBalance),
              creditLimit: drift.Value(f.creditLimit),
              customerTier: drift.Value(f.customerTier.label),
              membershipId: drift.Value(_n(f.membershipId)),

              // Preferences
              ringSize: drift.Value(f.ringSize?.label),
              bangleSize: drift.Value(f.bangleSize?.label),
              familyDetailsJson: drift.Value(
                f.familyMembers.isEmpty
                    ? null
                    : FamilyMember.encodeList(f.familyMembers),
              ),

              // Additional
              referralSource: drift.Value(f.referralSource?.label),
              notes: drift.Value(_n(f.notes)),
              profileImagePath: drift.Value(f.profileImagePath),
            ),
          );

      debugPrint('✅ Customer saved: $displayName (${f.mobile})');
      return SaveResult.success;
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique') || msg.contains('constraint')) {
        return SaveResult.duplicate;
      }
      debugPrint('❌ Save Error: $e');
      return SaveResult.error;
    } catch (e) {
      debugPrint('❌ Unknown Error: $e');
      return SaveResult.error;
    }
  }

  // Helper: empty string → null
  String? _n(String v) => v.trim().isEmpty ? null : v.trim();

  // ── DUPLICATE CHECK ───────────────────────────────────────────────────────
  Future<bool> _checkMobileExists(String mobile) async {
    try {
      final r = await (_db.select(_db.customers)
            ..where((t) => t.mobile.equals(mobile))
            ..limit(1))
          .getSingleOrNull();
      return r != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isMobileDuplicate(String mobile) async {
    if (mobile.trim().length != 10) return false;
    return _checkMobileExists(mobile.trim());
  }
}

enum SaveResult { success, duplicate, error }
