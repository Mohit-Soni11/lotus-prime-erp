import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';

class CustomerMetalMeltingCheckoutTable extends StatelessWidget {
  final List<CustomerMetalPurchaseEntry> entries;
  final Set<String> selectedEntryKeys;
  final Color accent;
  final ValueChanged<CustomerMetalPurchaseEntry> onSelectionToggled;
  final ValueChanged<CustomerMetalPurchaseEntry> onCustomerPressed;
  final ValueChanged<CustomerMetalPurchaseEntry> onReferencePressed;
  final String Function(CustomerMetalPurchaseEntry entry) entryKeyBuilder;

  const CustomerMetalMeltingCheckoutTable({
    super.key,
    required this.entries,
    required this.selectedEntryKeys,
    required this.accent,
    required this.onSelectionToggled,
    required this.onCustomerPressed,
    required this.onReferencePressed,
    required this.entryKeyBuilder,
  });

  static const List<_CheckoutColumn> _columns = [
    _CheckoutColumn('Select', 72),
    _CheckoutColumn('S. No.', 66),
    _CheckoutColumn('Voucher No', 166, flexGrow: 0.16),
    _CheckoutColumn('Purchase Date', 128),
    _CheckoutColumn('Seller', 200, flexGrow: 0.20),
    _CheckoutColumn('Source', 150, flexGrow: 0.10),
    _CheckoutColumn('Item', 190, flexGrow: 0.20),
    _CheckoutColumn('Net Wt', 112),
    _CheckoutColumn('Fine Wt', 112),
    _CheckoutColumn('Value', 122),
    _CheckoutColumn('Metal Status', 152),
    _CheckoutColumn('Status Date', 130),
    _CheckoutColumn('Batch No', 162, flexGrow: 0.12),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E0D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(constraints.maxWidth, _baseWidth + 2);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _CheckoutHeader(columns: _columns, tableWidth: tableWidth),
                  for (var index = 0; index < entries.length; index++)
                    _CheckoutRow(
                      key: ValueKey(
                        'customer-metal-melting-checkout-row-${index + 1}',
                      ),
                      columns: _columns,
                      tableWidth: tableWidth,
                      accent: accent,
                      entry: entries[index],
                      serialNo: index + 1,
                      selected: selectedEntryKeys.contains(
                        entryKeyBuilder(entries[index]),
                      ),
                      onSelectionToggled: () =>
                          onSelectionToggled(entries[index]),
                      onCustomerPressed: () =>
                          onCustomerPressed(entries[index]),
                      onReferencePressed: () =>
                          onReferencePressed(entries[index]),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static double get _baseWidth =>
      _columns.fold(0, (total, column) => total + column.baseWidth);
}

class _CheckoutColumn {
  final String label;
  final double baseWidth;
  final double flexGrow;

  const _CheckoutColumn(
    this.label,
    this.baseWidth, {
    this.flexGrow = 0,
  });
}

class _CheckoutHeader extends StatelessWidget {
  final List<_CheckoutColumn> columns;
  final double tableWidth;

  const _CheckoutHeader({
    required this.columns,
    required this.tableWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          for (final column in columns)
            _CheckoutCell(
              width: _columnWidth(column),
              alignment: _centered(column.label)
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: Text(column.label, style: _tableHeadingStyle),
            ),
        ],
      ),
    );
  }

  bool _centered(String label) {
    return label == 'Select' || label == 'S. No.';
  }

  double _columnWidth(_CheckoutColumn column) {
    final baseWidth =
        columns.fold<double>(0, (total, item) => total + item.baseWidth);
    final extraWidth = math.max(0, tableWidth - baseWidth);
    return column.baseWidth + extraWidth * column.flexGrow;
  }
}

class _CheckoutRow extends StatefulWidget {
  final List<_CheckoutColumn> columns;
  final double tableWidth;
  final CustomerMetalPurchaseEntry entry;
  final int serialNo;
  final Color accent;
  final bool selected;
  final VoidCallback onSelectionToggled;
  final VoidCallback onCustomerPressed;
  final VoidCallback onReferencePressed;

  const _CheckoutRow({
    super.key,
    required this.columns,
    required this.tableWidth,
    required this.entry,
    required this.serialNo,
    required this.accent,
    required this.selected,
    required this.onSelectionToggled,
    required this.onCustomerPressed,
    required this.onReferencePressed,
  });

