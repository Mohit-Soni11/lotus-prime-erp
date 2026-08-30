part of 'customer_metal_purchase_ledger_actions.dart';

class _PdfTemplateSelector extends StatelessWidget {
  final String selectedTemplateId;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  const _PdfTemplateSelector({
    required this.selectedTemplateId,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final templates = PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.purchaseVoucher,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PDF Style',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: PurchaseEntryColors.textMain,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PurchaseEntryColors.purchaseAccent,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final template in templates)
              _PdfTemplateChip(
                template: template,
                selected: template.id == selectedTemplateId,
                onTap: () => onChanged(template.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _PdfTemplateChip extends StatelessWidget {
  final PrintTemplateDefinition template;
  final bool selected;
  final VoidCallback onTap;

  const _PdfTemplateChip({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : PurchaseEntryColors.bodyBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.description_outlined,
                size: 16,
                color: selected
                    ? PurchaseEntryColors.purchaseAccent
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 7),
              Text(
                template.shortName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? PurchaseEntryColors.purchaseAccent
                      : PurchaseEntryColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
