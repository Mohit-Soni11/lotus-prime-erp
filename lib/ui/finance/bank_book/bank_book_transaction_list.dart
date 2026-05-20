// =============================================================================
// FILE        : bank_book_transaction_list.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : UI
// DESCRIPTION : Right panel â€” search bar, filter chips, date-grouped
//               transaction list with cheque status badge, reconcile action,
//               void swipe action. ListenableBuilder â€” zero setState.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/finance/bank_book/bank_book_controller.dart';
import '../../../models/finance/bank_book/bank_book_enums.dart';
import '../../../models/finance/bank_book/bank_account_model.dart';
import '../../../theme/finance/bank_book/bank_book_theme.dart';

class BankBookTransactionList extends StatelessWidget {
  final BankBookController ctrl;
  final VoidCallback onAddEntry;

  const BankBookTransactionList({
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
          children: [
            // â”€â”€ Search + Filter Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _SearchFilterBar(ctrl: ctrl),

            // â”€â”€ Transaction List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: ctrl.selectedAccount == null
                  ? _buildNoAccountState()
                  : ctrl.isLoading
                      ? _buildLoadingState()
                      : ctrl.groups.isEmpty
                          ? _buildEmptyState(ctrl)
                          : _buildGroupedList(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupedList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: ctrl.groups.length,
      itemBuilder: (context, index) {
        final group = ctrl.groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date group header
            _GroupHeader(group: group),
            const SizedBox(height: 8),

            // Transaction rows
            ...group.transactions.map((txn) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionCard(txn: txn, ctrl: ctrl),
                )),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 80,
        decoration: BoxDecoration(
          color: BankBookColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BankBookColors.cardBorderLight),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BankBookController ctrl) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BankBookColors.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: BankBookColors.cardBorderLight),
            ),
            child: const Icon(BankBookIcons.moduleIcon,
                size: 40, color: BankBookColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text(BankBookStrings.noTransactions,
              style: BankBookStyles.labelPrimary
                  .copyWith(color: BankBookColors.textSecondary)),
          const SizedBox(height: 8),
          Text(BankBookStrings.noTransactionsHint,
              style: BankBookStyles.labelMuted, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAddEntry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: BankBookColors.brandGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Add First Entry',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccountState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(BankBookIcons.bankAccount,
              size: 48, color: BankBookColors.textMuted),
          const SizedBox(height: 16),
          Text('Select a bank account to view transactions',
              style: BankBookStyles.labelSecondary),
        ],
      ),
    );
  }
}

// â”€â”€ Search + Filter Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SearchFilterBar extends StatelessWidget {
  final BankBookController ctrl;
  const _SearchFilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: BankBookColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: BankBookColors.bodyBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Search field
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: BankBookColors.searchBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BankBookColors.searchBorder),
            ),
            child: TextField(
              controller: ctrl.searchCtrl,
              style: BankBookStyles.labelPrimary,
              decoration: InputDecoration(
                hintText: BankBookStrings.searchHint,
                hintStyle: BankBookStyles.labelMuted,
                prefixIcon: const Icon(BankBookIcons.search,
                    size: 18, color: BankBookColors.searchIcon),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  filter: BankBookFilter.all,
                  ctrl: ctrl,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Credits',
                  filter: BankBookFilter.creditOnly,
                  ctrl: ctrl,
                  color: BankBookColors.creditAccent,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Debits',
                  filter: BankBookFilter.debitOnly,
                  ctrl: ctrl,
                  color: BankBookColors.debitAccent,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cheques',
                  filter: BankBookFilter.chequeOnly,
                  ctrl: ctrl,
                  color: BankBookColors.chequeAccent,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Unreconciled',
                  filter: BankBookFilter.pendingReconciliation,
                  ctrl: ctrl,
                  color: BankBookColors.debitAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final BankBookFilter filter;
  final BankBookController ctrl;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.ctrl,
    this.color = BankBookColors.brandGold,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = ctrl.filter == filter;

    return GestureDetector(
      onTap: () => ctrl.setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : BankBookColors.toggleInactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : BankBookColors.bodyBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? color : BankBookColors.textSecondary,
              )),
        ),
      ),
    );
  }
}

