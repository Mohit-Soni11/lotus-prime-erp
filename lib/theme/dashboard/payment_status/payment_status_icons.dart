// =============================================================================
// FILE        : payment_status_icons.dart
// =============================================================================
import 'package:flutter/material.dart';
import '../../../models/dashboard/payment_bill_item.dart';

class PaymentStatusIcons {
  static const IconData header = Icons.account_balance_wallet_rounded;
  static const IconData paid = Icons.check_circle_rounded;
  static const IconData partial = Icons.hourglass_bottom_rounded;
  static const IconData unpaid = Icons.cancel_rounded;
  static const IconData chevron = Icons.keyboard_arrow_down_rounded;
  static const IconData profile = Icons.person_rounded;

  static IconData forStatus(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return paid;
      case PaymentStatus.partial:
        return partial;
      case PaymentStatus.unpaid:
        return unpaid;
    }
  }
}
