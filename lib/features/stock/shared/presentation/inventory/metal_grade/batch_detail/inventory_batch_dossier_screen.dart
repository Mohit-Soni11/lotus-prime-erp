part of '../../inventory_screen.dart';

class _InventoryBatchDossierScreen extends StatelessWidget {
  final StockCategory metal;
  final _InventoryGradeSummary grade;
  final _InventoryBatchGroup batch;

  const _InventoryBatchDossierScreen({
    required this.metal,
    required this.grade,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(metal);
    final title = _inventoryGradeTitle(metal, grade.gradeLabel);

    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: _BatchDossierHeader(
                ui: ui,
                title: title,
                batch: batch,
                onDocuments: () => _openDocumentCenter(context),
                onCleanup: () => _openCleanupCenter(context),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BatchOverviewPanel(batch: batch, ui: ui),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BatchPaymentPanel(batch: batch, ui: ui),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BatchDocumentPanel(batch: batch, ui: ui),
                  const SizedBox(height: 16),
                  _BatchStockLedgerPanel(batch: batch, ui: ui),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printDocument(_InventoryBatchDocumentType type) async {
    final bytes = await _buildBatchPdfBytes(
      metal: metal,
      grade: grade,
      batch: batch,
      type: type,
    );
    await Printing.layoutPdf(
      name: _batchPdfFileName(batch, type),
      onLayout: (_) async => bytes,
    );
  }

  void _viewDocument(BuildContext context, _InventoryBatchDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _InventoryBatchPdfPreviewScreen(
          metal: metal,
          grade: grade,
          batch: batch,
          type: type,
        ),
      ),
    );
  }

  Future<void> _downloadDocument(
    BuildContext context,
    _InventoryBatchDocumentType type,
  ) async {
    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Download ${type.title}',
      fileName: _batchPdfFileName(batch, type),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );
    if (selectedPath == null) return;

    final exportPath = selectedPath.toLowerCase().endsWith('.pdf')
        ? selectedPath
        : '$selectedPath.pdf';
    final file = File(exportPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final bytes = await _buildBatchPdfBytes(
      metal: metal,
      grade: grade,
      batch: batch,
      type: type,
    );
    await file.writeAsBytes(bytes);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Batch dossier saved: ${file.path}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openDocumentCenter(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _InventoryBatchDocumentDialog(
        onView: (type) {
          Navigator.of(dialogContext).pop();
          _viewDocument(context, type);
        },
        onPrint: (type) {
          Navigator.of(dialogContext).pop();
          _printDocument(type);
        },
        onDownload: (type) {
          Navigator.of(dialogContext).pop();
          _downloadDocument(context, type);
        },
      ),
    );
  }

  void _openCleanupCenter(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _InventoryBatchCleanupDialog(
        batchCode: batch.batchCode,
        onCleanupConfirmed: () async {
          final service = InventoryBatchCleanupService(AppDatabase());
          final result = await service.deleteSafeTestBatch(batch.batchCode);
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cleaned ${result.batchCode}: ${result.removedUnits} stock unit(s) removed.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}

class _BatchDossierHeader extends StatelessWidget {
  final StockMetalUiData ui;
  final String title;
  final _InventoryBatchGroup batch;
  final VoidCallback onDocuments;
  final VoidCallback onCleanup;

  const _BatchDossierHeader({
    required this.ui,
    required this.title,
    required this.batch,
    required this.onDocuments,
    required this.onCleanup,
  });

  @override
  Widget build(BuildContext context) {
    final statusAccent = _dossierBatchStatusAccent(batch);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: ui.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
            ),
            child: Icon(ui.icon, color: ui.textOnGradient, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        batch.batchCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: ui.textOnGradient,
                        ),
                      ),
                    ),
                    if (batch.isGst) ...[
                      const SizedBox(width: 10),
                      _HeaderGstTag(textColor: ui.textOnGradient),
                    ],
                    const SizedBox(width: 10),
                    _DossierHeaderStatusTag(
                      label: batch.stockStatusLabel,
                      accent: statusAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$title - complete batch dossier',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ui.textOnGradient.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderMetric(
                label: 'Items',
                value: '${batch.availableItems}/${batch.totalItems}',
                textColor: ui.textOnGradient,
              ),
              _HeaderMetric(
                label: 'Stock Status',
                value: batch.stockStatusLabel,
                textColor: ui.textOnGradient,
              ),
              _HeaderMetric(
                label: 'Actual Fine',
                value: '${_weight(batch.actualFine)} g',
                textColor: ui.textOnGradient,
              ),
              _HeaderActionButton(
                label: 'Documents',
                icon: Icons.description_rounded,
                textColor: ui.textOnGradient,
                onTap: onDocuments,
              ),
              _HeaderActionButton(
                label: 'Cleanup',
                icon: Icons.cleaning_services_rounded,
                textColor: ui.textOnGradient,
                onTap: onCleanup,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryBatchPdfPreviewScreen extends StatelessWidget {
  final StockCategory metal;
  final _InventoryGradeSummary grade;
  final _InventoryBatchGroup batch;
  final _InventoryBatchDocumentType type;

  const _InventoryBatchPdfPreviewScreen({
    required this.metal,
    required this.grade,
    required this.batch,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _InventoryAppBar(onBack: () => Navigator.of(context).maybePop()),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: _batchPdfFileName(batch, type),
        build: (_) => _buildBatchPdfBytes(
          metal: metal,
          grade: grade,
          batch: batch,
          type: type,
        ),
      ),
    );
  }
}

class _InventoryBatchDocumentDialog extends StatelessWidget {
  final ValueChanged<_InventoryBatchDocumentType> onView;
  final ValueChanged<_InventoryBatchDocumentType> onPrint;
  final ValueChanged<_InventoryBatchDocumentType> onDownload;

  const _InventoryBatchDocumentDialog({
    required this.onView,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: InvColors.brandGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: InvColors.brandGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Documents',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: InvColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Preview, print or download professional inventory PDFs.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: InvColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final type in _InventoryBatchDocumentType.values) ...[
                _InventoryBatchDocumentOption(
                  type: type,
                  onView: () => onView(type),
                  onPrint: () => onPrint(type),
                  onDownload: () => onDownload(type),
                ),
                if (type != _InventoryBatchDocumentType.values.last)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryBatchDocumentOption extends StatelessWidget {
  final _InventoryBatchDocumentType type;
  final VoidCallback onView;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  const _InventoryBatchDocumentOption({
    required this.type,
    required this.onView,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: InvColors.brandGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              type == _InventoryBatchDocumentType.fullDossier
                  ? Icons.assignment_rounded
                  : Icons.fact_check_rounded,
              color: InvColors.brandGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _DocumentMiniAction(
            label: 'View',
            icon: Icons.visibility_rounded,
            onTap: onView,
          ),
          const SizedBox(width: 8),
          _DocumentMiniAction(
            label: 'Print',
            icon: Icons.print_rounded,
            onTap: onPrint,
          ),
          const SizedBox(width: 8),
          _DocumentMiniAction(
            label: 'Download',
            icon: Icons.download_rounded,
            onTap: onDownload,
          ),
        ],
      ),
    );
  }
}

class _DocumentMiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DocumentMiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: InvColors.brandGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: InvColors.brandGold.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: InvColors.brandGold),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchOverviewPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchOverviewPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final statusAccent = _dossierBatchStatusAccent(batch);
    return _DossierPanel(
      icon: Icons.inventory_2_rounded,
      title: 'Batch Overview',
      subtitle: 'Supplier, invoice and stock status',
      accent: ui.accent,
      child: Column(
        children: [
          _DossierInfoRow(label: 'Supplier', value: _dash(batch.supplierName)),
          _DossierInfoRow(
            label: 'Supplier Invoice',
            value: _dash(batch.supplierInvoiceNo),
          ),
          _DossierInfoRow(
              label: 'Purchase Type',
              value: batch.isGst ? 'GST Purchase' : 'Non-GST Purchase'),
          _DossierInfoRow(
            label: 'Batch Date',
            value: batch.createdAt > 0
                ? DateFormat('dd MMM yyyy').format(
                    DateTime.fromMillisecondsSinceEpoch(batch.createdAt),
                  )
                : 'Not recorded',
          ),
          _DossierInfoRow(
            label: 'Stock Status',
            value: batch.stockStatusLabel,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DossierMetric(
                  label: 'Total Items',
                  value: '${batch.totalItems} pcs',
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Available',
                  value: '${batch.availableItems} pcs',
                  accent: InvColors.success),
              _DossierMetric(
                  label: 'Sold',
                  value: '${batch.totalItems - batch.availableItems} pcs',
                  accent: InvColors.danger),
              _DossierMetric(
                  label: 'Stock Status',
                  value: batch.stockStatusLabel,
                  accent: statusAccent),
              _DossierMetric(
                  label: 'Gross Wt',
                  value: '${_weight(batch.grossWeight)} g',
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Net Wt',
                  value: '${_weight(batch.netWeight)} g',
                  accent: const Color(0xFF0F766E)),
              _DossierMetric(
                  label: 'Purity',
                  value: '${_percent(batch.purityPercent)}%',
                  accent: const Color(0xFF2563EB)),
              _DossierMetric(
                  label: 'Wastage',
                  value: '${_percent(batch.wastagePercent)}%',
                  accent: const Color(0xFFF59E0B)),
              _DossierMetric(
                  label: 'Actual Fine',
                  value: '${_weight(batch.actualFine)} g',
                  accent: InvColors.success),
              _DossierMetric(
                  label: 'Wastage Fine',
                  value: '${_weight(batch.wastageFine)} g',
                  accent: const Color(0xFFF59E0B)),
              _DossierMetric(
                  label: 'Valuation Fine',
                  value: '${_weight(batch.valuationFine)} g',
                  accent: InvColors.brandGold),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color textColor;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchPaymentPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchPaymentPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final payment = batch.payment;
    return _DossierPanel(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Payment Summary',
      subtitle: 'Cash, metal, GST, due and return snapshot',
      accent: ui.accent,
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DossierMetric(
                  label: 'Final Bill',
                  value: _money(payment.grandTotal),
                  accent: ui.accent),
              _DossierMetric(
                  label: 'Total Paid',
                  value: _money(payment.totalPaid),
                  accent: InvColors.success),
              _DossierMetric(
                  label: 'Cash Due',
                  value: _money(payment.balanceDue),
                  accent: payment.balanceDue > 0
                      ? InvColors.danger
                      : InvColors.success),
              _DossierMetric(
                  label: 'Metal Paid',
                  value: '${_weight(payment.metalPaidFine)} g',
                  accent: InvColors.brandGold),
              _DossierMetric(
                  label: 'Fine Due',
                  value: '${_weight(payment.fineDueWeight)} g',
                  accent: payment.fineDueWeight > 0
                      ? InvColors.danger
                      : InvColors.success),
              _DossierMetric(
                  label: 'Fine Return',
                  value: '${_weight(payment.fineReturnWeight)} g',
                  accent: const Color(0xFF0F766E)),
            ],
          ),
          const SizedBox(height: 12),
          _DossierInfoRow(label: 'Cash', value: _money(payment.cashPaid)),
          _DossierInfoRow(label: 'UPI', value: _money(payment.upiPaid)),
          _DossierInfoRow(label: 'Bank', value: _money(payment.bankPaid)),
          _DossierInfoRow(label: 'Card', value: _money(payment.cardPaid)),
          if (batch.isGst) ...[
            _DossierInfoRow(
                label: 'GST Total', value: _money(payment.gstAmount)),
            _DossierInfoRow(
                label: 'CGST / SGST',
                value:
                    '${_money(payment.cgstAmount)} / ${_money(payment.sgstAmount)}'),
          ],
          _DossierInfoRow(label: 'Status', value: _dash(payment.paymentStatus)),
        ],
      ),
    );
  }
}

class _BatchDocumentPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchDocumentPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final path = batch.payment.attachmentPath.trim();
    return _DossierPanel(
      icon: Icons.attach_file_rounded,
      title: 'Supplier Bill Document',
      subtitle: 'View or locate the bill attached during stock intake',
      accent: ui.accent,
      child: Row(
        children: [
          Expanded(
            child: Text(
              path.isEmpty
                  ? 'No supplier bill attachment is linked with this batch.'
                  : path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: path.isEmpty ? InvColors.textMuted : InvColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _DossierActionButton(
            label: 'Open Bill',
            icon: Icons.open_in_new_rounded,
            accent: ui.accent,
            enabled: path.isNotEmpty,
            onTap: () => _openLocalPath(path),
          ),
          const SizedBox(width: 10),
          _DossierActionButton(
            label: 'Show File',
            icon: Icons.folder_open_rounded,
            accent: ui.accent,
            enabled: path.isNotEmpty,
            onTap: () => _showLocalFile(path),
          ),
        ],
      ),
    );
  }
}

class _BatchStockLedgerPanel extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;

