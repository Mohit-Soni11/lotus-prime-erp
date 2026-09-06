import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'booking_money_text.dart';
import 'booking_section_header.dart';

class BookingSummaryBoard extends StatelessWidget {
  const BookingSummaryBoard({super.key, required this.controller});

  final BookingAdvanceController controller;

  @override
  Widget build(BuildContext context) {
    final isLocked = controller.bookingType == BookingType.locked;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BookingSectionHeader(
            icon: BookingAdvanceIcons.summaryIcon,
            title: BookingAdvanceStrings.sectionSummary,
            subtitle: BookingAdvanceStrings.summarySubtitle,
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Customer',
            value: controller.nameCtrl.text.isNotEmpty
                ? controller.nameCtrl.text
                : '-',
            valueColor: controller.nameCtrl.text.isNotEmpty
                ? BookingAdvanceColors.textDark
                : BookingAdvanceColors.bodyTextMuted,
          ),
          _SummaryRow(
            label: 'Total Items',
            value: '${controller.bookingItems.length} item(s)',
          ),
          _SummaryRow(
            label: 'Rate Type',
            value: isLocked
                ? BookingAdvanceStrings.lockedBadge
                : BookingAdvanceStrings.openBadge,
            valueColor: isLocked
                ? BookingAdvanceColors.lockedRateColor
                : BookingAdvanceColors.openRateColor,
          ),
          if (isLocked && controller.lockedRate > 0)
            _SummaryRow(
              label: 'Locked Rate',
              value: '${BookingMoneyText.whole(controller.lockedRate)} / g',
              valueColor: BookingAdvanceColors.lockedRateColor,
            ),
          if (controller.deliveryDate != null)
            _SummaryRow(
              label: 'Delivery Date',
              value: DateFormat('dd MMM yyyy').format(controller.deliveryDate!),
            ),
          const SizedBox(height: 12),
          _BookingValueTile(
            label: 'APPROX. BOOKING VALUE',
            value: BookingMoneyText.whole(controller.totalBookingVal),
          ),
          if (controller.scrapItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ScrapValueTile(value: controller.totalScrapVal),
          ],
        ],
      ),
    );
  }
}

class _BookingValueTile extends StatelessWidget {
  const _BookingValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BookingAdvanceColors.bodyBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BookingAdvanceStyles.totalRowLabel),
          Text(value, style: BookingAdvanceStyles.totalRowValue),
        ],
      ),
    );
  }
}

class _ScrapValueTile extends StatelessWidget {
  const _ScrapValueTile({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.danger.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BookingAdvanceColors.danger.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.recycling_rounded,
                color: BookingAdvanceColors.danger,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'SCRAP METAL VALUE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: BookingAdvanceColors.danger,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Text(
            BookingMoneyText.whole(value),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: BookingAdvanceColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BookingAdvanceStyles.summaryLabel),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: BookingAdvanceStyles.summaryValue.copyWith(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
