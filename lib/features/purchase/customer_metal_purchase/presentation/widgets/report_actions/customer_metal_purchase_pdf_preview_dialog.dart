part of 'customer_metal_purchase_ledger_actions.dart';

class _LedgerPdfPreviewDialog extends StatefulWidget {
  final CustomerMetalPurchaseEntry entry;
  final String? initialTemplateId;
  final Map<String, PurchaseBillingModel>? initialDisplaySettings;

  const _LedgerPdfPreviewDialog({
    required this.entry,
    required this.initialTemplateId,
    required this.initialDisplaySettings,
  });

  @override
  State<_LedgerPdfPreviewDialog> createState() =>
      _LedgerPdfPreviewDialogState();
}

class _LedgerPdfPreviewDialogState extends State<_LedgerPdfPreviewDialog> {
  late final Future<_PdfStylePreferences> _stylePreferencesFuture;
  late String _selectedTemplateId;
  late Map<String, PurchaseBillingModel> _displaySettings;
  late Future<Uint8List> _pdfBytes;

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = CustomerMetalPurchaseLedgerActions._resolveTemplateId(
      widget.initialTemplateId ?? PrintTemplateRegistry.defaultTemplateId,
    );
    _displaySettings =
        widget.initialDisplaySettings ?? const <String, PurchaseBillingModel>{};
    _stylePreferencesFuture =
        CustomerMetalPurchaseLedgerActions._loadPdfStylePreferences(
      widget.entry,
    )..then((preferences) {
            if (!mounted) return;
            if (widget.initialTemplateId != null) {
              setState(() => _displaySettings = preferences.displaySettings);
              return;
            }
            setState(() {
              _selectedTemplateId = preferences.selectedTemplateId;
              _displaySettings = preferences.displaySettings;
              _pdfBytes = _buildPdfBytes();
            });
          });
    _pdfBytes = _buildPdfBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: PurchaseEntryColors.bodyPanel,
      child: Column(
        children: [
          _PreviewHeader(
            entry: widget.entry,
            selectedTemplateId: _selectedTemplateId,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: PurchaseEntryColors.bodyBorder),
              ),
            ),
            child: FutureBuilder<_PdfStylePreferences>(
              future: _stylePreferencesFuture,
              builder: (context, snapshot) {
                return _PdfTemplateSelector(
                  selectedTemplateId: _selectedTemplateId,
                  isLoading: snapshot.connectionState != ConnectionState.done,
                  onChanged: _selectTemplate,
                );
              },
            ),
          ),
          Expanded(
            child: PdfPreview(
              key: ValueKey(_selectedTemplateId),
              build: (_) => _pdfBytes,
              initialPageFormat: PdfPageFormat.a4,
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              useActions: false,
              maxPageWidth: 980,
              pdfFileName: CustomerMetalPurchaseLedgerActions._pdfFileName(
                widget.entry,
                templateId: _selectedTemplateId,
              ),
              scrollViewDecoration: const BoxDecoration(
                color: PurchaseEntryColors.bodyBg,
              ),
            ),
          ),
          _PreviewBottomBar(
            entry: widget.entry,
            selectedTemplateId: _selectedTemplateId,
            displaySettings: _displaySettings,
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildPdfBytes() {
    return CustomerMetalPurchaseLedgerActions._buildInvoiceBytes(
      widget.entry,
      templateId: _selectedTemplateId,
      displaySettings: _displaySettings,
    );
  }

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId =
          CustomerMetalPurchaseLedgerActions._resolveTemplateId(templateId);
      _pdfBytes = _buildPdfBytes();
    });
  }
}

class _PreviewHeader extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final String selectedTemplateId;

  const _PreviewHeader({
    required this.entry,
    required this.selectedTemplateId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: PurchaseEntryColors.shellBorder),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: PurchaseEntryColors.purchaseAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Metal Purchase PDF',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${entry.referenceNo} • ${entry.customerName} • ${PrintTemplateRegistry.labelFor(selectedTemplateId)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PurchaseEntryColors.shellMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close preview',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PreviewBottomBar extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final String selectedTemplateId;
  final Map<String, PurchaseBillingModel> displaySettings;

  const _PreviewBottomBar({
    required this.entry,
    required this.selectedTemplateId,
    required this.displaySettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PurchaseEntryColors.bodyBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _PreviewActionButton(
            icon: Icons.image_rounded,
            label: 'Print Photo',
            enabled: entry.hasSellerPhoto,
            onPressed: () => CustomerMetalPurchaseLedgerActions.printPhoto(
              context,
              entry,
            ),
          ),
          const SizedBox(width: 10),
          _PreviewActionButton(
            icon: Icons.download_rounded,
            label: 'Download PDF',
            onPressed: () => CustomerMetalPurchaseLedgerActions.downloadPdf(
              context,
              entry,
              templateId: selectedTemplateId,
              displaySettings: displaySettings,
            ),
          ),
          const SizedBox(width: 10),
          _PreviewActionButton(
            icon: Icons.print_rounded,
            label: 'Print PDF',
            onPressed: () => CustomerMetalPurchaseLedgerActions.printPdf(
              context,
              entry,
              templateId: selectedTemplateId,
              displaySettings: displaySettings,
            ),
          ),
        ],
      ),
    );
  }
}
