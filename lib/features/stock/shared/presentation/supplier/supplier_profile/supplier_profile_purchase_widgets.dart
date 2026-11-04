part of 'supplier_profile_screen.dart';

class _PurchaseHistoryCard extends StatelessWidget {
  final SupplierProfilePurchaseModel item;
  final bool highlighted;

  const _PurchaseHistoryCard({required this.item, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final dueColor = item.hasDue
        ? SupplierProfileColors.warning
        : SupplierProfileColors.success;
    final taxColor = item.isGstPurchase
        ? SupplierProfileColors.info
        : SupplierProfileColors.bodyTextMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: highlighted
          ? SupplierProfileStyles.softPanelDecoration.copyWith(
              border: Border.all(
                color: SupplierProfileColors.brandGold,
                width: 2,
              ),
            )
          : SupplierProfileStyles.softPanelDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BillThumb(path: item.billPhotoPath),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.voucherNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SupplierProfileStyles.historyTitle,
                      ),
                    ),
                    _MiniBadge(
                      item.isGstPurchase ? 'GST' : 'No ITC',
                      taxColor,
                    ),
                    const SizedBox(width: 8),
                    _MiniBadge(item.statusLabel, dueColor),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    item.formattedDate,
                    if ((item.supplierInvoiceNo ?? '').trim().isNotEmpty)
                      'Supplier bill ${item.supplierInvoiceNo}',
                  ].join(' | '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.historyMeta,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(
                      'Bill ${_money(item.grandTotal)}',
                      SupplierProfileColors.brandGold,
                    ),
                    _MiniBadge(
                      'Paid ${_money(item.totalPaid)}',
                      SupplierProfileColors.success,
                    ),
                    _MiniBadge(
                      'Baki ${_money(item.balanceDue)}',
                      dueColor,
                    ),
                    if (item.hasOldDueAdjustment)
                      _MiniBadge(
                        'Old due adjusted ${_money(item.oldDueAdjustedAmount)}',
                        SupplierProfileColors.success,
                      ),
                    if (item.hasMetalSettlement)
                      _MiniBadge(
                        '${_weight(item.metalPaidFine)} g fine',
                        SupplierProfileColors.metalText,
                      ),
                    if (item.hasMetalFineDue)
                      _MiniBadge(
                        'Fine due ${_weight(item.metalFineDue)} g',
                        dueColor,
                      ),
                    if (item.hasMetalFineCredit)
                      _MiniBadge(
                        'Fine credit ${_weight(item.metalFineCredit)} g',
                        SupplierProfileColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
