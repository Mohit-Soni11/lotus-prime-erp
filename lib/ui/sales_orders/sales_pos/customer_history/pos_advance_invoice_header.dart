import 'package:flutter/material.dart';

import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'pos_advance_invoice_formatters.dart';
import 'pos_advance_invoice_metric.dart';

class PosAdvanceInvoiceHeader extends StatelessWidget {
  const PosAdvanceInvoiceHeader({
    super.key,
    required this.bookingCount,
    required this.advanceTotal,
  });

  final int bookingCount;
  final double advanceTotal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final heading = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFC52F), Color(0xFFB87A00)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                size: 37,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Booking Advance Invoices',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SalesPosColors.textDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Advance bookings ready for sales conversion',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          SalesPosColors.bodyTextMain.withValues(alpha: 0.85),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final metrics = Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            PosAdvanceInvoiceMetric(
              icon: Icons.description_outlined,
              label: 'Total Bookings',
              value: '$bookingCount',
              width: width >= 900 ? 220 : 202,
            ),
            PosAdvanceInvoiceMetric(
              icon: Icons.stacked_bar_chart_rounded,
              label: 'Total Advance',
              value: PosAdvanceInvoiceFormatters.money(
                advanceTotal,
                alwaysShowPaise: true,
              ),
              width: width >= 900 ? 270 : 240,
              valueColor: SalesPosColors.goldHoverDark,
            ),
          ],
        );

        if (width < 1050) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 15),
              metrics,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            metrics,
          ],
        );
      },
    );
  }
}
