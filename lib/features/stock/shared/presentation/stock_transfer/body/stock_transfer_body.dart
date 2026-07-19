import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/stock_transfer_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_available_panel.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_draft_panel.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_header.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_recent_panel.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class StockTransferBody extends StatefulWidget {
  final StockTransferController controller;

  const StockTransferBody({super.key, required this.controller});

  @override
  State<StockTransferBody> createState() => _StockTransferBodyState();
}

class _StockTransferBodyState extends State<StockTransferBody> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchText,
    );
  }

  @override
  void didUpdateWidget(covariant StockTransferBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.controller.searchText) {
      _searchController.text = widget.controller.searchText;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createTransfer(StockTransferForm form) async {
    try {
      final result = await widget.controller.createTransfer(form);
      if (!mounted) return;
      _showMessage(
        'Transfer ${result.transferNo} created for ${result.unitCount} pcs.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error), danger: true);
    }
  }

  Future<void> _receiveTransfer(StockTransferRecord transfer) async {
    final receiver = await _askForText(
      title: 'Receive ${transfer.transferNo}',
      label: 'Received By',
      hint: 'Staff name',
    );
    if (receiver == null) return;
    try {
      await widget.controller.receiveTransfer(
        transfer: transfer,
        receivedBy: receiver,
      );
      if (!mounted) return;
      _showMessage('${transfer.transferNo} received successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error), danger: true);
    }
  }

  Future<void> _cancelTransfer(StockTransferRecord transfer) async {
    final reason = await _askForText(
      title: 'Cancel ${transfer.transferNo}',
      label: 'Cancel Reason',
      hint: 'Reason for cancelling this transfer',
      maxLines: 2,
    );
    if (reason == null) return;
    try {
      await widget.controller.cancelTransfer(
        transfer: transfer,
        reason: reason,
      );
      if (!mounted) return;
      _showMessage('${transfer.transferNo} cancelled and stock restored.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error), danger: true);
    }
  }

  Future<String?> _askForText({
    required String title,
    required String label,
    required String hint,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(context).pop(value.isEmpty ? null : value);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _showMessage(String message, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: danger ? InvColors.danger : InvColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: controller.load,
          color: InvColors.brandGold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StockTransferHeader(summary: controller.summary),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _ErrorBanner(message: controller.errorMessage!),
                ],
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final available = StockTransferAvailablePanel(
                      controller: controller,
                      searchController: _searchController,
                    );
                    final draft = StockTransferDraftPanel(
                      controller: controller,
                      onSubmit: _createTransfer,
                    );
                    if (!wide) {
                      return Column(
                        children: [
                          available,
                          const SizedBox(height: 18),
                          draft,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: available),
                        const SizedBox(width: 18),
                        Expanded(flex: 5, child: draft),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                StockTransferRecentPanel(
                  controller: controller,
                  onReceive: _receiveTransfer,
                  onCancel: _cancelTransfer,
                ),
              ],
            ),
          ),
        ),
        if (controller.isSaving)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.white.withValues(alpha: 0.28),
                child: const Center(
                  child: CircularProgressIndicator(color: InvColors.brandGold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InvColors.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: InvColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: InvStyles.cardSubValue.copyWith(color: InvColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
