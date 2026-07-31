import 'package:flutter/material.dart';

import '../../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../finance/due_collection_entry/due_collection_entry_screen.dart';
import 'pos_customer_history_formatters.dart';

class PosCustomerHistoryCard extends StatelessWidget {
  final PosBillingController ctrl;

  const PosCustomerHistoryCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoadingHistory) {
      return const _HistoryShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryHeader(customerType: 'Loading'),
            SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SalesPosColors.brandGold,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading customer account...',
                  style: TextStyle(
                    color: SalesPosColors.bodyTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final history = ctrl.customerHistory;
    if (history == null) {
      return const _HistoryShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryHeader(customerType: 'New'),
            SizedBox(height: 12),
            _EmptyHistoryNotice(),
          ],
        ),
      );
    }

    final totalBills = history.bills.length;
    final dueBills = history.dues;
    final outstanding = history.outstanding;
    final accountCredit = history.accountCreditBalance;
    final hasDue = outstanding > 0.005;
    final hasCredit = accountCredit > 0.005;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SalesPosColors.customerCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDue
              ? SalesPosColors.danger.withValues(alpha: 0.38)
              : SalesPosColors.brandGold.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryHeader(customerType: history.type),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total Bills',
                  value: '$totalBills',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.access_time_rounded,
                  label: 'Last Visit',
                  value: PosCustomerHistoryFormatters.lastVisit(history.bills),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: hasDue
                      ? Icons.error_outline_rounded
                      : Icons.verified_rounded,
                  label: hasDue ? 'Outstanding' : 'Account',
                  value: hasDue
                      ? PosCustomerHistoryFormatters.amount(outstanding)
                      : 'Settled',
                  valueColor:
                      hasDue ? SalesPosColors.danger : SalesPosColors.success,
                ),
              ),
            ],
          ),
          if (hasCredit) ...[
            const SizedBox(height: 10),
            _StatusStrip(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Customer credit available',
              value: PosCustomerHistoryFormatters.amount(accountCredit),
              color: SalesPosColors.success,
            ),
          ],
          if (hasDue) ...[
            const SizedBox(height: 10),
            _DueSummary(
              customerName: history.name,
              customerId: history.id,
              mobile: history.mobile,
              dueBills: dueBills,
              totalOutstanding: outstanding,
              onReturned: ctrl.refreshSelectedCustomerHistory,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryShell extends StatelessWidget {
  final Widget child;

  const _HistoryShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SalesPosColors.customerCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.24),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final String customerType;

  const _HistoryHeader({required this.customerType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.25),
            ),
          ),
          child: const Icon(
            Icons.manage_history_rounded,
            size: 21,
            color: SalesPosColors.brandGold,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CUSTOMER ACCOUNT',
                style: SalesPosStyles.highVisHeader,
              ),
              const SizedBox(height: 2),
              Text(
                'Purchase history, visits and due status',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.subTitleMuted,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            customerType.toUpperCase(),
            style: const TextStyle(
              color: SalesPosColors.goldHoverDark,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryNotice extends StatelessWidget {
  const _EmptyHistoryNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SalesPosColors.formInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.person_add_alt_1_rounded,
            size: 17,
            color: SalesPosColors.bodyTextMuted,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'First invoice for this customer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SalesPosColors.bodyTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = SalesPosColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.formInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: SalesPosColors.bodyTextMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.bodyTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusStrip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueSummary extends StatelessWidget {
  final int customerId;
  final String customerName;
  final String mobile;
  final List<dynamic> dueBills;
  final double totalOutstanding;
  final Future<void> Function() onReturned;

  const _DueSummary({
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.dueBills,
    required this.totalOutstanding,
    required this.onReturned,
  });

  @override
  Widget build(BuildContext context) {
    final previewBills = dueBills.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: SalesPosColors.danger.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.danger.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: SalesPosColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: SalesPosColors.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outstanding Balance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SalesPosColors.danger,
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueBills.length == 1
                            ? 'Pending against 1 invoice'
                            : 'Pending against ${dueBills.length} invoices',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SalesPosColors.bodyTextMuted,
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  PosCustomerHistoryFormatters.amount(totalOutstanding),
                  style: const TextStyle(
                    color: SalesPosColors.danger,
                    fontSize: SalesPosStyles.fontInput,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (previewBills.isNotEmpty) ...[
            const Divider(height: 1, color: SalesPosColors.bodyBorder),
            ...previewBills.map(
              (due) => _DuePreviewRow(
                billNo: due.billNo,
                date: due.formattedDate,
                amount: due.dueAmount,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                if (dueBills.length > previewBills.length)
                  Text(
                    '+${dueBills.length - previewBills.length} more',
                    style: const TextStyle(
                      color: SalesPosColors.bodyTextMuted,
                      fontSize: SalesPosStyles.fontCaption,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  const Spacer(),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _openDueCollection(context),
                    icon: const Icon(Icons.payments_outlined, size: 14),
                    label: const Text('Collect Due'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SalesPosColors.danger,
                      side: BorderSide(
                        color: SalesPosColors.danger.withValues(alpha: 0.55),
                      ),
                      textStyle: const TextStyle(
                        fontSize: SalesPosStyles.fontCaption,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDueCollection(BuildContext context) async {
    final firstBillNo = dueBills.isEmpty ? null : dueBills.first.billNo;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DueCollectionEntryScreen(
          initialCustomerId: customerId,
          initialCustomerName: customerName,
          initialMobile: mobile,
          initialBillNo: firstBillNo,
        ),
      ),
    );
    await onReturned();
  }
}

class _DuePreviewRow extends StatelessWidget {
  final String billNo;
  final String date;
  final double amount;

  const _DuePreviewRow({
    required this.billNo,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_outlined,
            size: 13,
            color: SalesPosColors.bodyTextMuted,
          ),
          const SizedBox(width: 6),
          Text(
            billNo,
            style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.bodyTextMuted,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            PosCustomerHistoryFormatters.amount(amount),
            style: const TextStyle(
              color: SalesPosColors.danger,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
