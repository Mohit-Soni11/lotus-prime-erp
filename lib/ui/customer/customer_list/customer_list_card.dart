import 'package:flutter/material.dart';

import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import 'customer_list_card_components.dart';
import 'customer_list_identity.dart';

class CustomerListCard extends StatefulWidget {
  const CustomerListCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  final CustomerListItemModel customer;
  final VoidCallback? onTap;

  @override
  State<CustomerListCard> createState() => _CustomerListCardState();
}

class _CustomerListCardState extends State<CustomerListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.customer.isVip
        ? CustomerListColors.brandGold
        : widget.customer.hasDue
            ? CustomerListColors.danger
            : CustomerListColors.info;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: _isHovered
              ? CustomerListStyles.cardDecorationHover
              : CustomerListStyles.cardDecoration,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) => setState(() => _isHovered = hovered),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: accent),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontal = constraints.maxWidth >= 850;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
                      child: horizontal
                          ? _buildHorizontalContent(constraints.maxWidth)
                          : _buildCompactContent(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalContent(double width) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: CustomerListIdentity(customer: widget.customer),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 7,
          child: CustomerListMetricRail(customer: widget.customer),
        ),
        const SizedBox(width: 14),
        _buildProfileAction(compact: width < 1100),
      ],
    );
  }

  Widget _buildCompactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CustomerListIdentity(customer: widget.customer)),
            const SizedBox(width: 10),
            _buildProfileAction(compact: true),
          ],
        ),
        const SizedBox(height: 12),
        CustomerListMetricRail(customer: widget.customer),
      ],
    );
  }

  Widget _buildProfileAction({required bool compact}) {
    return Tooltip(
      message: CustomerListStrings.viewDetails,
      child: Container(
        key: const ValueKey('open-profile-action'),
        constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 11),
        decoration: BoxDecoration(
          color: CustomerListColors.brandGoldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CustomerListColors.brandGold),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Text(
                CustomerListStrings.viewDetails,
                style: CustomerListStyles.toolbarButton,
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              CustomerListIcons.arrowRight,
              size: 17,
              color: CustomerListColors.bodyTextMain,
            ),
          ],
        ),
      ),
    );
  }
}
