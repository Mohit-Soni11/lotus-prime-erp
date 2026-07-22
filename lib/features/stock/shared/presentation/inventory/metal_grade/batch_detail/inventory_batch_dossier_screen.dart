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
