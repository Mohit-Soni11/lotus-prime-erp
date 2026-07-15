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
}

class _BatchDossierHeader extends StatelessWidget {
  final StockMetalUiData ui;
  final String title;
  final _InventoryBatchGroup batch;
  final VoidCallback onDocuments;

  const _BatchDossierHeader({
    required this.ui,
    required this.title,
    required this.batch,
    required this.onDocuments,
  });

  @override
  Widget build(BuildContext context) {
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
    return _DossierPanel(
      icon: Icons.view_list_rounded,
      title: 'Batch Item Ledger',
      subtitle: 'Available and sold stock units from this batch',
      accent: ui.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 1180
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final unit in batch.units)
                SizedBox(
                  width: itemWidth,
                  child: _InventoryGradeUnitCard(unit: unit, ui: ui),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DossierPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  const _DossierPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: InvColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DossierMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DossierMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DossierInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DossierInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: InvColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DossierActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  const _DossierActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? accent : InvColors.textHint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 17, color: enabled ? Colors.white : InvColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: enabled ? Colors.white : InvColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderGstTag extends StatelessWidget {
  final Color textColor;

  const _HeaderGstTag({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
      ),
      child: Text(
        'GST',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