// â”€â”€ Group Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GroupHeader extends StatelessWidget {
  final BankTransactionGroup group;
  const _GroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final isPos = group.groupNet >= 0;
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: 'â‚¹ ', decimalDigits: 2);

    return Row(children: [
      Text(group.dateLabel, style: BankBookStyles.sectionTitle),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isPos ? BankBookColors.creditBg : BankBookColors.debitBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPos
                ? BankBookColors.creditBorder
                : BankBookColors.debitBorder,
          ),
        ),
        child: Text(
          '${isPos ? '+' : '-'} ${fmt.format(group.groupNet.abs())}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPos ? BankBookColors.creditText : BankBookColors.debitText,
          ),
        ),
      ),
    ]);
  }
}

// â”€â”€ Transaction Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TransactionCard extends StatefulWidget {
  final BankTransactionModel txn;
  final BankBookController ctrl;
  const _TransactionCard({required this.txn, required this.ctrl});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final txn = widget.txn;
    final isCredit = txn.isCredit;
    final accentColor =
        isCredit ? BankBookColors.creditAccent : BankBookColors.debitAccent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: BankBookColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? accentColor.withValues(alpha: 0.4)
                : BankBookColors.cardBorderLight,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? accentColor.withValues(alpha: 0.08)
                  : BankBookColors.cardShadow,
              blurRadius: _hovered ? 16 : 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Row 1: Icon + Category + Amount â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direction icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      isCredit ? BankBookIcons.credit : BankBookIcons.debit,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category + party + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(txn.categoryLabel,
                            style: BankBookStyles.txnCategory),
                        if (txn.partyName != null && txn.partyName!.isNotEmpty)
                          Text(txn.partyName!,
                              style: BankBookStyles.txnSubtitle,
                              overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(children: [
                          _ModeChip(txn: txn),
                          const SizedBox(width: 6),
                          Text(txn.timeFormatted,
                              style: BankBookStyles.labelMuted),
                        ]),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(txn.signedAmountFormatted,
                          style: isCredit
                              ? BankBookStyles.txnAmountCredit
                              : BankBookStyles.txnAmountDebit),
                      const SizedBox(height: 4),
                      _StatusBadges(txn: txn),
                    ],
                  ),
                ],
              ),

              // â”€â”€ Row 2: Description + Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (txn.description != null && txn.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(txn.description!,
                    style: BankBookStyles.txnSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],

              // â”€â”€ Row 3: Cheque details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (txn.isCheque) ...[
                const SizedBox(height: 8),
                _ChequeDetailsRow(txn: txn, ctrl: widget.ctrl),
              ],

              // â”€â”€ Row 4: Action buttons (on hover) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (_hovered) ...[
                const SizedBox(height: 10),
                const Divider(color: BankBookColors.cardBorderLight, height: 1),
                const SizedBox(height: 8),
                _ActionRow(txn: txn, ctrl: widget.ctrl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Mode Chip (NEFT / UPI / Cheque etc) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ModeChip extends StatelessWidget {
  final BankTransactionModel txn;
  const _ModeChip({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCheque = txn.isCheque;
    final color = isCheque ? BankBookColors.chequeAccent : BankBookColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(txn.paymentMode.displayLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          )),
    );
  }
}

// â”€â”€ Status Badges (Auto, Reconciled) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatusBadges extends StatelessWidget {
  final BankTransactionModel txn;
  const _StatusBadges({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (txn.isAutoGenerated)
          const _Badge(
            label: BankBookStrings.autoLabel,
            bg: BankBookColors.autoBadgeBg,
            color: BankBookColors.autoBadgeText,
          ),
        if (txn.isAutoGenerated && txn.isReconciled) const SizedBox(width: 4),
        if (txn.isReconciled)
          const _Badge(
            label: BankBookStrings.reconciledLabel,
            bg: BankBookColors.reconciledBg,
            color: BankBookColors.reconciledText,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;
  const _Badge({required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.3,
          )),
    );
  }
}

