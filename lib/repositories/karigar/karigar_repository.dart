// =============================================================================
// FILE        : karigar_repository.dart
// MODULE      : Karigar
// LAYER       : Repository / Data Access
// DESCRIPTION : Single data-access gateway for the entire Karigar module.
//               Wraps all Drift queries, join operations, sequence generators,
//               and aggregate stat computations behind clean async methods.
//               Controllers NEVER touch AppDatabase directly — only this class.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../models/karigar/karigar_issue_model.dart';
import '../../models/karigar/karigar_stats_model.dart';

class KarigarRepository {
  final AppDatabase _db;

  KarigarRepository(this._db);

  // ════════════════════════════════════════════════════════════════════════════
  // KARIGAR MASTER — CRUD
  // ════════════════════════════════════════════════════════════════════════════

  /// Insert a new karigar and return the auto-generated id.
  Future<int> addKarigar(KarigarMastersCompanion companion) async {
    return _db.into(_db.karigarMasters).insert(companion);
  }

  /// Return all karigars. [activeOnly] filters out deactivated records.
  Future<List<KarigarMaster>> getAllKarigars({bool activeOnly = true}) async {
    final query = _db.select(_db.karigarMasters);
    if (activeOnly) {
      query.where((k) => k.isActive.equals(true));
    }
    query.orderBy([(k) => drift.OrderingTerm.asc(k.name)]);
    return query.get();
  }

