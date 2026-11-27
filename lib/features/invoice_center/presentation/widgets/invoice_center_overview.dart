import 'package:flutter/material.dart';

import '../../domain/invoice_center_models.dart';
import '../invoice_center_style.dart';

class InvoiceCenterOverview extends StatelessWidget {
  const InvoiceCenterOverview({
    super.key,
    required this.summary,
    required this.selected,
    required this.onSelect,
  });

  final InvoiceCenterSummary? summary;
  final InvoiceCenterTab selected;
  final ValueChanged<InvoiceCenterTab> onSelect;

  static const _tabs = [
    InvoiceCenterTab.regular,
    InvoiceCenterTab.gst,
    InvoiceCenterTab.due,
    InvoiceCenterTab.advance,
    InvoiceCenterTab.cancelled,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 1120
              ? 5
              : constraints.maxWidth >= 680
                  ? 3
                  : constraints.maxWidth >= 420
                      ? 2
                      : 1;
          final width = (constraints.maxWidth - (count - 1) * 12) / count;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final tab in _tabs)
                SizedBox(
                  width: width,
                  child: _SummaryCard(
                    tab: tab,
                    metric: summary?.forTab(tab),
                    selected: selected == tab,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          );
        },
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.tab,
    required this.metric,
    required this.selected,
    required this.onTap,
  });

  final InvoiceCenterTab tab;
  final InvoiceCenterMetric? metric;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = InvoiceCenterFormat.color(tab);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 112,
          decoration: BoxDecoration(
            color:
                Color.alphaBlend(accent.withValues(alpha: 0.06), Colors.white),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: accent.withValues(alpha: selected ? 0.68 : 0.18),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(InvoiceCenterFormat.icon(tab),
                    color: accent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      InvoiceCenterFormat.label(tab),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InvoiceCenterStyle.ink,
                        fontSize: InvoiceCenterStyle.bodyTextSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric?.count.toString() ?? '—',
                      style: const TextStyle(
                        color: InvoiceCenterStyle.ink,
                        fontSize: 25,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric == null
                          ? '—'
                          : InvoiceCenterFormat.money(metric!.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InvoiceCenterStyle.ink,
                        fontSize: InvoiceCenterStyle.bodyTextSize,
                        fontWeight: InvoiceCenterStyle.bodyTextWeight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceCenterTabs extends StatelessWidget {
  const InvoiceCenterTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final InvoiceCenterTab selected;
  final ValueChanged<InvoiceCenterTab> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        decoration: InvoiceCenterStyle.panel(radius: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in InvoiceCenterTab.values)
                    SizedBox(
                      width: constraints.maxWidth >= 1080
                          ? constraints.maxWidth /
                              InvoiceCenterTab.values.length
                          : 174,
                      height: 56,
                      child: _TabButton(
                        tab: tab,
                        active: tab == selected,
                        onTap: () => onSelect(tab),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final InvoiceCenterTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active ? InvoiceCenterStyle.gold : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                InvoiceCenterFormat.icon(tab),
                size: 19,
                color: active ? Colors.white : InvoiceCenterStyle.ink,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  InvoiceCenterFormat.label(tab),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : InvoiceCenterStyle.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: InvoiceCenterStyle.bodyTextSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
