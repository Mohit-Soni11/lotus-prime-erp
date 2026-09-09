import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logging/app_logger.dart';
import '../../core/printing/lotus_pdf_print_dispatcher.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../repositories/booking_advance/booking_advance_repository.dart';
import 'booking_invoice_pdf_service.dart';

enum BookingInvoiceGenerationState {
  idle,
  generating,
  ready,
  error,
}

class BookingInvoicePreviewController extends ChangeNotifier {
  BookingInvoicePreviewController({
    this.orderIds = const [],
    this.initialBookings = const [],
    BookingAdvanceRepository? repository,
    BookingInvoicePdfService pdfService = const BookingInvoicePdfService(),
    LotusPdfPrintDispatcher printDispatcher = const LotusPdfPrintDispatcher(),
  })  : _repository = repository ?? BookingAdvanceRepository(),
        _pdfService = pdfService,
        _printDispatcher = printDispatcher;

  final List<int> orderIds;
  final List<EditableBookingAdvance> initialBookings;
  final BookingAdvanceRepository _repository;
  final BookingInvoicePdfService _pdfService;
  final LotusPdfPrintDispatcher _printDispatcher;

  BookingInvoiceGenerationState genState = BookingInvoiceGenerationState.idle;
  List<EditableBookingAdvance> bookings = const [];
  Uint8List? pdfBytes;
  String? errorMessage;
  String shopName = 'Shop Name Not Set';

  PrintFormat selectedFormat = PrintFormat.a4;
  String selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
  int printCopies = 1;
  bool includeDuplicateStamp = false;
  bool usePrinterDriverSettings = true;
  bool includeCustomerAddress = true;
  bool includeTerms = true;
  bool includeRateColumn = true;

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  bool get isReady => genState == BookingInvoiceGenerationState.ready;

  String get bookingNumber {
    if (bookings.isEmpty) return '-';
    if (bookings.length == 1) return bookings.single.order.orderNo;
    return '${bookings.first.order.orderNo} +${bookings.length - 1}';
  }

  String get customerName {
    final name = bookings.firstOrNull?.customer?.name.trim() ?? '';
    return name.isEmpty ? 'Customer' : name;
  }

  int get lineCount => bookings.length;

  PrintTemplateDefinition get selectedTemplate {
    return PrintTemplateRegistry.byId(selectedTemplateId);
  }

  double get totalAdvance {
    return bookings.fold<double>(
      0,
      (sum, booking) =>
          sum +
          booking.advances.fold<double>(
            0,
            (advanceSum, row) => advanceSum + row.amountPaid,
          ),
    );
  }

  BookingInvoicePrintOptions get options {
    return BookingInvoicePrintOptions(
      format: selectedFormat,
      templateId: selectedTemplateId,
      copies: printCopies,
      includeDuplicateStamp: includeDuplicateStamp,
      includeCustomerAddress: includeCustomerAddress,
      includeTerms: includeTerms,
      includeRateColumn: includeRateColumn,
    );
  }

