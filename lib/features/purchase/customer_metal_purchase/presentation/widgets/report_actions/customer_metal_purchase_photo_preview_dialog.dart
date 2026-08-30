part of 'customer_metal_purchase_ledger_actions.dart';

class _SellerPhotoPreviewDialog extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final File photo;

  const _SellerPhotoPreviewDialog({
    required this.entry,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PhotoHeader(entry: entry),
            Flexible(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF8FAFC),
                child: Image.file(photo, fit: BoxFit.contain),
              ),
            ),
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _PreviewActionButton(
                    icon: Icons.print_rounded,
                    label: 'Print Photo',
                    onPressed: () =>
                        CustomerMetalPurchaseLedgerActions.printPhoto(
                      context,
                      entry,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;

  const _PhotoHeader({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: PurchaseEntryColors.bodyBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_rounded,
              color: PurchaseEntryColors.purchaseAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${entry.customerName} Photo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: PurchaseEntryColors.textMain,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
