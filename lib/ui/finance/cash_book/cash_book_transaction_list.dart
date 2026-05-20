// =============================================================================
// FILE        : cash_book_transaction_list.dart
// MODULE      : Accounts / Cash Book
// LAYER       : UI
// DESCRIPTION : Center panel â€” search bar, filter chips, grouped transaction
//               list with animated entry rows and swipe-to-void action.
//               Zero setState â€” ListenableBuilder only.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/finance/cash_book/cash_transaction_model.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

class CashBookTransactionList extends StatelessWidget {
  final CashBookController ctrl;
  final VoidCallback onAddEntry;

  const CashBookTransactionList({
    super.key,
    required this.ctrl,
    required this.onAddEntry,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ Top control bar: search + filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _TopBar(ctrl: ctrl),

            // â”€â”€ List body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: ctrl.isLoading
                  ? _LoadingShimmer()
                  : ctrl.groups.isEmpty
                      ? _EmptyState(onAddEntry: onAddEntry)
                      : _GroupedList(ctrl: ctrl),
            ),
          ],
        );
      },
    );
  }
}

// â”€â”€ Top Bar: Search + Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TopBar extends StatelessWidget {
  final CashBookController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: CashBookColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: CashBookColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: CashBookColors.searchBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CashBookColors.searchBorder),
            ),
            child: TextField(
              controller: ctrl.searchCtrl,
              style: CashBookStyles.labelPrimary,
              decoration: InputDecoration(
                hintText: CashBookStrings.searchHint,
                hintStyle: CashBookStyles.labelMuted,
                prefixIcon: const Icon(CashBookIcons.search,
                    size: 18, color: CashBookColors.searchIcon),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter chips
          Row(
            children: CashBookFilter.values.map((f) {
              final isActive = ctrl.filter == f;
              final label = switch (f) {
                CashBookFilter.all => 'All',
                CashBookFilter.incomeOnly => 'â†“ Income',
                CashBookFilter.expenseOnly => 'â†‘ Expense',
              };
              final activeColor = switch (f) {
                CashBookFilter.incomeOnly => CashBookColors.incomeAccent,
                CashBookFilter.expenseOnly => CashBookColors.expenseAccent,
                _ => CashBookColors.brandGold,
              };

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ctrl.setFilter(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeColor.withValues(alpha: 0.12)
                          : CashBookColors.summaryChipBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? activeColor.withValues(alpha: 0.4)
                            : CashBookColors.bodyBorder,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? activeColor
                            : CashBookColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Grouped Transaction List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GroupedList extends StatelessWidget {
  final CashBookController ctrl;
  const _GroupedList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: ctrl.groups.length,
      itemBuilder: (_, i) => _DateGroup(
        group: ctrl.groups[i],
        ctrl: ctrl,
      ),
    );
  }
}

// â”€â”€ Date Group Header + rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DateGroup extends StatelessWidget {
  final CashTransactionGroup group;
  final CashBookController ctrl;

  const _DateGroup({required this.group, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Text(group.dateLabel, style: CashBookStyles.sectionTitle),
              const Spacer(),
              // Group net mini-badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: group.groupNet >= 0
                      ? CashBookColors.incomeBg
                      : CashBookColors.expenseBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${group.groupNet >= 0 ? '+' : ''}â‚¹ ${_compact(group.groupNet.abs())}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: group.groupNet >= 0
                        ? CashBookColors.incomeChip
                        : CashBookColors.expenseChip,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transaction rows
        ...group.transactions.map((txn) => _TxnRow(
              txn: txn,
              ctrl: ctrl,
            )),

        const SizedBox(height: 8),
        const Divider(color: CashBookColors.divider, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// â”€â”€ Transaction Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TxnRow extends StatefulWidget {
  final CashTransactionModel txn;
  final CashBookController ctrl;

  const _TxnRow({required this.txn, required this.ctrl});

  @override
  State<_TxnRow> createState() => _TxnRowState();
}

class _TxnRowState extends State<_TxnRow> with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );

    // Stagger based on list position (small delay)
    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.txn;
    final isIncome = txn.isIncome;

    return AnimatedBuilder(
      animation: _slideCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: child),
      ),
      child: Dismissible(
        key: Key('txn_${txn.id}'),
        direction: DismissDirection.endToStart,
        background: _voidBackground(),
        confirmDismiss: (_) => _confirmVoid(context),
        onDismissed: (_) => widget.ctrl.voidTransaction(txn.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: CashBookColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CashBookColors.cardBorderLight),
            boxShadow: const [
              BoxShadow(
                color: CashBookColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashColor: CashBookColors.brandGoldLight,
              onTap: () => _showDetail(context, txn),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Direction icon circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isIncome
                            ? CashBookColors.incomeBg
                            : CashBookColors.expenseBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isIncome
                              ? CashBookColors.incomeBorder
                              : CashBookColors.expenseBorder,
                        ),
                      ),
                      child: Icon(
                        isIncome ? CashBookIcons.income : CashBookIcons.expense,
                        size: 16,
                        color: isIncome
                            ? CashBookColors.incomeAccent
                            : CashBookColors.expenseAccent,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Category + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(txn.categoryLabel,
                                  style: CashBookStyles.txnCategory,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (txn.isAutoGenerated) ...[
                              const SizedBox(width: 6),
                              _AutoBadge(),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            txn.partyName ?? txn.description ?? txn.txnId,
                            style: CashBookStyles.txnSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Amount + time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          txn.signedAmountFormatted,
                          style: isIncome
                              ? CashBookStyles.txnAmountIncome
                              : CashBookStyles.txnAmountExpense,
                        ),
                        const SizedBox(height: 2),
                        Text(txn.timeFormatted,
                            style: CashBookStyles.labelMuted),
                      ],
                    ),

                    const SizedBox(width: 8),

                    // Payment mode icon
                    _PaymentModeIcon(mode: txn.paymentMode),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _voidBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CashBookColors.expenseAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CashBookColors.expenseBorder),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CashBookIcons.void_,
              color: CashBookColors.expenseChip, size: 20),
          SizedBox(height: 4),
          Text('Void',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CashBookColors.expenseChip,
              )),
        ],
      ),
    );
  }

  Future<bool?> _confirmVoid(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CashBookColors.bodyPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(CashBookStrings.voidTransaction,
            style: CashBookStyles.labelPrimary),
        content: Text(CashBookStrings.voidConfirm,
            style: CashBookStyles.labelSecondary),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(CashBookStrings.voidCancel,
                style: TextStyle(color: CashBookColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CashBookColors.expenseAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(CashBookStrings.voidConfirmBtn,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, CashTransactionModel txn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CashBookColors.bodyPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TxnDetailSheet(txn: txn),
    );
  }
}

// â”€â”€ Transaction Detail Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TxnDetailSheet extends StatelessWidget {
  final CashTransactionModel txn;
  const _TxnDetailSheet({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.isIncome;
    final color =
        isIncome ? CashBookColors.incomeAccent : CashBookColors.expenseAccent;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
              child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CashBookColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          )),

          const SizedBox(height: 20),

          // Amount hero
          Center(
              child: Text(
            txn.signedAmountFormatted,
            style: CashBookStyles.amountHero.copyWith(color: color),
          )),

          const SizedBox(height: 4),

          Center(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(txn.categoryLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          )),

          const SizedBox(height: 24),

          _DetailRow('TXN ID', txn.txnId),
          _DetailRow(
              'Date & Time', '${txn.dateFormatted}  ${txn.timeFormatted}'),
          _DetailRow('Payment Mode', txn.paymentMode.displayLabel),
          if (txn.partyName != null) _DetailRow('Party', txn.partyName!),
          if (txn.description != null)
            _DetailRow('Description', txn.description!),
          if (txn.referenceId != null)
            _DetailRow('Reference', '${txn.referenceType}: ${txn.referenceId}'),
          _DetailRow('Source',
              txn.isAutoGenerated ? 'Auto-generated' : 'Manual entry'),

          const SizedBox(height: 24),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: CashBookStyles.labelSecondary),
          ),
          Expanded(
            child: Text(value, style: CashBookStyles.labelPrimary),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Auto Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AutoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CashBookColors.autoBadgeBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: CashBookColors.autoBadgeText.withValues(alpha: 0.2)),
      ),
      child: const Row(children: [
        Icon(CashBookIcons.auto, size: 10, color: CashBookColors.autoBadgeText),
        SizedBox(width: 2),
        Text(CashBookStrings.autoLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: CashBookColors.autoBadgeText,
              letterSpacing: 0.5,
            )),
      ]),
    );
  }
}

