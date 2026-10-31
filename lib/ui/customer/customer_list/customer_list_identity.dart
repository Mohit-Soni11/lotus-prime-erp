import 'package:flutter/material.dart';

import '../../../models/customer/customer_enums/customer_list_enums.dart';
import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';

class CustomerListIdentity extends StatelessWidget {
  const CustomerListIdentity({super.key, required this.customer});

  final CustomerListItemModel customer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final address = customer.formattedAddress;
        final detailWidth =
            (constraints.maxWidth - CustomerListStyles.avatarSize - 12)
                .clamp(0.0, double.infinity)
                .toDouble();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customer.name,
                    style: CustomerListStyles.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  _buildTierBadge(compact: detailWidth < 310),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 13,
                    runSpacing: 5,
                    children: [
                      _buildMeta(
                        CustomerListIcons.phone,
                        customer.mobile.isEmpty
                            ? 'Mobile not added'
                            : customer.mobile,
                        detailWidth,
                      ),
                      _buildMeta(
                        CustomerListIcons.calendar,
                        customer.formattedDate,
                        detailWidth,
                      ),
                      _buildMeta(
                        CustomerListIcons.address,
                        address == null
                            ? CustomerListStrings.noAddress
                            : 'Address: $address',
                        detailWidth,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Container(
      key: const ValueKey('customer-avatar'),
      width: CustomerListStyles.avatarSize,
      height: CustomerListStyles.avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: customer.isVip
            ? CustomerListColors.brandGoldBg
            : CustomerListColors.infoBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: customer.isVip
              ? CustomerListColors.brandGold
              : CustomerListColors.info,
        ),
      ),
      child: Text(customer.initials, style: CustomerListStyles.customerName),
    );
  }

  Widget _buildTierBadge({required bool compact}) {
    final tier = customer.type;
    final icon = switch (tier) {
      CustomerType.elite => CustomerListIcons.vipBadge,
      CustomerType.alert => Icons.priority_high_rounded,
      CustomerType.standard => CustomerListIcons.defaultAvatar,
    };
    final accent = tier == CustomerType.alert
        ? const Color(0xFFDC2626)
        : tier == CustomerType.elite
            ? const Color(0xFF7C3AED)
            : const Color(0xFF2563EB);
    return Tooltip(
        message: customer.categoryScore == null
            ? '${tier.displayLabel} Customer'
          : customer.categoryScore!.explanation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 5),
              Text(
                compact
                    ? tier.displayLabel
                    : '${tier.displayLabel} Customer'
                        '${customer.categoryScore == null ? '' : ' • ${customer.categoryScore!.formattedPoints}/10'}',
                style: CustomerListStyles.regularBadge,
              ),
            ],
          ),
        ));
  }

  Widget _buildMeta(
    IconData icon,
    String value,
    double maxWidth, {
    int maxLines = 1,
  }) {
    if (maxLines == 1 && maxWidth >= 300) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CustomerListColors.bodyTextMain),
          const SizedBox(width: 5),
          Text(value, style: CustomerListStyles.customerDetail),
        ],
      );
    }

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CustomerListColors.bodyTextMain),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              style: CustomerListStyles.customerDetail,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return maxLines > 1 ? Tooltip(message: value, child: content) : content;
  }
}
