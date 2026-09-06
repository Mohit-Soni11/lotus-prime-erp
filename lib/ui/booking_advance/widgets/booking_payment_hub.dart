import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'booking_money_text.dart';
import 'booking_section_header.dart';

class BookingPaymentHub extends StatelessWidget {
  const BookingPaymentHub({super.key, required this.controller});

  final BookingAdvanceController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BookingSectionHeader(
            icon: BookingAdvanceIcons.advancePayment,
            title: BookingAdvanceStrings.sectionPayment,
            subtitle: BookingAdvanceStrings.paymentSubtitle,
          ),
          const SizedBox(height: 16),
          _PaymentEntryRow(
            label: BookingAdvanceStrings.lblCash,
            icon: BookingAdvanceIcons.cash,
            color: BookingAdvanceColors.cashColor,
            controller: controller.cashCtrl,
          ),
          const SizedBox(height: 10),
          _PaymentEntryRow(
            label: BookingAdvanceStrings.lblUpi,
            icon: BookingAdvanceIcons.upi,
            color: BookingAdvanceColors.upiColor,
            controller: controller.upiCtrl,
          ),
          const SizedBox(height: 10),
          _PaymentEntryRow(
            label: BookingAdvanceStrings.lblCard,
            icon: BookingAdvanceIcons.card,
            color: BookingAdvanceColors.cardColor,
            controller: controller.cardCtrl,
          ),
          const SizedBox(height: 16),
          _AdvanceTotalTile(totalAdvance: controller.totalAdvance),
          if (controller.totalBookingVal > 0) ...[
            const SizedBox(height: 10),
            _BalanceDueTile(balanceDue: controller.balanceDue),
          ],
        ],
      ),
    );
  }
}

class _PaymentEntryRow extends StatelessWidget {
  const _PaymentEntryRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.controller,
  });

  final String label;
  final IconData icon;
  final Color color;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: BookingAdvanceStyles.inputText,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color:
                      BookingAdvanceColors.bodyTextMuted.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                prefixText: '${BookingMoneyText.symbol}  ',
                prefixStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: color.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: color.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvanceTotalTile extends StatelessWidget {
  const _AdvanceTotalTile({required this.totalAdvance});

  final double totalAdvance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BookingAdvanceColors.brandGold.withValues(alpha: 0.08),
            BookingAdvanceColors.brandGold.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BookingAdvanceColors.brandGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            BookingAdvanceStrings.lblAdvanceTotal,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: BookingAdvanceColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            BookingMoneyText.whole(totalAdvance),
            style: BookingAdvanceStyles.grandTotalText,
          ),
          if (totalAdvance > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BookingAdvanceColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                BookingAdvanceStrings.advanceReceived,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: BookingAdvanceColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceDueTile extends StatelessWidget {
  const _BalanceDueTile({required this.balanceDue});

  final double balanceDue;

  @override
  Widget build(BuildContext context) {
    final isDue = balanceDue > 0;
    final color =
        isDue ? BookingAdvanceColors.warning : BookingAdvanceColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'BALANCE DUE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            BookingMoneyText.whole(balanceDue.abs()),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
