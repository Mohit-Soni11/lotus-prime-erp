part of '../metal_rate_detail_screen.dart';

class _HistoryEntries extends StatefulWidget {
  final List<MetalRateRevision> entries;
  final Color accent;
  final MetalRatePriceUnit priceUnit;
  const _HistoryEntries(
      {required this.entries, required this.accent, required this.priceUnit});

  @override
  State<_HistoryEntries> createState() => _HistoryEntriesState();
}

class _HistoryEntriesState extends State<_HistoryEntries> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _HistoryEntries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.length != widget.entries.length ||
        (oldWidget.entries.isNotEmpty &&
            widget.entries.isNotEmpty &&
            oldWidget.entries.first.entry.changedAt !=
                widget.entries.first.entry.changedAt)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            // The list consumes the wheel first when it can move. At its edges,
            // absorb the signal here so it does not scroll the surrounding page.
            GestureBinding.instance.pointerSignalResolver
                .register(event, (_) {});
          }
        },
        child: Container(
          height: 310,
          padding: const EdgeInsets.all(14),
          decoration: MetalRateDetailStyles.tint(widget.accent),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('Rate Changes', style: _historyText(size: 15))),
              Text('${widget.entries.length} revisions',
                  style: _historyText(size: 12)),
            ]),
            const SizedBox(height: 10),
            Expanded(
              child: widget.entries.isEmpty
                  ? Center(
                      child: Text('No rate changes in this period',
                          style: _historyText()))
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      thickness: 5,
                      radius: const Radius.circular(5),
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: widget.entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 7),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _HistoryEntry(
                            entry: widget.entries[index],
                            accent: widget.accent,
                            priceUnit: widget.priceUnit,
                          ),
                        ),
                      ),
                    ),
            ),
          ]),
        ),
      );
}

class _HistoryEntry extends StatelessWidget {
  final MetalRateRevision entry;
  final Color accent;
  final MetalRatePriceUnit priceUnit;
  const _HistoryEntry(
      {required this.entry, required this.accent, required this.priceUnit});

  @override
  Widget build(BuildContext context) {
    final changes = entry.changes;
    final summary = changes.isEmpty
        ? 'No rate values changed'
        : changes.map((change) {
            final before = priceUnit.toMarket(change.previousRate);
            final after = priceUnit.toMarket(change.currentRate);
            return '${change.label}: ${_money(before)} → ${_money(after)} / ${priceUnit.label}';
          }).join('\n');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: MetalRateColors.cardBorder),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: MetalRateDetailStyles.tint(accent),
          child: Icon(Icons.history_rounded, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('d MMM yyyy, h:mm a').format(entry.entry.changedAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _historyText(size: 12)),
            const SizedBox(height: 4),
            Text(
              summary,
              style: _historyText(size: 12),
            ),
          ],
        )),
      ]),
    );
  }
}
