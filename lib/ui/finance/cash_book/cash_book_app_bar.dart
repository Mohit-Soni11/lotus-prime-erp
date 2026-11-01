import 'package:flutter/material.dart';

import '../../../theme/finance/cash_book/cash_book_theme.dart';
import '../../shared/system_status_badge.dart';

class CashBookAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CashBookAppBar({
    super.key,
    required this.onBack,
    required this.status,
    required this.onAddEntry,
    required this.onSyncBills,
  });

  final VoidCallback onBack;
  final SystemStatus status;
  final VoidCallback onAddEntry;
  final VoidCallback onSyncBills;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 740;
        return Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
          decoration: const BoxDecoration(
            color: CashBookColors.shellPanel,
            border:
                Border(bottom: BorderSide(color: CashBookColors.shellBorder)),
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
                  color: CashBookColors.shellBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(10),
                    child: const Tooltip(
                      message: 'Back',
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 10 : 18),
                if (!compact) ...[
                  Container(
                      width: 1, height: 32, color: CashBookColors.shellBorder),
                  const SizedBox(width: 18),
                ],
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFF4D65E), CashBookColors.brandGold]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CashBookIcons.moduleIcon,
                      color: Colors.white, size: 18),
                ),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: Text(
                    CashBookStrings.moduleTitle.toUpperCase(),
                    style: CashBookStyles.appBarTitle.copyWith(
                        letterSpacing: 0.3, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!compact) ...[
                  SystemStatusBadge(status: status, showLabel: true),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: onSyncBills,
                    icon: const Icon(CashBookIcons.sync, size: 18),
                    label: const Text('Sync Bills'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: CashBookColors.shellBorder),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onAddEntry,
                    icon: const Icon(CashBookIcons.addEntry, size: 18),
                    label: const Text('Add Entry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CashBookColors.brandGold,
                      foregroundColor: CashBookColors.textDark,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ] else ...[
                  IconButton(
                    onPressed: onSyncBills,
                    tooltip: CashBookStrings.syncBills,
                    icon: const Icon(CashBookIcons.sync, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: onAddEntry,
                    tooltip: CashBookStrings.addEntry,
                    icon: const Icon(CashBookIcons.addEntry,
                        color: CashBookColors.brandGold),
                  ),
                  SystemStatusBadge(status: status, showLabel: false),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
