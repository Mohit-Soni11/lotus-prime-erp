part of '../stock_search_screen.dart';

void _showStockDetail(
  BuildContext context,
  StockSearchResult item, {
  VoidCallback? onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: _StockDetailDossier(item: item, onChanged: onChanged),
      );
    },
  );
}

class _StockDetailDossier extends StatelessWidget {
  final StockSearchResult item;
  final VoidCallback? onChanged;

  const _StockDetailDossier({required this.item, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1060, maxHeight: 760),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: InvColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 34,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _StockDossierHeader(item: item),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DetailSection(
                              title: 'Stock Identity',
                              icon: Icons.qr_code_2_rounded,
                              children: [
                                _DetailTile(
                                  label: 'HUID / Serial',
                                  value:
                                      item.hasHuid ? item.huid : item.unitCode,
                                ),
                                _DetailTile(
                                    label: 'Unit Code', value: item.unitCode),
                                _DetailTile(
                                  label: 'Batch Code',
                                  value: item.inventoryBatchCode,
                                ),
                                _DetailTile(
                                    label: 'Piece No.',
                                    value: item.pieceNo.toString()),
                                _DetailTile(
                                    label: 'Status', value: item.status),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _DetailSection(
                              title: 'Item Classification',
                              icon: Icons.category_rounded,
                              children: [
                                _DetailTile(
                                    label: 'Metal',
                                    value: _clean(item.metalType)),
                                _DetailTile(
                                    label: 'Item Type',
                                    value: _clean(item.itemType)),
                                _DetailTile(
                                    label: 'Segment',
                                    value: _clean(item.segment)),
                                _DetailTile(
                                    label: 'Tracking',
                                    value: item.trackingLabel),
                                _DetailTile(
                                    label: 'Created',
                                    value: _formatDateTime(item.createdAt)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _DetailSection(
                        title: 'Weight & Purity',
                        icon: Icons.scale_rounded,
                        children: [
                          _DetailTile(
                              label: 'Gross Weight',
                              value: _grams(item.grossWeight)),
                          _DetailTile(
                              label: 'Less Weight',
                              value: _grams(item.lessWeight)),
                          _DetailTile(
                              label: 'Net Weight',
                              value: _grams(item.netWeight)),
                          _DetailTile(
                              label: 'Purity',
                              value: _percent(item.purityPercent)),
                          _DetailTile(
                              label: 'Actual Fine',
                              value: _grams(item.actualFineWeight)),
                          _DetailTile(
                              label: 'Valuation Fine',
                              value: _grams(item.valuationFineWeight)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _PurchaseSection(item: item)),
                          const SizedBox(width: 14),
                          Expanded(child: _SaleSection(item: item)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _UnitMovementHistorySection(item: item),
                      const SizedBox(height: 14),
                      _StockLifecycleActionSection(
                        item: item,
                        onChanged: onChanged,
                      ),
                    ],
                  ),
                ),
              ),
              _StockDossierActions(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockDossierHeader extends StatelessWidget {
  final StockSearchResult item;

  const _StockDossierHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isSold ? InvColors.danger : InvColors.success;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF4C4), Color(0xFFD8B12C)],
        ),
      ),
      child: Row(
        children: [
          _MetalAvatar(metal: item.metalType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2B2106),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.metalType.toUpperCase()} • ${item.trackingLabel} • ${item.inventoryBatchCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5D4A15),
                  ),
                ),
              ],
            ),
          ),
          _HeaderPill(
            label: item.status.toUpperCase(),
            value:
                item.isSold ? _formatDateTime(item.soldAt) : 'Ready for sale',
            color: statusColor,
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF2B2106)),
          ),
        ],
      ),
    );
  }
}

class _PurchaseSection extends StatelessWidget {
  final StockSearchResult item;

  const _PurchaseSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Purchase Source',
      icon: Icons.receipt_long_rounded,
      children: [
        _DetailTile(label: 'Supplier', value: _clean(item.supplierName)),
        _DetailTile(label: 'Supplier Invoice', value: item.sourceInvoice),
        _DetailTile(label: 'Purchase Tax Type', value: _clean(item.taxType)),
        _DetailTile(
            label: 'Batch Date', value: _formatDateTime(item.createdAt)),
      ],
    );
  }
}

class _SaleSection extends StatelessWidget {
  final StockSearchResult item;

  const _SaleSection({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!item.isSold && item.soldBillNo.isEmpty) {
      return const _DetailSection(
        title: 'Sale Status',
        icon: Icons.point_of_sale_rounded,
        children: [
          _DetailTile(label: 'Sale Invoice', value: 'Not sold yet'),
          _DetailTile(label: 'Customer', value: 'Stock is currently available'),
          _DetailTile(label: 'Sale Date', value: 'Not recorded'),
          _DetailTile(label: 'Stock Status', value: 'Ready for sale'),
        ],
      );
    }

    return _DetailSection(
      title: 'Sale Status',
      icon: Icons.point_of_sale_rounded,
      accent: InvColors.danger,
      background: const Color(0xFFFFF7F7),
      children: [
        _DetailTile(label: 'Sale Invoice', value: _clean(item.soldBillNo)),
        _DetailTile(label: 'Customer', value: _clean(item.soldCustomerName)),
        _DetailTile(
            label: 'Sale Date',
            value: _formatDateTime(item.soldBillDate ?? item.soldAt)),
        _DetailTile(
            label: 'Bill Amount',
            value: _currencyFormat.format(item.soldBillAmount)),
        _DetailTile(label: 'Stock Status', value: item.status),
      ],
    );
  }
}
