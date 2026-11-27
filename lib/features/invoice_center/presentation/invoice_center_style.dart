import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_colors.dart';

import '../domain/invoice_center_models.dart';

abstract final class InvoiceCenterStyle {
  static const background = SalesPosColors.bodyBg;
  static const surface = SalesPosColors.bodyPanelBg;
  static const ink = SalesPosColors.textDark;
  static const muted = SalesPosColors.bodyTextMain;
  static const border = SalesPosColors.bodyBorder;
  static const gold = Color(0xFFC99500);
  static const rowAlternate = Color(0xFFFCFAF6);
  static const header = Color(0xFFF4F0E8);
  static const double bodyTextSize = 14;
  static const FontWeight bodyTextWeight = FontWeight.w700;
  static const green = Color(0xFF12833D);
  static const red = Color(0xFFC03327);
  static const blue = Color(0xFF1266C3);
  static const purple = Color(0xFF5C30B6);

  static BoxDecoration panel({double radius = 14}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C182239),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      );
}

abstract final class InvoiceCenterFormat {
  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );
  static final _date = DateFormat('dd MMM yyyy');
  static final _month = DateFormat('MMM yyyy');

  static String money(double amount) => _money.format(amount);
  static String date(DateTime date) => _date.format(date);
  static String month(DateTime date) => _month.format(date);

  static String label(InvoiceCenterTab tab) => switch (tab) {
        InvoiceCenterTab.all => 'All Invoices',
        InvoiceCenterTab.regular => 'Regular Invoice',
        InvoiceCenterTab.gst => 'GST Invoice',
        InvoiceCenterTab.due => 'Due Invoice',
        InvoiceCenterTab.advance => 'Advance Invoice',
        InvoiceCenterTab.cancelled => 'Cancelled Invoice',
      };

  static IconData icon(InvoiceCenterTab tab) => switch (tab) {
        InvoiceCenterTab.all => Icons.grid_view_rounded,
        InvoiceCenterTab.regular => Icons.description_outlined,
        InvoiceCenterTab.gst => Icons.receipt_long_outlined,
        InvoiceCenterTab.due => Icons.hourglass_bottom_rounded,
        InvoiceCenterTab.advance => Icons.layers_outlined,
        InvoiceCenterTab.cancelled => Icons.cancel_outlined,
      };

  static Color color(InvoiceCenterTab tab) => switch (tab) {
        InvoiceCenterTab.all ||
        InvoiceCenterTab.regular =>
          InvoiceCenterStyle.gold,
        InvoiceCenterTab.gst => InvoiceCenterStyle.purple,
        InvoiceCenterTab.due => InvoiceCenterStyle.red,
        InvoiceCenterTab.advance => InvoiceCenterStyle.blue,
        InvoiceCenterTab.cancelled => InvoiceCenterStyle.muted,
      };

  static String status(String raw) => switch (raw) {
        'PARTIALLY_RETURNED' => 'Partial Return',
        'RETURNED' => 'Returned',
        'DELIVERED' => 'Delivered',
        'CANCELLED' => 'Cancelled',
        'ADVANCE' => 'Advance',
        'DUE' => 'Due',
        _ => 'Settled',
      };

  static Color statusColor(String raw) => switch (raw) {
        'DUE' => InvoiceCenterStyle.red,
        'ADVANCE' => InvoiceCenterStyle.blue,
        'CANCELLED' ||
        'RETURNED' ||
        'PARTIALLY_RETURNED' =>
          InvoiceCenterStyle.muted,
        'DELIVERED' || 'SETTLED' => InvoiceCenterStyle.green,
        _ => InvoiceCenterStyle.muted,
      };
}
