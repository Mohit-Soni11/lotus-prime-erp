part of '../market_refill_report_screen.dart';

final _refillNumberFormat = NumberFormat.decimalPattern('en_IN');
final _refillWeightFormat = NumberFormat('##,##0.000', 'en_IN');
final _refillDateFormat = DateFormat('dd MMM yyyy, hh:mm a');

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

class _MetalPurchaseColumn extends StatelessWidget {
  final String title;
  final String modeLabel;
  final List<MarketRefillItemRow> rows;
  final Future<void> Function(
    MarketRefillItemRow row, {
    int? boughtQuantity,
    bool? purchaseDone,
  }) onProgressChanged;

  const _MetalPurchaseColumn({
    required this.title,
    required this.modeLabel,
    required this.rows,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(title);
    final grouped = <String, List<MarketRefillItemRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(_marketGroupTitle(row), () => []).add(row);
    }
    final entries = grouped.entries.toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RefillIconBox(icon: _metalIcon(title), accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _refillStrongStyle(fontSize: 17)),
                    Text(modeLabel, style: _refillMutedStyle(fontSize: 11)),
                  ],
                ),
              ),
              _RefillBadge(label: '${rows.length} lines', accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            _RefillEmptyState(message: 'No $title item sold yet.')
          else
            for (final entry in entries) ...[
              _PurchaseGroupBlock(
                title: entry.key,
                rows: entry.value,
                onProgressChanged: onProgressChanged,
              ),
              if (entry != entries.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _PurchaseGroupBlock extends StatelessWidget {
  final String title;
  final List<MarketRefillItemRow> rows;
  final Future<void> Function(
    MarketRefillItemRow row, {
    int? boughtQuantity,
    bool? purchaseDone,
  }) onProgressChanged;

  const _PurchaseGroupBlock({
    required this.title,
    required this.rows,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF7EF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: _refillStrongStyle(fontSize: 13.5)),
                ),
                Text('${rows.length} item', style: _refillMutedStyle()),
              ],
            ),
          ),
          const _PurchaseHeaderRow(),
          for (final row in rows)
            _PurchaseItemRow(
              row: row,
              onProgressChanged: onProgressChanged,
            ),
        ],
      ),
    );
  }
}

class _PurchaseHeaderRow extends StatelessWidget {
  const _PurchaseHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8DDC9))),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Item Name', style: _tableHeadStyle())),
          Expanded(flex: 2, child: Text('Total Qty', style: _tableHeadStyle())),
          Expanded(
              flex: 2, child: Text('Bought Qty', style: _tableHeadStyle())),
          SizedBox(width: 34, child: Text('Done', style: _tableHeadStyle())),
        ],
      ),
    );
  }
}

class _PurchaseItemRow extends StatefulWidget {
  final MarketRefillItemRow row;
  final Future<void> Function(
    MarketRefillItemRow row, {
    int? boughtQuantity,
    bool? purchaseDone,
  }) onProgressChanged;

  const _PurchaseItemRow({
    required this.row,
    required this.onProgressChanged,
  });

  @override
  State<_PurchaseItemRow> createState() => _PurchaseItemRowState();
}

class _PurchaseItemRowState extends State<_PurchaseItemRow> {
  bool _checked = false;
  late final TextEditingController _boughtController;

  @override
  void initState() {
    super.initState();
    _checked = widget.row.purchaseDone;
    _boughtController = TextEditingController(
      text: widget.row.boughtQuantity.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _PurchaseItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.rowKey != widget.row.rowKey ||
        oldWidget.row.boughtQuantity != widget.row.boughtQuantity) {
      final nextText = widget.row.boughtQuantity.toString();
      if (_boughtController.text != nextText) {
        _boughtController.text = nextText;
      }
    }
    if (oldWidget.row.rowKey != widget.row.rowKey ||
        oldWidget.row.purchaseDone != widget.row.purchaseDone) {
      _checked = widget.row.purchaseDone;
    }
  }

