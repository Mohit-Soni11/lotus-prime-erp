import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseFilterSurface extends StatelessWidget {
  final Widget child;

  const CustomerMetalPurchaseFilterSurface({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.bodyPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: PurchaseEntryColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CustomerMetalPurchaseStatusFilter extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseStatusFilter({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = ['ALL', 'PAID', 'PARTIAL', 'PENDING'];

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PurchaseEntryColors.bodyBorder),
      ),
      child: Row(
        children: [
          for (var index = 0; index < statuses.length; index++)
            Expanded(
              child: _StatusSegment(
                label: _statusLabel(statuses[index]),
                selected: controller.paymentStatusFilter == statuses[index],
                accent: _statusAccent(statuses[index]),
                showDivider: index > 0,
                onTap: () => controller.setPaymentStatusFilter(
                  statuses[index],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomerMetalPurchaseActiveMetalChip extends StatelessWidget {
  final CustomerMetalPurchaseMetal? metal;
  final VoidCallback onClear;

  const CustomerMetalPurchaseActiveMetalChip({
    super.key,
    required this.metal,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final selectedMetal = metal;
    if (selectedMetal == null) {
      return const SizedBox.shrink();
    }

    return _ActionChip(
      icon: Icons.filter_alt_off_rounded,
      label: '${selectedMetal.label} Active',
      onTap: onClear,
    );
  }
}

class CustomerMetalPurchaseSearchField extends StatelessWidget {
  final TextEditingController controller;

  const CustomerMetalPurchaseSearchField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: PurchaseEntryColors.textMain,
        ),
        decoration: InputDecoration(
          hintText: 'Search seller, voucher, mobile or metal',
          isDense: true,
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Clear search',
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded, size: 18),
              );
            },
          ),
          prefixIconColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return PurchaseEntryColors.purchaseAccent;
            }
            return PurchaseEntryColors.purchaseAccent;
          }),
          suffixIconColor: PurchaseEntryColors.shellMuted,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: PurchaseEntryColors.textMain.withValues(alpha: 0.48),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: _fieldBorder(PurchaseEntryColors.bodyBorder),
          enabledBorder: _fieldBorder(PurchaseEntryColors.bodyBorder),
          focusedBorder: _fieldBorder(
            PurchaseEntryColors.purchaseAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _StatusSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showDivider;
  final Color accent;
  final VoidCallback onTap;

  const _StatusSegment({
    required this.label,
    required this.selected,
    required this.showDivider,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(
                      left: BorderSide(
                        color: PurchaseEntryColors.bodyBorder
                            .withValues(alpha: selected ? 0 : 1),
                      ),
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: selected ? accent : PurchaseEntryColors.textMain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        foregroundColor: PurchaseEntryColors.purchaseAccent,
        backgroundColor:
            PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.08),
        side: BorderSide(
          color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.38),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color, width: width),
  );
}

String _statusLabel(String status) {
  switch (status) {
    case 'ALL':
      return 'All';
    case 'PAID':
      return 'Paid';
    case 'PARTIAL':
      return 'Partial';
    case 'PENDING':
      return 'Pending';
    default:
      return status;
  }
}

Color _statusAccent(String status) {
  switch (status) {
    case 'PAID':
      return PurchaseEntryColors.success;
    case 'PARTIAL':
      return PurchaseEntryColors.warning;
    case 'PENDING':
      return PurchaseEntryColors.danger;
    default:
      return PurchaseEntryColors.purchaseAccent;
  }
}
