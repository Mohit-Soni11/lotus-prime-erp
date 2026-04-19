// =============================================================================
// FILE        : bank_book_left_panel.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : UI
// DESCRIPTION : Fixed left panel (330px) — Account selector cards,
//               view-mode toggle, date navigator, summary cards,
//               reconciliation status, cheque summary, category breakdown.
//               ListenableBuilder — zero setState in UI layer.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../logic/finance/bank_book/bank_book_controller.dart';
import '../../../models/finance/bank_book/bank_book_enums.dart';
import '../../../models/finance/bank_book/bank_account_model.dart';
import '../../../models/finance/bank_book/bank_book_summary_model.dart';
import '../../../theme/finance/bank_book/bank_book_theme.dart';

class BankBookLeftPanel extends StatelessWidget {
  final BankBookController ctrl;
  final VoidCallback       onAddAccount;

  const BankBookLeftPanel({
    super.key,
    required this.ctrl,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        return Container(
          width:  330,
          height: double.infinity,
          color:  BankBookColors.bodyBg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // 1. Account Selector
                _AccountSelector(ctrl: ctrl, onAddAccount: onAddAccount),
                const SizedBox(height: 16),

                if (ctrl.selectedAccount != null) ...[

                  // 2. View Mode Toggle
                  _ViewModeToggle(ctrl: ctrl),
                  const SizedBox(height: 12),

                  // 3. Date Navigator
                  _DateNavigator(ctrl: ctrl),
                  const SizedBox(height: 16),

                  // 4. Opening Balance
                  _OpeningBalanceCard(ctrl: ctrl),
                  const SizedBox(height: 12),

                  // 5. Credit / Debit split
                  _CreditDebitRow(ctrl: ctrl),
                  const SizedBox(height: 12),

                  // 6. Closing Balance
                  _ClosingBalanceCard(ctrl: ctrl),
                  const SizedBox(height: 12),

                  // 7. Transaction count pills
                  _CountRow(ctrl: ctrl),
                  const SizedBox(height: 16),

                  // 8. Reconciliation Status
                  _ReconciliationCard(ctrl: ctrl),
                  const SizedBox(height: 12),

                  // 9. Cheque Summary
                  if (ctrl.summary.chequeSummary.totalIssued > 0) ...[
                    _ChequeSummaryCard(ctrl: ctrl),
                    const SizedBox(height: 16),
                  ],

                  // 10. Credit Breakdown
                  if (ctrl.summary.creditBreakdown.isNotEmpty)
                    _BreakdownSection(
                      title:   BankBookStrings.creditBreakdown,
                      items:   ctrl.summary.creditBreakdown,
                      color:   BankBookColors.creditAccent,
                      bgColor: BankBookColors.creditBg,
                    ),

                  if (ctrl.summary.creditBreakdown.isNotEmpty)
                    const SizedBox(height: 12),

                  // 11. Debit Breakdown
                  if (ctrl.summary.debitBreakdown.isNotEmpty)
                    _BreakdownSection(
                      title:   BankBookStrings.debitBreakdown,
                      items:   ctrl.summary.debitBreakdown,
                      color:   BankBookColors.debitAccent,
                      bgColor: BankBookColors.debitBg,
                    ),

                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Account Selector ──────────────────────────────────────────────────────────

class _AccountSelector extends StatelessWidget {
  final BankBookController ctrl;
  final VoidCallback       onAddAccount;
  const _AccountSelector({required this.ctrl, required this.onAddAccount});

  @override
  Widget build(BuildContext context) {
    if (ctrl.accountsLoading) {
      return _shimmerBox(height: 80);
    }

    if (ctrl.accounts.isEmpty) {
      return GestureDetector(
        onTap: onAddAccount,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        BankBookColors.brandGoldLight,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: BankBookColors.brandGold.withOpacity(0.3)),
          ),
          child: Column(children: [
            const Icon(BankBookIcons.addAccount,
                color: BankBookColors.brandGold, size: 28),
            const SizedBox(height: 8),
            Text(BankBookStrings.noAccountsTitle,
                style: BankBookStyles.labelPrimary,
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(BankBookStrings.noAccountsHint,
                style: BankBookStyles.labelMuted,
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ACCOUNTS', style: BankBookStyles.sectionTitle),
            GestureDetector(
              onTap: onAddAccount,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        BankBookColors.brandGoldLight,
                  borderRadius: BorderRadius.circular(6),
                  border:       Border.all(
                      color: BankBookColors.brandGold.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(BankBookIcons.addAccount,
                      size: 12, color: BankBookColors.brandGold),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                    color:      BankBookColors.brandGold,
                  )),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...ctrl.accounts.map((acc) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _AccountCard(
            account:    acc,
            isSelected: ctrl.selectedAccount?.id == acc.id,
            onTap:      () => ctrl.selectAccount(acc),
          ),
        )),
      ],
    );
  }
}

class _AccountCard extends StatefulWidget {
  final BankAccountModel account;
  final bool             isSelected;
  final VoidCallback     onTap;

  const _AccountCard({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final acc    = widget.account;
    final isPos  = acc.currentBalance >= 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor:  SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:  const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? BankBookColors.accountCardSelected
                : (_hovered
                    ? BankBookColors.shellPanel
                    : BankBookColors.accountCardBg),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? BankBookColors.brandGold
                  : BankBookColors.accountCardBorder,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(acc.accountName,
                      style: BankBookStyles.accountName,
                      overflow: TextOverflow.ellipsis),
                ),
                if (acc.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:        BankBookColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: BankBookColors.brandGold.withOpacity(0.3)),
                    ),
                    child: const Text(BankBookStrings.primaryBadge,
                        style: TextStyle(
                          fontSize:   9,
                          fontWeight: FontWeight.w800,
                          color:      BankBookColors.brandGold,
                          letterSpacing: 0.5,
                        )),
                  ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(BankBookIcons.bankAccount,
                    size: 11, color: BankBookColors.shellMuted),
                const SizedBox(width: 4),
                Text(acc.bankName,
                    style: BankBookStyles.accountNumber,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(width: 8),
                Text(acc.accountNumberMasked,
                    style: BankBookStyles.accountNumber),
              ]),
              const SizedBox(height: 10),
              Text(
                acc.currentBalanceFormatted,
                style: BankBookStyles.accountBalance.copyWith(
                  color: isPos
                      ? BankBookColors.brandGold
                      : BankBookColors.debitAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── View Mode Toggle ───────────────────────────────────────────────────────────

class _ViewModeToggle extends StatelessWidget {
  final BankBookController ctrl;
  const _ViewModeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color:        BankBookColors.toggleInactiveBg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: BankBookColors.bodyBorder),
      ),
      child: Row(
        children: BankBookViewMode.values.map((mode) {
          final isActive = ctrl.viewMode == mode;
          final label = switch (mode) {
            BankBookViewMode.daily   => BankBookStrings.viewDaily,
            BankBookViewMode.monthly => BankBookStrings.viewMonthly,
            BankBookViewMode.yearly  => BankBookStrings.viewYearly,
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => ctrl.setViewMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color:        isActive
                      ? BankBookColors.toggleActiveBg
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset:     const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Center(
                  child: Text(label,
                    style: isActive
                        ? BankBookStyles.toggleActive
                        : BankBookStyles.toggleInactive),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Date Navigator ─────────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  final BankBookController ctrl;
  const _DateNavigator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:        BankBookColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: BankBookColors.cardBorderLight),
        boxShadow: [BoxShadow(
          color:      BankBookColors.cardShadow,
          blurRadius: 8,
          offset:     const Offset(0, 2),
        )],
      ),
      child: Row(children: [
        _NavBtn(icon: BankBookIcons.previous, onTap: ctrl.navigatePrevious),
        Expanded(
          child: GestureDetector(
            onTap: ctrl.isToday ? null : ctrl.jumpToToday,
            child: Center(
              child: Text(ctrl.activeDateLabel,
                  style: BankBookStyles.labelPrimary,
                  textAlign: TextAlign.center),
            ),
          ),
        ),
        _NavBtn(
          icon:     BankBookIcons.next,
          onTap:    ctrl.navigateNext,
          disabled: ctrl.isToday &&
              ctrl.viewMode == BankBookViewMode.daily,
        ),
      ]),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final bool         disabled;
  const _NavBtn({required this.icon, required this.onTap, this.disabled = false});

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   widget.disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp:     widget.disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap:       widget.disabled ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width:  44,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _pressed ? BankBookColors.toggleInactiveBg : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft:    Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Icon(widget.icon, size: 18,
          color: widget.disabled
              ? BankBookColors.textMuted
              : BankBookColors.textSecondary),
      ),
    );
  }
}

// ── Opening Balance Card ───────────────────────────────────────────────────────

class _OpeningBalanceCard extends StatelessWidget {
  final BankBookController ctrl;
  const _OpeningBalanceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return _Card(
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color:        BankBookColors.brandGoldLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: BankBookColors.brandGold.withOpacity(0.3)),
          ),
          child: const Icon(BankBookIcons.openingBalance,
              size: 18, color: BankBookColors.brandGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(BankBookStrings.openingBalance,
                  style: BankBookStyles.labelSecondary),
              const SizedBox(height: 2),
              s.isLoading
                  ? _shimmerText(100)
                  : Text(s.openingBalanceStr, style: BankBookStyles.amountSmall),
            ],
          ),
        ),
        // Edit
        GestureDetector(
          onTap: () => _showEditDialog(context),
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color:        BankBookColors.toggleInactiveBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(BankBookIcons.edit,
                size: 14, color: BankBookColors.textSecondary),
          ),
        ),
      ]),
    );
  }

  void _showEditDialog(BuildContext context) {
    final txtCtrl = TextEditingController(
      text: ctrl.summary.openingBalance > 0
          ? ctrl.summary.openingBalance.toStringAsFixed(2)
          : '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BankBookColors.bodyPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(BankBookStrings.editOpeningBalance,
            style: BankBookStyles.labelPrimary),
        content: TextField(
          controller:   txtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style:        BankBookStyles.inputText,
          decoration: InputDecoration(
            hintText:   BankBookStrings.openingBalanceHint,
            prefixText: '₹ ',
            filled:     true,
            fillColor:  BankBookColors.toggleInactiveBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:   const BorderSide(color: BankBookColors.bodyBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BankBookStrings.cancel,
                style: TextStyle(color: BankBookColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BankBookColors.brandGold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final v = double.tryParse(txtCtrl.text.trim()) ?? 0;
              await ctrl.updateOpeningBalance(v);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text(BankBookStrings.openingBalanceSaved)),
                );
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF111827))),
          ),
        ],
      ),
    );
  }
}

