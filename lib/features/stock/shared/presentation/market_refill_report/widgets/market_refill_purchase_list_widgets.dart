part of '../market_refill_report_screen.dart';

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
            flex: 2,
            child: Text('Bought Qty', style: _tableHeadStyle()),
          ),
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
