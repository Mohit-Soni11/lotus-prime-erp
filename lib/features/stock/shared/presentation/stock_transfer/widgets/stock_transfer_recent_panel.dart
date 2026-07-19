import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/stock_transfer_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_shared_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class StockTransferRecentPanel extends StatelessWidget {
  final StockTransferController controller;
  final Future<void> Function(StockTransferRecord transfer) onReceive;
  final Future<void> Function(StockTransferRecord transfer) onCancel;

  const StockTransferRecentPanel({
    super.key,
    required this.controller,
    required this.onReceive,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return TransferPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TransferSectionHeader(
            icon: Icons.route_rounded,
            title: 'Transfer Queue',
            subtitle:
                'Latest transfer slips, receive confirmations and cancelled movement.',
          ),
          const SizedBox(height: 14),
          if (controller.recentTransfers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF7),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: InvColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 36,
                    color: InvColors.textHint,
                  ),
                  const SizedBox(height: 8),
                  Text('No transfer recorded yet',
                      style: InvStyles.sectionTitle),
                  const SizedBox(height: 3),
                  Text(
                    'Create your first transfer slip from selected stock units.',
                    style: InvStyles.cardNote,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...controller.recentTransfers.map(
              (transfer) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentTransferCard(
                  transfer: transfer,
                  onReceive: () => onReceive(transfer),
                  onCancel: () => onCancel(transfer),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentTransferCard extends StatelessWidget {
  final StockTransferRecord transfer;
  final VoidCallback onReceive;
  final VoidCallback onCancel;

  const _RecentTransferCard({
    required this.transfer,
    required this.onReceive,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(transfer.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.local_shipping_outlined,
                    color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.transferNo,
                      style: InvStyles.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transfer.fromLocation} to ${transfer.toLocation}',
                      style: InvStyles.itemSku,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: transfer.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Fact(label: 'Type', value: transfer.transferType),
              _Fact(label: 'Units', value: '${transfer.totalUnits} pcs'),
              _Fact(
                  label: 'Net', value: transferWeight(transfer.totalNetWeight)),
              _Fact(label: 'Created', value: transferDate(transfer.createdAt)),
              _Fact(
                  label: 'Expected',
                  value: transferDate(transfer.expectedDate)),
            ],
          ),
          if (transfer.isInTransit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TransferPrimaryButton(
                    icon: Icons.inventory_rounded,
                    label: 'Receive',
                    onTap: onReceive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TransferPrimaryButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    danger: true,
                    onTap: onCancel,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: InvStyles.itemFieldLabel),
          const SizedBox(height: 2),
          Text(
            value,
            style: InvStyles.itemFieldValue.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _statusLabel(status),
        style: InvStyles.statusBadgeText(color),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case StockTransferStatus.received:
      return InvColors.success;
    case StockTransferStatus.cancelled:
      return InvColors.danger;
    default:
      return InvColors.warning;
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case StockTransferStatus.received:
      return 'RECEIVED';
    case StockTransferStatus.cancelled:
      return 'CANCELLED';
    default:
      return 'IN TRANSIT';
  }
}
