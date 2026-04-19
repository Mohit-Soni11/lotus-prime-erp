// =============================================================================
// FILE        : bank_book_screen.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : UI — Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Bank Book components.
//               Follows the exact same pattern as CashBookScreen.
//
//               LAYOUT:
//               ┌──────────────────────────────────────────────────────────┐
//               │  DARK APP BAR (module title, sync, add entry, add acct)  │
//               ├───────────────────┬──────────────────────────────────────┤
//               │  LEFT PANEL 330px │  CENTER PANEL (flex)                 │
//               │  ─────────────── │  ───────────────────────────────────  │
//               │  Account Selector │  Search Bar + Filter Chips            │
//               │  View Toggle      │  Grouped Transaction List             │
//               │  Date Navigator   │  (hover for actions, void, reconcile) │
//               │  Summary Cards    │                                        │
//               │  Reconciliation   │                                        │
//               │  Cheque Summary   │                                        │
//               │  Breakdown        │                                        │
//               └───────────────────┴──────────────────────────────────────┘
//
//               ✅ Dark AppBar + Cream body (matches Cash Book / POS)
//               ✅ Left panel fixed 330px | Right panel flex
//               ✅ ListenableBuilder — zero setState in UI layer
//               ✅ Entry dialog — slide-up animated
//               ✅ Add Account dialog — slide-up animated
//               ✅ Auto-sync on screen open
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/finance/bank_book/bank_book_theme.dart';
import '../../../logic/finance/bank_book/bank_book_controller.dart';
import '../../finance/bank_book/bank_book_app_bar.dart';
import '../../finance/bank_book/bank_book_left_panel.dart';
import '../../finance/bank_book/bank_book_transaction_list.dart';
import '../../finance/bank_book/bank_book_entry_dialog.dart';
import '../../finance/bank_book/bank_book_add_account_dialog.dart';

class BankBookScreen extends StatefulWidget {
  const BankBookScreen({super.key});

  @override
  State<BankBookScreen> createState() => _BankBookScreenState();
}

class _BankBookScreenState extends State<BankBookScreen> {

  late final BankBookController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = BankBookController();

    // Auto-sync today's bills on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.syncTodaysBills();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Show Add Entry Dialog ─────────────────────────────────────────────────

  void _showAddEntryDialog() {
    if (_ctrl.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add or select a bank account first'),
          backgroundColor: BankBookColors.chequeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showDialog(
      context:            context,
      barrierDismissible: true,
      barrierColor:       Colors.black.withOpacity(0.45),
      builder: (_) => BankBookEntryDialog(ctrl: _ctrl),
    );
  }

  // ── Show Add Account Dialog ───────────────────────────────────────────────

  void _showAddAccountDialog() {
    showDialog(
      context:            context,
      barrierDismissible: true,
      barrierColor:       Colors.black.withOpacity(0.45),
      builder: (_) => BankBookAddAccountDialog(ctrl: _ctrl),
    );
  }

  // ── Sync Bills ────────────────────────────────────────────────────────────

  Future<void> _onSyncBills() async {
    final count = await _ctrl.syncTodaysBills();
    if (!mounted) return;

    final message = count > 0
        ? '$count bill(s) synced successfully'
        : BankBookStrings.syncSuccess;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: BankBookColors.creditAccent,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin:   const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: BankBookColors.bodyBg,

        // ── Dark App Bar ───────────────────────────────────────────────────
        appBar: BankBookAppBar(
          onBack:        () => Navigator.pop(context),
          ctrl:          _ctrl,
          onAddEntry:    _showAddEntryDialog,
          onSyncBills:   _onSyncBills,
          onAddAccount:  _showAddAccountDialog,
        ),

        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── LEFT PANEL — Accounts + Summary ───────────────────────────
              BankBookLeftPanel(
                ctrl:         _ctrl,
                onAddAccount: _showAddAccountDialog,
              ),

              // ── Vertical Divider ───────────────────────────────────────────
              Container(
                width: 1,
                color: BankBookColors.bodyBorder,
              ),

              // ── CENTER PANEL — Transaction List ────────────────────────────
              Expanded(
                child: BankBookTransactionList(
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