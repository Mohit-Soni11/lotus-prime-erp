import 'package:flutter/material.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import '../../shared/system_status_badge.dart';

class DayBookAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DayBookAppBar({super.key, required this.onBack, required this.ctrl});

  final VoidCallback onBack;
  final DayBookController ctrl;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          return Container(
            height: preferredSize.height,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
            decoration: const BoxDecoration(
              color: DayBookColors.shellPanel,
              border:
                  Border(bottom: BorderSide(color: DayBookColors.shellBorder)),
            ),
            child: SafeArea(
              bottom: false,
              child: ListenableBuilder(
                listenable: ctrl,
                builder: (context, _) => Row(children: [
                  IconButton(
                    onPressed: onBack,
                    tooltip: 'Back',
                    icon: const Icon(DayBookIcons.back, color: Colors.white),
                    style: IconButton.styleFrom(
                      fixedSize: const Size(42, 42),
                      backgroundColor:
                          DayBookColors.shellBorder.withValues(alpha: 0.3),
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 18),
                  if (!compact) ...[
                    Container(
                        width: 1, height: 32, color: DayBookColors.shellBorder),
                    const SizedBox(width: 18),
                  ],
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        DayBookColors.goldGradientStart,
                        DayBookColors.brandGold
                      ]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(DayBookIcons.module,
                        color: Colors.white, size: 18),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Text(
                      DayBookStrings.moduleTitle.toUpperCase(),
                      style: DayBookStyles.appBarTitle.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SystemStatusBadge(
                    status: ctrl.isLoading
                        ? SystemStatus.loading
                        : ctrl.errorMessage != null
                            ? SystemStatus.unavailable
                            : SystemStatus.online,
                    showLabel: !compact,
                  ),
                ]),
              ),
            ),
          );
        },
      );
}
