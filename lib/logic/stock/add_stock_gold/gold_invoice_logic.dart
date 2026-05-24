// =============================================================================
// FILE        : Gold_invoice_logic.dart
// MODULE      : Stock & Inventory — Gold
// LAYER       : Logic / Invoice
// DESCRIPTION : Isolated Invoice Logic for Gold Add Stock.
//               ✅ Auto-generates System Batch ID (GOL-YYYYMMDD-XXXX format).
//               ✅ Manages supplier invoice TextEditingController.
//               ✅ Exposes live date/time stream via DateCardLogic.
//               ✅ Tracks GST status for invoice type label (Tax / Estimate).
//               ✅ Fully disposable — all controllers released in dispose().
//
// WHY SEPARATE:
//   Invoice concerns (batch ID, supplier ref, date, document type) change
//   independently of overview stats and row management. Keeping it isolated
//   means you can change batch ID format or add e-invoice fields without
//   touching the main controller or overview logic.
//
// USAGE:
//   final invoice = GoldInvoiceLogic();
//   invoice.init();
//   String code = invoice.batchCode;          // GOL-20250511-0001
//   String type = invoice.invoiceTypeLabel;   // "Tax Invoice — GST" or "Standard Estimate"
//   // Always call invoice.dispose() in parent's dispose().
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/logic/dashboard/date_card/date_card_logic.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gold INVOICE LOGIC
// ─────────────────────────────────────────────────────────────────────────────
class GoldInvoiceLogic {
  // ── DATE / TIME STREAM ───────────────────────────────────────
  /// Live date+time stream — used by GoldInvoiceCard for chips display.
  late final DateCardLogic _dateLogic;

  DateCardLogic get dateLogic => _dateLogic;

  // ── BATCH CODE ───────────────────────────────────────────────
  /// System-generated batch ID — immutable for the lifetime of this session.
  /// Format: GOL-YYYYMMDD-XXXX (e.g. GOL-20250511-0042)
  late final String _batchCode;

  String get batchCode => _batchCode;

  // ── SUPPLIER INVOICE CONTROLLER ──────────────────────────────
  /// Editable supplier invoice reference — for B2B / GST traceability.
  /// Operator fills this manually. Stored against the batch on save.
  final TextEditingController supplierInvoiceCtrl = TextEditingController();

  // ── INTERNAL STATE ───────────────────────────────────────────
  bool _initialised = false;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  /// Call once after construction — initialises date stream and locks batch code.
  void init() {
    if (_initialised) return;
    _initialised = true;

    _dateLogic = DateCardLogic();
    _dateLogic.init();

    _batchCode = _generateBatchCode();
  }

  /// Release all resources — always call from parent controller's dispose().
  void dispose() {
    _dateLogic.dispose();
    supplierInvoiceCtrl.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // INVOICE TYPE LABEL
  // ─────────────────────────────────────────────────────────────

  /// Returns the document type label based on GST status.
  /// Reads gstEnabled from outside — pass it as a param to keep this class
  /// stateless about GST (GST state lives in GoldOverviewLogic).
  String invoiceTypeLabel({required bool gstEnabled}) {
    return gstEnabled ? 'Tax Invoice — GST' : 'Standard Estimate';
  }

  /// Short pill label for the invoice card status badge.
  String invoicePillLabel({required bool gstEnabled}) {
    return gstEnabled ? 'GST BILL' : 'ESTIMATE';
  }

  // ─────────────────────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────────────────────

  /// Clears supplier invoice input only.
  /// Batch code is NOT regenerated — one code per session.
  /// Call resetForNewBatch() on the main controller to start fresh.
  void clearSupplierInvoice() {
    supplierInvoiceCtrl.clear();
  }

  // ─────────────────────────────────────────────────────────────
  // GETTERS — DATA FOR SAVE
  // ─────────────────────────────────────────────────────────────

  /// Cleaned supplier invoice reference ready for persistence.
  /// Returns null if blank — callers should store null, not empty string.
  String? get supplierInvoiceRef {
    final val = supplierInvoiceCtrl.text.trim();
    return val.isEmpty ? null : val;
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE — BATCH CODE GENERATION
  // ─────────────────────────────────────────────────────────────

  /// Generates a unique system batch ID for this Gold intake session.
  ///
  /// Format: GOL-YYYYMMDD-XXXX
  ///   GOL   — Gold module prefix (3 chars, fixed)
  ///   YYYYMMDD — Session date
  ///   XXXX  — 4-digit microsecond-derived suffix for uniqueness within a day
  ///
  /// Example: GOL-20250511-0327
  String _generateBatchCode() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix =
        (now.microsecondsSinceEpoch % 9999).toString().padLeft(4, '0');
    return 'GOL-$datePart-$suffix';
  }
}
