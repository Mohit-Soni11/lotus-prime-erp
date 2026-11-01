import 'package:flutter/material.dart';

import '../../../theme/finance/due_report/due_report_theme.dart';
import '../../shared/system_status_badge.dart';

class DueReportAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DueReportAppBar({
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
        final compact = constraints.maxWidth < 500;

        return Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
          decoration: const BoxDecoration(
            color: DueReportColors.appBarBg,
            border: Border(
              bottom: BorderSide(color: DueReportColors.appBarBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Material(
                  color: DueReportColors.appBarBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(10),
                    child: const Tooltip(
                      message: 'Back',
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          DueReportIcons.back,
                          color: DueReportColors.textLight,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 10 : 18),
                if (!compact) ...[
                  Container(
                    width: 1,
                    height: 32,
                    color: DueReportColors.appBarBorder,
                  ),
                  const SizedBox(width: 18),
                ],
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DueReportColors.goldBright,
                        DueReportColors.gold,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    DueReportIcons.module,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: Text(
                    DueReportStrings.title.toUpperCase(),
                    style: DueReportStyles.appBarTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SystemStatusBadge(
                  status: status,
                  showLabel: constraints.maxWidth >= 650,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