  @override
  void dispose() {
    _boughtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E7D8))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _refillStrongStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatQty(row.soldQuantity, row.unitLabel),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _refillStrongStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _boughtController,
              keyboardType: TextInputType.number,
              style: _refillStrongStyle(fontSize: 13),
              onChanged: _handleBoughtChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                suffixText: row.unitLabel,
                suffixStyle: _refillMutedStyle(fontSize: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Color(0xFFE8DDC9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Color(0xFFE8DDC9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: InvColors.brandGold),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Checkbox(
              value: _checked,
              activeColor: InvColors.brandGold,
              onChanged: _handleCheckedChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBoughtChanged(String value) async {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return;
    await widget.onProgressChanged(
      widget.row,
      boughtQuantity: parsed < 0 ? 0 : parsed,
      purchaseDone: _checked,
    );
  }

  Future<void> _handleCheckedChanged(bool? value) async {
    final checked = value ?? false;
    setState(() => _checked = checked);
    await widget.onProgressChanged(
      widget.row,
      boughtQuantity: int.tryParse(_boughtController.text.trim()) ??
          widget.row.boughtQuantity,
      purchaseDone: checked,
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

class _RefillHeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _RefillHeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          _RefillIconBox(icon: icon, accent: accent, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: _refillMutedStyle(fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _refillStrongStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RefillPrimaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RefillActionButton(
      label: label,
      icon: icon,
      enabled: enabled,
      fill: InvColors.brandGold,
      foreground: Colors.white,
      onTap: onTap,
    );
  }
}

class _RefillSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RefillSecondaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RefillActionButton(
      label: label,
      icon: icon,
      enabled: enabled,
      fill: const Color(0xFFFFFCF7),
      foreground: InvColors.textDark,
      border: const Color(0xFFE8DDC9),
      onTap: onTap,
    );
  }
}

class _RefillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color fill;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  const _RefillActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.fill,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? fill : const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? (border ?? fill) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? foreground : InvColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: enabled ? foreground : InvColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefillShellButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RefillShellButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_RefillShellButton> createState() => _RefillShellButtonState();
}

class _RefillShellButtonState extends State<_RefillShellButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? InvColors.shellBg
                : InvColors.shellBorder.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hovered ? InvColors.brandGold : InvColors.shellBorder,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? InvColors.brandGold : InvColors.shellTextTitle,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _RefillAppIcon extends StatelessWidget {
  const _RefillAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD76A), InvColors.brandGold],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.shopping_bag_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _RefillIconBox extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double size;

  const _RefillIconBox({
    required this.icon,
    required this.accent,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size >= 50 ? 16 : 13),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: accent, size: size >= 50 ? 28 : 21),
    );
  }
}

class _RefillBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _RefillBadge({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      ),
    );
  }
}

class _RefillEmptyState extends StatelessWidget {
  final String message;

  const _RefillEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: _refillMutedStyle(),
      ),
    );
  }
}

class _MarketRefillError extends StatelessWidget {
  final String message;

  const _MarketRefillError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: InvColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: InvColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillDivider extends StatelessWidget {
  const _RefillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            InvColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _RefillOnlineBadge extends StatelessWidget {
  final AnimationController pulse;

  const _RefillOnlineBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: InvColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: InvColors.onlineGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RefillPulseWave(animation: pulse, delay: 0),
                _RefillPulseWave(animation: pulse, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: InvColors.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SYSTEM ONLINE',
            style: GoogleFonts.inter(
              color: InvColors.onlineGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefillPulseWave extends StatelessWidget {
  final AnimationController animation;
  final double delay;

  const _RefillPulseWave({
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final value = (animation.value + delay) % 1;
        return Opacity(
          opacity: 1 - value,
          child: Transform.scale(
            scale: 1 + value * 1.5,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: InvColors.onlineGreen.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE8DDC9)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.055),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

TextStyle _refillStrongStyle({double fontSize = 14}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w900,
    color: InvColors.textDark,
  );
}

TextStyle _refillMutedStyle({double fontSize = 12}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: InvColors.textMuted,
  );
}

TextStyle _tableHeadStyle() {
  return GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w900,
    color: InvColors.textMuted,
  );
}

String _formatQty(int value, String unitLabel) {
  final clean = unitLabel.trim().toLowerCase();
  final unit = clean.isEmpty || clean == 'unit' ? 'unit' : clean;
  return '${_refillNumberFormat.format(value)} $unit';
}

String _weight(double value) => _refillWeightFormat.format(value);

String _date(DateTime? value) {
  if (value == null) return 'Not checked out yet';
  return _refillDateFormat.format(value);
}

String _marketGroupTitle(MarketRefillItemRow row) {
  switch (row.metal.trim().toLowerCase()) {
    case 'gold':
      return row.gradeLabel.trim().isEmpty
          ? 'Gold Grade Not Tagged'
          : row.gradeLabel;
    case 'silver':
      return row.companyLabel;
    default:
      return row.gradeLabel.trim().isEmpty ? row.metal : row.gradeLabel;
  }
}

Color _metalAccent(String metal) {
  switch (metal.toLowerCase()) {
    case 'silver':
      return const Color(0xFF64748B);
    case 'diamond':
      return const Color(0xFF0EA5E9);
    case 'platinum':
      return const Color(0xFF475569);
    case 'gold':
      return InvColors.brandGold;
    default:
      return const Color(0xFF64748B);
  }
}

IconData _metalIcon(String metal) {
  switch (metal.toLowerCase()) {
    case 'silver':
      return Icons.circle_outlined;
    case 'diamond':
      return Icons.diamond_rounded;
    case 'platinum':
      return Icons.radio_button_checked_rounded;
    case 'gold':
      return Icons.workspace_premium_rounded;
    default:
      return Icons.inventory_2_rounded;
  }
}
