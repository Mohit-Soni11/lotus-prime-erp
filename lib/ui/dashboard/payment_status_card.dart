import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/dashboard/payment_status/payment_status_logic.dart';
import '../../models/dashboard/payment_status_model.dart';
import '../../repositories/dashboard/payment_status_repository.dart';
import '../../theme/dashboard/payment_status/payment_status_theme.dart';
import 'payment_status/collected_flip_card.dart';
import 'payment_status/payment_invoice_row.dart';

class PaymentStatusCard extends StatefulWidget {
  const PaymentStatusCard({
    super.key,
    required this.onOpenCustomer,
    required this.onOpenInvoice,
    this.repository,
  });

  final ValueChanged<int> onOpenCustomer;
  final void Function(int billId, int? customerId) onOpenInvoice;
  final PaymentStatusRepository? repository;

  @override
  State<PaymentStatusCard> createState() => _PaymentStatusCardState();
}

class _PaymentStatusCardState extends State<PaymentStatusCard> {
  late final PaymentStatusLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = PaymentStatusLogic(repository: widget.repository);
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PaymentStatusStyles.cardDecoration,
      padding: PaymentStatusStyles.cardPadding,
      child: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          final data = _logic.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(data.summary.totalBills),
              const SizedBox(height: 16),
              if (_logic.hasError)
                _buildError()
              else if (_logic.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                CollectedFlipCard(summary: data.summary),
                const SizedBox(height: 16),
                _buildTabs(data.activeTab),
                const SizedBox(height: 12),
                _buildInvoices(data),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int billCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.payments_outlined,
                color: PaymentStatusColors.accentGold, size: 20),
            SizedBox(width: 9),
            Flexible(
              child: Text('PAYMENT STATUS',
                  style: PaymentStatusStyles.headerStyle,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '$billCount invoices issued today',
          style: PaymentStatusStyles.dateStyle,
        ),
      ],
    );
  }

  Widget _buildTabs(PaymentFilterTab activeTab) {
    return Row(
      children: [
        for (final tab in PaymentFilterTab.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('payment-tab-${tab.name}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _logic.setTab(tab),
                  child: AnimatedContainer(
                    height: PaymentStatusStyles.tabHeight,
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: tab == activeTab
                          ? _tabColor(tab).withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tab == activeTab
                            ? _tabColor(tab).withValues(alpha: 0.5)
                            : PaymentStatusColors.tabBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tab.name.toUpperCase(),
                      style: PaymentStatusStyles.tabStyle.copyWith(
                        color: tab == activeTab
                            ? _tabColor(tab)
                            : PaymentStatusColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _tabColor(PaymentFilterTab tab) => switch (tab) {
        PaymentFilterTab.all => PaymentStatusColors.accentGold,
        PaymentFilterTab.due => PaymentStatusColors.amountDue,
        PaymentFilterTab.paid => PaymentStatusColors.amountPaid,
      };

  Widget _buildInvoices(PaymentStatusModel data) {
    final bills = data.filteredBills;
    if (bills.isEmpty) {
      final label = switch (data.activeTab) {
        PaymentFilterTab.all => 'No invoices issued today.',
        PaymentFilterTab.due => 'No due invoices issued today.',
        PaymentFilterTab.paid => 'No fully paid invoices issued today.',
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(label, style: PaymentStatusStyles.emptyStyle),
        ),
      );
    }

    final shown = math.min(_logic.visibleCount, bills.length);
    return Column(
      children: [
        for (final bill in bills.take(shown))
          PaymentInvoiceRow(
            key: ValueKey('payment-invoice-${bill.billId}'),
            bill: bill,
            onOpenCustomer: widget.onOpenCustomer,
            onOpenInvoice: () =>
                widget.onOpenInvoice(bill.billId, bill.customerId),
          ),
        if (bills.length > 3)
          TextButton.icon(
            key: const ValueKey('payment-show-more'),
            onPressed: _logic.toggleExpanded,
            icon: Icon(_logic.hasMore
                ? Icons.expand_more_rounded
                : Icons.expand_less_rounded),
            label: Text(_logic.hasMore
                ? 'Show ${math.min(10, bills.length - shown)} more'
                : 'Show less'),
            style: TextButton.styleFrom(
              foregroundColor: PaymentStatusColors.accentGold,
            ),
          ),
      ],
    );
  }

  Widget _buildError() => Center(
        child: Column(
          children: [
            const Text('Payment status could not be loaded.',
                style: PaymentStatusStyles.emptyStyle),
            TextButton(onPressed: _logic.retry, child: const Text('Retry')),
          ],
        ),
      );
}
