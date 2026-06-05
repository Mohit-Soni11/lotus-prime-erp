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

  Future<void> _handlePrint() async {
    final receipts = _ctrl.receipts;
    if (receipts.isEmpty) {
      _showNotice('No receipt history data to print.');
      return;
    }
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            'LOTUS ERP - DUE RECEIPT HISTORY',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Filter: ${_ctrl.dateFilter.label} / ${_ctrl.modeFilter.label}   Sort: ${_ctrl.sort.label}   Generated: ${DueReceiptHistoryController.formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Receipt',
              'Customer',
              'Bill',
              'Mode',
              'Amount',
              'Date',
              'Status',
            ],
            data: receipts
                .map(
                  (receipt) => [
                    receipt.receiptNo,
                    receipt.customerName,
                    receipt.billNo,
                    receipt.paymentMode,
                    DueReceiptHistoryController.formatAmount(receipt.amount),
                    DueReceiptHistoryController.formatDateTime(
                      receipt.receiptDate,
                    ),
                    receipt.statusLabel,
                  ],
                )
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
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
    );
    if (path == null) return;
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(_buildReceiptCsv(receipts));
    _showNotice('Due receipt history exported.');
  }

  String _buildReceiptCsv(List<DueReceiptModel> receipts) {
    final rows = <List<String>>[
      [
        'Receipt No',
        'Receipt Date',
        'Customer',
        'Mobile',
        'Bill No',
        'Mode',
        'Amount',
        'Ledger',
        'Current Due',
        'Status',
      ],
      ...receipts.map(
        (receipt) => [
          receipt.receiptNo,
          DueReceiptHistoryController.formatDateTime(receipt.receiptDate),
          receipt.customerName,
          receipt.mobile,
          receipt.billNo,
          receipt.paymentMode,
          receipt.amount.toStringAsFixed(2),
          receipt.channelLabel,
          receipt.currentDue.toStringAsFixed(2),
          receipt.statusLabel,
        ],
      ),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
        behavior: SnackBarBehavior.floating,
        width: 390,
        backgroundColor: DueReceiptHistoryColors.appBarBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
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
