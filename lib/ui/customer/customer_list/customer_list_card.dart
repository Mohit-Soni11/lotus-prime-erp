// -----------------------------------------------------------------------------
// FILE: customer_list_card.dart
// MODULE: Customer â†’ Customer List
// DESCRIPTION: Individual customer card. Cream BG + White card.
//              Hover effect with gold border glow.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import '../../../models/customer/customer_list/customer_list_ui_model.dart';

class CustomerListCard extends StatefulWidget {
  final CustomerListItemModel customer;
  final VoidCallback? onTap;

  const CustomerListCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  @override
  State<CustomerListCard> createState() => _CustomerListCardState();
}

class _CustomerListCardState extends State<CustomerListCard> {
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
              ? CustomerListStyles.cardDecorationHover
              : CustomerListStyles.cardDecoration,
          child: Padding(
            padding: CustomerListStyles.cardPaddingH,
            child: Row(
              children: [
                // â”€â”€ AVATAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _buildAvatar(),
                const SizedBox(width: 16),

                // â”€â”€ MAIN INFO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Expanded(child: _buildMainInfo()),
                const SizedBox(width: 12),

                // â”€â”€ INVOICE COUNT (FIXED) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _buildInvoiceBox(),
                const SizedBox(width: 12),

                // â”€â”€ ARROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    CustomerListIcons.arrowRight,
                    color: CustomerListColors.brandGold,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: CustomerListStyles.avatarSize,
          height: CustomerListStyles.avatarSize,
          decoration: BoxDecoration(
            color: widget.customer.isVip
                ? CustomerListColors.vipBadgeBg
                : CustomerListColors.brandGoldLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.customer.isVip
                  ? CustomerListColors.vipBadgeBorder
                  : CustomerListColors.brandGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.customer.initials,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CustomerListColors.brandGold,
            ),
          ),
        ),
        if (widget.customer.isNewToday)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: CustomerListColors.onlineGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CustomerListColors.onlineGreen,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + Badge row
        Row(
          children: [
            Flexible(
              child: Text(
                widget.customer.name,
                style: CustomerListStyles.customerName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildTypeBadge(),
          ],
        ),
        const SizedBox(height: 6),

        // Mobile
        Row(
          children: [
            const Icon(
              CustomerListIcons.phone,
              size: 13,
              color: CustomerListColors.bodyTextMuted,
            ),
            const SizedBox(width: 5),
            Text(
              widget.customer.mobile,
              style: CustomerListStyles.customerMobile,
            ),
          ],
        ),
        const SizedBox(height: 4),

        // City + Since
        Row(
          children: [
            const Icon(
              CustomerListIcons.city,
              size: 12,
              color: CustomerListColors.bodyTextMuted,
            ),
            const SizedBox(width: 4),
            Text(
              widget.customer.city.isEmpty
                  ? CustomerListStrings.noCity
                  : widget.customer.city,
              style: CustomerListStyles.customerDetail,
            ),
            const SizedBox(width: 12),
            const Icon(
              CustomerListIcons.calendar,
              size: 12,
              color: CustomerListColors.bodyTextMuted,
            ),
            const SizedBox(width: 4),
            Text(
              "Since ${widget.customer.formattedDate}",
              style: CustomerListStyles.customerSince,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    if (widget.customer.isVip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: CustomerListColors.vipBadgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CustomerListColors.vipBadgeBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CustomerListIcons.vipBadge,
              size: 10,
              color: CustomerListColors.vipBadgeText,
            ),
            const SizedBox(width: 4),
            Text("ELITE", style: CustomerListStyles.vipBadge), // Fixed text
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: CustomerListColors.regularBadgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CustomerListColors.regularBadgeBorder,
            width: 1,
          ),
        ),
        child: Text("STANDARD",
            style: CustomerListStyles.regularBadge), // Fixed text
      );
    }
  }

  Widget _buildInvoiceBox() {
    // Renamed from _buildBillBox
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: widget.customer.billCount > 0
            ? CustomerListColors.brandGoldLight
            : CustomerListColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.customer.billCount > 0
              ? CustomerListColors.brandGold.withValues(alpha: 0.3)
              : CustomerListColors.bodyBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CustomerListIcons.invoice,
            size: 14,
            color: widget.customer.billCount > 0
                ? CustomerListColors.brandGold
                : CustomerListColors.bodyTextMuted,
          ),
          const SizedBox(height: 4),
          Text(
            widget.customer.billCount.toString(),
            style: CustomerListStyles.invoiceCount, // Fixed variable
            textAlign: TextAlign.center,
          ),
          Text(
            "INVOICES", // Fixed text
            style: CustomerListStyles.invoiceLabel, // Fixed variable
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
