part of '../../inventory_screen.dart';

class _InventoryBatchDossierScreen extends StatefulWidget {
  final AppDatabase db;
  final StockCategory metal;
  final _InventoryGradeSummary grade;
  final _InventoryBatchGroup batch;

  const _InventoryBatchDossierScreen({
    required this.db,
    required this.metal,
    required this.grade,
    required this.batch,
  });

  @override
  State<_InventoryBatchDossierScreen> createState() =>
      _InventoryBatchDossierScreenState();
}

class _InventoryBatchDossierScreenState
    extends State<_InventoryBatchDossierScreen> {
  bool _closingVariance = false;

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(widget.metal);
    final title = widget.batch.sourceDocumentLabel;

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
                batch: widget.batch,
                metal: widget.metal,
                onDocuments: () => _openDocumentCenter(context),
                onCloseVariance: widget.batch.hasScaleVariance
                    ? () => _closeVariance(context)
                    : null,
                isClosingVariance: _closingVariance,
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
                        child: _BatchOverviewPanel(
                          batch: widget.batch,
                          metal: widget.metal,
                          ui: ui,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BatchPaymentPanel(batch: widget.batch, ui: ui),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.batch.payment.hasAttachment) ...[
                    _BatchDocumentPanel(batch: widget.batch, ui: ui),
                    const SizedBox(height: 16),
                  ],
                  _BatchStockLedgerPanel(batch: widget.batch, ui: ui),
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
      metal: widget.metal,
      grade: widget.grade,
      batch: widget.batch,
      type: type,
    );
    await Printing.layoutPdf(
      name: _batchPdfFileName(widget.batch, type),
      onLayout: (_) async => bytes,
    );
  }

  void _viewDocument(BuildContext context, _InventoryBatchDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _InventoryBatchPdfPreviewScreen(
          metal: widget.metal,
          grade: widget.grade,
          batch: widget.batch,
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
      fileName: _batchPdfFileName(widget.batch, type),
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
      metal: widget.metal,
      grade: widget.grade,
      batch: widget.batch,
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

  Future<void> _closeVariance(BuildContext context) async {
    if (_closingVariance || !widget.batch.hasScaleVariance) return;
    final reason = await _showCloseVarianceDialog(context);
    if (reason == null || !mounted || !context.mounted) return;

    setState(() => _closingVariance = true);
    try {
      final lines =
          widget.batch.units.where((unit) => unit.hasScaleVariance).map((unit) {
        final delta = -unit.scaleVarianceWeight;
        final purityFactor =
            unit.totalPurityPercent > 0 ? unit.totalPurityPercent / 100.0 : 0.0;
        return InventoryWeightVarianceLine(
          stockItemId: unit.stockItemId,
          unitId: unit.unitId,
          unitCode: unit.unitCode,
          metalType: widget.metal.label,
          itemName: unit.itemName,
          netWeightDelta: delta,
          fineWeightDelta: delta * purityFactor,
        );
      }).toList(growable: false);
      await InventoryWeightReconciliationService(widget.db).closeBatchVariance(
        batchCode: widget.batch.batchCode,
        lines: lines,
        reason: reason,
      );
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Weight variance closed with audit record.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _closingVariance = false);
    }
  }

  Future<String?> _showCloseVarianceDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'Scale variance accepted after physical verification',
    );
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Close Weight Variance',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VarianceDialogMetric(
                  label: 'Open Variance',
                  value: widget.batch.scaleVarianceLabel,
                  accent: widget.batch.hasResidualWeight
                      ? InvColors.warning
                      : InvColors.danger,
                ),
                const SizedBox(height: 12),
                Text(
                  'This will keep the purchase record intact and post an audited stock reconciliation movement for this batch.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textBody,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 3,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Reconciliation Note',
                    hintText: 'Machine variation, physical verification note',
                    filled: true,
                    fillColor: const Color(0xFFFAF7EF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: InvColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: InvColors.brandGold,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.length < 3) return;
                Navigator.of(dialogContext).pop(reason);
              },
              icon: const Icon(Icons.fact_check_rounded, size: 18),
              label: const Text('Close Variance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: InvColors.warning,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }
}

class _VarianceDialogMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _VarianceDialogMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.scale_rounded, color: accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: InvColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
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
