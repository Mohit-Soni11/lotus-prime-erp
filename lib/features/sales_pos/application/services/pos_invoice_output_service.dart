import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

class PosInvoiceOutputService {
  const PosInvoiceOutputService();

  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
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

  Uri buildWhatsAppUri(PosInvoiceModel invoice) {
    final phone = invoice.customerMobile.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.length == 10 ? '91$phone' : phone;
    final customerName =
        invoice.customerName.isNotEmpty ? invoice.customerName : 'Customer';
    final message = [
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

    return Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );
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
    final customerName =
        invoice.customerName.isNotEmpty ? invoice.customerName : 'Customer';
    final cleanName = customerName
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final cleanInvoice =
        invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');
    final prefix = cleanName.isEmpty ? 'Customer' : cleanName;

    return '${prefix}_$cleanInvoice.pdf';
  }
}