// ── Credit / Debit Row ─────────────────────────────────────────────────────────

class _CreditDebitRow extends StatelessWidget {
  final BankBookController ctrl;
  const _CreditDebitRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Row(children: [
      Expanded(child: _StatBlock(
        label:   '↓  Credit',
        value:   s.totalCreditStr,
        count:   s.creditCount,
        color:   BankBookColors.creditAccent,
        bg:      BankBookColors.creditBg,
        border:  BankBookColors.creditBorder,
        loading: s.isLoading,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatBlock(
        label:   '↑  Debit',
        value:   s.totalDebitStr,
        count:   s.debitCount,
        color:   BankBookColors.debitAccent,
        bg:      BankBookColors.debitBg,
        border:  BankBookColors.debitBorder,
        loading: s.isLoading,
      )),
    ]);
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final int    count;
  final Color  color;
  final Color  bg;
  final Color  border;
  final bool   loading;

  const _StatBlock({
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
        color:        bg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
            fontSize:      11,
            fontWeight:    FontWeight.w700,
            color:         color,
            letterSpacing: 0.5,
          )),
          const SizedBox(height: 6),
          loading
              ? _shimmerText(80)
              : Text(value, style: GoogleFonts.inter(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      color)),
          const SizedBox(height: 4),
          Text('$count entries', style: BankBookStyles.labelMuted),
        ],
      ),
    );
  }
}

