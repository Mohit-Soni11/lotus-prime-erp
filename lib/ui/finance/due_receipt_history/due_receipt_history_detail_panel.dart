import 'package:flutter/material.dart';

import '../../../logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import '../../../models/finance/due_receipt_history/due_receipt_history_model.dart';
import '../../../theme/finance/due_receipt_history/due_receipt_history_theme.dart';

class DueReceiptHistoryDetailPanel extends StatelessWidget {
  final DueReceiptModel? receipt;

  const DueReceiptHistoryDetailPanel({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final item = receipt;
    return Container(
      decoration: DueReceiptHistoryStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: item == null ? const _EmptyDetail() : _DetailBody(receipt: item),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final DueReceiptModel receipt;

  const _DetailBody({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: DueReceiptHistoryColors.tableHeaderBg,
            border: Border(
              bottom: BorderSide(color: DueReceiptHistoryColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DueReceiptHistoryColors.goldSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: DueReceiptHistoryColors.gold
                              .withValues(alpha: 0.35)),
                    ),
                    child: const Icon(DueReceiptHistoryIcons.receipts,
                        color: DueReceiptHistoryColors.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(DueReceiptHistoryStrings.receiptDetails,
                            style: DueReceiptHistoryStyles.sectionTitle),
                        const SizedBox(height: 3),
                        Text(receipt.receiptNo,
                            style: DueReceiptHistoryStyles.rowSub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _StatusPill(receipt: receipt),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                DueReceiptHistoryController.formatAmount(receipt.amount),
                style: DueReceiptHistoryStyles.amountSuccess
                    .copyWith(fontSize: 24),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                '${receipt.receiptKind} via ${receipt.paymentMode.toUpperCase()}',
                style: DueReceiptHistoryStyles.muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CustomerCard(receipt: receipt),
                const SizedBox(height: 12),
                _InfoGrid(receipt: receipt),
                const SizedBox(height: 12),
                _AmountBreakup(receipt: receipt),
                const SizedBox(height: 12),
                _ReferenceBox(receipt: receipt),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final DueReceiptModel receipt;

  const _CustomerCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueReceiptHistoryStyles.flatPanel(
          color: DueReceiptHistoryColors.panelSoft),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DueReceiptHistoryColors.infoSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(DueReceiptHistoryIcons.customers,
                color: DueReceiptHistoryColors.info, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receipt.customerName,
                    style: DueReceiptHistoryStyles.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(DueReceiptHistoryIcons.phone,
                        size: 13, color: DueReceiptHistoryColors.textMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(receipt.mobile,
                          style: DueReceiptHistoryStyles.rowSub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (receipt.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(DueReceiptHistoryIcons.location,
                          size: 13, color: DueReceiptHistoryColors.textMuted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(receipt.address,
                            style: DueReceiptHistoryStyles.rowSub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final DueReceiptModel receipt;

  const _InfoGrid({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final data = [
      _InfoData('Bill No', receipt.billNo, DueReceiptHistoryIcons.bill),
      _InfoData(
          'Receipt Date',
          DueReceiptHistoryController.formatDateTime(receipt.receiptDate),
          DueReceiptHistoryIcons.today),
      _InfoData(
          'Bill Date',
          DueReceiptHistoryController.formatDate(receipt.billDate),
          DueReceiptHistoryIcons.receipts),
      _InfoData(
          'Ledger',
          receipt.channelLabel,
          receipt.isCashLedger
              ? DueReceiptHistoryIcons.cash
              : DueReceiptHistoryIcons.bank),
      _InfoData('Mode', receipt.paymentMode.toUpperCase(),
          _modeIcon(receipt.modeKey)),
      _InfoData('Account', receipt.bankAccountName ?? '-',
          DueReceiptHistoryIcons.bank),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 2 : 1;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: data
              .map((item) =>
                  SizedBox(width: width, child: _InfoTile(data: item)))
              .toList(),
        );
      },
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'CASH':
        return DueReceiptHistoryIcons.cash;
      case 'UPI':
        return DueReceiptHistoryIcons.upi;
      case 'CARD':
        return DueReceiptHistoryIcons.card;
      case 'CHEQUE':
        return DueReceiptHistoryIcons.cheque;
      default:
        return DueReceiptHistoryIcons.bank;
    }
  }
}

class _InfoData {
  final String label;
  final String value;
  final IconData icon;

  const _InfoData(this.label, this.value, this.icon);
}

class _InfoTile extends StatelessWidget {
  final _InfoData data;

  const _InfoTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: DueReceiptHistoryStyles.flatPanel(),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DueReceiptHistoryColors.goldSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(data.icon, size: 16, color: DueReceiptHistoryColors.gold),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: DueReceiptHistoryStyles.rowSub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(data.value,
                    style: DueReceiptHistoryStyles.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountBreakup extends StatelessWidget {
  final DueReceiptModel receipt;

  const _AmountBreakup({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueReceiptHistoryStyles.flatPanel(
          color: DueReceiptHistoryColors.panelSoft),
      child: Column(
        children: [
          _AmountRow(
              label: 'Bill Amount',
              value: receipt.billAmount,
              color: DueReceiptHistoryColors.textPrimary),
          const SizedBox(height: 8),
          _AmountRow(
              label: 'Total Paid',
              value: receipt.billPaid,
              color: DueReceiptHistoryColors.success),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Current Due',
            value: receipt.currentDue,
            color: receipt.currentDue > 0.5
                ? DueReceiptHistoryColors.warning
                : DueReceiptHistoryColors.success,
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AmountRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: DueReceiptHistoryStyles.label)),
        Text(
          DueReceiptHistoryController.formatAmount(value),
          style: DueReceiptHistoryStyles.rowTitle
              .copyWith(color: color, fontSize: 14),
        ),
      ],
    );
  }
}

class _ReferenceBox extends StatelessWidget {
  final DueReceiptModel receipt;

  const _ReferenceBox({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueReceiptHistoryStyles.flatPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ledger Reference', style: DueReceiptHistoryStyles.label),
          const SizedBox(height: 7),
          Text(receipt.referenceId ?? '-',
              style: DueReceiptHistoryStyles.rowTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if ((receipt.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Narration', style: DueReceiptHistoryStyles.label),
            const SizedBox(height: 7),
            Text(receipt.description!, style: DueReceiptHistoryStyles.muted),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final DueReceiptModel receipt;

  const _StatusPill({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final color = receipt.isDueMarked
        ? DueReceiptHistoryColors.gold
        : receipt.hasCurrentDue
            ? DueReceiptHistoryColors.warning
            : DueReceiptHistoryColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        receipt.statusLabel,
        style:
            DueReceiptHistoryStyles.label.copyWith(color: color, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(DueReceiptHistoryIcons.receipts,
              size: 48, color: DueReceiptHistoryColors.textMuted),
          SizedBox(height: 12),
          Text('Select a receipt', style: DueReceiptHistoryStyles.sectionTitle),
          SizedBox(height: 5),
          Text('Receipt details will appear here.',
              style: DueReceiptHistoryStyles.muted),
        ],
      ),
    );
  }
}
