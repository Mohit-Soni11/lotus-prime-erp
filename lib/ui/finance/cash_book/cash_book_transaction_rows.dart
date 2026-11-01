part of 'cash_book_transaction_list.dart';

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
    final netSign = group.groupNet >= 0 ? '+' : '-';

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
                  'Net $netSign Rs ${_compact(group.groupNet.abs())}',
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
