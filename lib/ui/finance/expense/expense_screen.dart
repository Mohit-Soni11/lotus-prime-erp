// =============================================================================
// FILE        : expense_screen.dart
// MODULE      : Expense Entry
// LAYER       : UI — Master Screen Assembly
// DESCRIPTION : Top-level shell connecting all Expense Entry components.
//               Follows exact same layout pattern as CashBookScreen.
//
//               LAYOUT:
//               ┌──────────────────────────────────────────────────────────┐
//               │  DARK APP BAR (module title, sort, add expense)          │
//               ├───────────────────┬──────────────────────────────────────┤
//               │  LEFT PANEL 330px │  CENTER PANEL (flex)                 │
//               │  ─────────────── │  ───────────────────────────────────  │
//               │  View Toggle      │  Search Bar + Category Filter Chips  │
//               │  Date Navigator   │  Grouped Expense List                │
//               │  Total Card       │  (swipe left to void, tap = detail)  │
//               │  Stats Row        │                                       │
//               │  Cat. Breakdown   │                                       │
//               │  Mode Breakdown   │                                       │
//               └───────────────────┴──────────────────────────────────────┘
//
//               ✅ Dark AppBar + Cream body (matches all ERP modules)
//               ✅ Left panel fixed 330px | Center panel flex
//               ✅ ListenableBuilder — zero setState in UI layer
//               ✅ Entry dialog — slide-up animated
//               ✅ Swipe-to-void with confirmation dialog
//               ✅ Wired to CashTransactions table — auto-reflected in Cash Book
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

  // ── Show Add Expense Dialog ────────────────────────────────────────────────

  void _showAddExpenseDialog() {
    showDialog(
      context:            context,
      barrierDismissible: true,
      barrierColor:       Colors.black.withOpacity(0.45),
      builder: (_) => ExpenseEntryDialog(ctrl: _ctrl),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: ExpenseColors.bodyBg,

        // ── Dark App Bar ─────────────────────────────────────────────────
        appBar: ExpenseAppBar(
          onBack:       widget.onBack ?? () => Navigator.pop(context),
          ctrl:         _ctrl,
          onAddExpense: _showAddExpenseDialog,
        ),

        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── LEFT PANEL — Summary + Navigator ──────────────────────
              ExpenseLeftPanel(ctrl: _ctrl),

              // ── Vertical Divider ──────────────────────────────────────
              Container(
                width: 1,
                color: ExpenseColors.bodyBorder,
              ),

              // ── CENTER PANEL — Expense List ───────────────────────────
              Expanded(
                child: ExpenseList(
                  ctrl:        _ctrl,
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
