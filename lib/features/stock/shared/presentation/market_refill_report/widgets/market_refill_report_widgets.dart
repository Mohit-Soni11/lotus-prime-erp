part of '../market_refill_report_screen.dart';

class _MarketRefillAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _MarketRefillAppBar({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<_MarketRefillAppBar> createState() => _MarketRefillAppBarState();
}

class _MarketRefillAppBarState extends State<_MarketRefillAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: InvColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: InvColors.shellBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _RefillShellButton(
              icon: Icons.arrow_back_rounded,
              onTap: widget.onBack,
            ),
            const SizedBox(width: 18),
            const _RefillDivider(),
            const SizedBox(width: 18),
            const _RefillAppIcon(),
            const SizedBox(width: 14),
            Text(
              'MARKET PURCHASE LIST',
              style: InvStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            _RefillShellButton(
              icon: Icons.refresh_rounded,
              onTap: widget.onRefresh,
            ),
            const SizedBox(width: 14),
            _RefillOnlineBadge(pulse: _pulse),
          ],
        ),
      ),
    );
  }
}

class _MarketRefillHero extends StatelessWidget {
  final MarketRefillReport report;
  final bool isExportEnabled;
  final bool canRestore;
  final VoidCallback onPreviewPdf;
  final VoidCallback onCheckout;
  final VoidCallback onRestore;

  const _MarketRefillHero({
    required this.report,
    required this.isExportEnabled,
    required this.canRestore,
    required this.onPreviewPdf,
    required this.onCheckout,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final summary = report.summary;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RefillIconBox(
                icon: Icons.storefront_rounded,
                accent: InvColors.brandGold,
                size: 58,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Purchase List',
                      style: GoogleFonts.manrope(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      report.lastClearedAt == null
                          ? 'All sold stock waiting for market purchase checkout.'
                          : 'Sold stock after last checkout: ${_date(report.lastClearedAt)}',
                      style: _refillMutedStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              _RefillPrimaryButton(
                label: 'Preview PDF',
                icon: Icons.picture_as_pdf_rounded,
                enabled: isExportEnabled,
                onTap: onPreviewPdf,
              ),
              const SizedBox(width: 10),
              _RefillSecondaryButton(
                label: 'Checkout Clear',
                icon: Icons.check_circle_rounded,
                enabled: isExportEnabled,
                onTap: onCheckout,
              ),
              if (canRestore) ...[
                const SizedBox(width: 10),
                _RefillSecondaryButton(
                  label: 'Restore List',
                  icon: Icons.restore_rounded,
                  enabled: true,
                  onTap: onRestore,
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _RefillHeroMetric(
                label: 'Sold',
                value: _formatQty(summary.soldQuantity, 'unit'),
                icon: Icons.point_of_sale_rounded,
                accent: InvColors.danger,
              ),
              _RefillHeroMetric(
                label: 'Items',
                value: '${summary.itemGroups} lines',
                icon: Icons.list_alt_rounded,
                accent: const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketRefillItemList extends StatelessWidget {
  final MarketRefillReport report;
  final Future<void> Function(
    MarketRefillItemRow row, {
    int? boughtQuantity,
    bool? purchaseDone,
  }) onProgressChanged;

  const _MarketRefillItemList({
    required this.report,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final goldRows = report.rows
        .where((row) => row.metal.trim().toLowerCase() == 'gold')
        .toList(growable: false);
    final silverRows = report.rows
        .where((row) => row.metal.trim().toLowerCase() == 'silver')
        .toList(growable: false);
    final otherRows = report.rows.where((row) {
      final metal = row.metal.trim().toLowerCase();
      return metal != 'gold' && metal != 'silver';
    }).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RefillIconBox(
                icon: Icons.fact_check_rounded,
                accent: InvColors.brandGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Ready List',
                      style: _refillStrongStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Export this list, purchase stock, then checkout-clear to start a fresh list.',
                      style: _refillMutedStyle(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (report.rows.isEmpty)
            const _RefillEmptyState(
              message: 'No sold items waiting for purchase checkout.',
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumn = constraints.maxWidth >= 920;
                if (!twoColumn) {
                  return Column(
                    children: [
                      _MetalPurchaseColumn(
                        title: 'Gold',
                        modeLabel: 'Grade wise',
                        rows: goldRows,
                        onProgressChanged: onProgressChanged,
                      ),
                      const SizedBox(height: 14),
                      _MetalPurchaseColumn(
                        title: 'Silver',
                        modeLabel: 'Company wise',
                        rows: silverRows,
                        onProgressChanged: onProgressChanged,
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetalPurchaseColumn(
                        title: 'Gold',
                        modeLabel: 'Grade wise',
                        rows: goldRows,
                        onProgressChanged: onProgressChanged,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MetalPurchaseColumn(
                        title: 'Silver',
                        modeLabel: 'Company wise',
                        rows: silverRows,
                        onProgressChanged: onProgressChanged,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (otherRows.isNotEmpty) ...[
              const SizedBox(height: 14),
              _MetalPurchaseColumn(
                title: 'Other',
                modeLabel: 'Group wise',
                rows: otherRows,
                onProgressChanged: onProgressChanged,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MarketRefillHistoryPanel extends StatelessWidget {
  final List<MarketRefillCheckoutRecord> records;

  const _MarketRefillHistoryPanel({required this.records});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RefillIconBox(
                icon: Icons.history_rounded,
                accent: InvColors.brandGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checkout History',
                      style: _refillStrongStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Temporary checkout records auto-clean after 2 days.',
                      style: _refillMutedStyle(),
                    ),
                  ],
                ),
              ),
              _RefillBadge(
                label: '${records.length} records',
                accent: InvColors.brandGold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            const _RefillEmptyState(message: 'No checkout history yet.')
          else
            for (final record in records) ...[
              _CheckoutHistoryRow(record: record),
              if (record != records.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _CheckoutHistoryRow extends StatelessWidget {
  final MarketRefillCheckoutRecord record;

  const _CheckoutHistoryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.checkoutNo,
                    style: _refillStrongStyle(fontSize: 13)),
                const SizedBox(height: 3),
                Text(_date(record.checkedOutAt), style: _refillMutedStyle()),
              ],
            ),
          ),
          _HistoryMetric(label: 'Sold', value: '${record.soldQuantity} unit'),
          const SizedBox(width: 10),
          _HistoryMetric(label: 'Items', value: '${record.itemGroups} lines'),
          const SizedBox(width: 10),
          _HistoryMetric(
            label: 'Net',
            value: '${_weight(record.soldNetWeight)} g',
          ),
        ],
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _refillMutedStyle(fontSize: 9.5)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _refillStrongStyle(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
