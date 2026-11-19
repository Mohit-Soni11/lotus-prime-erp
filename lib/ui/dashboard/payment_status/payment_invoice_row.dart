import 'package:flutter/material.dart';

import '../../../logic/dashboard/payment_status/payment_status_logic.dart';
import '../../../models/dashboard/payment_bill_item.dart';
import '../../../theme/dashboard/payment_status/payment_status_theme.dart';

class PaymentInvoiceRow extends StatelessWidget {
  const PaymentInvoiceRow({
    super.key,
    required this.bill,
    required this.onOpenCustomer,
    required this.onOpenInvoice,
  });

  final PaymentBillItem bill;
  final ValueChanged<int> onOpenCustomer;
  final VoidCallback onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: PaymentStatusColors.rowBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('open-invoice-${bill.billId}'),
          onTap: onOpenInvoice,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PaymentStatusColors.rowBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          PaymentStatusColors.accentDimFor(bill.status),
                      child: Text(bill.customerInitials,
                          style: TextStyle(
                              color: PaymentStatusColors.accentFor(bill.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bill.customerId != null)
                            InkWell(
                              key: ValueKey('open-customer-${bill.billId}'),
                              onTap: () => onOpenCustomer(bill.customerId!),
                              child: Text(
                                bill.customerName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: PaymentStatusStyles.customerNameStyle,
                              ),
                            )
                          else
                            Text(bill.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PaymentStatusStyles.customerNameStyle),
                          const SizedBox(height: 3),
                          Text('Invoice ${bill.billNo}  ↗',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PaymentStatusStyles.billNoStyle.copyWith(
                                color: PaymentStatusColors.accentGold,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _amount('Total', bill.totalAmount, Colors.white),
                    _amount('Paid', bill.paidAmount,
                        PaymentStatusColors.amountPaid),
                    if (bill.dueAmount > 0.5)
                      _amount(
                          'DUE', bill.dueAmount, PaymentStatusColors.amountDue),
                    _statusBadge(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amount(String label, double value, Color color) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                  color: label == 'DUE'
                      ? PaymentStatusColors.amountDue
                      : PaymentStatusColors.textSecondary,
                  fontSize: 11),
            ),
            TextSpan(
              text: PaymentStatusLogic.formatAmountFull(value),
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _statusBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: PaymentStatusStyles.badgeDecoration(bill.status),
        child: Text(
          PaymentStatusColors.badgeLabelFor(bill.status),
          style: PaymentStatusStyles.badgeStyle.copyWith(
            fontSize: 10,
            color: PaymentStatusColors.badgeTextFor(bill.status),
          ),
        ),
      );
}
