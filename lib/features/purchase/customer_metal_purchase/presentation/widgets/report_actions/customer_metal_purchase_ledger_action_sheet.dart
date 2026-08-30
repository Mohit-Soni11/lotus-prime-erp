part of 'customer_metal_purchase_ledger_actions.dart';

class _PdfStylePreferences {
  final String selectedTemplateId;
  final Map<String, PurchaseBillingModel> displaySettings;

  const _PdfStylePreferences({
    required this.selectedTemplateId,
    required this.displaySettings,
  });
}

class _LedgerActionSheet extends StatefulWidget {
  final BuildContext parentContext;
  final CustomerMetalPurchaseEntry entry;

  const _LedgerActionSheet({
    required this.parentContext,
    required this.entry,
  });

  @override
  State<_LedgerActionSheet> createState() => _LedgerActionSheetState();
}

class _LedgerActionSheetState extends State<_LedgerActionSheet> {
  late final Future<_PdfStylePreferences> _stylePreferencesFuture;
  String _selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
  Map<String, PurchaseBillingModel> _displaySettings =
      const <String, PurchaseBillingModel>{};

  @override
  void initState() {
    super.initState();
    _stylePreferencesFuture =
        CustomerMetalPurchaseLedgerActions._loadPdfStylePreferences(
      widget.entry,
    )..then((preferences) {
            if (!mounted) return;
            setState(() {
              _selectedTemplateId = preferences.selectedTemplateId;
              _displaySettings = preferences.displaySettings;
            });
          });
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.entry.hasSellerPhoto;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PurchaseEntryColors.bodyBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PurchaseEntryColors.purchaseAccent.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: PurchaseEntryColors.purchaseAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.referenceNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: PurchaseEntryColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.entry.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.black,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<_PdfStylePreferences>(
                future: _stylePreferencesFuture,
                builder: (context, snapshot) {
                  return _PdfTemplateSelector(
                    selectedTemplateId: _selectedTemplateId,
                    isLoading: snapshot.connectionState != ConnectionState.done,
                    onChanged: _selectTemplate,
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SheetActionButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'View PDF',
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.viewPdf(
                        widget.parentContext,
                        widget.entry,
                        templateId: _selectedTemplateId,
                        displaySettings: _displaySettings,
                      );
                    },
                  ),
                  _SheetActionButton(
                    icon: Icons.image_rounded,
                    label: 'View Photo',
                    enabled: hasPhoto,
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.viewPhoto(
                        widget.parentContext,
                        widget.entry,
                      );
                    },
                  ),
                  _SheetActionButton(
                    icon: Icons.download_rounded,
                    label: 'Download PDF',
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.downloadPdf(
                        widget.parentContext,
                        widget.entry,
                        templateId: _selectedTemplateId,
                        displaySettings: _displaySettings,
                      );
                    },
                  ),
                  _SheetActionButton(
                    icon: Icons.print_rounded,
                    label: 'Print PDF',
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.printPdf(
                        widget.parentContext,
                        widget.entry,
                        templateId: _selectedTemplateId,
                        displaySettings: _displaySettings,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId =
          CustomerMetalPurchaseLedgerActions._resolveTemplateId(templateId);
    });
  }
}
