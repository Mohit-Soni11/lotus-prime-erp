import 'package:flutter/material.dart';

import '../../../../models/customer/customer_profile/customer_profile_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'pos_advance_invoice_formatters.dart';

class PosAdvanceInvoiceCard extends StatelessWidget {
  const PosAdvanceInvoiceCard({
    super.key,
    required this.order,
    required this.width,
    required this.onViewBooking,
    required this.onUseInSale,
    this.isSelected = false,
  });

  final CustomerAdvanceOrderModel order;
  final double width;
  final bool isSelected;
  final VoidCallback onViewBooking;
  final VoidCallback onUseInSale;

  @override
  Widget build(BuildContext context) {
    final rateLocked =
        PosAdvanceInvoiceFormatters.isRateLocked(order.bookingType);
    final accent =
        rateLocked ? SalesPosColors.goldHoverDark : const Color(0xFF176B52);

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 294),
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? SalesPosColors.brandGold.withValues(alpha: 0.80)
              : const Color(0xFFEBD7B8),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF76532B).withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 27,
                color: Color(0xFFE09A00),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  order.orderNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _RateBadge(isLocked: rateLocked),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.itemName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 11),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Purity: '),
                TextSpan(
                  text: order.purity.isEmpty ? order.metalType : order.purity,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: '    |    Weight: '),
                TextSpan(
                  text: PosAdvanceInvoiceFormatters.weight(order.approxWeight),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF263953),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0E8D9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AmountDetail(
                  label: rateLocked ? 'Locked Rate' : 'Open Rate',
                  value: rateLocked
                      ? '${PosAdvanceInvoiceFormatters.money(order.lockedRate)}/g'
                      : 'At sale',
                  valueColor: accent,
                ),
              ),
              Container(
                height: 48,
                width: 1,
                color: const Color(0xFFE8D4B3),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: _AmountDetail(
                  label: 'Advance',
                  value: PosAdvanceInvoiceFormatters.money(
                    order.totalAdvancePaid,
                  ),
                  valueColor: const Color(0xFF078B36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFF0E8D9)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewBooking,
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: const Text('View Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SalesPosColors.textDark,
                    side: const BorderSide(color: Color(0xFFD38C00)),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE5AD21), Color(0xFFA96B00)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: onUseInSale,
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            const Flexible(
                              child: Text(
                                'Use in Sale',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (width >= 330) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 17,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateBadge extends StatelessWidget {
  const _RateBadge({required this.isLocked});

  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFFFE9B4) : const Color(0xFFDCF5E8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 15,
            color: isLocked ? const Color(0xFF80500B) : const Color(0xFF176B52),
          ),
          const SizedBox(width: 4),
          Text(
            isLocked ? 'Rate Locked' : 'Open Rate',
            style: TextStyle(
              color:
                  isLocked ? const Color(0xFF80500B) : const Color(0xFF176B52),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountDetail extends StatelessWidget {
  const _AmountDetail({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF263953), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
