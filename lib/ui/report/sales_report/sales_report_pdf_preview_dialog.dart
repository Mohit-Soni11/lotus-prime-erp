import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../theme/reports/sales_report/sales_report_theme.dart';

class SalesReportPdfPreviewDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String fileName;
  final Future<Uint8List> Function() buildBytes;

  const SalesReportPdfPreviewDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fileName,
    required this.buildBytes,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String fileName,
    required Future<Uint8List> Function() buildBytes,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: SalesReportColors.shellBg.withValues(alpha: 0.72),
      useSafeArea: false,
      builder: (_) => SalesReportPdfPreviewDialog(
        title: title,
        subtitle: subtitle,
        fileName: fileName,
        buildBytes: buildBytes,
      ),
    );
  }

  @override
  State<SalesReportPdfPreviewDialog> createState() =>
      _SalesReportPdfPreviewDialogState();
}

class _SalesReportPdfPreviewDialogState
    extends State<SalesReportPdfPreviewDialog> {
  late final Future<Uint8List> _previewBytes = widget.buildBytes();

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: SalesReportColors.bodyPanel,
      child: Column(
        children: [
          _PreviewHeader(title: widget.title, subtitle: widget.subtitle),
          Expanded(
            child: PdfPreview(
              build: (_) => _previewBytes,
              initialPageFormat: PdfPageFormat.a4.landscape,
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              dpi: 360,
              useActions: false,
              maxPageWidth: 1400,
              pdfFileName: widget.fileName,
              scrollViewDecoration: const BoxDecoration(
                color: SalesReportColors.bodyBg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PreviewHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: SalesReportColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: SalesReportColors.shellBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SalesReportColors.brandGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SalesReportColors.brandGold.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              size: 18,
              color: SalesReportColors.brandGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesReportStyles.appBarTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesReportStyles.appBarSubtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Close preview',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: SalesReportColors.shellTitle,
          ),
        ],
      ),
    );
  }
}
