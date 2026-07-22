part of 'silver_invoice_card.dart';

class _PurchaseTypeSelector extends StatelessWidget {
  final bool gstEnabled;
  final ValueChanged<bool> onChanged;

  const _PurchaseTypeSelector({
    required this.gstEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Purchase Type',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: SilverStockColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: SilverStockColors.cardBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: SilverStockColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PurchaseTypeButton(
                  selected: gstEnabled,
                  label: 'GST Purchase',
                  icon: Icons.verified_user_outlined,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _PurchaseTypeButton(
                  selected: !gstEnabled,
                  label: 'Non-GST / No ITC',
                  icon: Icons.receipt_outlined,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseTypeButton extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PurchaseTypeButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : SilverStockColors.textDark;
    final background =
        selected ? SilverStockColors.brandSilver : Colors.transparent;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierInvoiceInput extends StatelessWidget {
  final SilverStockController ctrl;
  final Color accent;

  const _SupplierInvoiceInput({
    required this.ctrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Supplier Invoice No.',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: SilverStockColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: TextFormField(
            controller: ctrl.supplierInvoiceNumberCtrl,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: SilverStockColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: 'Enter supplier invoice number',
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SilverStockColors.textHint,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(9),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 14,
                    color: accent,
                  ),
                ),
              ),
              filled: true,
              fillColor: SilverStockColors.cardBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: SilverStockColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(color: accent, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BillPhotoPicker extends StatelessWidget {
  final SilverStockController ctrl;
  final Color accent;

  const _BillPhotoPicker({
    required this.ctrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final photoPath = ctrl.billPhotoPath;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final canPreview = hasPhoto && File(photoPath).existsSync();
    final isPdf = hasPhoto && photoPath.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Supplier Bill',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: SilverStockColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            onPressed: ctrl.isPickingBillPhoto ? null : ctrl.pickBillPhoto,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              backgroundColor: SilverStockColors.cardBg,
              side: BorderSide(color: accent.withValues(alpha: 0.38)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctrl.isPickingBillPhoto)
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                else if (canPreview && !isPdf)
                  Container(
                    width: 22,
                    height: 22,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.file(File(photoPath), fit: BoxFit.cover),
                  )
                else if (isPdf)
                  Icon(Icons.picture_as_pdf_rounded, size: 17, color: accent)
                else
                  Icon(Icons.upload_file_rounded, size: 17, color: accent),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    hasPhoto ? 'Change Bill File' : 'Upload Bill / PDF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: ctrl.clearBillPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: SilverStockColors.danger,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final bool gstEnabled;

  const _Note({required this.gstEnabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note:',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: SilverStockColors.brandSilver,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            gstEnabled
                ? 'GST purchase keeps invoice number and bill file linked for ITC-safe records. Supplier GSTIN can be updated later from supplier profile.'
                : 'Non-GST purchases stay separate as No ITC records in supplier history.',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: SilverStockColors.textBody,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
