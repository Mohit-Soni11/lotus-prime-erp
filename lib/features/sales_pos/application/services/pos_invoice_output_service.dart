import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/services/pos_invoice_file_naming.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

class PosInvoiceOutputService {
  const PosInvoiceOutputService();

  Future<bool> printPdf({
    required BuildContext context,
    required Uint8List bytes,
    required PosInvoiceModel invoice,
  }) {
    return _printPdfWithNamedOutput(
      context: context,
      bytes: bytes,
      invoice: invoice,
    );
  }

  Future<bool> _printPdfWithNamedOutput({
    required BuildContext context,
    required Uint8List bytes,
    required PosInvoiceModel invoice,
  }) async {
    final printer = await Printing.pickPrinter(
      context: context,
      title: 'Select Invoice Printer',
    );
    if (printer == null) return false;

    if (_isVirtualPdfPrinter(printer)) {
      return _saveVirtualPrintOutput(bytes: bytes, invoice: invoice);
    }

    return Printing.directPrintPdf(
      printer: printer,
      name: PosInvoiceFileNaming.pdfBaseName(invoice),
      onLayout: (_) async => bytes,
    );
  }

  bool _isVirtualPdfPrinter(Printer printer) {
    final signature = [
      printer.name,
      printer.model,
      printer.url,
      printer.comment,
    ].whereType<String>().join(' ').toLowerCase();

    return signature.contains('pdf') ||
        signature.contains('xps') ||
        signature.contains('onenote');
  }

  Future<bool> _saveVirtualPrintOutput({
    required Uint8List bytes,
    required PosInvoiceModel invoice,
  }) async {
    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Print Output As',
      fileName: buildExportFileName(invoice),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );

    if (selectedPath == null) return false;

    final exportPath = selectedPath.toLowerCase().endsWith('.pdf')
        ? selectedPath
        : '$selectedPath.pdf';
    final file = File(exportPath);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    await file.writeAsBytes(bytes, flush: true);
    AppLogger.debug('Virtual print PDF saved at: ${file.path}');
    return true;
  }

  Future<void> openWhatsAppInvoice(PosInvoiceModel invoice) async {
    if (invoice.customerMobile.isEmpty) return;

    final uri = buildWhatsAppUri(invoice);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    AppLogger.debug('Could not launch WhatsApp');
  }

  Future<bool> shareInvoicePdf({
    required PosInvoiceModel invoice,
    required Future<Uint8List> Function() buildPdfBytes,
  }) async {
    final bytes = await buildPdfBytes();
    final fileName = buildExportFileName(invoice);
    final pdfFile = await _writeTemporaryShareFile(fileName, bytes);
    final result = await SharePlus.instance.share(
      ShareParams(
        title: 'Share Invoice PDF',
        subject: 'Invoice ${invoice.invoiceNumber}',
        files: [
          XFile(
            pdfFile.path,
            mimeType: 'application/pdf',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
      ),
    );

    if (result.status != ShareResultStatus.dismissed) return true;

    final shared = await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
      subject: 'Invoice ${invoice.invoiceNumber}',
    );

    if (shared) return true;

    await openWhatsAppInvoice(invoice);
    return false;
  }

  Future<File> _writeTemporaryShareFile(
    String fileName,
    Uint8List bytes,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'lotus_erp_invoice_share_',
    );
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Uri buildWhatsAppUri(PosInvoiceModel invoice) {
    final phone = invoice.customerMobile.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.length == 10 ? '91$phone' : phone;
    return Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(buildShareMessage(invoice))}',
    );
  }

  String buildShareMessage(PosInvoiceModel invoice) {
    final customerName =
        invoice.customerName.isNotEmpty ? invoice.customerName : 'Customer';
    return [
      'Dear $customerName,',
      '',
      'Thank you for shopping at *${invoice.shopName}*!',
      '',
      'Here are your invoice details:',
      '*Invoice No:* ${invoice.invoiceNumber}',
      '*Total Amount:* Rs ${invoice.netPayable.toStringAsFixed(2)}',
      '',
      'Visit again!',
    ].join('\n');
  }

  Future<String?> downloadPdf({
    required PosInvoiceModel invoice,
    required Future<Uint8List> Function() buildPdfBytes,
  }) async {
    try {
      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Invoice PDF',
        fileName: buildExportFileName(invoice),
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        lockParentWindow: true,
      );

      if (selectedPath == null) {
        AppLogger.debug('PDF export cancelled by user');
        return null;
      }

      final exportPath = selectedPath.toLowerCase().endsWith('.pdf')
          ? selectedPath
          : '$selectedPath.pdf';
      final file = File(exportPath);
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsBytes(await buildPdfBytes());
      AppLogger.debug('File successfully saved at: ${file.path}');
      return file.path;
    } catch (error) {
      AppLogger.error('Error saving file: $error');
      return null;
    }
  }

  String buildExportFileName(PosInvoiceModel invoice) {
    return PosInvoiceFileNaming.pdfFileName(invoice);
  }
}
