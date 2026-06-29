// =============================================================================
// FILE        : cash_book_left_panel.dart
// MODULE      : Accounts / Cash Book
// LAYER       : UI
// DESCRIPTION : Fixed left panel â€” Summary card, view-mode toggle,
//               date navigator, and category breakdown.
//               Uses ListenableBuilder â€” zero setState in UI.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/finance/cash_book/cash_book_summary_model.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class CashBookLeftPanel extends StatelessWidget {
  final CashBookController ctrl;

  const CashBookLeftPanel({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        return Container(
          width: 330,
          height: double.infinity,
          color: CashBookColors.bodyBg,
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

                // 3. Opening Balance card
                _OpeningBalanceCard(ctrl: ctrl),
                const SizedBox(height: 12),

                // 4. Income / Expense split
                _IncomeExpenseRow(ctrl: ctrl),
                const SizedBox(height: 12),

                // 5. Net Balance card
                _NetBalanceCard(ctrl: ctrl),
                const SizedBox(height: 16),

                // 6. Transaction count pills
                _CountRow(ctrl: ctrl),
                const SizedBox(height: 16),

                // 7. Income Breakdown
                if (ctrl.summary.incomeBreakdown.isNotEmpty)
                  _BreakdownSection(
                    title: CashBookStrings.incomeBreakdown,
                    items: ctrl.summary.incomeBreakdown,
                    color: CashBookColors.incomeAccent,
                    bgColor: CashBookColors.incomeBg,
                  ),

                if (ctrl.summary.incomeBreakdown.isNotEmpty)
                  const SizedBox(height: 12),

                // 8. Expense Breakdown
                if (ctrl.summary.expenseBreakdown.isNotEmpty)
                  _BreakdownSection(
                    title: CashBookStrings.expenseBreakdown,
                    items: ctrl.summary.expenseBreakdown,
                    color: CashBookColors.expenseAccent,
                    bgColor: CashBookColors.expenseBg,
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// â”€â”€ View Mode Toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ViewModeToggle extends StatelessWidget {
  final CashBookController ctrl;
  const _ViewModeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: CashBookColors.summaryChipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashBookColors.bodyBorder),
      ),
      child: Row(
        children: CashBookViewMode.values.map((mode) {
          final isActive = ctrl.viewMode == mode;
          final label = switch (mode) {
            CashBookViewMode.daily => CashBookStrings.viewDaily,
            CashBookViewMode.monthly => CashBookStrings.viewMonthly,
            CashBookViewMode.yearly => CashBookStrings.viewYearly,
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => ctrl.setViewMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive
                      ? CashBookColors.toggleActiveBg
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: isActive
                        ? CashBookStyles.toggleActive
                        : CashBookStyles.toggleInactive,
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

// â”€â”€ Date Navigator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DateNavigator extends StatelessWidget {
  final CashBookController ctrl;
  const _DateNavigator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: CashBookColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CashBookColors.cardBorderLight),
        boxShadow: const [
          BoxShadow(
            color: CashBookColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Previous
          _NavBtn(icon: CashBookIcons.previous, onTap: ctrl.navigatePrevious),

          // Label (tap to jump to today)
          Expanded(
            child: GestureDetector(
              onTap: ctrl.isToday ? null : ctrl.jumpToToday,
              child: Center(
                child: Text(
                  ctrl.activeDateLabel,
                  style: CashBookStyles.labelPrimary,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Next
          _NavBtn(
            icon: CashBookIcons.next,
            onTap: ctrl.navigateNext,
            disabled: ctrl.isToday && ctrl.viewMode == CashBookViewMode.daily,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;
  const _NavBtn(
      {required this.icon, required this.onTap, this.disabled = false});

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.disabled ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _pressed ? CashBookColors.summaryChipBg : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: widget.disabled
              ? CashBookColors.textMuted
              : CashBookColors.textSecondary,
        ),
      ),
    );
  }
}

// â”€â”€ Opening Balance Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OpeningBalanceCard extends StatelessWidget {
  final CashBookController ctrl;
  const _OpeningBalanceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final summary = ctrl.summary;

    return _Card(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: CashBookColors.brandGoldLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: CashBookColors.brandGold.withValues(alpha: 0.3)),
            ),
            child: const Icon(CashBookIcons.openingBalance,
                size: 18, color: CashBookColors.brandGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(CashBookStrings.openingBalance,
                    style: CashBookStyles.labelSecondary),
                const SizedBox(height: 2),
                summary.isLoading
                    ? _shimmerText(100)
                    : Text(summary.openingBalanceStr,
                        style: CashBookStyles.amountSmall),
              ],
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: () => _showEditOpeningBalance(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: CashBookColors.summaryChipBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CashBookIcons.edit,
                  size: 14, color: CashBookColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditOpeningBalance(BuildContext context) {
    final txtCtrl = TextEditingController(
      text: ctrl.summary.openingBalance > 0
          ? ctrl.summary.openingBalance.toStringAsFixed(2)
          : '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CashBookColors.bodyPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(CashBookStrings.editOpeningBalance,
            style: CashBookStyles.labelPrimary),
        content: TextField(
          controller: txtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: CashBookStyles.inputText,
          decoration: InputDecoration(
            hintText: CashBookStrings.openingBalanceHint,
            prefixText: 'Rs ',
            filled: true,
            fillColor: CashBookColors.summaryChipBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CashBookColors.bodyBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(CashBookStrings.cancel,
                style: TextStyle(color: CashBookColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CashBookColors.brandGold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final v = double.tryParse(txtCtrl.text.trim()) ?? 0;
              await ctrl.updateOpeningBalance(v);
              if (context.mounted) {
                Navigator.pop(context);
                AppFeedback.show(
                  context,
                  type: AppFeedbackType.success,
                  message: CashBookStrings.openingBalanceSaved,
                );
              }
            },
            child:
                const Text('Save', style: TextStyle(color: Color(0xFF111827))),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Income / Expense Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _IncomeExpenseRow extends StatelessWidget {
  final CashBookController ctrl;
  const _IncomeExpenseRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Row(
      children: [
        Expanded(
            child: _StatBlock(
          icon: CashBookIcons.income,
          label: 'Income',
          value: s.totalIncomeStr,
          count: s.incomeCount,
          color: CashBookColors.incomeAccent,
          bg: CashBookColors.incomeBg,
          border: CashBookColors.incomeBorder,
          loading: s.isLoading,
        )),
        const SizedBox(width: 8),
        Expanded(
            child: _StatBlock(
          icon: CashBookIcons.expense,
          label: 'Expense',
          value: s.totalExpenseStr,
          count: s.expenseCount,
          color: CashBookColors.expenseAccent,
          bg: CashBookColors.expenseBg,
          border: CashBookColors.expenseBorder,
          loading: s.isLoading,
        )),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int count;
  final Color color;
  final Color bg;
  final Color border;
  final bool loading;

  const _StatBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.count,
    required this.color,
    required this.bg,
    required this.border,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          loading
              ? _shimmerText(80)
              : Text(value,
                  style:
                      GoogleFontsWrapper.interBold(fontSize: 14, color: color)),
          const SizedBox(height: 4),
          Text('$count entries', style: CashBookStyles.labelMuted),
        ],
      ),
    );
  }
}

// â”€â”€ Net Balance Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NetBalanceCard extends StatelessWidget {
  final CashBookController ctrl;
  const _NetBalanceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    final pos = s.isPositive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            pos ? CashBookColors.netPositiveBg : CashBookColors.netNegativeBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              pos ? CashBookColors.incomeBorder : CashBookColors.expenseBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (pos
                    ? CashBookColors.incomeAccent
                    : CashBookColors.expenseAccent)
                .withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              pos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: pos
                  ? CashBookColors.incomeAccent
                  : CashBookColors.expenseAccent,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(CashBookStrings.closingBalance,
                style: CashBookStyles.labelSecondary),
          ]),
          const SizedBox(height: 8),
          s.isLoading
              ? _shimmerText(140)
              : Text(
                  s.closingBalanceStr,
                  style: CashBookStyles.amountHero.copyWith(
                    color: pos
                        ? CashBookColors.incomeText
                        : CashBookColors.expenseText,
                  ),
                ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(
              pos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 12,
              color:
                  pos ? CashBookColors.incomeChip : CashBookColors.expenseChip,
            ),
            const SizedBox(width: 4),
            Text(
              '${pos ? '+' : '-'} ${s.netFlowStr} net flow',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: pos
                    ? CashBookColors.incomeChip
                    : CashBookColors.expenseChip,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// â”€â”€ Count Pill Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CountRow extends StatelessWidget {
  final CashBookController ctrl;
  const _CountRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Row(children: [
      _Pill('${s.totalTransactions}', 'Total', CashBookColors.textSecondary),
      const SizedBox(width: 8),
      _Pill('${s.incomeCount}', 'Income', CashBookColors.incomeAccent),
      const SizedBox(width: 8),
      _Pill('${s.expenseCount}', 'Expense', CashBookColors.expenseAccent),
    ]);
  }
}

class _Pill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Pill(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          Text(label, style: CashBookStyles.labelMuted),
        ]),
      ),
    );
  }
}

// â”€â”€ Breakdown Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BreakdownSection extends StatelessWidget {
  final String title;
  final List<CategoryBreakdownItem> items;
  final Color color;
  final Color bgColor;

  const _BreakdownSection({
    required this.title,
    required this.items,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: CashBookStyles.sectionTitle),
          const SizedBox(height: 12),
          ...items.take(5).map((item) => _BreakdownRow(
                item: item,
                color: color,
                bgColor: bgColor,
              )),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final CategoryBreakdownItem item;
  final Color color;
  final Color bgColor;

  const _BreakdownRow({
    required this.item,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(item.label,
                    style: CashBookStyles.txnSubtitle,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(item.amountFormatted,
                  style: CashBookStyles.amountSmall.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percentage / 100,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Shared Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CashBookColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CashBookColors.cardBorderLight),
        boxShadow: const [
          BoxShadow(
            color: CashBookColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }
}

Widget _shimmerText(double width) {
  return Shimmer.fromColors(
    baseColor: const Color(0xFFE8E3D8),
    highlightColor: const Color(0xFFF5F0E8),
    child: Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

// Tiny wrapper so we don't import google_fonts in this file
class GoogleFontsWrapper {
  static TextStyle interBold({required double fontSize, required Color color}) {
    return TextStyle(
        fontSize: fontSize, fontWeight: FontWeight.w700, color: color);
  }
}
