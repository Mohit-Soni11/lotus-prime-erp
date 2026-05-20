// =============================================================================
// FILE        : expense_screen.dart
// MODULE      : Expense Entry
// LAYER       : UI â€” Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Expense Entry components.
//               Follows exact same layout pattern as CashBookScreen.
//
//               LAYOUT:
//               â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
//               â”‚  DARK APP BAR (module title, sort, add expense)          â”‚
//               â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
//               â”‚  LEFT PANEL 330px â”‚  CENTER PANEL (flex)                 â”‚
//               â”‚  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  â”‚
//               â”‚  View Toggle      â”‚  Search Bar + Category Filter Chips  â”‚
//               â”‚  Date Navigator   â”‚  Grouped Expense List                â”‚
//               â”‚  Total Card       â”‚  (swipe left to void, tap = detail)  â”‚
//               â”‚  Stats Row        â”‚                                       â”‚
//               â”‚  Cat. Breakdown   â”‚                                       â”‚
//               â”‚  Mode Breakdown   â”‚                                       â”‚
//               â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
//
//               âœ… Dark AppBar + Cream body (matches all ERP modules)
//               âœ… Left panel fixed 330px | Center panel flex
//               âœ… ListenableBuilder â€” zero setState in UI layer
//               âœ… Entry dialog â€” slide-up animated
//               âœ… Swipe-to-void with confirmation dialog
//               âœ… Wired to CashTransactions table â€” auto-reflected in Cash Book
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/finance/expense/expense_theme.dart';
import '../../../logic/finance/expense/expense_controller.dart';
import 'expense_app_bar.dart';
import 'expense_left_panel.dart';
import 'expense_list.dart';
import 'expense_entry_dialog.dart';

class ExpenseScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ExpenseScreen({super.key, this.onBack});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late final ExpenseController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ExpenseController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // â”€â”€ Show Add Expense Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => ExpenseEntryDialog(ctrl: _ctrl),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ExpenseColors.bodyBg,

        // â”€â”€ Dark App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        appBar: ExpenseAppBar(
          onBack: widget.onBack ?? () => Navigator.pop(context),
          ctrl: _ctrl,
          onAddExpense: _showAddExpenseDialog,
        ),

        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ LEFT PANEL â€” Summary + Navigator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              ExpenseLeftPanel(ctrl: _ctrl),

              // â”€â”€ Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: 1,
                color: ExpenseColors.bodyBorder,
              ),

              // â”€â”€ CENTER PANEL â€” Expense List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: ExpenseList(
                  ctrl: _ctrl,
                  onAddExpense: _showAddExpenseDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
