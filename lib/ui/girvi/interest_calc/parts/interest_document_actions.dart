part of '../interest_calc_screen.dart';

extension InterestDocumentActions on _InterestCalcScreenState {
  Future<void> _showSettlementSavedDialog(
    int loanId, {
    bool delivered = false,
  }) {
    final title = delivered ? 'Delivery Completed' : 'Settlement Saved';
    final message = delivered
        ? 'The pledged item has been marked as delivered. You can view, print, or save the complete Girvi document set now.'
        : 'Final settlement is complete and the Girvi ticket is ready for delivery. You can view, print, or save the payment and release document now.';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GirviColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GirviColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: GirviColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _saveGirviReleaseDocumentForLoan(loanId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.info,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 17),
              label: Text(
                'Save PDF',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _printGirviReleaseDocumentForLoan(loanId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.warning,
                foregroundColor: GirviColors.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.print_rounded, size: 17),
              label: Text(
                'Print',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _previewGirviReleaseDocumentForLoan(loanId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.visibility_rounded, size: 17),
              label: Text(
                'View Document',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Uint8List?> _buildGirviReleaseDocumentPdfForLoan(int loanId) async {
    final repo = GirviRepository(_db);
    final accounts = await repo.getLoansWithCustomer(loanId: loanId);
    if (accounts.isEmpty) return null;
    final account = accounts.single;
    final draft =
        await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
      customerId: account.loan.customerId,
      loanId: loanId,
    );
    if (draft == null) return null;

    final templateId = await _selectGirviDocumentTemplate(
      title: 'Select Girvi PDF Design',
      actionLabel: 'Use Design',
    );
    if (templateId == null) return null;

    return _buildGirviTemplatePdfBytes(
      draft: draft.copyWith(mode: GirviReceiptMode.release),
      templateId: templateId,
    );
  }

  Future<void> _previewGirviReleaseDocumentForLoan(int loanId) async {
    try {
      final bytes = await _buildGirviReleaseDocumentPdfForLoan(loanId);
      if (!mounted) return;
      if (bytes == null) return;
      await _showGirviReleaseDocumentPreview(
        pdfBytes: bytes,
        fileName: _girviReleaseDocumentFileName(loanId),
      );
    } catch (_) {
      if (mounted) _showInfoFeedback('Girvi document could not be opened.');
    }
  }

  Future<void> _printGirviReleaseDocumentForLoan(int loanId) async {
    try {
      final bytes = await _buildGirviReleaseDocumentPdfForLoan(loanId);
      if (!mounted) return;
      if (bytes == null) return;

      final fileName = _girviReleaseDocumentFileName(loanId);
      final result = await const LotusPdfPrintDispatcher().dispatch(
        context: context,
        bytes: bytes,
        documentName: fileName,
        outputFileName: fileName,
        printerPickerTitle: 'Select Girvi Document Printer',
        virtualSaveDialogTitle: 'Save Girvi Print Output As',
      );
      if (!mounted) return;
      if (!result.completed && result != LotusPdfPrintResult.cancelled) {
        _showInfoFeedback('Girvi document could not be printed.');
      }
    } catch (_) {
      if (mounted) _showInfoFeedback('Girvi document could not be printed.');
    }
  }

  Future<void> _saveGirviReleaseDocumentForLoan(int loanId) async {
    try {
      final bytes = await _buildGirviReleaseDocumentPdfForLoan(loanId);
      if (!mounted) return;
      if (bytes == null) return;

      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Girvi Document PDF',
        fileName: _girviReleaseDocumentFileName(loanId),
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        lockParentWindow: true,
      );
      if (selectedPath == null) return;

      final outputPath = _ensurePdfExtension(selectedPath);
      final file = File(outputPath);
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        AppFeedback.success(
          context,
          message: 'Girvi document PDF saved successfully.',
        );
      }
    } catch (_) {
      if (mounted) _showInfoFeedback('Girvi document could not be saved.');
    }
  }

  String _girviReleaseDocumentFileName(int loanId) {
    return 'girvi_release_$loanId.pdf';
  }

  String _ensurePdfExtension(String path) {
    return path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
  }

  Future<Uint8List?> _buildGirviTemplatePdfBytes({
    required GirviInvoiceDraft draft,
    required String templateId,
  }) async {
    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await controller.generatePreview();
      await controller.switchTemplate(templateId);
      return controller.pdfBytes;
    } finally {
      controller.dispose();
    }
  }

  Future<String?> _selectGirviDocumentTemplate({
    required String title,
    required String actionLabel,
  }) {
    final templates = PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.girviReceipt,
    );
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: GirviColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGold.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_motion_rounded,
                      color: GirviColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose the same Girvi invoice design used in the invoice hub.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final template in templates) ...[
                      _GirviDocumentTemplateTile(
                        template: template,
                        selected: template.id == selectedTemplateId,
                        onTap: () => setDialogState(
                          () => selectedTemplateId = template.id,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GirviColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedTemplateId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GirviColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    actionLabel,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGirviReleaseDocumentPreview({
    required Uint8List pdfBytes,
    required String fileName,
  }) {
    var previewScale = 1.15;

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.74),
      useSafeArea: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void setPreviewScale(double value) {
              setDialogState(() {
                previewScale = value.clamp(0.75, 2.25).toDouble();
              });
            }

            return Dialog.fullscreen(
              backgroundColor: const Color(0xFF111827),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PdfPreview(
                      key: ValueKey(previewScale.toStringAsFixed(2)),
                      build: (_) async => pdfBytes,
                      initialPageFormat: PdfPageFormat.a4,
                      allowPrinting: true,
                      allowSharing: true,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      pdfFileName: fileName,
                      maxPageWidth: 980 * previewScale,
                      scrollViewDecoration: const BoxDecoration(
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PdfPreviewZoomButton(
                              tooltip: 'Zoom out',
                              icon: Icons.remove_rounded,
                              onPressed: () =>
                                  setPreviewScale(previewScale - 0.15),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '${(previewScale * 100).round()}%',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _PdfPreviewZoomButton(
                              tooltip: 'Zoom in',
                              icon: Icons.add_rounded,
                              onPressed: () =>
                                  setPreviewScale(previewScale + 0.15),
                            ),
                            const SizedBox(width: 6),
                            TextButton(
                              onPressed: () => setPreviewScale(1.15),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                minimumSize: const Size(0, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Reset',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PdfPreviewZoomButton extends StatelessWidget {
  const _PdfPreviewZoomButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _GirviDocumentTemplateTile extends StatelessWidget {
  const _GirviDocumentTemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final PrintTemplateDefinition template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEconomy = template.id == PrintTemplateRegistry.lotusEconomy.id;
    final isSignature = template.id == PrintTemplateRegistry.lotusSignature.id;
    final accent = isEconomy
        ? GirviColors.textDark
        : isSignature
            ? GirviColors.warning
            : GirviColors.brandGold;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : GirviColors.inputBg.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : GirviColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 68,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 5, color: accent),
                  const SizedBox(height: 7),
                  Container(height: 4, color: GirviColors.cardBorder),
                  const SizedBox(height: 5),
                  Container(height: 4, color: GirviColors.cardBorder),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: Container(height: 4, color: accent)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          color: accent.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selected ? accent : GirviColors.textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textBody,
                      fontSize: 12.5,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? accent : GirviColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
