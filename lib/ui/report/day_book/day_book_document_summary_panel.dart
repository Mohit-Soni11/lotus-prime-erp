import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_document_explorer.dart';
import '../../../models/reports/day_book/day_book_document.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_document_explorer_card.dart';
import 'day_book_document_explorer_summary.dart';

class DayBookDocumentSummaryPanel extends StatefulWidget {
  const DayBookDocumentSummaryPanel({
    super.key,
    required this.summary,
  });

  final DayBookSummary summary;

  @override
  State<DayBookDocumentSummaryPanel> createState() =>
      _DayBookDocumentSummaryPanelState();
}

class _DayBookDocumentSummaryPanelState
    extends State<DayBookDocumentSummaryPanel> {
  DayBookExplorerTab _selected = DayBookExplorerTab.sales;
  int _visibleCount = 20;

  void _select(DayBookExplorerTab tab) {
    setState(() {
      _selected = tab;
      _visibleCount = 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final explorer = DayBookDocumentExplorer(summary);
    final entries = explorer.entriesFor(_selected);
    final visible = entries.take(_visibleCount).toList();
    return Container(
      decoration: DayBookStyles.panel(),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.description_outlined,
              color: DayBookColors.goldMetal, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Source Documents',
                style: DayBookStyles.sectionTitle.copyWith(fontSize: 18)),
          ),
        ]),
        const SizedBox(height: 13),
        _ExplorerTabs(selected: _selected, onSelected: _select),
        const SizedBox(height: 10),
        if (entries.any((entry) =>
            entry.document is DayBookDocument &&
            !entry.document!.issueSnapshotAvailable)) ...[
          const Text(
            'Historical invoice issue values are unverified. Reconcile the original saved invoices before certifying this day.',
            style: TextStyle(
                color: DayBookColors.negative, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
        ],
        DayBookDocumentExplorerSummary(tab: _selected, entries: entries),
        const SizedBox(height: 11),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                  'No ${_selected.label.toLowerCase()} records for this day.',
                  style: DayBookStyles.label),
            ),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            const gap = 10.0;
            final width = constraints.maxWidth;
            final columns = width >= 1180
                ? 5
                : width >= 1050
                    ? 4
                    : width >= 650
                        ? 3
                        : width >= 430
                            ? 2
                            : 1;
            final cardWidth = (width - gap * (columns - 1)) / columns;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (final entry in visible)
                SizedBox(
                  width: cardWidth,
                  child: DayBookDocumentExplorerCard(
                    entry: entry,
                    summary: summary,
                  ),
                ),
            ]);
          }),
        if (entries.length > visible.length) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => setState(() => _visibleCount += 20),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                  'Show more · ${entries.length - visible.length} remaining'),
            ),
          ),
        ],
      ]),
    );
  }
}

class _ExplorerTabs extends StatelessWidget {
  const _ExplorerTabs({required this.selected, required this.onSelected});

  final DayBookExplorerTab selected;
  final ValueChanged<DayBookExplorerTab> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final inline = constraints.maxWidth >= 800;
          final tabs = Row(children: [
            for (final tab in DayBookExplorerTab.values)
              inline
                  ? Expanded(child: _tab(tab))
                  : SizedBox(width: 145, child: _tab(tab)),
          ]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 37,
              decoration: BoxDecoration(
                border: Border.all(color: DayBookColors.bodyBorder),
                borderRadius: BorderRadius.circular(9),
              ),
              child: inline
                  ? tabs
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: tabs,
                    ),
            ),
          );
        },
      );

  Widget _tab(DayBookExplorerTab tab) {
    final active = selected == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('document-tab-${tab.name}'),
        onTap: () => onSelected(tab),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [
                    Color(0xFFB77C0B),
                    Color(0xFFD9A72F),
                  ])
                : null,
            border: const Border(
              right: BorderSide(color: DayBookColors.bodyBorder),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_icon(tab),
                size: 17,
                color: active ? Colors.white : DayBookColors.goldMetal),
            const SizedBox(width: 6),
            Flexible(
                child: Text(tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DayBookStyles.labelStrong.copyWith(
                        color:
                            active ? Colors.white : DayBookColors.textPrimary,
                        fontSize: 13))),
          ]),
        ),
      ),
    );
  }

  IconData _icon(DayBookExplorerTab tab) => switch (tab) {
        DayBookExplorerTab.sales => Icons.shopping_bag_outlined,
        DayBookExplorerTab.gstSales => Icons.percent_rounded,
        DayBookExplorerTab.girvi => Icons.balance_outlined,
        DayBookExplorerTab.advance => Icons.layers_outlined,
        DayBookExplorerTab.returns => Icons.keyboard_return_rounded,
        DayBookExplorerTab.purchase => Icons.inventory_2_outlined,
      };
}