  const _BatchStockLedgerPanel({
    required this.batch,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final availableUnits = batch.units
        .where((unit) => unit.status.toLowerCase() == 'available')
        .toList();
    final soldUnits = batch.units
        .where((unit) => unit.status.toLowerCase() != 'available')
        .toList();
    return _DossierPanel(
      icon: Icons.view_list_rounded,
      title: 'Batch Item Ledger',
      subtitle: '${batch.stockStatusLabel} stock movement from this batch',
      accent: ui.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 1180
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (availableUnits.isNotEmpty)
                _DossierLedgerSection(
                  title: 'Available Stock Units',
                  subtitle: 'Ready for sale and stock movement',
                  units: availableUnits,
                  itemWidth: itemWidth,
                  ui: ui,
                  accent: InvColors.success,
                ),
              if (availableUnits.isNotEmpty && soldUnits.isNotEmpty)
                const SizedBox(height: 18),
              if (soldUnits.isNotEmpty)
                _DossierLedgerSection(
                  title: 'Sold Stock Units',
                  subtitle: 'Linked with sales invoices or closed movement',
                  units: soldUnits,
                  itemWidth: itemWidth,
                  ui: ui,
                  accent: InvColors.danger,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DossierLedgerSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_InventoryGradeUnit> units;
  final double itemWidth;
  final StockMetalUiData ui;
  final Color accent;

  const _DossierLedgerSection({
    required this.title,
    required this.subtitle,
    required this.units,
    required this.itemWidth,
    required this.ui,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Text(
                '${units.length} pcs',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: InvColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final unit in units)
              SizedBox(
                width: itemWidth,
                child: _InventoryGradeUnitCard(unit: unit, ui: ui),
              ),
          ],
        ),
      ],
    );
  }
}

Color _dossierBatchStatusAccent(_InventoryBatchGroup batch) {
  if (batch.isSoldOut) return InvColors.danger;
  if (batch.isPartiallySold) return const Color(0xFFF59E0B);
  return InvColors.success;
}