  @override
  State<_CheckoutRow> createState() => _CheckoutRowState();
}

class _CheckoutRowState extends State<_CheckoutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background =
        widget.serialNo.isEven ? const Color(0xFFFCFCFD) : Colors.white;
    final statusDate = widget.entry.isTransferredToMelting
        ? widget.entry.transferredToMeltingAt
        : widget.entry.returnedAt;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        width: widget.tableWidth,
        height: 64,
        decoration: BoxDecoration(
          color: widget.selected
              ? widget.accent.withValues(alpha: 0.08)
              : background,
          border: Border(
            bottom: BorderSide(
              color: _hovered
                  ? widget.accent.withValues(alpha: 0.38)
                  : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Row(
          children: [
            _CheckoutCell(
              width: _columnWidth(widget.columns[0]),
              alignment: Alignment.center,
              child: widget.entry.isAvailable
                  ? Checkbox(
                      value: widget.selected,
                      onChanged: (_) => widget.onSelectionToggled(),
                      activeColor: widget.accent,
                      side: BorderSide(
                        color: widget.accent.withValues(alpha: 0.65),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : const Icon(Icons.lock_rounded, size: 17),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[1]),
              alignment: Alignment.center,
              child: Text('${widget.serialNo}', style: _tableBodyStyle),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[2]),
              child: _LinkText(
                label: widget.entry.referenceNo,
                accent: widget.accent,
                onPressed: widget.onReferencePressed,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[3]),
              child: Text(
                CustomerMetalPurchaseFormatters.date(widget.entry.date),
                style: _tableBodyStyle,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[4]),
              child: _TwoLineText(
                title: widget.entry.customerName,
                subtitle: widget.entry.mobile ?? 'Mobile not recorded',
                onPressed: widget.entry.customerId == null
                    ? null
                    : widget.onCustomerPressed,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[5]),
              child: Text(
                widget.entry.displaySourceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _tableBodyStyle,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[6]),
              child: Text(
                widget.entry.itemDescription.isEmpty
                    ? widget.entry.metalType
                    : widget.entry.itemDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _tableBodyStyle,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[7]),
              child: Text(
                CustomerMetalPurchaseFormatters.weight(widget.entry.netWeight),
                style: _tableBodyStyle,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[8]),
              child: Text(
                CustomerMetalPurchaseFormatters.weight(widget.entry.fineWeight),
                style: _tableBodyStyle,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[9]),
              child: Text(
                CustomerMetalPurchaseFormatters.amount(widget.entry.amount),
                style: _tableBodyStyle,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[10]),
              child: _StatusPill(entry: widget.entry),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[11]),
              child: Text(
                statusDate == null
                    ? '-'
                    : CustomerMetalPurchaseFormatters.date(statusDate),
                style: _tableBodyStyle,
              ),
            ),
            _CheckoutCell(
              width: _columnWidth(widget.columns[12]),
              child: Text(
                widget.entry.meltingBatchNo ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _tableBodyStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _columnWidth(_CheckoutColumn column) {
    final baseWidth = widget.columns.fold<double>(
      0,
      (total, item) => total + item.baseWidth,
    );
    final extraWidth = math.max(0, widget.tableWidth - baseWidth);
    return column.baseWidth + extraWidth * column.flexGrow;
  }
}

class _CheckoutCell extends StatelessWidget {
  final double width;
  final Widget child;
  final AlignmentGeometry alignment;

  const _CheckoutCell({
    required this.width,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}

class _TwoLineText extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  const _TwoLineText({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _tableBodyStyle.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _tableBodyStyle.copyWith(fontSize: 11),
        ),
      ],
    );

    if (onPressed == null) {
      return content;
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: content,
    );
  }
}

class _LinkText extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onPressed;

  const _LinkText({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _tableBodyStyle.copyWith(
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;

  const _StatusPill({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.metalFlowStatusCode) {
      'MELTING' => const Color(0xFF7C2D12),
      'RETURNED' => const Color(0xFF475569),
      _ => const Color(0xFF047857),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          entry.metalFlowStatusLabel,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: color,
          ),
        ),
      ),
    );
  }
}

final TextStyle _tableHeadingStyle = GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w900,
  letterSpacing: 0,
  color: Colors.black,
);

final TextStyle _tableBodyStyle = GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w800,
  letterSpacing: 0,
  color: Colors.black,
);