// ── Closing Balance Card ───────────────────────────────────────────────────────

class _ClosingBalanceCard extends StatelessWidget {
  final BankBookController ctrl;
  const _ClosingBalanceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s   = ctrl.summary;
    final pos = s.isPositive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding:  const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        pos ? BankBookColors.netPositiveBg : BankBookColors.netNegativeBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pos ? BankBookColors.creditBorder : BankBookColors.debitBorder,
          width: 1.5,
        ),
        boxShadow: [BoxShadow(
          color: (pos
              ? BankBookColors.creditAccent
              : BankBookColors.debitAccent).withOpacity(0.12),
          blurRadius: 12,
          offset:     const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              pos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: pos
                  ? BankBookColors.creditAccent
                  : BankBookColors.debitAccent,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(BankBookStrings.closingBalance,
                style: BankBookStyles.labelSecondary),
          ]),
          const SizedBox(height: 8),
          s.isLoading
              ? _shimmerText(140)
              : Text(s.closingBalanceStr,
                  style: BankBookStyles.amountHero.copyWith(
                    color: pos
                        ? BankBookColors.creditText
                        : BankBookColors.debitText,
                  )),
          const SizedBox(height: 6),
          Row(children: [
            Icon(
              pos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size:  12,
              color: pos
                  ? BankBookColors.creditChip
                  : BankBookColors.debitChip,
            ),
            const SizedBox(width: 4),
            Text(
              '${pos ? '+' : '-'} ${s.netFlowStr} net flow',
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color: pos
                    ? BankBookColors.creditChip
                    : BankBookColors.debitChip,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Count Pill Row ─────────────────────────────────────────────────────────────

class _CountRow extends StatelessWidget {
  final BankBookController ctrl;
  const _CountRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Row(children: [
      _Pill('${s.totalTransactions}', 'Total',  BankBookColors.textSecondary),
      const SizedBox(width: 8),
      _Pill('${s.creditCount}',       'Credit', BankBookColors.creditAccent),
      const SizedBox(width: 8),
      _Pill('${s.debitCount}',        'Debit',  BankBookColors.debitAccent),
    ]);
  }
}

class _Pill extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  const _Pill(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w800,
            color:      color,
          )),
          Text(label, style: BankBookStyles.labelMuted),
        ]),
      ),
    );
  }
}