  Future<void> load() async {
    genState = BookingInvoiceGenerationState.generating;
    errorMessage = null;
    notifyListeners();

    try {
      bookings = initialBookings.isNotEmpty
          ? List.unmodifiable(initialBookings)
          : await _repository.fetchPrintableBookings(orderIds);
      if (bookings.isEmpty) {
        throw StateError('Booking invoice data could not be loaded.');
      }
      shopName = await _repository.resolveShopDisplayName();
      await _generatePdf();
      genState = BookingInvoiceGenerationState.ready;
    } catch (error, stackTrace) {
      pdfBytes = null;
      errorMessage = error.toString();
      genState = BookingInvoiceGenerationState.error;
      AppLogger.error(
        'Booking invoice preview generation failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    notifyListeners();
  }

  Future<void> switchFormat(PrintFormat format) async {
    if (selectedFormat == format) return;
    selectedFormat = format;
    await refreshPreview();
  }

  Future<void> switchTemplate(String templateId) async {
    final template = PrintTemplateRegistry.byId(templateId);
    if (!template.supports(PrintTemplateDocumentType.bookingAdvance)) {
      return;
    }
    if (selectedTemplateId == template.id) return;
    selectedTemplateId = template.id;
    await refreshPreview();
  }

  Future<void> updatePrintOptions({
    int? copies,
    bool? duplicate,
    bool? useDriverSettings,
  }) async {
    printCopies = (copies ?? printCopies).clamp(1, 5).toInt();
    includeDuplicateStamp = duplicate ?? includeDuplicateStamp;
    usePrinterDriverSettings = useDriverSettings ?? usePrinterDriverSettings;
    if (printCopies <= 1) {
      includeDuplicateStamp = false;
    }
    await refreshPreview();
  }

  Future<void> updateDocumentOptions({
    bool? customerAddress,
    bool? terms,
    bool? rateColumn,
  }) async {
    includeCustomerAddress = customerAddress ?? includeCustomerAddress;
    includeTerms = terms ?? includeTerms;
    includeRateColumn = rateColumn ?? includeRateColumn;
    await refreshPreview();
  }

  Future<void> refreshPreview() async {
    if (bookings.isEmpty) {
      await load();
      return;
    }
    genState = BookingInvoiceGenerationState.generating;
    errorMessage = null;
    notifyListeners();

    try {
      await _generatePdf();
      genState = BookingInvoiceGenerationState.ready;
    } catch (error, stackTrace) {
      pdfBytes = null;
      errorMessage = error.toString();
      genState = BookingInvoiceGenerationState.error;
      AppLogger.error(
        'Booking invoice preview refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    notifyListeners();
  }

  Future<void> loadSavedBookings(List<int> savedOrderIds) async {
    if (savedOrderIds.isEmpty) {
      throw ArgumentError.value(
        savedOrderIds,
        'savedOrderIds',
        'No saved booking lines to load.',
      );
    }

    genState = BookingInvoiceGenerationState.generating;
    errorMessage = null;
    notifyListeners();

    try {
      bookings = await _repository.fetchPrintableBookings(savedOrderIds);
      if (bookings.isEmpty) {
        throw StateError('Saved booking invoice data could not be loaded.');
      }
      await _generatePdf();
      genState = BookingInvoiceGenerationState.ready;
    } catch (error, stackTrace) {
      pdfBytes = null;
      errorMessage = error.toString();
      genState = BookingInvoiceGenerationState.error;
      AppLogger.error(
        'Saved booking invoice refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> printInvoice(BuildContext context) async {
    final bytes = await _latestBytes();
    if (bytes == null || !context.mounted) return false;

    final result = await _printDispatcher.dispatch(
      context: context,
      bytes: bytes,
      documentName: _pdfBaseName,
      outputFileName: _pdfFileName,
      printerPickerTitle: 'Select Booking Invoice Printer',
      virtualSaveDialogTitle: 'Save Booking Invoice As',
      usePrinterSettings: usePrinterDriverSettings,
    );
    return result.completed;
  }

  Future<bool> shareInvoicePdf() async {
    final bytes = await _latestBytes();
    if (bytes == null) return false;

    final tempDirectory = await Directory.systemTemp.createTemp(
      'lotus_erp_booking_invoice_share_',
    );
    final file =
        File('${tempDirectory.path}${Platform.pathSeparator}$_pdfFileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        title: 'Share Booking Invoice PDF',
        subject: _pdfBaseName,
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: _pdfFileName,
          ),
        ],
        fileNameOverrides: [_pdfFileName],
      ),
    );

    if (result.status != ShareResultStatus.dismissed) return true;
    return Printing.sharePdf(
      bytes: bytes,
      filename: _pdfFileName,
      subject: _pdfBaseName,
    );
  }

  Future<String?> exportInvoicePdf() async {
    final bytes = await _latestBytes();
    if (bytes == null) return null;

    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Booking Invoice PDF',
      fileName: _pdfFileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );
    if (selectedPath == null) return null;

    final path = selectedPath.toLowerCase().endsWith('.pdf')
        ? selectedPath
        : '$selectedPath.pdf';
    final file = File(path);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Uint8List?> _latestBytes() async {
    if (pdfBytes == null || genState != BookingInvoiceGenerationState.ready) {
      await refreshPreview();
    }
    return pdfBytes;
  }

  Future<void> _generatePdf() async {
    pdfBytes = await _pdfService.buildInvoice(
      shopName: shopName,
      bookings: bookings,
      options: options,
    );
  }

  String get _pdfBaseName => 'Booking Invoice $bookingNumber';

  String get _pdfFileName {
    final safeNumber =
        bookingNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return 'booking_invoice_$safeNumber.pdf';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
