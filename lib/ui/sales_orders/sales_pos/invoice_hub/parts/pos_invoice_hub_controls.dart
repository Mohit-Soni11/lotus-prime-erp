part of '../../pos_invoice_preview_screen.dart';

extension _PosInvoiceHubControls on _PosInvoicePreviewScreenState {
  Widget _buildFormatGrid() {
    final selectedFormat = _invCtrl.selectedFormat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DOCUMENT FORMAT',
          style: TextStyle(
            color: SalesPosColors.shellTextMuted,
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    _FormatChangeButton(
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
                _invCtrl.switchFormat(format);
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

  String _formatShortName(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return 'A4';
      case PrintFormat.thermal3inch:
        return '80 mm';
      case PrintFormat.thermal2inch:
        return '57 mm';
    }
  }

  String _formatPaperSpec(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return '210 x 297 mm';
      case PrintFormat.thermal3inch:
        return '80 mm roll';
      case PrintFormat.thermal2inch:
        return '57 mm roll';
    }
  }

  String _formatUseCase(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return 'GST ready';
      case PrintFormat.thermal3inch:
        return 'Counter print';
      case PrintFormat.thermal2inch:
        return 'Compact POS';
    }
  }

  Widget _buildTemplateSelector() {
    return PosInvoiceTemplateSelector(
      selectedTemplateId: _invCtrl.selectedTemplateId,
      documentType: PrintTemplateDocumentType.salesInvoice,
      title: 'INVOICE DESIGN',
      onChanged: (templateId) => _invCtrl.selectPrintTemplate(templateId),
    );
  }

  Widget _buildCategorizedCustomization() {
    if (_invCtrl.selectedFormat != PrintFormat.a4) return const SizedBox();

    final metals = _invCtrl.presentMetals;
    final billingModeLabel =
        widget.billingCtrl.billingMode == BillingMode.wholesale ? 'B2B' : 'B2C';
    final billTypeLabel = widget.billingCtrl.billType == BillType.gst
        ? 'GST Invoice'
        : 'Sales Invoice';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILL CONTEXT',
          style: TextStyle(
            color: SalesPosColors.shellTextMuted,
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SalesPosColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalesPosColors.shellBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildProfileChip(Icons.storefront_rounded, billingModeLabel),
                  _buildProfileChip(Icons.receipt_long_rounded, billTypeLabel),
                  _buildProfileChip(
                    Icons.category_rounded,
                    metals.isEmpty
                        ? 'No Metal Items'
                        : metals.map((metal) => metal.displayName).join(' + '),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'INVOICE DISPLAY',
          style: TextStyle(
            color: SalesPosColors.shellTextMuted,
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        if (metals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SalesPosColors.shellBorder),
            ),
            child: const Text(
              'Add sale items to load metal-wise invoice controls.',
              style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: SalesPosStyles.fontCaption,
              ),
            ),
          )
        else ...[
          _buildMetalInvoiceSelector(metals),
          const SizedBox(height: 12),
          if (_invCtrl.effectiveActiveMetal != null)
            _buildMetalBillingSetupCard(_invCtrl.effectiveActiveMetal!),
        ],
        const SizedBox(height: 12),
        _buildShopPrintSetupCard(),
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

  Widget _buildMetalInvoiceSelector(List<MetalType> metals) {
    if (metals.length <= 1) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metals.map(_buildMetalInvoiceButton).toList(),
    );
  }

