import 'package:flutter/material.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import 'day_book_overview_panel.dart';
import 'day_book_workspace_header.dart';

class DayBookTopSection extends StatelessWidget {
  const DayBookTopSection({
    super.key,
    required this.ctrl,
    required this.summary,
    required this.onReconcile,
    required this.onViewPdf,
    required this.onExportCsv,
    required this.onSharePdf,
  });

  final DayBookController ctrl;
  final DayBookSummary summary;
  final VoidCallback onReconcile;
  final VoidCallback? onViewPdf;
  final VoidCallback? onExportCsv;
  final VoidCallback? onSharePdf;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DayBookWorkspaceHeader(
            ctrl: ctrl,
            summary: summary,
            onReconcile: onReconcile,
            onViewPdf: onViewPdf,
            onExportCsv: onExportCsv,
            onSharePdf: onSharePdf,
          ),
          const SizedBox(height: 14),
          DayBookOverviewPanel(summary: summary),
        ],
      );
}
