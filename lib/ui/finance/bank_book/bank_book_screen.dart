// =============================================================================
// FILE        : bank_book_screen.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : UI â€” Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Bank Book components.
//               Follows the exact same pattern as CashBookScreen.
//
//               LAYOUT:
//               â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
//               â”‚  DARK APP BAR (module title, sync, add entry, add acct)  â”‚
//               â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
//               â”‚  LEFT PANEL 330px â”‚  CENTER PANEL (flex)                 â”‚
//               â”‚  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  â”‚
//               â”‚  Account Selector â”‚  Search Bar + Filter Chips            â”‚
//               â”‚  View Toggle      â”‚  Grouped Transaction List             â”‚
//               â”‚  Date Navigator   â”‚  (hover for actions, void, reconcile) â”‚
//               â”‚  Summary Cards    â”‚                                        â”‚
//               â”‚  Reconciliation   â”‚                                        â”‚
//               â”‚  Cheque Summary   â”‚                                        â”‚
//               â”‚  Breakdown        â”‚                                        â”‚
//               â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
//
//               âœ… Dark AppBar + Cream body (matches Cash Book / POS)
//               âœ… Left panel fixed 330px | Right panel flex
//               âœ… ListenableBuilder â€” zero setState in UI layer
//               âœ… Entry dialog â€” slide-up animated
//               âœ… Add Account dialog â€” slide-up animated
//               âœ… Auto-sync on screen open
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

  // â”€â”€ Show Add Entry Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showAddEntryDialog() {
    if (_ctrl.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add or select a bank account first'),
          backgroundColor: BankBookColors.chequeAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => BankBookEntryDialog(ctrl: _ctrl),
    );
  }

  // â”€â”€ Show Add Account Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => BankBookAddAccountDialog(ctrl: _ctrl),
    );
  }

  // â”€â”€ Sync Bills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: BankBookColors.bodyBg,

        // â”€â”€ Dark App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        appBar: BankBookAppBar(
          onBack: () => Navigator.pop(context),
          ctrl: _ctrl,
          onAddEntry: _showAddEntryDialog,
          onSyncBills: _onSyncBills,
          onAddAccount: _showAddAccountDialog,
        ),

        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ LEFT PANEL â€” Accounts + Summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              BankBookLeftPanel(
                ctrl: _ctrl,
                onAddAccount: _showAddAccountDialog,
              ),

              // â”€â”€ Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: 1,
                color: BankBookColors.bodyBorder,
              ),

              // â”€â”€ CENTER PANEL â€” Transaction List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: BankBookTransactionList(
                  ctrl: _ctrl,
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
