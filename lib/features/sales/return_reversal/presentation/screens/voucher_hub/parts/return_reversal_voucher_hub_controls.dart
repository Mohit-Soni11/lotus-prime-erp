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
                    );
                  },
                  onIncrease: () {
                    if (!canIncrease) return;
                    _voucherCtrl.updatePrintOptions(
                      copies: copies + 1,
                      duplicate: duplicateEnabled,
                      useDriverSettings: useDriverSettings,
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
                icon: Icons.settings_applications_rounded,
                title: 'Printer Driver Settings',
                subtitle: 'Use saved paper, tray and printer defaults',
                trailing: Switch(
                  value: useDriverSettings,
                  onChanged: (value) => _voucherCtrl.updatePrintOptions(
                    copies: copies,
                    duplicate: duplicateEnabled,
                    useDriverSettings: value,
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

class _ShellSectionLabel extends StatelessWidget {
  final String label;

  const _ShellSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: SalesPosColors.shellTextMuted,
        fontSize: SalesPosStyles.fontCaption,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _FormatIcon extends StatelessWidget {
  final PrintFormat format;

  const _FormatIcon({required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(format.icon, color: SalesPosColors.brandGold, size: 20),
    );
  }
}

class _ShellChangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ShellChangeButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: SalesPosColors.brandGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SalesPosColors.brandGold.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: SalesPosColors.brandGold,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: SalesPosColors.brandGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatDetailPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FormatDetailPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SalesPosColors.shellTextMuted, size: 14),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.shellTextTitle,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentChoiceSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _DocumentChoiceSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled
        ? (selected ? SalesPosColors.brandGold : SalesPosColors.shellTextMuted)
        : SalesPosColors.shellTextMuted.withValues(alpha: 0.42);
    return Tooltip(
      message: enabled ? title : 'Sales invoice source required',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? SalesPosColors.brandGold.withValues(alpha: 0.11)
                : SalesPosColors.shellBg
                    .withValues(alpha: enabled ? 0.58 : 0.30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? SalesPosColors.brandGold
                  : SalesPosColors.shellBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? SalesPosColors.shellTextTitle
                            : SalesPosColors.shellTextMuted,
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? SalesPosColors.shellTextMuted
                            : SalesPosColors.shellTextMuted
                                .withValues(alpha: 0.58),
                        fontSize: SalesPosStyles.fontCaption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : enabled
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.lock_rounded,
                color: accent,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceMetalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _InvoiceMetalChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        selected ? SalesPosColors.brandGold : SalesPosColors.shellTextMuted;
    return Tooltip(
      message: enabled ? '$label invoice' : 'Only one metal is available',
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? SalesPosColors.brandGold.withValues(alpha: 0.12)
                : SalesPosColors.shellBg.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? SalesPosColors.brandGold
                  : SalesPosColors.shellBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? SalesPosColors.shellTextTitle
                      : SalesPosColors.shellTextMuted,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrintIconTile extends StatelessWidget {
  const _PrintIconTile();

  @override
  Widget build(BuildContext context) {
    return Container(
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
        Icons.print_rounded,
        color: SalesPosColors.brandGold,
        size: 20,
      ),
    );
  }
}

class _PrintControlSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PrintControlSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SalesPosColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontLabel,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _CopyStepper extends StatelessWidget {
  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CopyStepper({
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  color: SalesPosColors.brandGold,
                  fontSize: SalesPosStyles.fontInput,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.add_rounded ? 'Add copy' : 'Remove copy',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? SalesPosColors.brandGold
                : SalesPosColors.shellTextMuted.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

class _PrintStatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const _PrintStatusBadge({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? SalesPosColors.brandGold.withValues(alpha: 0.14)
            : SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? SalesPosColors.brandGold.withValues(alpha: 0.34)
              : SalesPosColors.shellBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive
              ? SalesPosColors.brandGold
              : SalesPosColors.shellTextMuted,
          fontSize: SalesPosStyles.fontCaption,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PrintMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PrintMetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SalesPosColors.brandGold, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.shellTextTitle,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentFormatPickerPanel extends StatelessWidget {
  final PrintFormat selectedFormat;
  final String Function(PrintFormat) formatShortName;
  final String Function(PrintFormat) formatPaperSpec;
  final String Function(PrintFormat) formatUseCase;
  final ValueChanged<PrintFormat> onSelect;
  final VoidCallback onClose;

  const _DocumentFormatPickerPanel({
    required this.selectedFormat,
    required this.formatShortName,
    required this.formatPaperSpec,
    required this.formatUseCase,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 420.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalesPosColors.shellBorder),
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
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.straighten_rounded,
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
                          'DOCUMENT FORMAT',
                          style: TextStyle(
                            color: SalesPosColors.shellTextTitle,
                            fontSize: SalesPosStyles.fontInput,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Voucher paper and receipt layout',
                          style: TextStyle(
                            color: SalesPosColors.shellTextMuted,
                            fontSize: SalesPosStyles.fontCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: SalesPosColors.shellTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: SalesPosColors.shellBorder, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final format = PrintFormat.values[index];
                  final selected = format == selectedFormat;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelect(format),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? SalesPosColors.brandGold.withValues(alpha: 0.10)
                            : SalesPosColors.shellBg.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? SalesPosColors.brandGold
                              : SalesPosColors.shellBorder,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _FormatIcon(format: format),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  format.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? SalesPosColors.brandGold
                                        : SalesPosColors.shellTextTitle,
                                    fontSize: SalesPosStyles.fontLabel,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${formatPaperSpec(format)} - ${formatUseCase(format)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SalesPosColors.shellTextMuted,
                                    fontSize: SalesPosStyles.fontCaption,
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
                            color: selected
                                ? SalesPosColors.brandGold
                                : SalesPosColors.shellTextMuted,
                            size: 21,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: PrintFormat.values.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _monthShort = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];
