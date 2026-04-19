// =============================================================================
// FILE        : expense_list.dart
// MODULE      : Expense Entry
// LAYER       : UI
// DESCRIPTION : Center panel — Search bar, category filter chips,
//               grouped expense list with swipe-to-void and tap for detail.
//               ✅ ListenableBuilder — zero setState.
//               ✅ Animated empty state.
//               ✅ Dismissible (swipe left) → void with reason dialog.
// =============================================================================

import 'package:flutter/material.dart';


import '../../../logic/finance/expense/expense_controller.dart';
import '../../../models/finance/expense/expense_enums.dart';
import '../../../models/finance/expense/expense_model.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/finance/expense/expense_theme.dart';

class ExpenseList extends StatelessWidget {
  final ExpenseController ctrl;
  final VoidCallback      onAddExpense;

  const ExpenseList({
    super.key,
    required this.ctrl,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        return Column(
          children: [

            // ── Search + Filter Bar ──────────────────────────────────────
            _SearchFilterBar(ctrl: ctrl),

            // ── Category Filter Chips ────────────────────────────────────
            _FilterChips(ctrl: ctrl),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: ctrl.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ExpenseColors.moduleAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : ctrl.groups.isEmpty
                      ? _EmptyState(onAddExpense: onAddExpense)
                      : _GroupedList(ctrl: ctrl),
            ),
          ],
        );
      },
    );
  }
}

