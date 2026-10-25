part of '../contact_recovery_screen.dart';

extension _AccountDocuments on _ContactRecoveryScreenState {
  Future<void> _viewInvoice(ContactRecoveryCase item) async {
    try {
      final bytes = await _buildInvoicePdfBytes(item);
      if (!mounted) return;
      await _showInvoicePreview(item: item, bytes: bytes);
    } catch (_) {
      _controller.showInlineMessage(
        'Invoice PDF could not be opened for ticket ${item.loan.ticketNo}.',
      );
    }
  }

  Future<void> _downloadInvoice(ContactRecoveryCase item) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Invoice PDF',
        fileName: 'girvi_invoice_${_safeFileToken(item.loan.ticketNo)}.pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        lockParentWindow: true,
      );
      if (outputPath == null) return;

      final normalizedPath = outputPath.toLowerCase().endsWith('.pdf')
          ? outputPath
          : '$outputPath.pdf';
      final bytes = await _buildInvoicePdfBytes(item);
      await File(normalizedPath).writeAsBytes(bytes, flush: true);
      _controller.showInlineMessage(
        'Invoice PDF saved for ticket ${item.loan.ticketNo}.',
      );
    } catch (_) {
      _controller.showInlineMessage(
        'Invoice PDF could not be saved for ticket ${item.loan.ticketNo}.',
      );
    }
  }

  Future<Uint8List> _buildInvoicePdfBytes(ContactRecoveryCase item) async {
    if (item.loan.invoiceGenerated) {
      final savedBytes = await const GirviInvoiceDocumentStore().readInvoice(
        loanId: item.loan.id,
        ticketNo: item.loan.ticketNo,
      );
      if (savedBytes != null) {
        final disposition = item.recoveryDisposition;
        if (disposition == null) return savedBytes;
        return const GirviRecoveryPdfStampService()
            .stamp(savedBytes, disposition);
      }
    }

    final draft = await CustomerProfileRepository(db: _controller.database)
        .fetchGirviInvoiceDraft(
      customerId: item.loan.customerId,
      loanId: item.loan.id,
    );
    if (draft == null) {
      throw StateError('Invoice draft could not be loaded.');
    }

    final invoiceController = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await invoiceController.generatePreview();
      final bytes = invoiceController.pdfBytes;
      if (bytes == null) {
        throw StateError('Invoice PDF could not be generated.');
      }
      return bytes;
    } finally {
      invoiceController.dispose();
    }
  }

  Future<void> _showInvoicePreview({
    required ContactRecoveryCase item,
    required Uint8List bytes,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => bytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: false,
                maxPageWidth: 920,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 18,
              child: _PreviewTitleBadge(
                title: 'Invoice PDF',
                subtitle: item.loan.ticketNo,
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoticePreview({
    required String title,
    required String subtitle,
    required Uint8List bytes,
  }) {
    final media = MediaQuery.of(context);
    final viewportWidth = media.size.width - 16;
    final pageWidth = viewportWidth < 920 ? viewportWidth : 920.0;
    final nativeDpi = pageWidth *
        media.devicePixelRatio /
        PdfPageFormat.a4.width *
        PdfPageFormat.inch;
    final previewDpi = nativeDpi.clamp(200.0, 260.0);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => bytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: false,
                dpi: previewDpi,
                maxPageWidth: 920,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 18,
              child: _PreviewTitleBadge(
                title: title,
                subtitle: subtitle,
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewItemImage(ContactRecoveryCase item) async {
    final path = _firstExistingItemPhotoPath(item);
    if (path == null) {
      _controller.showInlineMessage(
        'No item image is available for ticket ${item.loan.ticketNo}.',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.6,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.all(260),
                child: Center(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Item image could not be opened',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 18,
              child: _PreviewTitleBadge(
                title: 'Item Image',
                subtitle: item.loan.ticketNo,
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close image',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadItemImage(ContactRecoveryCase item) async {
    final path = _firstExistingItemPhotoPath(item);
    if (path == null) {
      _controller.showInlineMessage(
        'No item image is available for ticket ${item.loan.ticketNo}.',
      );
      return;
    }

    try {
      final extension = _fileExtension(path);
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Item Image',
        fileName:
            'pledged_item_${_safeFileToken(item.loan.ticketNo)}.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
        lockParentWindow: true,
      );
      if (outputPath == null) return;

      final normalizedPath = outputPath.toLowerCase().endsWith('.$extension')
          ? outputPath
          : '$outputPath.$extension';
      await File(path).copy(normalizedPath);
      _controller.showInlineMessage(
        'Item image saved for ticket ${item.loan.ticketNo}.',
      );
    } catch (_) {
      _controller.showInlineMessage(
        'Item image could not be saved for ticket ${item.loan.ticketNo}.',
      );
    }
  }

  String? _firstExistingItemPhotoPath(ContactRecoveryCase item) {
    for (final rawPath in item.itemPhotoPaths) {
      final path = rawPath.trim();
      if (path.isNotEmpty && File(path).existsSync()) return path;
    }
    return null;
  }

  String _fileExtension(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return 'jpg';
    final extension = name.substring(dotIndex + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{2,5}$').hasMatch(extension) ? extension : 'jpg';
  }

  String _safeFileToken(String value) {
    final token = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return token.isEmpty ? 'document' : token;
  }

  String _noticePdfName(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
  ) {
    final safeTicket =
        item.loan.ticketNo.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return 'girvi_${safeTicket}_notice_${language.fileLabel}.pdf';
  }
}
