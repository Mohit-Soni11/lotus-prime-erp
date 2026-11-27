import 'package:flutter/material.dart';

import '../invoice_center_style.dart';

class InvoiceCenterFooter extends StatelessWidget {
  const InvoiceCenterFooter({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalRows,
    required this.onPage,
    required this.onExport,
    required this.exporting,
  });

  final int page;
  final int pageSize;
  final int totalRows;
  final ValueChanged<int> onPage;
  final VoidCallback onExport;
  final bool exporting;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalRows / pageSize).ceil().clamp(1, 1 << 30);
    final first = totalRows == 0 ? 0 : (page - 1) * pageSize + 1;
    final last = (page * pageSize).clamp(0, totalRows);
    final visiblePages = <int>{
      1,
      totalPages,
      if (page > 1) page - 1,
      page,
      if (page < totalPages) page + 1,
    }.toList()
      ..sort();

    return Wrap(
      spacing: 14,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(
          'Showing $first–$last of $totalRows invoices',
          style: const TextStyle(
            color: InvoiceCenterStyle.ink,
            fontWeight: FontWeight.w600,
            fontSize: InvoiceCenterStyle.bodyTextSize,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pageButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous page',
              onPressed: page > 1 ? () => onPage(page - 1) : null,
            ),
            for (var index = 0; index < visiblePages.length; index++) ...[
              if (index > 0 &&
                  visiblePages[index] - visiblePages[index - 1] > 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('…'),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _pageButton(
                  label: '${visiblePages[index]}',
                  selected: visiblePages[index] == page,
                  onPressed: () => onPage(visiblePages[index]),
                ),
              ),
            ],
            _pageButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next page',
              onPressed: page < totalPages ? () => onPage(page + 1) : null,
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: exporting ? null : onExport,
          icon: exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded, size: 19),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: InvoiceCenterStyle.ink,
            backgroundColor: Colors.white,
            side: const BorderSide(color: InvoiceCenterStyle.border),
            minimumSize: const Size(126, 44),
            textStyle: const TextStyle(
              fontSize: InvoiceCenterStyle.bodyTextSize,
              fontWeight: InvoiceCenterStyle.bodyTextWeight,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _pageButton({
    String? label,
    IconData? icon,
    String? tooltip,
    required VoidCallback? onPressed,
    bool selected = false,
  }) =>
      SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: icon == null
              ? Text(
                  label ?? '',
                  style: TextStyle(
                    color: selected ? Colors.white : InvoiceCenterStyle.ink,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: InvoiceCenterStyle.ink,
            backgroundColor: selected ? InvoiceCenterStyle.gold : Colors.white,
            side: BorderSide(
              color: selected
                  ? InvoiceCenterStyle.gold
                  : InvoiceCenterStyle.border,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
      );
}
