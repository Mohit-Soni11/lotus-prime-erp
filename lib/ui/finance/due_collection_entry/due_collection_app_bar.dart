import 'package:flutter/material.dart';

import '../../../theme/finance/due_collection_entry/due_collection_entry_theme.dart';
import '../../shared/system_status_badge.dart';

class DueCollectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DueCollectionAppBar({
    super.key,
    required this.onBack,
    required this.status,
    this.onReset,
  });

  final VoidCallback onBack;
  final SystemStatus status;
  final VoidCallback? onReset;

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
            color: DueCollectionEntryColors.shellPanel,
            border: Border(
                bottom:
                    BorderSide(color: DueCollectionEntryColors.shellBorder)),
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
                  color: DueCollectionEntryColors.shellBorder
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
                        child: Icon(DueCollectionEntryIcons.back,
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
                      color: DueCollectionEntryColors.shellBorder),
                  const SizedBox(width: 18),
                ],
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFF4D65E),
                      DueCollectionEntryColors.brandGold
                    ]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(DueCollectionEntryIcons.module,
                      color: Colors.white, size: 18),
                ),
                SizedBox(width: compact ? 10 : 14),
                const Expanded(
                  child: Text(
                    'DUE COLLECTION ENTRY',
                    style: DueCollectionEntryStyles.appBarTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onReset != null && constraints.maxWidth >= 780) ...[
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(DueCollectionEntryIcons.reset, size: 17),
                    label: const Text('Reset Entry'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (onReset != null && constraints.maxWidth < 780) ...[
                  IconButton(
                    onPressed: onReset,
                    tooltip: 'Reset Entry',
                    icon: const Icon(DueCollectionEntryIcons.reset,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                ],
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
