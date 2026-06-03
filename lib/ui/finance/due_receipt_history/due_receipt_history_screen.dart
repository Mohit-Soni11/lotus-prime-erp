import 'package:flutter/material.dart';

import '../../../logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import '../../../theme/finance/due_receipt_history/due_receipt_history_theme.dart';
import 'due_receipt_history_app_bar.dart';
import 'due_receipt_history_detail_panel.dart';
import 'due_receipt_history_filter_bar.dart';
import 'due_receipt_history_list.dart';
import 'due_receipt_history_summary_panel.dart';

class DueReceiptHistoryScreen extends StatefulWidget {
  const DueReceiptHistoryScreen({super.key});

  @override
  State<DueReceiptHistoryScreen> createState() =>
      _DueReceiptHistoryScreenState();
}

class _DueReceiptHistoryScreenState extends State<DueReceiptHistoryScreen> {
  late final DueReceiptHistoryController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DueReceiptHistoryController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: DueReceiptHistoryColors.bodyBg,
            appBar: DueReceiptHistoryAppBar(
              onBack: _handleBack,
              onRefresh: _ctrl.refresh,
              isLoading: _ctrl.isLoading,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DueReceiptHistorySummaryPanel(
                      stats: _ctrl.stats,
                      isLoading: _ctrl.isLoading,
                    ),
                    const SizedBox(height: 12),
                    DueReceiptHistoryFilterBar(ctrl: _ctrl),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 1060;
                          if (stacked) {
                            return Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: DueReceiptHistoryList(ctrl: _ctrl),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  flex: 4,
                                  child: DueReceiptHistoryDetailPanel(
                                    receipt: _ctrl.selectedReceipt,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 8,
                                child: DueReceiptHistoryList(ctrl: _ctrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: DueReceiptHistoryDetailPanel(
                                  receipt: _ctrl.selectedReceipt,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
