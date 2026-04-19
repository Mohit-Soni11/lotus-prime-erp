// =============================================================================
// FILE        : expense_left_panel.dart
// MODULE      : Expense Entry
// LAYER       : UI
// DESCRIPTION : Fixed 330px left panel — Total summary, view-mode toggle,
//               date navigator, category breakdown, payment-mode breakdown.
//               ✅ ListenableBuilder — zero setState in UI layer.
//               ✅ Shimmer loading state.
//               ✅ Matches Cash Book left panel layout exactly.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
//import 'package:intl/intl.dart';

import '../../../logic/finance/expense/expense_controller.dart';
import '../../../models/finance/expense/expense_enums.dart';
//import '../../../models/finance/expense/expense_summary_model.dart';
import '../../../theme/finance/expense/expense_theme.dart';

class ExpenseLeftPanel extends StatelessWidget {
  final ExpenseController ctrl;
  const ExpenseLeftPanel({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        return Container(
          width:  330,
          height: double.infinity,
          color:  ExpenseColors.bodyBg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // 1. View Mode Toggle
                _ViewModeToggle(ctrl: ctrl),
                const SizedBox(height: 12),

                // 2. Date Navigator
                _DateNavigator(ctrl: ctrl),
                const SizedBox(height: 16),

                // 3. Total Expense Card
                ctrl.isLoading
                    ? _shimmerCard(height: 100)
                    : _TotalExpenseCard(ctrl: ctrl),
                const SizedBox(height: 12),

                // 4. Stats Row (Daily Avg + Highest)
                ctrl.isLoading
                    ? _shimmerCard(height: 70)
                    : _StatsRow(ctrl: ctrl),
                const SizedBox(height: 16),

                // 5. Category Breakdown
                if (!ctrl.isLoading &&
                    ctrl.summary.categoryBreakdown.isNotEmpty) ...[
                  _SectionHeader(ExpenseStrings.categoryBreakdown),
                  const SizedBox(height: 8),
                  _CategoryBreakdownList(ctrl: ctrl),
                  const SizedBox(height: 16),
                ],

                // 6. Payment Mode Breakdown
                if (!ctrl.isLoading &&
                    ctrl.summary.paymentBreakdown.isNotEmpty) ...[
                  _SectionHeader(ExpenseStrings.paymentBreakdown),
                  const SizedBox(height: 8),
                  _PaymentBreakdownList(ctrl: ctrl),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerCard({required double height}) {
    return Shimmer.fromColors(
      baseColor:      const Color(0xFFE5E0D8),
      highlightColor: const Color(0xFFF9F6F0),
      child: Container(
        height:     height,
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ── View Mode Toggle ──────────────────────────────────────────────────────────

class _ViewModeToggle extends StatelessWidget {
  final ExpenseController ctrl;
  const _ViewModeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:     40,
      decoration: BoxDecoration(
        color:        ExpenseColors.summaryChipBg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: ExpenseColors.bodyBorder),
      ),
      child: Row(
        children: ExpenseViewMode.values.map((mode) {
          final isActive = ctrl.viewMode == mode;
          final label = switch (mode) {
            ExpenseViewMode.daily   => ExpenseStrings.viewDaily,
            ExpenseViewMode.monthly => ExpenseStrings.viewMonthly,
            ExpenseViewMode.yearly  => ExpenseStrings.viewYearly,
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => ctrl.setViewMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin:   const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive
                      ? ExpenseColors.moduleAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : ExpenseColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Date Navigator ────────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  final ExpenseController ctrl;
  const _DateNavigator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:     44,
      decoration: BoxDecoration(
        color:        ExpenseColors.bodyPanel,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: ExpenseColors.bodyBorder),
      ),
      child: Row(
        children: [
          // Previous
          _NavButton(
            icon:  ExpenseIcons.previous,
            onTap: ctrl.goToPrevious,
          ),

          // Label
          Expanded(
            child: GestureDetector(
              onTap: ctrl.goToToday,
              child: Center(
                child: Text(
                  ctrl.headerLabel,
                  style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      ExpenseColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Next (disabled if at today)
          _NavButton(
            icon:    ExpenseIcons.next,
            onTap:   ctrl.isAtToday ? null : ctrl.goToNext,
            disabled: ctrl.isAtToday,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData     icon;
  final VoidCallback? onTap;
  final bool         disabled;
  const _NavButton({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: double.infinity,
        child: Icon(
          icon,
          size:  18,
          color: disabled
              ? ExpenseColors.textMuted
              : ExpenseColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Total Expense Card ────────────────────────────────────────────────────────

class _TotalExpenseCard extends StatelessWidget {
  final ExpenseController ctrl;
  const _TotalExpenseCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ExpenseColors.bodyPanel,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: ExpenseColors.cardBorderLight),
        boxShadow: [
          BoxShadow(
            color:      ExpenseColors.shadowLight,
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width:  32,
              height: 32,
              decoration: BoxDecoration(
                color:        ExpenseColors.moduleAccentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                ExpenseIcons.expense,
                size:  16,
                color: ExpenseColors.moduleAccent,
              ),
            ),
            const SizedBox(width: 10),
            Text(ExpenseStrings.totalExpenses,
                style: ExpenseStyles.totalLabel),
          ]),
          const SizedBox(height: 12),
          Text(
            s.totalExpenseFormatted,
            style: ExpenseStyles.totalAmount,
          ),
          const SizedBox(height: 6),
          Text(
            '${s.totalCount} ${s.totalCount == 1 ? 'entry' : 'entries'}',
            style: ExpenseStyles.metaLabel,
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ExpenseController ctrl;
  const _StatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: ExpenseStrings.dailyAverage,
            value: s.dailyAverageFormatted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: ExpenseStrings.highestEntry,
            value: s.highestSingleFormatted,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        ExpenseColors.summaryChipBg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: ExpenseColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ExpenseStyles.totalLabel.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: ExpenseStyles.metaValue.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 12,
          decoration: BoxDecoration(
            color:        ExpenseColors.moduleAccent,
            borderRadius: BorderRadius.circular(2),
          )),
      const SizedBox(width: 8),
      Text(title, style: ExpenseStyles.sectionHeader),
    ]);
  }
}

// ── Category Breakdown List ───────────────────────────────────────────────────

class _CategoryBreakdownList extends StatelessWidget {
  final ExpenseController ctrl;
  const _CategoryBreakdownList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        ExpenseColors.bodyPanel,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: ExpenseColors.cardBorderLight),
      ),
      child: Column(
        children: ctrl.summary.categoryBreakdown
            .asMap()
            .entries
            .map((entry) {
          final i    = entry.key;
          final item = entry.value;
          final isLast =
              i == ctrl.summary.categoryBreakdown.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(item.label,
                            style: ExpenseStyles.breakdownLabel),
                      ),
                      Text(item.amountFormatted,
                          style: ExpenseStyles.breakdownAmount),
                      const SizedBox(width: 6),
                      Text('${item.percentage.toStringAsFixed(0)}%',
                          style: ExpenseStyles.breakdownPct),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.percentage / 100,
                        minHeight:       4,
                        backgroundColor: ExpenseColors.summaryChipBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ExpenseColors.moduleAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, color: ExpenseColors.divider,
                    indent: 12, endIndent: 12),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Payment Mode Breakdown ────────────────────────────────────────────────────

class _PaymentBreakdownList extends StatelessWidget {
  final ExpenseController ctrl;
  const _PaymentBreakdownList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        ExpenseColors.bodyPanel,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: ExpenseColors.cardBorderLight),
      ),
      child: Column(
        children: ctrl.summary.paymentBreakdown
            .asMap()
            .entries
            .map((entry) {
          final i    = entry.key;
          final item = entry.value;
          final isLast =
              i == ctrl.summary.paymentBreakdown.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(children: [
                  Expanded(
                    child: Text(item.paymentModeLabel,
                        style: ExpenseStyles.breakdownLabel),
                  ),
                  Text('${item.count}x',
                      style: ExpenseStyles.breakdownPct),
                  const SizedBox(width: 10),
                  Text(item.amountFormatted,
                      style: ExpenseStyles.breakdownAmount),
                ]),
              ),
              if (!isLast)
                const Divider(
                    height: 1, color: ExpenseColors.divider,
                    indent: 12, endIndent: 12),
            ],
          );
        }).toList(),
      ),
    );
  }
}
