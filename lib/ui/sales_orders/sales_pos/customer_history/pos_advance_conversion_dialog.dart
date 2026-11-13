import 'package:flutter/material.dart';

import '../../../../models/customer/customer_profile/customer_profile_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

Future<bool> confirmAdvanceConversion(
  BuildContext context,
  CustomerAdvanceOrderModel order,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Use booking in sale'),
          content: Text(
            'The current sale entry will be replaced with booking ${order.orderNo}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep current sale'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: SalesPosColors.goldHoverDark,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: const Text('Use in Sale'),
            ),
          ],
        ),
      ) ??
      false;
}
