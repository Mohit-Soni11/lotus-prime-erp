import 'package:flutter/material.dart';

import '../../../logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import 'due_receipt_history_detail_panel.dart';
import 'due_receipt_history_filter_bar.dart';
import 'due_receipt_history_list.dart';
import 'due_receipt_history_summary_panel.dart';

class DueReceiptHistoryBody extends StatelessWidget {
  const DueReceiptHistoryBody({
    super.key,
    required this.ctrl,
    required this.onPrint,
    required this.onExport,
  });

  final DueReceiptHistoryController ctrl;
  final VoidCallback onPrint;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1100;
        final summary = DueReceiptHistorySummaryPanel(
          stats: ctrl.stats,
          isLoading: ctrl.isLoading,
        );
        final filters = DueReceiptHistoryFilterBar(
          ctrl: ctrl,
          onPrint: onPrint,
          onExport: onExport,
        );

        if (desktop) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: 12),
                filters,
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          flex: 8, child: DueReceiptHistoryList(ctrl: ctrl)),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: DueReceiptHistoryDetailPanel(
                            receipt: ctrl.selectedReceipt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summary,
              const SizedBox(height: 12),
              filters,
              const SizedBox(height: 14),
              SizedBox(height: 430, child: DueReceiptHistoryList(ctrl: ctrl)),
              if (ctrl.selectedReceipt != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: constraints.maxWidth < 500 ? 650 : 520,
                  child: DueReceiptHistoryDetailPanel(
                      receipt: ctrl.selectedReceipt),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