// â”€â”€ Payment Mode Icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PaymentModeIcon extends StatelessWidget {
  final PaymentMode mode;
  const _PaymentModeIcon({required this.mode});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      PaymentMode.cash => CashBookIcons.cash,
      PaymentMode.upi => CashBookIcons.upi,
      PaymentMode.card => CashBookIcons.card,
      PaymentMode.bank => CashBookIcons.bank,
      PaymentMode.cheque => CashBookIcons.cheque,
    };

    return Tooltip(
      message: mode.displayLabel,
      child: Icon(icon, size: 16, color: CashBookColors.textMuted),
    );
  }
}

// â”€â”€ Loading Shimmer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE8E3D8),
        highlightColor: const Color(0xFFF5F0E8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Empty State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddEntry;
  const _EmptyState({required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: CashBookColors.summaryChipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CashBookColors.bodyBorder),
            ),
            child: const Icon(CashBookIcons.moduleIcon,
                size: 32, color: CashBookColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(CashBookStrings.noTransactions,
              style: CashBookStyles.labelPrimary),
          const SizedBox(height: 6),
          Text(CashBookStrings.noTransactionsHint,
              style: CashBookStyles.labelSecondary,
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAddEntry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: CashBookColors.brandGold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CashBookIcons.addEntry,
                    size: 16, color: Color(0xFF111827)),
                SizedBox(width: 8),
                Text('Add First Entry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
