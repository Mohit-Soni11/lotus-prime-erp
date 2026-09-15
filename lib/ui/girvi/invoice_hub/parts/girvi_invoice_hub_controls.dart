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

  Widget _buildBillContextCard() {
    final metals = _controller.presentMetals;
    final metalLabel = metals.isEmpty
        ? 'No Item'
        : metals.map(GirviBillingMetal.displayName).join(' + ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('BILL CONTEXT'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GirviColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GirviColors.shellBorder),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProfileChip(
                Icons.account_balance_wallet_outlined,
                _controller.selectedReceiptMode.title,
              ),
              _buildProfileChip(Icons.receipt_long_outlined, 'Girvi Invoice'),
              _buildProfileChip(Icons.category_rounded, metalLabel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GirviColors.brandGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.shellTextTitle,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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

class _GirviTemplatePickerPanel extends StatelessWidget {
  const _GirviTemplatePickerPanel({
    required this.templates,
    required this.selectedTemplateId,
    required this.onSelect,
    required this.onClose,
  });

  final List<PrintTemplateDefinition> templates;
  final String selectedTemplateId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 420.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: GirviColors.shellPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_motion_rounded,
                      color: GirviColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GIRVI INVOICE DESIGN',
                          style: GoogleFonts.inter(
                            color: GirviColors.shellTextTitle,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Classic, Economy and Signature A4 receipts',
                          style: GoogleFonts.inter(
                            color: GirviColors.shellTextMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: GirviColors.shellTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: GirviColors.shellBorder, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _GirviTemplateOptionTile(
                    template: template,
                    selected: template.id == selectedTemplateId,
                    onTap: () => onSelect(template.id),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: templates.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GirviTemplateOptionTile extends StatelessWidget {
  const _GirviTemplateOptionTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final PrintTemplateDefinition template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? GirviColors.brandGold.withValues(alpha: 0.10)
              : GirviColors.shellBg.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? GirviColors.brandGold : GirviColors.shellBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _GirviTemplateThumbnail(template: template),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: selected
                                ? GirviColors.brandGold
                                : GirviColors.shellTextTitle,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (template.isSystemDefault)
                        const _TemplateDefaultBadge(),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.shellTextMuted,
                      fontSize: 12.5,
                      height: 1.18,
                      fontWeight: FontWeight.w600,
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
              color:
                  selected ? GirviColors.brandGold : GirviColors.shellTextMuted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _GirviTemplateThumbnail extends StatelessWidget {
  const _GirviTemplateThumbnail({required this.template});

  final PrintTemplateDefinition template;

  @override
  Widget build(BuildContext context) {
    final isEconomy = template.id == PrintTemplateRegistry.lotusEconomy.id;
    final isSignature = template.id == PrintTemplateRegistry.lotusSignature.id;
    final pageColor =
        isEconomy || isSignature ? Colors.white : GirviColors.shellBg;
    final accentColor = isEconomy
        ? GirviColors.shellTextTitle
        : isSignature
            ? const Color(0xFFB87819)
            : GirviColors.brandGold;
    final lineColor = isEconomy
        ? GirviColors.shellBorder
        : isSignature
            ? const Color(0xFFE8D7B3)
            : Colors.white.withValues(alpha: 0.82);

    return Container(
      width: 36,
      height: 46,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accentColor.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isEconomy ? 1.5 : (isSignature ? 1.2 : 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(
            3,
            (index) => Container(
              height: 2.8,
              width: index == 1 ? 16 : double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 1.3),
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (isSignature) ...[
            const Spacer(),
            Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GirviTemplateChangeButton extends StatelessWidget {
  const _GirviTemplateChangeButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: GirviColors.brandGold.withValues(alpha: enabled ? 0.10 : 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                GirviColors.brandGold.withValues(alpha: enabled ? 0.32 : 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              enabled ? 'Change' : 'Fixed',
              style: GoogleFonts.inter(
                color: enabled
                    ? GirviColors.brandGold
                    : GirviColors.shellTextMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color:
                  enabled ? GirviColors.brandGold : GirviColors.shellTextMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateInfoPill extends StatelessWidget {
  const _TemplateInfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: GirviColors.shellTextMuted, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.shellTextTitle,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateDefaultBadge extends StatelessWidget {
  const _TemplateDefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        'Default',
        style: GoogleFonts.inter(
          color: GirviColors.brandGold,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
