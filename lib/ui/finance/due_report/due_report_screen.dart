import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';
import 'due_report_app_bar.dart';
import 'due_report_bill_panel.dart';
import 'due_report_customer_list.dart';
import 'due_report_filter_bar.dart';
import 'due_report_summary_panel.dart';

class DueReportScreen extends StatefulWidget {
  const DueReportScreen({super.key});

  @override
  State<DueReportScreen> createState() => _DueReportScreenState();
}

class _DueReportScreenState extends State<DueReportScreen> {
  late final DueReportController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DueReportController();
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
            backgroundColor: DueReportColors.bodyBg,
            appBar: DueReportAppBar(
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
                    DueReportSummaryPanel(
                      stats: _ctrl.stats,
                      isLoading: _ctrl.isLoading,
                    ),
                    const SizedBox(height: 12),
                    DueReportFilterBar(ctrl: _ctrl),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 1040;
                          if (stacked) {
                            return Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: DueReportCustomerList(ctrl: _ctrl),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  flex: 4,
                                  child: DueReportBillPanel(
                                    group: _ctrl.selectedGroup,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 7,
                                child: DueReportCustomerList(ctrl: _ctrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: DueReportBillPanel(
                                  group: _ctrl.selectedGroup,
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