// â”€â”€ Cheque Details Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ChequeDetailsRow extends StatelessWidget {
  final BankTransactionModel txn;
  final BankBookController ctrl;
  const _ChequeDetailsRow({required this.txn, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final status = txn.chequeStatus;
    final statusColor = switch (status) {
      ChequeStatus.cleared => BankBookColors.statusClearedText,
      ChequeStatus.bounced => BankBookColors.statusBouncedText,
      ChequeStatus.presented => BankBookColors.chequeAccent,
      _ => BankBookColors.statusIssuedText,
    };
    final statusBg = switch (status) {
      ChequeStatus.cleared => BankBookColors.statusClearedBg,
      ChequeStatus.bounced => BankBookColors.statusBouncedBg,
      ChequeStatus.presented => BankBookColors.chequeBg,
      _ => BankBookColors.statusIssuedBg,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BankBookColors.chequeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BankBookColors.chequeBorder),
      ),
      child: Row(children: [
        const Icon(BankBookIcons.cheque,
            size: 14, color: BankBookColors.chequeText),
        const SizedBox(width: 6),
        Text('Cheque #${txn.chequeNumber ?? "-"}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BankBookColors.chequeText,
            )),
        const Spacer(),
        // Status pill
        GestureDetector(
          onTap: () => _showChequeStatusDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(status?.displayLabel ?? 'Issued',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                )),
          ),
        ),
      ]),
    );
  }

  void _showChequeStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BankBookColors.bodyPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(BankBookStrings.updateCheque,
            style: BankBookStyles.labelPrimary),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ChequeStatus.values.map((s) {
            final isSelected = txn.chequeStatus == s;
            return ListTile(
              title: Text(s.displayLabel, style: BankBookStyles.labelPrimary),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: BankBookColors.creditAccent)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await ctrl.updateChequeStatus(txn.id, s);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// â”€â”€ Action Row (shown on hover) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActionRow extends StatelessWidget {
  final BankTransactionModel txn;
  final BankBookController ctrl;
  const _ActionRow({required this.txn, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('TXN: ${txn.txnId}', style: BankBookStyles.labelMuted),
      const Spacer(),

      // Reconcile button (if not yet reconciled & not auto)
      if (!txn.isReconciled)
        _ActionBtn(
          icon: BankBookIcons.reconciled,
          label: 'Reconcile',
          color: BankBookColors.reconciledText,
          onTap: () async {
            await ctrl.markReconciled(txn.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Marked as reconciled')),
              );
            }
          },
        ),

      if (!txn.isReconciled) const SizedBox(width: 8),

      // Void button (only manual entries)
      if (!txn.isAutoGenerated)
        _ActionBtn(
          icon: BankBookIcons.void_,
          label: 'Void',
          color: BankBookColors.debitChip,
          onTap: () => _confirmVoid(context),
        ),
    ]);
  }

  void _confirmVoid(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BankBookColors.bodyPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(BankBookStrings.voidTransaction,
            style: BankBookStyles.labelPrimary),
        content: Text(BankBookStrings.voidConfirm,
            style: BankBookStyles.txnSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(BankBookStrings.voidCancel,
                style: TextStyle(color: BankBookColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BankBookColors.debitAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ctrl.voidTransaction(txn.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(BankBookStrings.voidSuccess)),
                );
              }
            },
            child: const Text(BankBookStrings.voidConfirmBtn,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.3)
                  : BankBookColors.bodyBorder,
            ),
          ),
          child: Row(children: [
            Icon(widget.icon, size: 13, color: widget.color),
            const SizedBox(width: 4),
            Text(widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                )),
          ]),
        ),
      ),
    );
  }
}
