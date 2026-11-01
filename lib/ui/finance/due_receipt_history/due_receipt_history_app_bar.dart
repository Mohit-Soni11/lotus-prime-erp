import 'package:flutter/material.dart';

import '../../../theme/finance/due_receipt_history/due_receipt_history_theme.dart';
import '../../shared/system_status_badge.dart';

class DueReceiptHistoryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DueReceiptHistoryAppBar({
    super.key,
    required this.onBack,
    required this.status,
  });

  final VoidCallback onBack;
  final SystemStatus status;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
          decoration: const BoxDecoration(
            color: DueReceiptHistoryColors.appBarBg,
            border: Border(
                bottom:
                    BorderSide(color: DueReceiptHistoryColors.appBarBorder)),
            boxShadow: [
              BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 16,
                  offset: Offset(0, 4))
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Material(
                  color: DueReceiptHistoryColors.appBarBorder
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(10),
                    child: const Tooltip(
                      message: 'Back',
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(DueReceiptHistoryIcons.back,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 10 : 18),
                if (!compact) ...[
                  Container(
                      width: 1,
                      height: 32,
                      color: DueReceiptHistoryColors.appBarBorder),
                  const SizedBox(width: 18),
                ],
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      DueReceiptHistoryColors.goldBright,
                      DueReceiptHistoryColors.gold
                    ]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(DueReceiptHistoryIcons.module,
                      color: Colors.white, size: 18),
                ),
                SizedBox(width: compact ? 10 : 14),
                const Expanded(
                  child: Text(
                    'DUE RECEIPT HISTORY',
                    style: DueReceiptHistoryStyles.appBarTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SystemStatusBadge(
                    status: status, showLabel: constraints.maxWidth >= 650),
              ],
            ),
          ),
        );
      },
    );
  }
}