  Widget _buildMetalInvoiceButton(MetalType metal) {
    final isSelected = _invCtrl.effectiveActiveMetal == metal;
    final color = _metalColor(metal);

    return InkWell(
      key: ValueKey('invoice-display-selector-${metal.name}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => _invCtrl.setActivePrintMetal(metal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : SalesPosColors.shellPanelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : SalesPosColors.shellBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 15,
              color: isSelected ? color : SalesPosColors.shellTextMuted,
            ),
            const SizedBox(width: 7),
            Text(
              '${metal.displayName} Invoice',
              style: TextStyle(
                color: isSelected ? color : SalesPosColors.shellTextTitle,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetalBillingSetupCard(MetalType metal) {
    return PosInvoiceMetalSetupCard(
      key: ValueKey('invoice-display-profile-${metal.name}'),
      metal: metal,
      controller: _invCtrl,
      accentColor: _metalColor(metal),
    );
  }

  Widget _buildShopPrintSetupCard() {
    return PosInvoiceShopPrintSetupCard(controller: _invCtrl);
  }

  Color _metalColor(MetalType metal) {
    switch (metal) {
      case MetalType.gold:
        return SalesPosColors.brandGold;
      case MetalType.silver:
        return SalesPosColors.brandSilver;
      case MetalType.platinum:
        return SalesPosColors.brandPlatinum;
      case MetalType.diamond:
        return SalesPosColors.brandDiamond;
    }
  }

  Widget _buildDueDateSection() {
    final hasDue = (_invCtrl.invoice?.balanceDue ?? 0) > 0.5;
    if (!hasDue) return const SizedBox();

    final dueDate = _invCtrl.dueDate;
    final dueDateLabel = dueDate != null
        ? '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}'
        : 'Select a due date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT TERMS',
          style: TextStyle(
            color: SalesPosColors.shellTextMuted,
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  dueDate ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: SalesPosColors.brandGold,
                    onPrimary: Colors.black,
                    surface: SalesPosColors.shellPanelBg,
                    onSurface: SalesPosColors.shellTextTitle,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              await _invCtrl.setDueDate(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dueDate != null
                    ? SalesPosColors.brandGold
                    : SalesPosColors.shellBorder,
                width: dueDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: dueDate != null
                      ? SalesPosColors.brandGold
                      : SalesPosColors.shellTextMuted,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Due By',
                        style: TextStyle(
                          color: SalesPosColors.shellTextMuted,
                          fontSize: SalesPosStyles.fontCaption,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueDateLabel,
                        style: TextStyle(
                          color: dueDate != null
                              ? SalesPosColors.brandGold
                              : SalesPosColors.shellTextTitle,
                          fontSize: SalesPosStyles.fontLabel,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dueDate != null)
                  GestureDetector(
                    onTap: () => _invCtrl.setDueDate(null),
                    child: const Icon(
                      Icons.close_rounded,
                      color: SalesPosColors.shellTextMuted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
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

  Widget _buildPrintOptions() {
    final copies = _invCtrl.printCopies;
    final duplicateEnabled = _invCtrl.includeDuplicateStamp;
    final useDriverSettings = _invCtrl.usePrinterDriverSettings;
    final totalPages = LotusPdfPageCounter.tryCountPages(_invCtrl.pdfBytes);
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
        const Text(
          'PRINT CONTROLS',
          style: TextStyle(
            color: SalesPosColors.shellTextMuted,
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      Icons.print_rounded,
                      color: SalesPosColors.brandGold,
                      size: 20,
                    ),
                  ),
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
                    _invCtrl.updatePrintOptions(
                      copies: copies - 1,
                      duplicate: duplicateEnabled,
                      useDriverSettings: useDriverSettings,
                    );
                  },
                  onIncrease: () {
                    if (!canIncrease) return;
                    _invCtrl.updatePrintOptions(
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
                      ? (value) => _invCtrl.updatePrintOptions(
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
                subtitle: 'Use saved duplex, paper tray and printer defaults',
                trailing: Switch(
                  value: useDriverSettings,
                  onChanged: (value) => _invCtrl.updatePrintOptions(
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
                      label: _formatShortName(_invCtrl.selectedFormat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: Icons.layers_rounded,
                      label: pagesPerCopy == null
                          ? (copies == 1 ? 'Single copy' : '$copies copies')
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: useDriverSettings
                          ? Icons.settings_rounded
                          : Icons.straighten_rounded,
                      label: useDriverSettings ? 'Driver' : 'App size',
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
              ? SalesPosColors.brandGold.withValues(alpha: 0.40)
              : SalesPosColors.shellBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: SalesPosColors.shellTextMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.shellTextTitle,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
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
                      color: SalesPosColors.brandGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
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
                          'Choose print paper and receipt size',
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
                  return _DocumentFormatOptionTile(
                    format: format,
                    selected: format == selectedFormat,
                    shortName: formatShortName(format),
                    paperSpec: formatPaperSpec(format),
                    useCase: formatUseCase(format),
                    onTap: () => onSelect(format),
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

class _DocumentFormatOptionTile extends StatelessWidget {
  final PrintFormat format;
  final bool selected;
  final String shortName;
  final String paperSpec;
  final String useCase;
  final VoidCallback onTap;

  const _DocumentFormatOptionTile({
    required this.format,
    required this.selected,
    required this.shortName,
    required this.paperSpec,
    required this.useCase,
    required this.onTap,
  });

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
                    '$shortName  |  $paperSpec  |  $useCase',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SalesPosColors.shellTextMuted,
                      fontSize: SalesPosStyles.fontCaption,
                      height: 1.25,
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
  }
}

class _FormatIcon extends StatelessWidget {
  final PrintFormat format;

  const _FormatIcon({required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(
        format.icon,
        color: SalesPosColors.brandGold,
        size: 21,
      ),
    );
  }
}

class _FormatChangeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FormatChangeButton({required this.onTap});

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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change',
              style: TextStyle(
                color: SalesPosColors.brandGold,
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 4),
            Icon(
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
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SalesPosColors.shellTextMuted, size: 15),
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
