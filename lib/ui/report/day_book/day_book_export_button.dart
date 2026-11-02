import 'package:flutter/material.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';

enum _ExportAction { pdf, csv, share }

class DayBookExportButton extends StatelessWidget {
  const DayBookExportButton({
    super.key,
    required this.onViewPdf,
    required this.onExportCsv,
    required this.onSharePdf,
  });

  final VoidCallback? onViewPdf;
  final VoidCallback? onExportCsv;
  final VoidCallback? onSharePdf;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_ExportAction>(
        tooltip: 'Day Book export options',
        enabled: onViewPdf != null || onExportCsv != null || onSharePdf != null,
        onSelected: (action) {
          switch (action) {
            case _ExportAction.pdf:
              onViewPdf?.call();
            case _ExportAction.csv:
              onExportCsv?.call();
            case _ExportAction.share:
              onSharePdf?.call();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _ExportAction.pdf,
            enabled: onViewPdf != null,
            child: const Text('View PDF'),
          ),
          PopupMenuItem(
            value: _ExportAction.csv,
            enabled: onExportCsv != null,
            child: const Text('Export CSV'),
          ),
          PopupMenuItem(
            value: _ExportAction.share,
            enabled: onSharePdf != null,
            child: const Text('Share PDF'),
          ),
        ],
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: DayBookStyles.softPanel(
            color: DayBookColors.bodySubtle,
            borderColor: DayBookColors.bodyBorder,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.ios_share_rounded,
                size: 18, color: DayBookColors.textPrimary),
            const SizedBox(width: 8),
            Text('Export', style: DayBookStyles.button.copyWith(fontSize: 14)),
            const SizedBox(width: 5),
            const Icon(Icons.expand_more_rounded,
                size: 18, color: DayBookColors.textPrimary),
          ]),
        ),
      );
}