  /// Return a single karigar by primary key, or null if not found.
  Future<KarigarMaster?> getKarigarById(int id) async {
    return (_db.select(_db.karigarMasters)..where((k) => k.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update an existing karigar record.
  Future<bool> updateKarigar(int id, KarigarMastersCompanion companion) async {
    final rowsAffected = await (_db.update(_db.karigarMasters)
          ..where((k) => k.id.equals(id)))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Soft-delete: mark karigar as inactive (preserves historical data).
  Future<bool> deactivateKarigar(int id) async {
    final rowsAffected = await (_db.update(_db.karigarMasters)
          ..where((k) => k.id.equals(id)))
        .write(KarigarMastersCompanion(
      isActive: const drift.Value(false),
      updatedAt: drift.Value(DateTime.now()),
    ));
    return rowsAffected > 0;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // KARIGAR ISSUES — CRUD & QUERIES
  // ════════════════════════════════════════════════════════════════════════════

  /// Insert a new issue and return the auto-generated id.
  Future<int> createIssue(KarigarIssuesCompanion companion) async {
    return _db.into(_db.karigarIssues).insert(companion);
  }

  /// Return all active (Pending / In Progress) issues with karigar details.
  Future<List<KarigarIssueWithKarigar>> getActiveIssuesWithKarigar() async {
    return _getIssuesWithKarigar(activeOnly: true);
  }

  /// Return all issues with karigar details, with optional status filter.
  Future<List<KarigarIssueWithKarigar>> getAllIssuesWithKarigar({
    IssueStatus? statusFilter,
    int? karigarIdFilter,
  }) async {
    return _getIssuesWithKarigar(
      statusFilter: statusFilter,
      karigarIdFilter: karigarIdFilter,
    );
  }

  /// Internal join query helper.
  Future<List<KarigarIssueWithKarigar>> _getIssuesWithKarigar({
    bool activeOnly = false,
    IssueStatus? statusFilter,
    int? karigarIdFilter,
  }) async {
    final query = _db.select(_db.karigarIssues).join([
      drift.innerJoin(
        _db.karigarMasters,
        _db.karigarMasters.id.equalsExp(_db.karigarIssues.karigarId),
      ),
    ]);

    if (activeOnly) {
      query.where(
        _db.karigarIssues.status.equals(IssueStatus.pending.label) |
            _db.karigarIssues.status.equals(IssueStatus.inProgress.label),
      );
    } else if (statusFilter != null) {
      query.where(_db.karigarIssues.status.equals(statusFilter.label));
    }

    if (karigarIdFilter != null) {
      query.where(_db.karigarIssues.karigarId.equals(karigarIdFilter));
    }

    query.orderBy([
      drift.OrderingTerm.desc(_db.karigarIssues.issueDate),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final issue = row.readTable(_db.karigarIssues);
      final karigar = row.readTable(_db.karigarMasters);
      return KarigarIssueWithKarigar(
        id: issue.id,
        issueNumber: issue.issueNumber,
        karigarId: karigar.id,
        karigarName: karigar.name,
        karigarPhone: karigar.phone,
        issueDate: issue.issueDate,
        itemDescription: issue.itemDescription,
        itemCategory: issue.itemCategory,
        quantity: issue.quantity,
        metalType: issue.metalType,
        purity: issue.purity,
        grossWeightIssued: issue.grossWeightIssued,
        netWeightIssued: issue.netWeightIssued,
        expectedDelivery: issue.expectedDelivery,
        status: issue.status,
        notes: issue.notes,
        createdAt: issue.createdAt,
      );
    }).toList();
  }

  /// Return a raw KarigarIssue by id (used in Receive screen).
  Future<KarigarIssue?> getIssueById(int id) async {
    return (_db.select(_db.karigarIssues)..where((i) => i.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update the status of an issue.
  Future<bool> updateIssueStatus(int id, IssueStatus newStatus) async {
    final rowsAffected = await (_db.update(_db.karigarIssues)
          ..where((i) => i.id.equals(id)))
        .write(KarigarIssuesCompanion(
      status: drift.Value(newStatus.label),
      updatedAt: drift.Value(DateTime.now()),
    ));
    return rowsAffected > 0;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // KARIGAR RECEIPTS — CRUD & QUERIES
  // ════════════════════════════════════════════════════════════════════════════

  /// Insert a new receipt. Also marks the linked issue as Completed.
  Future<int> createReceipt(KarigarReceiptsCompanion companion) async {
    return _db.transaction(() async {
      final receiptId = await _db.into(_db.karigarReceipts).insert(companion);

      // Auto-complete the linked issue
      final issueId = companion.issueId.value;
      await updateIssueStatus(issueId, IssueStatus.completed);

      return receiptId;
    });
  }

  /// Return all receipts for a specific karigar with full details.
  Future<List<KarigarReceiptWithDetails>> getReceiptsByKarigar(
    int karigarId,
  ) async {
    return _getReceiptsWithDetails(karigarIdFilter: karigarId);
  }

  /// Internal join query: Receipt + Issue + Karigar.
  Future<List<KarigarReceiptWithDetails>> _getReceiptsWithDetails({
    int? karigarIdFilter,
    int? issueIdFilter,
  }) async {
    final query = _db.select(_db.karigarReceipts).join([
      drift.innerJoin(
        _db.karigarIssues,
        _db.karigarIssues.id.equalsExp(_db.karigarReceipts.issueId),
      ),
      drift.innerJoin(
        _db.karigarMasters,
        _db.karigarMasters.id.equalsExp(_db.karigarReceipts.karigarId),
      ),
    ]);

    if (karigarIdFilter != null) {
      query.where(_db.karigarReceipts.karigarId.equals(karigarIdFilter));
    }
    if (issueIdFilter != null) {
      query.where(_db.karigarReceipts.issueId.equals(issueIdFilter));
    }

    query.orderBy([
      drift.OrderingTerm.desc(_db.karigarReceipts.receiptDate),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final receipt = row.readTable(_db.karigarReceipts);
      final issue = row.readTable(_db.karigarIssues);
      final karigar = row.readTable(_db.karigarMasters);
      return KarigarReceiptWithDetails(
        id: receipt.id,
        receiptNumber: receipt.receiptNumber,
        issueId: issue.id,
        issueNumber: issue.issueNumber,
        karigarId: karigar.id,
        karigarName: karigar.name,
        receiptDate: receipt.receiptDate,
        quantityReceived: receipt.quantityReceived,
        grossWeightReceived: receipt.grossWeightReceived,
        stoneWeight: receipt.stoneWeight,
        netWeightReceived: receipt.netWeightReceived,
        wastageWeight: receipt.wastageWeight,
        wastagePercent: receipt.wastagePercent,
        makingChargesType: receipt.makingChargesType,
        makingChargeRate: receipt.makingChargeRate,
        makingChargesAmount: receipt.makingChargesAmount,
        paymentStatus: receipt.paymentStatus,
        paidAmount: receipt.paidAmount,
        notes: receipt.notes,
        createdAt: receipt.createdAt,
      );
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEQUENCE NUMBER GENERATORS
  // ════════════════════════════════════════════════════════════════════════════

  /// Generates the next unique issue number: KGI-YYYYMMDD-NNNN
  Future<String> generateIssueNumber() async {
    final now = DateTime.now();
    final datePart = '${now.year}${_pad(now.month)}${_pad(now.day)}';
    final prefix = 'KGI-$datePart-';

    final existing = await (_db.select(_db.karigarIssues)
          ..where((i) => i.issueNumber.like('$prefix%'))
          ..orderBy([(i) => drift.OrderingTerm.desc(i.issueNumber)])
          ..limit(1))
        .getSingleOrNull();

    int nextSeq = 1;
    if (existing != null) {
      final parts = existing.issueNumber.split('-');
      if (parts.length == 3) {
        nextSeq = (int.tryParse(parts.last) ?? 0) + 1;
      }
    }
    return '$prefix${nextSeq.toString().padLeft(4, '0')}';
  }

  /// Generates the next unique receipt number: KGR-YYYYMMDD-NNNN
  Future<String> generateReceiptNumber() async {
    final now = DateTime.now();
    final datePart = '${now.year}${_pad(now.month)}${_pad(now.day)}';
    final prefix = 'KGR-$datePart-';

    final existing = await (_db.select(_db.karigarReceipts)
          ..where((r) => r.receiptNumber.like('$prefix%'))
          ..orderBy([(r) => drift.OrderingTerm.desc(r.receiptNumber)])
          ..limit(1))
        .getSingleOrNull();

    int nextSeq = 1;
    if (existing != null) {
      final parts = existing.receiptNumber.split('-');
      if (parts.length == 3) {
        nextSeq = (int.tryParse(parts.last) ?? 0) + 1;
      }
    }
    return '$prefix${nextSeq.toString().padLeft(4, '0')}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // ════════════════════════════════════════════════════════════════════════════
  // STATISTICS
  // ════════════════════════════════════════════════════════════════════════════

  /// Compute financial and weight summary for a single karigar.
  Future<KarigarStatsModel> getKarigarStats(
    int karigarId, {
    required double openingBalance,
  }) async {
    // Issues summary
    final issues = await (_db.select(_db.karigarIssues)
          ..where((i) => i.karigarId.equals(karigarId)))
        .get();

    double totalIssued = 0;
    int totalIssueCount = issues.length;
    int activeCount = 0;
    int completedCount = 0;
    int overdueCount = 0;

    for (final issue in issues) {
      totalIssued += issue.netWeightIssued;
      final status = IssueStatus.fromLabel(issue.status);
      if (status.isActive) {
        activeCount++;
        if (issue.expectedDelivery != null &&
            DateTime.now().isAfter(issue.expectedDelivery!)) {
          overdueCount++;
        }
      }
      if (status == IssueStatus.completed) completedCount++;
    }

    // Receipts summary
    final receipts = await (_db.select(_db.karigarReceipts)
          ..where((r) => r.karigarId.equals(karigarId)))
        .get();

    double totalReceived = 0;
    double totalCharges = 0;
    double totalPaid = 0;

    for (final receipt in receipts) {
      totalReceived += receipt.netWeightReceived;
      totalCharges += receipt.makingChargesAmount;
      totalPaid += receipt.paidAmount;
    }

    final pendingWeight =
        (totalIssued - totalReceived).clamp(0.0, double.infinity);
    final outstanding = openingBalance + totalCharges - totalPaid;

    return KarigarStatsModel(
      totalIssuedWeight: totalIssued,
      totalReceivedWeight: totalReceived,
      pendingWeight: pendingWeight,
      totalMakingCharges: totalCharges,
      totalPaid: totalPaid,
      outstandingBalance: outstanding,
      totalIssues: totalIssueCount,
      activeIssues: activeCount,
      completedIssues: completedCount,
      overdueIssues: overdueCount,
    );
  }

  /// Compute aggregate stats across all karigars (for Pending Jobs header).
  Future<OverallKarigarStats> getOverallStats() async {
    try {
      final karigars = await getAllKarigars(activeOnly: true);

      int totalActive = 0;
      int totalOverdue = 0;
      double totalWeight = 0;
      double totalOutstanding = 0;

      final activeIssues = await _getIssuesWithKarigar(activeOnly: true);
      totalActive = activeIssues.length;

      for (final issue in activeIssues) {
        totalWeight += issue.netWeightIssued;
        if (issue.isOverdue) totalOverdue++;
      }

      // Outstanding across all receipts
      final receipts = await (_db.select(_db.karigarReceipts)).get();
      for (final r in receipts) {
        totalOutstanding +=
            (r.makingChargesAmount - r.paidAmount).clamp(0, double.infinity);
      }

      return OverallKarigarStats(
        totalKarigars: karigars.length,
        totalActiveJobs: totalActive,
        totalOverdueJobs: totalOverdue,
        totalWeightWithKarigar: totalWeight,
        totalOutstanding: totalOutstanding,
      );
    } catch (e) {
      debugPrint('KarigarRepository.getOverallStats error: $e');
      return OverallKarigarStats.empty();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // KARIGAR HISAAB — FULL TRANSACTION TIMELINE
  // ════════════════════════════════════════════════════════════════════════════

  /// Returns all issues AND receipts for a karigar, merged and sorted by date.
  Future<List<KarigarTxnEntry>> getKarigarLedger(int karigarId) async {
    final issuesFuture = _getIssuesWithKarigar(karigarIdFilter: karigarId);
    final receiptsFuture = _getReceiptsWithDetails(karigarIdFilter: karigarId);

    final results = await Future.wait([issuesFuture, receiptsFuture]);
    final issues = results[0] as List<KarigarIssueWithKarigar>;
    final receipts = results[1] as List<KarigarReceiptWithDetails>;

    final entries = <KarigarTxnEntry>[
      ...issues.map(KarigarTxnEntry.fromIssue),
      ...receipts.map(KarigarTxnEntry.fromReceipt),
    ];

    // Sort chronologically descending (newest first)
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
}
