// -----------------------------------------------------------------------------
// FILE: supplier_list_card.dart
// MODULE: Supplier â†’ Supplier List
// DESCRIPTION: Hover card â€” gold border glow on hover, same as CustomerListCard.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_list/supplier_list_theme.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';

class SupplierListCard extends StatefulWidget {
  final SupplierListItemModel supplier;
  final VoidCallback? onTap;

  const SupplierListCard({super.key, required this.supplier, this.onTap});

  @override
  State<SupplierListCard> createState() => _SupplierListCardState();
}

class _SupplierListCardState extends State<SupplierListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _isHovered
              ? SupplierListStyles.cardDecorationHover
              : SupplierListStyles.cardDecoration,
          child: Padding(
            padding: SupplierListStyles.cardPaddingH,
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(child: _buildMainInfo()),
                const SizedBox(width: 12),
                _buildTypeBadge(),
                const SizedBox(width: 12),
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(SupplierListIcons.arrowRight,
                      color: SupplierListColors.brandGold, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: SupplierListStyles.avatarSize,
      height: SupplierListStyles.avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SupplierListColors.brandGold.withValues(alpha: 0.8),
            SupplierListColors.brandGold,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: SupplierListColors.brandGold.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.supplier.avatarInitial,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    final s = widget.supplier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.businessName,
            style: SupplierListStyles.supplierName,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        if (s.contactPersonName != null) ...[
          Text(s.contactPersonName!, style: SupplierListStyles.supplierDetail),
          const SizedBox(height: 3),
        ],
        Row(
          children: [
            const Icon(SupplierListIcons.phone,
                size: 13, color: SupplierListColors.bodyTextMuted),
            const SizedBox(width: 4),
            Text(s.mobile, style: SupplierListStyles.supplierMobile),
            if (s.gstNumber != null) ...[
              const SizedBox(width: 12),
              const Icon(SupplierListIcons.gst,
                  size: 13, color: SupplierListColors.bodyTextMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(s.gstNumber!,
                    style: SupplierListStyles.supplierGst,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    final s = widget.supplier;
    Color bg, textC, border;
    switch (s.supplierType) {
      case SupplierType.manufacturer:
        bg = SupplierListColors.manufacturerBg;
        textC = SupplierListColors.manufacturerText;
        border = SupplierListColors.manufacturerBorder;
        break;
      case SupplierType.wholesaler:
        bg = SupplierListColors.wholesalerBg;
        textC = SupplierListColors.wholesalerText;
        border = SupplierListColors.wholesalerBorder;
        break;
      case SupplierType.retailer:
        bg = SupplierListColors.retailerBg;
        textC = SupplierListColors.retailerText;
        border = SupplierListColors.retailerBorder;
        break;
      case SupplierType.individual:
        bg = SupplierListColors.individualBg;
        textC = SupplierListColors.individualText;
        border = SupplierListColors.individualBorder;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        s.supplierType.label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: textC,
            letterSpacing: 0.5),
      ),
    );
  }
}
