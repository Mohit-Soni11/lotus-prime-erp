part of 'supplier_profile_screen.dart';

class _BillDocumentCard extends StatelessWidget {
  final SupplierProfilePurchaseModel item;

  const _BillDocumentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final path = item.billPhotoPath;
    final exists = path != null && File(path).existsSync();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 124,
            height: 82,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: SupplierProfileColors.bodyBorder,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SupplierProfileColors.bodyBorder),
            ),
            child: exists
                ? Image.file(File(path), fit: BoxFit.cover)
                : const Icon(
                    SupplierProfileIcons.photo,
                    color: SupplierProfileColors.bodyTextMuted,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.voucherNo, style: SupplierProfileStyles.historyTitle),
                const SizedBox(height: 5),
                Text(
                  '${item.formattedDate} | Bill ${_money(item.grandTotal)}',
                  style: SupplierProfileStyles.historyMeta,
                ),
                const SizedBox(height: 10),
                _MiniBadge(
                  exists ? _fileName(path) : 'Photo path saved',
                  SupplierProfileColors.documentAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillThumb extends StatelessWidget {
  final String? path;

  const _BillThumb({this.path});

  @override
  Widget build(BuildContext context) {
    final exists = path != null && File(path!).existsSync();
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SupplierProfileColors.bodyBorder,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SupplierProfileColors.bodyBorder),
      ),
      child: exists
          ? Image.file(File(path!), fit: BoxFit.cover)
          : const Icon(
              SupplierProfileIcons.purchases,
              color: SupplierProfileColors.bodyTextMuted,
            ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: SupplierProfileStyles.tintedPanel(color),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SupplierProfileStyles.chipText.copyWith(color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Column(
        children: [
          Icon(icon, size: 38, color: SupplierProfileColors.bodyTextMuted),
          const SizedBox(height: 12),
          Text(title, style: SupplierProfileStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: SupplierProfileStyles.historyMeta,
          ),
        ],
      ),
    );
  }
}
