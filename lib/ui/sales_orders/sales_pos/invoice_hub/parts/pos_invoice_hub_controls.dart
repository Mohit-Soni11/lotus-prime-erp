part of '../../pos_invoice_preview_screen.dart';

extension _PosInvoiceHubControls on _PosInvoicePreviewScreenState {
  Widget _buildFormatGrid() {
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
        Row(
          children: PrintFormat.values.map((fmt) {
            final isSelected = _invCtrl.selectedFormat == fmt;
            return Expanded(
              child: GestureDetector(
                onTap: () => _invCtrl.switchFormat(fmt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SalesPosColors.brandGold.withValues(alpha: 0.15)
                        : SalesPosColors.shellPanelBg,
                    border: Border.all(
                      color: isSelected
                          ? SalesPosColors.brandGold
                          : SalesPosColors.shellBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        fmt.icon,
                        color: isSelected
                            ? SalesPosColors.brandGold
                            : SalesPosColors.shellTextMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fmt.label,
                        style: TextStyle(
                          color: isSelected
                              ? SalesPosColors.brandGold
                              : SalesPosColors.shellTextMuted,
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
        widget.billingCtrl.billingMode == BillingMode.wholesale
            ? 'Wholesale'
            : 'Retail';
    final billTypeLabel = widget.billingCtrl.billType == BillType.gst
        ? 'GST Invoice'
        : 'Non-GST Bill';

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
              const SizedBox(height: 10),
              Text(
                'Auto-detected from the current POS sale.',
                style: TextStyle(
                  color: SalesPosColors.shellTextMuted.withValues(alpha: 0.9),
                  fontSize: SalesPosStyles.fontCaption,
                  height: 1.3,
                ),
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

  Widget _buildPrintOptions() {
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SalesPosColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalesPosColors.shellBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Copies',
                    style: TextStyle(
                      color: SalesPosColors.shellTextTitle,
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: SalesPosColors.brandGold,
                        ),
                        onPressed: () {
                          if (_invCtrl.printCopies > 1) {
                            _invCtrl.updatePrintOptions(
                              copies: _invCtrl.printCopies - 1,
                              duplicate: _invCtrl.includeDuplicateStamp,
                            );
                          }
                        },
                      ),
                      Text(
                        '${_invCtrl.printCopies}',
                        style: const TextStyle(
                          color: SalesPosColors.brandGold,
                          fontSize: SalesPosStyles.fontValue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: SalesPosColors.brandGold,
                        ),
                        onPressed: () {
                          if (_invCtrl.printCopies < 5) {
                            _invCtrl.updatePrintOptions(
                              copies: _invCtrl.printCopies + 1,
                              duplicate: _invCtrl.includeDuplicateStamp,
                            );
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
              const Divider(color: SalesPosColors.shellBorder, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duplicate Mark',
                        style: TextStyle(
                          color: SalesPosColors.shellTextTitle,
                          fontSize: SalesPosStyles.fontLabel,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Marks reprinted copies',
                        style: TextStyle(
                          color: SalesPosColors.shellTextMuted,
                          fontSize: SalesPosStyles.fontCaption,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _invCtrl.includeDuplicateStamp,
                    onChanged: (value) => _invCtrl.updatePrintOptions(
                      copies: _invCtrl.printCopies,
                      duplicate: value,
                    ),
                    activeThumbColor: SalesPosColors.brandGold,
                    inactiveTrackColor: SalesPosColors.shellBg,
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
