import 'package:flutter/material.dart';

import '../../../logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import '../../../models/finance/due_receipt_history/due_receipt_history_model.dart';
import '../../../theme/finance/due_receipt_history/due_receipt_history_theme.dart';

class DueReceiptHistoryList extends StatelessWidget {
  final DueReceiptHistoryController ctrl;

  const DueReceiptHistoryList({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DueReceiptHistoryStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(DueReceiptHistoryIcons.receipts,
                    size: 19, color: DueReceiptHistoryColors.gold),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    DueReceiptHistoryStrings.receiptLedger,
                    style: DueReceiptHistoryStyles.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _CountBadge(
                    count: ctrl.receipts.length, total: ctrl.allReceiptCount),
              ],
            ),
          ),
          const _TableHeader(),
          Expanded(
            child: ctrl.errorMessage != null
                ? _ErrorState(
                    message: ctrl.errorMessage!, onRetry: ctrl.refresh)
                : ctrl.receipts.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        itemCount: ctrl.receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = ctrl.receipts[index];
                          return _ReceiptRow(
                            receipt: receipt,
                            selected: ctrl.selectedReceipt?.id == receipt.id,
                            alternate: index.isOdd,
                            onTap: () => ctrl.selectReceipt(receipt),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final int total;

  const _CountBadge({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DueReceiptHistoryColors.goldSoft,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: DueReceiptHistoryColors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$count of $total',
        style: DueReceiptHistoryStyles.label
            .copyWith(color: DueReceiptHistoryColors.gold),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: DueReceiptHistoryColors.tableHeaderBg,
      child: const Row(
        children: [
          Expanded(flex: 4, child: _HeaderCell('Customer')),
          Expanded(flex: 3, child: _HeaderCell('Receipt')),
          Expanded(flex: 2, child: _HeaderCell('Mode', center: true)),
          Expanded(flex: 2, child: _HeaderCell('Bill', center: true)),
          Expanded(flex: 2, child: _HeaderCell('Amount', center: true)),
          Expanded(flex: 2, child: _HeaderCell('Date', center: true)),
          Expanded(flex: 2, child: _HeaderCell('Status', center: true)),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;

  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: DueReceiptHistoryStyles.tableHeader,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ReceiptRow extends StatefulWidget {
  final DueReceiptModel receipt;
  final bool selected;
  final bool alternate;
  final VoidCallback onTap;

  const _ReceiptRow({
    required this.receipt,
    required this.selected,
    required this.alternate,
    required this.onTap,
  });

  @override
  State<_ReceiptRow> createState() => _ReceiptRowState();
}

class _ReceiptRowState extends State<_ReceiptRow> {
  bool _hover = false;

  void _setHover(bool value) {
    if (!mounted || _hover == value) return;
    setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;
    final bg = widget.selected
        ? DueReceiptHistoryColors.rowSelected
        : _hover
            ? DueReceiptHistoryColors.rowHover
            : widget.alternate
                ? DueReceiptHistoryColors.rowAlt
                : DueReceiptHistoryColors.panelBg;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 68,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(flex: 4, child: _CustomerCell(receipt: receipt)),
              Expanded(flex: 3, child: _ReceiptCell(receipt: receipt)),
              Expanded(
                  flex: 2, child: Center(child: _ModeChip(receipt: receipt))),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(receipt.billNo,
                      style: DueReceiptHistoryStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    DueReceiptHistoryController.formatCompact(receipt.amount),
                    style: DueReceiptHistoryStyles.amountSuccess
                        .copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    DueReceiptHistoryController.formatShortDate(
                        receipt.receiptDate),
                    style: DueReceiptHistoryStyles.rowSub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                  flex: 2,
                  child: Center(child: _StatusBadge(receipt: receipt))),
              const SizedBox(
                width: 28,
                child: Icon(DueReceiptHistoryIcons.arrow,
                    size: 18, color: DueReceiptHistoryColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCell extends StatelessWidget {
  final DueReceiptModel receipt;

  const _CustomerCell({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: receipt.isDueMarked
                ? DueReceiptHistoryColors.goldSoft
                : DueReceiptHistoryColors.infoSoft,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: receipt.isDueMarked
                  ? DueReceiptHistoryColors.gold.withValues(alpha: 0.35)
                  : DueReceiptHistoryColors.info.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            receipt.isDueMarked
                ? DueReceiptHistoryIcons.totalCollected
                : DueReceiptHistoryIcons.customers,
            size: 18,
            color: receipt.isDueMarked
                ? DueReceiptHistoryColors.gold
                : DueReceiptHistoryColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receipt.customerName,
                  style: DueReceiptHistoryStyles.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(receipt.mobile,
                  style: DueReceiptHistoryStyles.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptCell extends StatelessWidget {
  final DueReceiptModel receipt;

  const _ReceiptCell({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(receipt.receiptNo,
            style: DueReceiptHistoryStyles.rowTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(receipt.channelLabel,
            style: DueReceiptHistoryStyles.rowSub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final DueReceiptModel receipt;

  const _ModeChip({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final color = _modeColor(receipt.modeKey);
    return Container(
      constraints: const BoxConstraints(minWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        receipt.paymentMode.toUpperCase(),
        textAlign: TextAlign.center,
        style:
            DueReceiptHistoryStyles.label.copyWith(color: color, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'CASH':
        return DueReceiptHistoryColors.success;
      case 'UPI':
        return DueReceiptHistoryColors.teal;
      case 'CARD':
        return DueReceiptHistoryColors.indigo;
      case 'CHEQUE':
        return DueReceiptHistoryColors.warning;
      default:
        return DueReceiptHistoryColors.info;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final DueReceiptModel receipt;

  const _StatusBadge({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final color = receipt.isDueMarked
        ? DueReceiptHistoryColors.gold
        : receipt.hasCurrentDue
            ? DueReceiptHistoryColors.warning
            : DueReceiptHistoryColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        receipt.statusLabel,
        textAlign: TextAlign.center,
        style:
            DueReceiptHistoryStyles.label.copyWith(color: color, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 42, color: DueReceiptHistoryColors.danger),
          const SizedBox(height: 10),
          Text(message,
              style: DueReceiptHistoryStyles.sectionTitle,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(DueReceiptHistoryIcons.refresh, size: 16),
            label: const Text(DueReceiptHistoryStrings.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(DueReceiptHistoryIcons.empty,
              size: 48, color: DueReceiptHistoryColors.textMuted),
          SizedBox(height: 12),
          Text(DueReceiptHistoryStrings.emptyTitle,
              style: DueReceiptHistoryStyles.sectionTitle),
          SizedBox(height: 5),
          Text(
            DueReceiptHistoryStrings.emptySubtitle,
            style: DueReceiptHistoryStyles.muted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
