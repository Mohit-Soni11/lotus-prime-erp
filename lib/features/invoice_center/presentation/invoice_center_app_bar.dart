import 'package:flutter/material.dart';

import 'package:lotus_erp/ui/shared/lotus_module_app_bar.dart';

class InvoiceCenterAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const InvoiceCenterAppBar({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) => LotusModuleAppBar(
        onBack: onBack,
        icon: Icons.receipt_long_rounded,
        title: 'INVOICE CENTER',
      );
}
