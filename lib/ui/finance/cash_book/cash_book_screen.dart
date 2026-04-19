// =============================================================================
// FILE        : cash_book_screen.dart
// MODULE      : Accounts / Cash Book
// LAYER       : UI — Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Cash Book components.
//               Follows the exact same pattern as PurchaseEntryScreen
//               and PosMasterSaleScreen.
//
//               LAYOUT:
//               ┌──────────────────────────────────────────────────────────┐
//               │  DARK APP BAR (module title, sync, add entry)            │
//               ├───────────────────┬──────────────────────────────────────┤
//               │  LEFT PANEL 330px │  CENTER PANEL (flex)                 │
//               │  ─────────────── │  ───────────────────────────────────  │
//               │  View Toggle      │  Search Bar + Filter Chips            │
//               │  Date Navigator   │  Grouped Transaction List             │
//               │  Summary Cards    │  (swipe to void, tap for detail)      │
//               │  Breakdown        │                                        │
//               └───────────────────┴──────────────────────────────────────┘
//
//               ✅ Dark AppBar + Cream body (matches POS / Purchase)
//               ✅ Left panel fixed 330px | Right panel flex
//               ✅ ListenableBuilder — zero setState in UI layer
//               ✅ Entry dialog — slide-up animated
//               ✅ Auto-sync on screen open
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import '../../../logic/finance/cash_book/cash_book_controller.dart';
import 'cash_book_app_bar.dart';
import 'cash_book_left_panel.dart';
import 'cash_book_transaction_list.dart';
import 'cash_book_entry_dialog.dart';

class CashBookScreen extends StatefulWidget {
  const CashBookScreen({super.key});

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends State<CashBookScreen> {

  late final CashBookController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CashBookController();

    // Auto-sync today's POS bills on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.syncTodaysBills();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Add Entry ──────────────────────────────────────────────────────────────

  void _showAddEntryDialog() {
    showDialog(
      context:           context,
      barrierDismissible: true,
      barrierColor:       Colors.black.withOpacity(0.45),
      builder: (_) => CashBookEntryDialog(ctrl: _ctrl),
    );
  }

  // ── Sync Bills ─────────────────────────────────────────────────────────────

  Future<void> _onSyncBills() async {
    await _ctrl.syncTodaysBills();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          CashBookStrings.syncSuccess,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CashBookColors.incomeAccent,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin:   const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: CashBookColors.bodyBg,

        // ── Dark App Bar ───────────────────────────────────────────────
        appBar: CashBookAppBar(
          onBack:       () => Navigator.pop(context),
          ctrl:         _ctrl,
          onAddEntry:   _showAddEntryDialog,
          onSyncBills:  _onSyncBills,
        ),

        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── LEFT PANEL — Summary + Navigator ──────────────────────
              CashBookLeftPanel(ctrl: _ctrl),

              // ── Vertical Divider ───────────────────────────────────────
              Container(
                width: 1,
                color: CashBookColors.bodyBorder,
              ),

              // ── CENTER PANEL — Transaction List ────────────────────────
              Expanded(
                child: CashBookTransactionList(
                  ctrl:       _ctrl,
                  onAddEntry: _showAddEntryDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
