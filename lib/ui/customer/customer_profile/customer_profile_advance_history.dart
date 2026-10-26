part of 'customer_profile_screen.dart';

extension _ProfileAdvanceHistory on _CustomerProfileScreenState {
  Widget _buildAdvanceList(CustomerProfileModel p) {
    if (p.advanceOrders.isEmpty) {
      return _emptyState(
        icon: CustomerProfileIcons.advanceEmpty,
        title: CustomerProfileStrings.noAdvance,
        sub: CustomerProfileStrings.noAdvanceSub,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: p.advanceOrders.length,
      itemBuilder: (_, i) => _buildAdvanceRow(p.advanceOrders[i]),
    );
  }

  Widget _buildAdvanceRow(CustomerAdvanceOrderModel order) {
    // Status colors
    Color statusBg, statusText, statusBdr;
    IconData statusIcon;
    switch (order.status) {
      case AdvanceOrderStatus.ready:
        statusBg = CustomerProfileColors.advanceReadyBg;
        statusText = CustomerProfileColors.advanceReadyText;
        statusBdr = CustomerProfileColors.advanceReadyBdr;
        statusIcon = CustomerProfileIcons.advanceReady;
        break;
      case AdvanceOrderStatus.delivered:
        statusBg = CustomerProfileColors.paidBg;
        statusText = CustomerProfileColors.paidText;
        statusBdr = CustomerProfileColors.clearBorder;
        statusIcon = CustomerProfileIcons.clear;
        break;
      case AdvanceOrderStatus.cancelled:
        statusBg = CustomerProfileColors.defaulterBg;
        statusText = CustomerProfileColors.defaulterText;
        statusBdr = CustomerProfileColors.defaulterBorder;
        statusIcon = Icons.cancel_outlined;
        break;
      default: // pending
        statusBg = CustomerProfileColors.advancePendingBg;
        statusText = CustomerProfileColors.advancePendingText;
        statusBdr = CustomerProfileColors.advancePendingBdr;
        statusIcon = CustomerProfileIcons.advancePending;
    }

    final bool canConvert = order.isPending || order.isReady;

    return GestureDetector(
      onTap: () => _showAdvanceActions(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: CustomerProfileColors.advanceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CustomerProfileColors.advanceBorder),
          boxShadow: const [
            BoxShadow(
              color: CustomerProfileColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusBdr),
                    ),
                    child: Icon(statusIcon, color: statusText, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: CustomerProfileColors.bodyTextMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${order.itemName} | ${order.metalType} ${order.purity}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: CustomerProfileColors.bodyTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusBdr),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CustomerProfileColors.bodyBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CustomerProfileColors.bodyBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _advanceDetail(
                      "Approx. Weight",
                      "${order.approxWeight.toStringAsFixed(2)}g",
                      CustomerProfileColors.brandGold,
                    ),
                  ),
                  Expanded(
                    child: _advanceDetail(
                      CustomerProfileStrings.totalAdvancePaid,
                      "\u20B9${_fmt(order.totalAdvancePaid)}",
                      CustomerProfileColors.advanceAccent,
                    ),
                  ),
                  Expanded(
                    child: _advanceDetail(
                      CustomerProfileStrings.remainingBalance,
                      "\u20B9${_fmt(order.remainingBalance)}",
                      order.remainingBalance > 0
                          ? CustomerProfileColors.advanceRemaining
                          : CustomerProfileColors.clearIcon,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(CustomerProfileIcons.calendar,
                      size: 12, color: CustomerProfileColors.bodyTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    "Booked ${order.formattedDate}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: CustomerProfileColors.bodyTextMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(CustomerProfileIcons.deliveryDate,
                      size: 12, color: CustomerProfileColors.bodyTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    "Delivery ${order.formattedDelivery}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: CustomerProfileColors.bodyTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (canConvert) ...[
              const Divider(
                  height: 1, color: CustomerProfileColors.advanceBorder),
              Padding(
                padding: const EdgeInsets.all(12),
                child: CustomerProfileConvertToSaleButton(
                  onTap: () => _logic.triggerConvertAdvanceToSale(order.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _advanceDetail(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: CustomerProfileColors.bodyTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _advanceSourceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CustomerProfileColors.advanceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CustomerProfileColors.advanceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CustomerProfileIcons.advanceOrder,
            size: 11,
            color: CustomerProfileColors.advanceAccent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CustomerProfileColors.advanceAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _girviDetail(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 10,
              color: CustomerProfileColors.bodyTextMuted,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            )),
      ],
    );
  }
}
