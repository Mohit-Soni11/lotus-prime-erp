import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/core/documents/issued_pdf_preview_dialog.dart';
import 'package:lotus_erp/core/documents/issued_pdf_recovery.dart';

import '../application/invoice_center_controller.dart';
import '../application/invoice_center_document_service.dart';
import '../domain/invoice_center_models.dart';
import 'invoice_center_style.dart';
import 'widgets/invoice_center_table.dart';

class InvoiceCenterActions extends ChangeNotifier {
  InvoiceCenterActions({
    required InvoiceCenterController controller,
    required InvoiceCenterDocumentService documents,
  })  : _controller = controller,
        _documents = documents;

  final InvoiceCenterController _controller;
  final InvoiceCenterDocumentService _documents;
  bool exporting = false;
  bool _disposed = false;

  Future<void> viewOriginal(BuildContext context, InvoiceCenterRow row) async {
    final bytes = await _readOriginal(context, row);
    if (bytes == null || !context.mounted) return;
    await showIssuedPdfPreview(
      context: context,
      pdfBytes: bytes,
      title: row.number,
    );
  }

  Future<void> printOriginal(BuildContext context, InvoiceCenterRow row) async {
    final bytes = await _readOriginal(context, row);
    if (bytes == null || !context.mounted) return;
    try {
      await _documents.printOriginal(row, bytes);
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'The original PDF could not be printed.');
    }
  }

  Future<void> moreAction(
    BuildContext context,
    InvoiceCenterRow row,
    InvoiceCenterRowAction action,
  ) async {
    switch (action) {
      case InvoiceCenterRowAction.share:
        final bytes = await _readOriginal(context, row);
        if (bytes == null || !context.mounted) return;
        try {
          await _documents.shareOriginal(row, bytes);
        } catch (_) {
          if (!context.mounted) return;
          _message(context, 'The original PDF could not be shared.');
        }
      case InvoiceCenterRowAction.copyNumber:
        await Clipboard.setData(ClipboardData(text: row.number));
        if (!context.mounted) return;
        _message(context, 'Invoice number copied.');
    }
  }

  Future<Uint8List?> _readOriginal(
    BuildContext context,
    InvoiceCenterRow row,
  ) async {
    try {
      final bytes = await _documents.readOriginal(row);
      if (bytes == null) {
        if (!context.mounted) return null;
        return requestMissingIssuedPdf(
          context: context,
          documentNumber: row.number,
          attachOriginal: (selected) =>
              _documents.attachOriginal(row, selected),
        );
      }
      return bytes;
    } catch (_) {
      if (!context.mounted) return null;
      _message(context, 'The original issued PDF could not be opened.');
      return null;
    }
  }

  Future<void> showAmountFilters(BuildContext context) async {
    final min = TextEditingController(
      text: _controller.minAmount?.toString() ?? '',
    );
    final max = TextEditingController(
      text: _controller.maxAmount?.toString() ?? '',
    );
    try {
      final range = await showDialog<(double?, double?)>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Amount range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: min,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Minimum total (₹)'),
              ),
              TextField(
                controller: max,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Maximum total (₹)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, (null, null)),
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final lower = double.tryParse(min.text.trim());
                final upper = double.tryParse(max.text.trim());
                if ((min.text.trim().isNotEmpty && lower == null) ||
                    (max.text.trim().isNotEmpty && upper == null) ||
                    (lower != null && upper != null && lower > upper)) {
                  _message(dialogContext, 'Enter a valid amount range.');
                  return;
                }
                Navigator.pop(dialogContext, (lower, upper));
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      );
      if (range != null) {
        _controller.setAmountRange(min: range.$1, max: range.$2);
      }
    } finally {
      min.dispose();
      max.dispose();
    }
  }

  Future<void> export(BuildContext context) async {
    if (exporting) return;
    exporting = true;
    if (!_disposed) notifyListeners();
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export invoice list',
        fileName: 'invoice-center-${_controller.tab.name}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path == null) return;
      final rows = await _controller.exportRows();
      final csv = StringBuffer(
        'S. No.,Invoice No.,Date,Customer Name,Mobile,Metal,Type,Total,Paid,Due,Status\r\n',
      );
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        csv.writeln([
          index + 1,
          row.number,
          InvoiceCenterFormat.date(row.issuedAt),
          row.customerName,
          row.mobile,
          row.metals,
          InvoiceCenterFormat.label(row.category),
          row.total.toStringAsFixed(2),
          row.paid.toStringAsFixed(2),
          row.due.toStringAsFixed(2),
          InvoiceCenterFormat.status(row.status),
        ].map(_csvCell).join(','));
      }
      await File(path).writeAsBytes(utf8.encode('\uFEFF${csv.toString()}'));
      if (!context.mounted) return;
      _message(context, '${rows.length} invoices exported.');
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'The invoice list could not be exported.');
    } finally {
      exporting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String _csvCell(Object value) =>
      '"${value.toString().replaceAll('"', '""')}"';

  void _message(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