// ── Reconciliation Card ────────────────────────────────────────────────────────

class _ReconciliationCard extends StatelessWidget {
  final BankBookController ctrl;
  const _ReconciliationCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(BankBookStrings.reconciliationStatus.toUpperCase(),
              style: BankBookStyles.sectionTitle),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ReconcilePill(
              value: s.reconciledCount,
              label: BankBookStrings.reconciled,
              color: BankBookColors.reconciledText,
              bg:    BankBookColors.reconciledBg,
            )),
            const SizedBox(width: 8),
            Expanded(child: _ReconcilePill(
              value: s.unreconciledCount,
              label: BankBookStrings.unreconciled,
              color: BankBookColors.pendingText,
              bg:    BankBookColors.pendingBg,
            )),
          ]),
        ],
      ),
    );
  }
}

class _ReconcilePill extends StatelessWidget {
  final int    value;
  final String label;
  final Color  color;
  final Color  bg;
  const _ReconcilePill({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text('$value', style: TextStyle(
          fontSize:   18,
          fontWeight: FontWeight.w800,
          color:      color,
        )),
        Text(label, style: BankBookStyles.labelMuted),
      ]),
    );
  }
}

// ── Cheque Summary Card ────────────────────────────────────────────────────────

class _ChequeSummaryCard extends StatelessWidget {
  final BankBookController ctrl;
  const _ChequeSummaryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final cs = ctrl.summary.chequeSummary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(BankBookIcons.cheque,
                size: 14, color: BankBookColors.chequeAccent),
            const SizedBox(width: 6),
            Text(BankBookStrings.chequeSummary.toUpperCase(),
                style: BankBookStyles.sectionTitle),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _ChequeStatChip(cs.totalIssued,  BankBookStrings.chequeIssued,  BankBookColors.chequeAccent),
            const SizedBox(width: 6),
            _ChequeStatChip(cs.totalCleared, BankBookStrings.chequeCleared, BankBookColors.creditAccent),
            const SizedBox(width: 6),
            _ChequeStatChip(cs.totalBounced, BankBookStrings.chequeBounced, BankBookColors.debitAccent),
          ]),
          if (cs.totalPending > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        BankBookColors.chequeBg,
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: BankBookColors.chequeBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${cs.totalPending} pending',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      BankBookColors.chequeText,
                      )),
                  Text(cs.pendingAmountFormatted,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      BankBookColors.chequeText,
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChequeStatChip extends StatelessWidget {
  final int    value;
  final String label;
  final Color  color;
  const _ChequeStatChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(children: [
          Text('$value', style: TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w800,
            color:      color,
          )),
          Text(label, style: BankBookStyles.labelMuted.copyWith(fontSize: 10)),
        ]),
      ),
    );
  }
}

// ── Breakdown Section ──────────────────────────────────────────────────────────

class _BreakdownSection extends StatelessWidget {
  final String                       title;
  final List<BankCategoryBreakdownItem> items;
  final Color                        color;
  final Color                        bgColor;

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
          Text(title.toUpperCase(), style: BankBookStyles.sectionTitle),
          const SizedBox(height: 12),
          ...items.take(5).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(item.label,
                          style: BankBookStyles.txnSubtitle,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.amountFormatted,
                            style: BankBookStyles.amountSmall
                                .copyWith(color: color)),
                        Text('${item.count} entries',
                            style: BankBookStyles.labelMuted),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:           item.percentage / 100,
                    minHeight:       4,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor:      AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Shared Helpers ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        BankBookColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: BankBookColors.cardBorderLight),
        boxShadow: [BoxShadow(
          color:      BankBookColors.cardShadow,
          blurRadius: 8,
          offset:     const Offset(0, 2),
        )],
      ),
      child: child,
    );
  }
}

Widget _shimmerText(double width) {
  return Shimmer.fromColors(
    baseColor:      const Color(0xFFE8E3D8),
    highlightColor: const Color(0xFFF5F0E8),
    child: Container(
      width:  width,
      height: 16,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

Widget _shimmerBox({double height = 80}) {
  return Shimmer.fromColors(
    baseColor:      const Color(0xFFE8E3D8),
    highlightColor: const Color(0xFFF5F0E8),
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}