// ── Search + Filter Bar ───────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final ExpenseController ctrl;
  const _SearchFilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color:   ExpenseColors.bodyBg,
      child: TextField(
        controller: ctrl.searchCtrl,
        style:      ExpenseStyles.inputText.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText:  ExpenseStrings.searchHint,
          hintStyle: ExpenseStyles.labelMuted,
          prefixIcon: const Icon(
              ExpenseIcons.search,
              size: 18, color: ExpenseColors.textMuted),
          suffixIcon: ctrl.searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => ctrl.searchCtrl.clear(),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: ExpenseColors.textMuted),
                )
              : null,
          filled:      true,
          fillColor:   ExpenseColors.searchBg,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: ExpenseColors.searchBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: ExpenseColors.searchBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: ExpenseColors.moduleAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Category Filter Chips ─────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final ExpenseController ctrl;
  const _FilterChips({required this.ctrl});

  // Show only top categories to keep chips manageable
  static const _chips = [
    ExpenseFilter.all,
    ExpenseFilter.shopRent,
    ExpenseFilter.staffSalary,
    ExpenseFilter.electricity,
    ExpenseFilter.maintenance,
    ExpenseFilter.advertising,
    ExpenseFilter.transport,
    ExpenseFilter.other,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color:  ExpenseColors.bodyBg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:         const EdgeInsets.fromLTRB(16, 0, 16, 6),
        itemCount:       _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final f        = _chips[i];
          final isActive = ctrl.filter == f;
          return GestureDetector(
            onTap: () => ctrl.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? ExpenseColors.moduleAccent
                    : ExpenseColors.summaryChipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? ExpenseColors.moduleAccent
                      : ExpenseColors.bodyBorder,
                ),
              ),
              child: Text(
                f.displayLabel,
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : ExpenseColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Grouped List ──────────────────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final ExpenseController ctrl;
  const _GroupedList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding:     const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount:   ctrl.groups.length,
      itemBuilder: (ctx, gi) {
        final group = ctrl.groups[gi];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Group header
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(children: [
                Text(group.headerLabel, style: ExpenseStyles.groupHeader),
                const SizedBox(width: 8),
                Container(
                  width:  4, height: 4,
                  decoration: const BoxDecoration(
                    color: ExpenseColors.textMuted, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('${group.entries.length} entries',
                    style: ExpenseStyles.groupHeader.copyWith(
                      color: ExpenseColors.textMuted)),
                const Spacer(),
                Text(group.groupTotalFormatted,
                    style: ExpenseStyles.groupTotal),
              ]),
            ),

            // Entries
            Container(
              decoration: BoxDecoration(
                color:        ExpenseColors.bodyPanel,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: ExpenseColors.cardBorderLight),
              ),
              child: Column(
                children: group.entries.asMap().entries.map((entry) {
                  final i      = entry.key;
                  final item   = entry.value;
                  final isLast = i == group.entries.length - 1;
                  return Column(
                    children: [
                      _ExpenseRow(item: item, ctrl: ctrl),
                      if (!isLast)
                        const Divider(
                            height: 1, color: ExpenseColors.divider,
                            indent: 56, endIndent: 0),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Single Expense Row ────────────────────────────────────────────────────────

class _ExpenseRow extends StatelessWidget {
  final ExpenseModel      item;
  final ExpenseController ctrl;
  const _ExpenseRow({required this.item, required this.ctrl});

  IconData _categoryIcon(ExpenseCategory cat) => switch (cat) {
    ExpenseCategory.shopRent       => ExpenseIcons.shopRent,
    ExpenseCategory.staffSalary    => ExpenseIcons.staffSalary,
    ExpenseCategory.electricity    => ExpenseIcons.electricity,
    ExpenseCategory.purchasePayment=> ExpenseIcons.purchase,
    ExpenseCategory.girviGiven     => ExpenseIcons.girvi,
    ExpenseCategory.maintenance    => ExpenseIcons.maintenance,
    ExpenseCategory.advertising    => ExpenseIcons.advertising,
    ExpenseCategory.transport      => ExpenseIcons.transport,
    ExpenseCategory.bankCharges    => ExpenseIcons.bankCharges,
    ExpenseCategory.governmentFees => ExpenseIcons.governmentFees,
    ExpenseCategory.miscExpense    => ExpenseIcons.misc,
    ExpenseCategory.otherExpense   => ExpenseIcons.other,
  };

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key:       ValueKey('expense_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment:  Alignment.centerRight,
        padding:    const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color:        ExpenseColors.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(ExpenseIcons.void_,
            color: ExpenseColors.danger, size: 20),
      ),
      confirmDismiss: (_) async {
        return await _showVoidDialog(context);
      },
      onDismissed: (_) {},
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        borderRadius: BorderRadius.circular(12),
        splashColor: ExpenseColors.moduleAccentLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [

              // ── Category Icon ─────────────────────────────────────────
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color:        ExpenseColors.moduleAccentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(item.category),
                  size:  16,
                  color: ExpenseColors.moduleAccentMid,
                ),
              ),
              const SizedBox(width: 12),

              // ── Category + Meta ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.categoryLabel,
                        style: ExpenseStyles.itemCategory),
                    const SizedBox(height: 2),
                    Row(children: [
                      // Payment mode badge
                      _ModeBadge(mode: item.paymentMode),
                      const SizedBox(width: 6),
                      if (item.partyName != null) ...[
                        Text('· ${item.partyName}',
                            style: ExpenseStyles.itemMeta,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ],
                    ]),
                    if (item.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        style: ExpenseStyles.itemMeta.copyWith(
                          color: ExpenseColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Amount + Time ─────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.displayAmount,
                      style: ExpenseStyles.itemAmount),
                  const SizedBox(height: 2),
                  Text(item.timeFormatted,
                      style: ExpenseStyles.expenseId),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showVoidDialog(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ExpenseColors.bodyPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(ExpenseStrings.voidConfirmTitle,
            style: ExpenseStyles.labelPrimary.copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.categoryLabel}  ·  ${item.displayAmount}',
              style: ExpenseStyles.labelSecondary,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              autofocus:  true,
              decoration: InputDecoration(
                hintText:    ExpenseStrings.voidReasonHint,
                hintStyle:   ExpenseStyles.labelMuted,
                filled:      true,
                fillColor:   ExpenseColors.searchBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: ExpenseColors.bodyBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: ExpenseColors.moduleAccent, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ExpenseStrings.cancel,
                style: TextStyle(color: ExpenseColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ExpenseColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              final ok = await ctrl.voidExpense(item.id, reason);
              if (context.mounted) Navigator.pop(context, ok);
            },
            child: Text(ExpenseStrings.voidConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseDetailSheet(item: item),
    );
  }
}

// ── Payment Mode Badge ────────────────────────────────────────────────────────

class _ModeBadge extends StatelessWidget {
  final PaymentMode mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        ExpenseColors.summaryChipBg,
        borderRadius: BorderRadius.circular(4),
        border:       Border.all(color: ExpenseColors.bodyBorder),
      ),
      child: Text(
        mode.displayLabel,
        style: const TextStyle(
          fontSize:   10,
          fontWeight: FontWeight.w700,
          color:      ExpenseColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _ExpenseDetailSheet extends StatelessWidget {
  final ExpenseModel item;
  const _ExpenseDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.all(24),
      decoration:  const BoxDecoration(
        color:        ExpenseColors.bodyPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Handle bar
          Center(
            child: Container(
              width:  40, height: 4,
              decoration: BoxDecoration(
                color:        ExpenseColors.bodyBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              width:  44, height: 44,
              decoration: BoxDecoration(
                color:        ExpenseColors.moduleAccentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(ExpenseIcons.expense,
                  size: 20, color: ExpenseColors.moduleAccent),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.categoryLabel,
                  style: ExpenseStyles.labelPrimary.copyWith(fontSize: 16)),
              Text(item.expenseId,
                  style: ExpenseStyles.expenseId),
            ]),
            const Spacer(),
            Text(item.displayAmount,
                style: ExpenseStyles.totalAmount.copyWith(fontSize: 22)),
          ]),

          const SizedBox(height: 20),
          const Divider(color: ExpenseColors.divider),
          const SizedBox(height: 16),

          // Detail rows
          _DetailRow('Date',         item.dateFormatted),
          _DetailRow('Time',         item.timeFormatted),
          _DetailRow('Payment Mode', item.paymentMode.displayLabel),
          if (item.partyName != null)
            _DetailRow('Vendor',     item.partyName!),
          if (item.description != null)
            _DetailRow('Notes',      item.description!),
          if (item.customLabel != null)
            _DetailRow('Custom Label', item.customLabel!),
          _DetailRow('Entry Type',
              item.isAutoGenerated ? 'Auto-generated' : 'Manual'),

          const SizedBox(height: 24),

          // Close
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: ExpenseColors.bodyBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: ExpenseStyles.labelSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: ExpenseStyles.metaLabel),
          ),
          Expanded(
            child: Text(value, style: ExpenseStyles.metaValue.copyWith(
                fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddExpense;
  const _EmptyState({required this.onAddExpense});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              color:        ExpenseColors.moduleAccentLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              ExpenseIcons.moduleIcon,
              size:  32,
              color: ExpenseColors.moduleAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(ExpenseStrings.noExpenses,
              style: ExpenseStyles.labelPrimary.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            ExpenseStrings.noExpensesHint,
            style: ExpenseStyles.labelMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAddExpense,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color:        ExpenseColors.moduleAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(ExpenseIcons.addExpense,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(ExpenseStrings.addExpense,
                    style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      Colors.white,
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
