part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceHubControls on _GirviInvoiceHubScreenState {
  Widget _buildFormatSelector() {
    final selectedFormat = _controller.selectedFormat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('DOCUMENT FORMAT'),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDocumentFormatPicker(selectedFormat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GirviColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GirviColors.brandGold.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _GirviFormatIcon(format: selectedFormat),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatLabel(selectedFormat),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextTitle,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatShortName(selectedFormat),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: GirviColors.brandGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GirviFormatChangeButton(
                      onTap: () => _showDocumentFormatPicker(selectedFormat),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _GirviMetaPill(
                        icon: Icons.straighten_rounded,
                        label: _formatPaperSpec(selectedFormat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GirviMetaPill(
                        icon: Icons.verified_rounded,
                        label: _formatUseCase(selectedFormat),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDocumentFormatPicker(GirviInvoiceFormat selectedFormat) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Girvi document format selector',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _GirviDocumentFormatPickerPanel(
              selectedFormat: selectedFormat,
              labelFor: _formatLabel,
              shortNameFor: _formatShortName,
              paperSpecFor: _formatPaperSpec,
              useCaseFor: _formatUseCase,
              onSelect: (format) {
                _controller.switchFormat(format);
                Navigator.of(dialogContext).pop();
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  String _formatLabel(GirviInvoiceFormat format) {
    return switch (format) {
      GirviInvoiceFormat.a4 => 'A4 Girvi Invoice',
      GirviInvoiceFormat.compactA5 => '80 mm Girvi Receipt',
    };
  }

  String _formatShortName(GirviInvoiceFormat format) {
    return switch (format) {
      GirviInvoiceFormat.a4 => 'A4',
      GirviInvoiceFormat.compactA5 => '80 mm',
    };
  }

  String _formatPaperSpec(GirviInvoiceFormat format) {
    return switch (format) {
      GirviInvoiceFormat.a4 => '210 x 297 mm',
      GirviInvoiceFormat.compactA5 => '80 mm roll',
    };
  }

  String _formatUseCase(GirviInvoiceFormat format) {
    return switch (format) {
      GirviInvoiceFormat.a4 => 'Pledge ready',
      GirviInvoiceFormat.compactA5 => 'Counter copy',
    };
  }

  Widget _buildTemplateSelector() {
    final templates = PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.girviReceipt,
    );
    if (templates.isEmpty) return const SizedBox.shrink();

    final isA4 = _controller.selectedFormat == GirviInvoiceFormat.a4;
    final selectedTemplate = _resolveSelectedTemplate(templates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('INVOICE DESIGN'),
        const SizedBox(height: 10),
        InkWell(
          onTap: isA4
              ? () => _showTemplatePicker(templates, selectedTemplate)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GirviColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isA4
                    ? GirviColors.brandGold.withValues(alpha: 0.45)
                    : GirviColors.shellBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _GirviTemplateThumbnail(template: selectedTemplate),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isA4
                                ? selectedTemplate.name
                                : '80 mm Counter Receipt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: GirviColors.shellTextTitle,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isA4
                                ? selectedTemplate.shortName
                                : 'Counter receipt uses fixed Girvi design',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isA4
                                  ? GirviColors.brandGold
                                  : GirviColors.shellTextMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GirviTemplateChangeButton(
                      enabled: isA4 && templates.length > 1,
                      onTap: () =>
                          _showTemplatePicker(templates, selectedTemplate),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TemplateInfoPill(
                        icon: Icons.receipt_long_outlined,
                        label: PrintTemplateDocumentType.girviReceipt.label,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TemplateInfoPill(
                        icon: isA4
                            ? Icons.layers_rounded
                            : Icons.view_compact_alt_rounded,
                        label: isA4
                            ? '${templates.length} designs'
                            : 'Counter copy',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PrintTemplateDefinition _resolveSelectedTemplate(
    List<PrintTemplateDefinition> templates,
  ) {
    for (final template in templates) {
      if (template.id == _controller.selectedTemplateId) return template;
    }
    return templates.first;
  }

  Future<void> _showTemplatePicker(
    List<PrintTemplateDefinition> templates,
    PrintTemplateDefinition selectedTemplate,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Girvi invoice design selector',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _GirviTemplatePickerPanel(
              templates: templates,
              selectedTemplateId: selectedTemplate.id,
              onSelect: (templateId) {
                _controller.switchTemplate(templateId);
                Navigator.of(dialogContext).pop();
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  Widget _buildPrintOptions() {
    final copies = _controller.printCopies;
    final duplicateEnabled = _controller.includeDuplicateStamp;
    final useDriverSettings = _controller.usePrinterDriverSettings;
    final colorMode = _controller.printColorMode;
    final totalPages = LotusPdfPageCounter.tryCountPages(_controller.pdfBytes);
    final pagesPerCopy = LotusPdfPageCounter.pagesPerCopy(
      totalPages: totalPages,
      copies: copies,
    );
    final canDecrease = copies > 1;
    final canIncrease = copies < 5;
    final canMarkDuplicate = copies > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('PRINT CONTROLS'),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GirviColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GirviColors.brandGold.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GirviPrintControlSurface(
                icon: Icons.print_rounded,
                title: 'Print Run',
                subtitle: _printRunSummary(
                  copies: copies,
                  totalPages: totalPages,
                ),
                trailing: _GirviPrintStatusBadge(
                  label: duplicateEnabled ? 'Duplicate' : 'Original',
                  isActive: duplicateEnabled,
                ),
              ),
              const SizedBox(height: 10),
              _GirviPrintControlSurface(
                icon: Icons.copy_all_rounded,
                title: 'Copies',
                subtitle: _copyControlSubtitle(
                  totalPages: totalPages,
                  pagesPerCopy: pagesPerCopy,
                ),
                trailing: _GirviCopyStepper(
                  value: copies,
                  canDecrease: canDecrease,
                  canIncrease: canIncrease,
                  onDecrease: () => _controller.updatePrintOptions(
                    copies: copies - 1,
                    duplicate: duplicateEnabled,
                  ),
                  onIncrease: () => _controller.updatePrintOptions(
                    copies: copies + 1,
                    duplicate: duplicateEnabled,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _GirviPrintControlSurface(
                icon: Icons.verified_user_rounded,
                title: 'Duplicate Mark',
                subtitle: canMarkDuplicate
                    ? 'Mark additional copies as duplicate'
                    : 'Available when copies are 2 or more',
                trailing: Switch(
                  value: duplicateEnabled,
                  onChanged: canMarkDuplicate
                      ? (value) => _controller.updatePrintOptions(
                            copies: copies,
                            duplicate: value,
                          )
                      : null,
                  activeThumbColor: GirviColors.brandGold,
                ),
              ),
              const SizedBox(height: 10),
              _GirviPrintControlSurface(
                icon: Icons.invert_colors_rounded,
                title: 'Print Mode',
                subtitle: 'Choose colour or grayscale output',
                trailing: _GirviPrintModeSelector(
                  value: colorMode,
                  onChanged: (value) => _controller.updatePrintOptions(
                    copies: copies,
                    duplicate: duplicateEnabled,
                    colorMode: value,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _GirviPrintControlSurface(
                icon: Icons.settings_applications_rounded,
                title: 'Printer Driver Settings',
                subtitle: 'Use saved duplex, paper tray and printer defaults',
                trailing: Switch(
                  value: useDriverSettings,
                  onChanged: (value) => _controller.updatePrintOptions(
                    copies: copies,
                    duplicate: duplicateEnabled,
                    useDriverSettings: value,
                  ),
                  activeThumbColor: GirviColors.brandGold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GirviPrintMetaPill(
                      icon: Icons.description_outlined,
                      label: _formatShortName(_controller.selectedFormat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GirviPrintMetaPill(
                      icon: Icons.layers_rounded,
                      label: totalPages == null
                          ? 'Counting pages'
                          : LotusPdfPageCounter.pageLabel(totalPages),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GirviPrintMetaPill(
                      icon: Icons.palette_rounded,
                      label: colorMode.label,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _printRunSummary({
    required int copies,
    required int? totalPages,
  }) {
    final copyLabel = LotusPdfPageCounter.copyLabel(copies);
    if (totalPages == null) return '$copyLabel selected';
    return '$copyLabel selected - ${LotusPdfPageCounter.pageLabel(totalPages)} to print';
  }

  String _copyControlSubtitle({
    required int? totalPages,
    required int? pagesPerCopy,
  }) {
    if (totalPages == null || pagesPerCopy == null) {
      return 'Maximum 5 copies per print run';
    }
    return '${LotusPdfPageCounter.pageLabel(pagesPerCopy)} per copy - ${LotusPdfPageCounter.pageLabel(totalPages)} total';
  }

  Widget _buildErrorNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: GirviColors.dangerBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GirviColors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: GirviColors.danger,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: GirviColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: GirviColors.shellTextMuted,
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}
