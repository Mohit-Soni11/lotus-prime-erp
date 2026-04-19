// =============================================================================
// FILE        : karigar_directory_repository.dart
// MODULE      : Karigar → Karigar Directory
// LAYER       : Repository / Data Access
// DESCRIPTION : Data-access gateway for the Karigar Directory list screen.
//               Fetches karigar list with aggregated job/balance stats,
//               and computes dashboard stats.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../models/karigar/karigar_directory/karigar_directory_ui_model.dart';

class KarigarDirectoryRepository {
  final AppDatabase _db;

  KarigarDirectoryRepository(this._db);

  // ════════════════════════════════════════════════════════════════════════════
  // LIST — with aggregated stats per karigar
  // ════════════════════════════════════════════════════════════════════════════

  Future<List<KarigarDirectoryItemModel>> getAllKarigars({
    bool? activeOnly,
  }) async {
    try {
      // 1. Fetch all karigars
      final query = _db.select(_db.karigarMasters);
      if (activeOnly == true) {
        query.where((k) => k.isActive.equals(true));
      } else if (activeOnly == false) {
        query.where((k) => k.isActive.equals(false));
      }
      query.orderBy([(k) => drift.OrderingTerm.asc(k.name)]);
      final karigars = await query.get();

      // 2. Fetch all active issues
      final issues = await (_db.select(_db.karigarIssues)
            ..where((i) =>
                i.status.equals(IssueStatus.pending.label) |
                i.status.equals(IssueStatus.inProgress.label)))
          .get();

      // 3. Fetch all receipts (for outstanding balance)
      final receipts = await (_db.select(_db.karigarReceipts)).get();

      // 4. Build lookup maps
      final Map<int, int>    activeJobMap   = {};
      final Map<int, int>    overdueJobMap  = {};
      final Map<int, double> pendingWtMap   = {};
      final Map<int, double> outstandingMap = {};

      for (final issue in issues) {
        final kid = issue.karigarId;
        activeJobMap[kid]  = (activeJobMap[kid] ?? 0) + 1;
        pendingWtMap[kid]  = (pendingWtMap[kid] ?? 0.0) + issue.netWeightIssued;
        if (issue.expectedDelivery != null &&
            DateTime.now().isAfter(issue.expectedDelivery!)) {
          overdueJobMap[kid] = (overdueJobMap[kid] ?? 0) + 1;
        }
      }

      for (final receipt in receipts) {
        final kid = receipt.karigarId;
        final due = receipt.makingChargesAmount - receipt.paidAmount;
        if (due > 0) {
          outstandingMap[kid] = (outstandingMap[kid] ?? 0.0) + due;
        }
      }

      // 5. Map to UI models
      return karigars.map((k) {
        return KarigarDirectoryItemModel(
          id:                 k.id,
          name:               k.name,
          phone:              k.phone,
          alternatePhone:     k.alternatePhone,
          specialization:     k.specialization,
          rateType:           k.rateType,
          rateAmount:         k.rateAmount,
          address:            k.address,
          city:               k.city,
          openingBalance:     k.openingBalance,
          isActive:           k.isActive,
          notes:              k.notes,
          createdAt:          k.createdAt,
          activeJobCount:     activeJobMap[k.id] ?? 0,
          overdueJobCount:    overdueJobMap[k.id] ?? 0,
          outstandingBalance: (outstandingMap[k.id] ?? 0.0) + k.openingBalance,
          totalWeightPending: pendingWtMap[k.id] ?? 0.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('KarigarDirectoryRepository.getAllKarigars error: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATS
  // ════════════════════════════════════════════════════════════════════════════

  Future<KarigarDirectoryStatsModel> fetchStats() async {
    try {
      final all      = await _db.select(_db.karigarMasters).get();
      final now      = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      int totalActive   = 0;
      int totalInactive = 0;
      int newThisMonth  = 0;

      for (final k in all) {
        if (k.isActive) totalActive++;   else totalInactive++;
        if (k.createdAt.isAfter(monthStart)) newThisMonth++;
      }

      // Active jobs
      final activeIssues = await (_db.select(_db.karigarIssues)
            ..where((i) =>
                i.status.equals(IssueStatus.pending.label) |
                i.status.equals(IssueStatus.inProgress.label)))
          .get();

      final karigarsWithJobs =
          activeIssues.map((i) => i.karigarId).toSet().length;

      // Outstanding
      final receipts = await _db.select(_db.karigarReceipts).get();
      double totalOutstanding = 0;
      for (final r in receipts) {
        final due = r.makingChargesAmount - r.paidAmount;
        if (due > 0) totalOutstanding += due;
      }
      // Add opening balances
      for (final k in all) {
        if (k.isActive && k.openingBalance > 0) {
          totalOutstanding += k.openingBalance;
        }
      }

      return KarigarDirectoryStatsModel(
        totalActive:      totalActive,
        totalInactive:    totalInactive,
        newThisMonth:     newThisMonth,
        withActiveJobs:   karigarsWithJobs,
        totalOutstanding: totalOutstanding,
      );
    } catch (e) {
      debugPrint('KarigarDirectoryRepository.fetchStats error: $e');
      return KarigarDirectoryStatsModel.empty();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEARCH
  // ════════════════════════════════════════════════════════════════════════════

  Future<List<KarigarDirectoryItemModel>> searchKarigars(String query) async {
    final q = query.toLowerCase().trim();
    final all = await getAllKarigars();
    return all.where((k) {
      return k.name.toLowerCase().contains(q) ||
          k.phone.contains(q) ||
          (k.city?.toLowerCase().contains(q) ?? false) ||
          k.specialization.toLowerCase().contains(q);
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ADD NEW KARIGAR
  // ════════════════════════════════════════════════════════════════════════════

  Future<int> addKarigar(KarigarMastersCompanion companion) async {
    return _db.into(_db.karigarMasters).insert(companion);
  }

  Future<KarigarMaster?> getKarigarById(int id) async {
    return (_db.select(_db.karigarMasters)
          ..where((k) => k.id.equals(id)))
        .getSingleOrNull();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DEACTIVATE / REACTIVATE
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> setKarigarActiveStatus(int id, bool isActive) async {
    final rows = await (_db.update(_db.karigarMasters)
          ..where((k) => k.id.equals(id)))
        .write(KarigarMastersCompanion(
          isActive:  drift.Value(isActive),
          updatedAt: drift.Value(DateTime.now()),
        ));
    return rows > 0;
  }
}
