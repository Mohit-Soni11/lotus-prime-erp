import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import '../../../models/finance/due_receipt_history/due_receipt_history_model.dart';
import '../../../theme/finance/due_receipt_history/due_receipt_history_theme.dart';
import 'due_receipt_history_app_bar.dart';
import 'due_receipt_history_detail_panel.dart';
import 'due_receipt_history_filter_bar.dart';
import 'due_receipt_history_list.dart';
import 'due_receipt_history_summary_panel.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class DueReceiptHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DueReceiptHistoryScreen({super.key, this.onBack});

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
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _handlePrint() async {
    final receipts = _ctrl.receipts;
    if (receipts.isEmpty) {
      _showNotice('No receipt history data to print.');
      return;
    }
    final stats = DueReceiptStatsModel.fromReceipts(receipts);
    final generatedAt =
        DueReceiptHistoryController.formatDateTime(DateTime.now());
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          _pdfHeader('Due Receipt History', 'Recovered payments audit trail'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Filter: ${_ctrl.dateFilter.label} / ${_ctrl.modeFilter.label}    Sort: ${_ctrl.sort.label}    Generated: $generatedAt',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pdfMetric(
                  'Total Collected',
                  DueReceiptHistoryController.formatAmount(
                      stats.totalCollected)),
              _pdfMetric('Receipts', stats.receiptCount.toString()),
              _pdfMetric('Customers', stats.customerCount.toString()),
              _pdfMetric(
                  'Today',
                  DueReceiptHistoryController.formatAmount(
                      stats.todayCollected)),
              _pdfMetric('Cash / Bank',
                  '${DueReceiptHistoryController.formatAmount(stats.cashTotal)} / ${DueReceiptHistoryController.formatAmount(stats.bankTotal)}'),
            ],
          ),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('Receipt Ledger'),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Receipt',
              'Customer',
              'Mobile',
              'Bill',
              'Mode',
              'Amount',
              'Ledger',
              'Date',
              'Status',
            ],
            data: receipts
                .map(
                  (receipt) => [
                    receipt.receiptNo,
                    receipt.customerName,
                    receipt.mobile,
                    receipt.billNo,
                    receipt.paymentModeLabel,
                    DueReceiptHistoryController.formatAmount(receipt.amount),
                    receipt.channelLabel,
                    DueReceiptHistoryController.formatDateTime(
                      receipt.receiptDate,
                    ),
                    receipt.statusLabel,
                  ],
                )
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1EDE4),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> _handleExportCsv() async {
    final receipts = _ctrl.receipts;
    if (receipts.isEmpty) {
      _showNotice('No receipt history data to export.');
      return;
    }
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Due Receipt History',
      fileName: _datedFileName('due_receipt_history', 'csv'),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return;
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(_buildReceiptCsv(receipts));
    _showNotice('Due receipt history exported.');
  }

  String _buildReceiptCsv(List<DueReceiptModel> receipts) {
    final stats = DueReceiptStatsModel.fromReceipts(receipts);
    final rows = <List<String>>[
      ['Section', 'Metric', 'Value'],
      ['Summary', 'Total Collected', stats.totalCollected.toStringAsFixed(2)],
      ['Summary', 'Receipts', stats.receiptCount.toString()],
      ['Summary', 'Customers', stats.customerCount.toString()],
      ['Summary', 'Today Collected', stats.todayCollected.toStringAsFixed(2)],
      ['Summary', 'Cash Total', stats.cashTotal.toStringAsFixed(2)],
      ['Summary', 'Bank Total', stats.bankTotal.toStringAsFixed(2)],
      [],
      [
        'Receipt No',
        'Receipt Date',
        'Customer',
        'Mobile',
        'Bill No',
        'Mode',
        'Amount',
        'Ledger',
        'Account',
        'Bill Amount',
        'Total Paid',
        'Current Due',
        'Status',
        'Reference',
        'Narration',
      ],
      ...receipts.map(
        (receipt) => [
          receipt.receiptNo,
          DueReceiptHistoryController.formatDateTime(receipt.receiptDate),
          receipt.customerName,
          receipt.mobile,
          receipt.billNo,
          receipt.paymentModeLabel,
          receipt.amount.toStringAsFixed(2),
          receipt.channelLabel,
          receipt.bankAccountName ?? '',
          receipt.billAmount.toStringAsFixed(2),
          receipt.billPaid.toStringAsFixed(2),
          receipt.currentDue.toStringAsFixed(2),
          receipt.statusLabel,
          receipt.referenceId ?? '',
          receipt.description ?? '',
        ],
      ),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  pw.Widget _pdfHeader(String title, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1F2937)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LOTUS ERP',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey300,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
          pw.Text(
            DueReceiptHistoryController.formatDate(DateTime.now()),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetric(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFBF7ED),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE8D9A7)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _datedFileName(String prefix, String ext) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix}_$stamp.$ext';
  }

  void _showNotice(String message) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
      duration: const Duration(seconds: 2),
    );
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
                    DueReceiptHistoryFilterBar(
                      ctrl: _ctrl,
                      onPrint: _handlePrint,
                      onExport: _handleExportCsv,
                    ),
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
