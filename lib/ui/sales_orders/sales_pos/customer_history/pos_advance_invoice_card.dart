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
    required this.onCancelSaleDraft,
    this.isSelected = false,
    this.isLoaded = false,
  });

  final CustomerAdvanceOrderModel order;
  final double width;
  final bool isSelected;
  final bool isLoaded;
  final VoidCallback onViewBooking;
  final VoidCallback onUseInSale;
  final VoidCallback onCancelSaleDraft;

  @override
  Widget build(BuildContext context) {
    final rateLocked =
        PosAdvanceInvoiceFormatters.isRateLocked(order.bookingType);
    final accent =
        rateLocked ? SalesPosColors.goldHoverDark : const Color(0xFF176B52);

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 216),
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLoaded
              ? const Color(0xFF65C695)
              : isSelected
                  ? SalesPosColors.brandGold.withValues(alpha: 0.80)
                  : const Color(0xFFEBD7B8),
          width: isLoaded || isSelected ? 1.5 : 1,
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
          const SizedBox(height: 7),
          Text(
            order.itemName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
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
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF0E8D9)),
          const SizedBox(height: 8),
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
                height: 40,
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
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF0E8D9)),
          if (isLoaded) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF5E8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: Color(0xFF087D51)),
                  SizedBox(width: 5),
                  Text('Sale Draft Loaded',
                      style: TextStyle(
                          color: Color(0xFF087D51),
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 9),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewBooking,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View Booking',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: SalesPosColors.textDark,
              side: const BorderSide(color: Color(0xFFD38C00)),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isLoaded
              ? OutlinedButton.icon(
                  onPressed: onCancelSaleDraft,
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Cancel Draft',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBD3A32),
                    side: const BorderSide(color: Color(0xFFE59E97)),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                  ),
                )
              : _SaleActionButton(
                  showArrow: width >= 330,
                  onTap: onUseInSale,
                ),
        ),
      ],
    );
  }
}

class _SaleActionButton extends StatelessWidget {
  const _SaleActionButton({
    required this.showArrow,
    required this.onTap,
  });

  final bool showArrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE5AD21), Color(0xFFA96B00)],
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 17, color: Colors.white),
                const SizedBox(width: 5),
                const Flexible(
                  child: Text(
                    'Use in Sale',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                if (showArrow) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
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
          style: const TextStyle(color: Color(0xFF263953), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
