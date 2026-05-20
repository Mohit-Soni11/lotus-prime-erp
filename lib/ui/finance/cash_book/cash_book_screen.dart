// =============================================================================
// FILE        : cash_book_screen.dart
// MODULE      : Accounts / Cash Book
// LAYER       : UI â€” Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Cash Book components.
//               Follows the exact same pattern as PurchaseEntryScreen
//               and PosMasterSaleScreen.
//
//               LAYOUT:
//               â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
//               â”‚  DARK APP BAR (module title, sync, add entry)            â”‚
//               â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
//               â”‚  LEFT PANEL 330px â”‚  CENTER PANEL (flex)                 â”‚
//               â”‚  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  â”‚
//               â”‚  View Toggle      â”‚  Search Bar + Filter Chips            â”‚
//               â”‚  Date Navigator   â”‚  Grouped Transaction List             â”‚
//               â”‚  Summary Cards    â”‚  (swipe to void, tap for detail)      â”‚
//               â”‚  Breakdown        â”‚                                        â”‚
//               â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
//
//               âœ… Dark AppBar + Cream body (matches POS / Purchase)
//               âœ… Left panel fixed 330px | Right panel flex
//               âœ… ListenableBuilder â€” zero setState in UI layer
//               âœ… Entry dialog â€” slide-up animated
//               âœ… Auto-sync on screen open
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

  // â”€â”€ Add Entry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => CashBookEntryDialog(ctrl: _ctrl),
    );
  }

  // â”€â”€ Sync Bills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: CashBookColors.bodyBg,

        // â”€â”€ Dark App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        appBar: CashBookAppBar(
          onBack: () => Navigator.pop(context),
          ctrl: _ctrl,
          onAddEntry: _showAddEntryDialog,
          onSyncBills: _onSyncBills,
        ),

        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ LEFT PANEL â€” Summary + Navigator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              CashBookLeftPanel(ctrl: _ctrl),

              // â”€â”€ Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: 1,
                color: CashBookColors.bodyBorder,
              ),

              // â”€â”€ CENTER PANEL â€” Transaction List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: CashBookTransactionList(
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
