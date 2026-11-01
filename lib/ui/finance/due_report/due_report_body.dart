import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import 'due_report_bill_panel.dart';
import 'due_report_customer_list.dart';
import 'due_report_empty_state.dart';
import 'due_report_filter_bar.dart';
import 'due_report_summary_panel.dart';

class DueReportBody extends StatelessWidget {
  const DueReportBody({
    super.key,
    required this.ctrl,
    required this.onPrint,
    required this.onExport,
    required this.onCollectDue,
  });

  final DueReportController ctrl;
  final VoidCallback onPrint;
  final VoidCallback onExport;
  final ValueChanged<DueCustomerGroupModel> onCollectDue;

  bool get _showEmpty =>
      !ctrl.isLoading && ctrl.errorMessage == null && ctrl.groups.isEmpty;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scrollable =
              constraints.maxWidth < 1040 || constraints.maxHeight < 760;
          if (scrollable) {
            final panelHeight =
                (constraints.maxHeight * 0.65).clamp(380.0, 560.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryAndFilters(
                    ctrl: ctrl,
                    onPrint: onPrint,
                    onExport: onExport,
                  ),
                  const SizedBox(height: 12),
                  if (_showEmpty)
                    SizedBox(
                      height: panelHeight,
                      child: DueReportEmptyState(
                        hasOutstandingBills: ctrl.allDueBillCount > 0,
                        onClearFilters: ctrl.clearFilters,
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: panelHeight,
                      child: DueReportCustomerList(ctrl: ctrl),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: panelHeight,
                      child: DueReportBillPanel(
                        group: ctrl.selectedGroup,
                        onCollectDue: onCollectDue,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryAndFilters(
                  ctrl: ctrl,
                  onPrint: onPrint,
                  onExport: onExport,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _showEmpty
                      ? DueReportEmptyState(
                          hasOutstandingBills: ctrl.allDueBillCount > 0,
                          onClearFilters: ctrl.clearFilters,
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: DueReportCustomerList(ctrl: ctrl),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: DueReportBillPanel(
                                group: ctrl.selectedGroup,
                                onCollectDue: onCollectDue,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryAndFilters extends StatelessWidget {
  const _SummaryAndFilters({
    required this.ctrl,
    required this.onPrint,
    required this.onExport,
  });

  final DueReportController ctrl;
  final VoidCallback onPrint;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DueReportSummaryPanel(stats: ctrl.stats, isLoading: ctrl.isLoading),
        const SizedBox(height: 12),
        DueReportFilterBar(
          ctrl: ctrl,
          onPrint: onPrint,
          onExport: onExport,
        ),
      ],
    );
  }
}
