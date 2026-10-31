part of '../../return_reversal_voucher_preview_screen.dart';

extension _ReturnReversalVoucherHubControls
    on _ReturnReversalVoucherPreviewScreenState {
  Widget _buildFormatGrid() {
    final selectedFormat = _voucherCtrl.selectedFormat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('DOCUMENT FORMAT'),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDocumentFormatPicker(selectedFormat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SalesPosColors.brandGold.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _FormatIcon(format: selectedFormat),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedFormat.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SalesPosColors.shellTextTitle,
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatShortName(selectedFormat),
                            style: const TextStyle(
                              color: SalesPosColors.brandGold,
                              fontSize: SalesPosStyles.fontCaption,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ShellChangeButton(
                      label: 'Change',
                      onTap: () => _showDocumentFormatPicker(selectedFormat),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FormatDetailPill(
                        icon: Icons.straighten_rounded,
                        label: _formatPaperSpec(selectedFormat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FormatDetailPill(
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

  Future<void> _showDocumentFormatPicker(PrintFormat selectedFormat) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close document format selector',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _DocumentFormatPickerPanel(
              selectedFormat: selectedFormat,
              formatShortName: _formatShortName,
              formatPaperSpec: _formatPaperSpec,
              formatUseCase: _formatUseCase,
              onSelect: (format) {
                _voucherCtrl.switchFormat(format);
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

  Widget _buildTemplateSelector() {
    if (_voucherCtrl.selectedOutputDocument.requiresSalesInvoice) {
      return _buildLockedInvoiceTemplateSurface();
    }
    return PosInvoiceTemplateSelector(
      selectedTemplateId: _voucherCtrl.selectedTemplateId,
      documentType: _voucherCtrl.documentType,
      title: 'VOUCHER DESIGN',
      onChanged: (templateId) => _voucherCtrl.selectPrintTemplate(templateId),
    );
  }

  Widget _buildLockedInvoiceTemplateSurface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('INVOICE DESIGN'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SalesPosColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: SalesPosColors.brandGold,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locked from Sales Billing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SalesPosColors.shellTextTitle,
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Template, policies and display fields follow sales setup',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SalesPosColors.shellTextMuted,
                        fontSize: SalesPosStyles.fontCaption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherContext(ReturnReversalSourceDocument sourceDocument) {
    final reversedCount = sourceDocument.reversedLineCount;
    final activeCount = widget.controller.state.returnCartLineItems.length;
    final lineLabel = activeCount > 0
        ? '$activeCount selected'
        : reversedCount > 0
            ? '$reversedCount returned'
            : '${sourceDocument.itemCount} source lines';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('VOUCHER CONTEXT'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SalesPosColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalesPosColors.shellBorder),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProfileChip(
                Icons.swap_horiz_rounded,
                widget.controller.state.operationType.ledgerLabel,
              ),
              _buildProfileChip(
                Icons.receipt_long_rounded,
                sourceDocument.type.label,
              ),
              _buildProfileChip(
                Icons.calendar_today_rounded,
                _formatDate(sourceDocument.documentDate),
              ),
              _buildProfileChip(Icons.inventory_2_rounded, lineLabel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSelector() {
    final documents = _voucherCtrl.availableOutputDocuments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('DOCUMENT TO ISSUE'),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SalesPosColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalesPosColors.shellBorder),
          ),
          child: Column(
            children: [
              for (final entry in documents.indexed) ...[
                _DocumentChoiceSurface(
                  icon: _documentChoiceIcon(entry.$2),
                  title: _documentChoiceTitle(entry.$2),
                  subtitle: _documentChoiceSubtitle(entry.$2),
                  selected: _voucherCtrl.selectedOutputDocument == entry.$2,
                  enabled: _voucherCtrl.isOutputDocumentEnabled(entry.$2),
                  onTap: () => _voucherCtrl.selectOutputDocument(entry.$2),
                ),
                if (entry.$1 != documents.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceMetalScope() {
    if (!_voucherCtrl.showsInvoiceMetalScope) {
      return const SizedBox.shrink();
    }
    final metals = _voucherCtrl.availableInvoiceMetals;
    if (metals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('INVOICE METAL'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SalesPosColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalesPosColors.shellBorder),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InvoiceMetalChip(
                label: 'All',
                selected: _voucherCtrl.selectedInvoiceMetal == null,
                enabled: metals.length > 1,
                onTap: () => _voucherCtrl.selectInvoiceMetalScope(null),
              ),
              for (final metal in metals)
                _InvoiceMetalChip(
                  label: metal.displayName,
                  selected: _voucherCtrl.selectedInvoiceMetal == metal,
                  enabled: true,
                  onTap: () => _voucherCtrl.selectInvoiceMetalScope(metal),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _documentChoiceIcon(ReturnReversalOutputDocumentKind kind) {
    return switch (kind) {
      ReturnReversalOutputDocumentKind.returnVoucher =>
        Icons.assignment_return_rounded,
      ReturnReversalOutputDocumentKind.originalSalesInvoice =>
        Icons.receipt_long_rounded,
      ReturnReversalOutputDocumentKind.updatedSalesInvoice =>
        Icons.price_check_rounded,
    };
  }

  String _documentChoiceTitle(ReturnReversalOutputDocumentKind kind) {
    if (kind == ReturnReversalOutputDocumentKind.returnVoucher) {
      return _voucherCtrl.selectedOutputDocumentLabel;
    }
    return kind.label;
  }

  String _documentChoiceSubtitle(ReturnReversalOutputDocumentKind kind) {
    if (!_voucherCtrl.isOutputDocumentEnabled(kind)) {
      return 'Available only when source is a sales invoice';
    }
    if (kind == ReturnReversalOutputDocumentKind.returnVoucher) {
      return _voucherCtrl.selectedOutputDocumentSubtitle;
    }
    return kind.subtitle;
  }

  Widget _buildPrintOptions() {
    final copies = _voucherCtrl.printCopies;
    final duplicateEnabled = _voucherCtrl.includeDuplicateStamp;
    final useDriverSettings = _voucherCtrl.usePrinterDriverSettings;
    final colorMode = _voucherCtrl.printColorMode;
    final totalPages = LotusPdfPageCounter.tryCountPages(_voucherCtrl.pdfBytes);
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
        const _ShellSectionLabel('PRINT CONTROLS'),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SalesPosColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const _PrintIconTile(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Print Run',
                          style: TextStyle(
                            color: SalesPosColors.shellTextTitle,
                            fontSize: SalesPosStyles.fontLabel,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _printRunSummary(
                            copies: copies,
                            totalPages: totalPages,
                          ),
                          style: const TextStyle(
                            color: SalesPosColors.shellTextMuted,
                            fontSize: SalesPosStyles.fontCaption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PrintStatusBadge(
                    label: duplicateEnabled ? 'Duplicate On' : 'Original',
                    isActive: duplicateEnabled,
                  ),
                ],
              ),
              const Divider(color: SalesPosColors.shellBorder, height: 24),
              _PrintControlSurface(
                icon: Icons.copy_all_rounded,
                title: 'Copies',
                subtitle: _copyControlSubtitle(
                  totalPages: totalPages,
                  pagesPerCopy: pagesPerCopy,
                ),
                trailing: _CopyStepper(
                  value: copies,
                  canDecrease: canDecrease,
                  canIncrease: canIncrease,
                  onDecrease: () {
                    if (!canDecrease) return;
                    _voucherCtrl.updatePrintOptions(
                      copies: copies - 1,
                      duplicate: duplicateEnabled,
                      useDriverSettings: useDriverSettings,
                      colorMode: colorMode,
                    );
                  },
                  onIncrease: () {
                    if (!canIncrease) return;
                    _voucherCtrl.updatePrintOptions(
                      copies: copies + 1,
                      duplicate: duplicateEnabled,
                      useDriverSettings: useDriverSettings,
                      colorMode: colorMode,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.verified_user_rounded,
                title: 'Duplicate Mark',
                subtitle: canMarkDuplicate
                    ? 'Stamp second and later copies only'
                    : 'Available when copies are 2 or more',
                trailing: Switch(
                  value: duplicateEnabled,
                  onChanged: canMarkDuplicate
                      ? (value) => _voucherCtrl.updatePrintOptions(
                            copies: copies,
                            duplicate: value,
                            useDriverSettings: useDriverSettings,
                            colorMode: colorMode,
                          )
                      : null,
                  activeThumbColor: SalesPosColors.brandGold,
                  activeTrackColor:
                      SalesPosColors.brandGold.withValues(alpha: 0.32),
                  inactiveThumbColor: SalesPosColors.shellTextMuted,
                  inactiveTrackColor: SalesPosColors.shellBg,
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.invert_colors_rounded,
                title: 'Print Mode',
                subtitle: 'Choose colour or grayscale output',
                trailing: _PrintModeSelector(
                  value: colorMode,
                  onChanged: (value) => _voucherCtrl.updatePrintOptions(
                    copies: copies,
                    duplicate: duplicateEnabled,
                    useDriverSettings: useDriverSettings,
                    colorMode: value,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.settings_applications_rounded,
                title: 'Printer Driver Settings',
                subtitle: 'Use saved paper, tray and printer defaults',
                trailing: Switch(
                  value: useDriverSettings,
                  onChanged: (value) => _voucherCtrl.updatePrintOptions(
                    copies: copies,
                    duplicate: duplicateEnabled,
                    useDriverSettings: value,
                    colorMode: colorMode,
                  ),
                  activeThumbColor: SalesPosColors.brandGold,
                  activeTrackColor:
                      SalesPosColors.brandGold.withValues(alpha: 0.32),
                  inactiveThumbColor: SalesPosColors.shellTextMuted,
                  inactiveTrackColor: SalesPosColors.shellBg,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PrintMetaPill(
                      icon: Icons.description_rounded,
                      label: _formatShortName(_voucherCtrl.selectedFormat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: Icons.layers_rounded,
                      label: pagesPerCopy == null
                          ? LotusPdfPageCounter.copyLabel(copies)
                          : '${LotusPdfPageCounter.pageLabel(pagesPerCopy)}/copy',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: colorMode == LotusPrintColorMode.color
                          ? Icons.palette_rounded
                          : Icons.contrast_rounded,
                      label: colorMode == LotusPrintColorMode.color
                          ? 'Colour'
                          : 'B&W',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: duplicateEnabled
                          ? Icons.verified_rounded
                          : Icons.lock_open_rounded,
                      label: duplicateEnabled ? 'Stamped' : 'Clean',
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

  Widget _buildProfileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SalesPosColors.brandGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: SalesPosColors.shellTextTitle,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortName(PrintFormat format) {
    return switch (format) {
      PrintFormat.a4 => 'A4',
      PrintFormat.thermal3inch => '80 mm',
      PrintFormat.thermal2inch => '57 mm',
    };
  }

  String _formatPaperSpec(PrintFormat format) {
    return switch (format) {
      PrintFormat.a4 => '210 x 297 mm',
      PrintFormat.thermal3inch => '80 mm roll',
      PrintFormat.thermal2inch => '57 mm roll',
    };
  }

  String _formatUseCase(PrintFormat format) {
    return switch (format) {
      PrintFormat.a4 => 'Return audit',
      PrintFormat.thermal3inch => 'Counter print',
      PrintFormat.thermal2inch => 'Compact POS',
    };
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthShort[date.month - 1];
    return '$day $month ${date.year}';
  }
}
