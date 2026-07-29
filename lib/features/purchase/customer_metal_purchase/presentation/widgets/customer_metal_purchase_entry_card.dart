import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';

class CustomerMetalPurchaseEntryCard extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final Color accent;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onCustomerPressed;
  final VoidCallback? onReferencePressed;
  final VoidCallback? onReturnPressed;

  const CustomerMetalPurchaseEntryCard({
    super.key,
    required this.entry,
    required this.accent,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onCustomerPressed,
    this.onReferencePressed,
    this.onReturnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _EntryCardSurface(
      entry: entry,
      accent: accent,
      isSelected: isSelected,
      onSelectionChanged: onSelectionChanged,
      onCustomerPressed: onCustomerPressed,
      onReferencePressed: onReferencePressed,
      onReturnPressed: onReturnPressed,
    );
  }
}

class _EntryCardSurface extends StatefulWidget {
  final CustomerMetalPurchaseEntry entry;
  final Color accent;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onCustomerPressed;
  final VoidCallback? onReferencePressed;
  final VoidCallback? onReturnPressed;

  const _EntryCardSurface({
    required this.entry,
    required this.accent,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onCustomerPressed,
    required this.onReferencePressed,
    required this.onReturnPressed,
  });

  @override
  State<_EntryCardSurface> createState() => _EntryCardSurfaceState();
}

class _EntryCardSurfaceState extends State<_EntryCardSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final accent = widget.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: entry.isReturned
                ? const Color(0xFFD1D5DB)
                : (widget.isSelected || _hovered
                    ? accent
                    : const Color(0xFFE5E0D8)),
            width: widget.isSelected ? 1.6 : (_hovered ? 1.2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.05),
              blurRadius: _hovered ? 16 : 10,
              offset: Offset(0, _hovered ? 6 : 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 148,
              decoration: BoxDecoration(
                color: entry.isReturned ? const Color(0xFF9CA3AF) : accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EntryHeader(
                    entry: entry,
                    accent: accent,
                    isSelected: widget.isSelected,
                    onSelectionChanged: widget.onSelectionChanged,
                    onCustomerPressed: widget.onCustomerPressed,
                    onReturnPressed: widget.onReturnPressed,
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1180
                          ? 4
                          : constraints.maxWidth >= 720
                              ? 3
                              : constraints.maxWidth >= 520
                                  ? 2
                                  : 1;
                      const spacing = 12.0;
                      final width =
                          (constraints.maxWidth - (spacing * (columns - 1))) /
                              columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          _MeasureTile(
                            width: width,
                            label: 'Gross Weight',
                            value: CustomerMetalPurchaseFormatters.weight(
                              entry.grossWeight,
                            ),
                          ),
                          _MeasureTile(
                            width: width,
                            label: 'Paid Touch',
                            value: CustomerMetalPurchaseFormatters.purity(
                              entry.purity,
                            ),
                          ),
                          _MeasureTile(
                            width: width,
                            label: 'Fine Weight',
                            value: CustomerMetalPurchaseFormatters.weight(
                              entry.fineWeight,
                            ),
                          ),
                          _MeasureTile(
                            width: width,
                            label: 'Amount Paid',
                            value: CustomerMetalPurchaseFormatters.amount(
                              entry.amount,
                            ),
                          ),
                          _MeasureTile(
                            width: width,
                            label: 'Purchase Rate',
                            value: CustomerMetalPurchaseFormatters.rate(
                              entry.effectiveRate,
                            ),
                          ),
                          _MeasureTile(
                            width: width,
                            label: 'Reference No',
                            value: entry.referenceNo,
                            icon: Icons.receipt_long_rounded,
                            onTap: widget.onReferencePressed,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryHeader extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final Color accent;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onCustomerPressed;
  final VoidCallback? onReturnPressed;

  const _EntryHeader({
    required this.entry,
    required this.accent,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onCustomerPressed,
    required this.onReturnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final details = _HeaderDetails(
          entry: entry,
          accent: accent,
          isSelected: isSelected,
          onSelectionChanged: onSelectionChanged,
          onCustomerPressed: onCustomerPressed,
        );
        final action = _ReturnAction(
          entry: entry,
          accent: accent,
          onPressed: onReturnPressed,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              details,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: details),
            const SizedBox(width: 18),
            action,
          ],
        );
      },
    );
  }
}

class _HeaderDetails extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final Color accent;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onCustomerPressed;

  const _HeaderDetails({
    required this.entry,
    required this.accent,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onCustomerPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (entry.isAvailable)
              Checkbox(
                value: isSelected,
                onChanged: (value) => onSelectionChanged?.call(value ?? false),
                activeColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            _CustomerNameButton(
              name: entry.customerName,
              accent: accent,
              onPressed: onCustomerPressed,
            ),
            _StatusBadge(
              label: _statusLabel(entry),
              accent: entry.isAvailable ? accent : const Color(0xFF6B7280),
              filled: !entry.isAvailable,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _MetaText(
              label: 'Item',
              value: entry.itemDescription.isEmpty
                  ? entry.metalType
                  : entry.itemDescription,
            ),
            _MetaText(
              label: 'Date',
              value: CustomerMetalPurchaseFormatters.date(entry.date),
            ),
            if (entry.isReturned && entry.returnedAt != null)
              _MetaText(
                label: 'Returned On',
                value: CustomerMetalPurchaseFormatters.date(entry.returnedAt!),
              ),
            if (entry.isTransferredToMelting &&
                entry.transferredToMeltingAt != null)
              _MetaText(
                label: 'Melting Batch',
                value: entry.meltingBatchNo ?? 'Transferred',
              ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(CustomerMetalPurchaseEntry entry) {
    if (entry.isReturned) {
      return 'Returned';
    }
    if (entry.isTransferredToMelting) {
      return 'Transferred to Melting';
    }
    return entry.source;
  }
}

class _ReturnAction extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final Color accent;
  final VoidCallback? onPressed;

  const _ReturnAction({
    required this.entry,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (entry.isReturned) {
      return const _StatusBadge(
        label: 'Return Completed',
        accent: Color(0xFF6B7280),
        filled: true,
      );
    }
    if (entry.isTransferredToMelting) {
      return const _StatusBadge(
        label: 'In Melting Batch',
        accent: Color(0xFF6B7280),
        filled: true,
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.assignment_return_rounded, size: 18),
      label: const Text('Return Item'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: accent.withValues(alpha: 0.42)),
        minimumSize: const Size(132, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MeasureTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  const _MeasureTile({
    required this.width,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E0D8)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: width,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: content,
              ),
            ),
    );
  }
}

class _CustomerNameButton extends StatelessWidget {
  final String name;
  final Color accent;
  final VoidCallback? onPressed;

  const _CustomerNameButton({
    required this.name,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.manrope(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );

    if (onPressed == null) {
      return text;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: text),
              const SizedBox(width: 6),
              Icon(
                Icons.open_in_new_rounded,
                size: 17,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final String label;
  final String value;

  const _MetaText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color accent;
  final bool filled;

  const _StatusBadge({
    required this.label,
    required this.accent,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled
            ? accent.withValues(alpha: 0.14)
            : accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}
