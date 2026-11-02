import 'package:flutter/material.dart';

import '../../../theme/finance/cash_book/cash_book_theme.dart';
import '../../shared/system_status_badge.dart';

class CashBookAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CashBookAppBar({
    super.key,
    required this.onBack,
    required this.status,
    this.onHome,
    this.showHomeAction = false,
    this.onExportCsv,
    this.onPrintPdf,
  });

  final VoidCallback onBack;
  final VoidCallback? onHome;
  final bool showHomeAction;
  final SystemStatus status;
  final VoidCallback? onExportCsv;
  final VoidCallback? onPrintPdf;

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
                    child: Tooltip(
                      message:
                          showHomeAction ? 'Back to Cash Book Home' : 'Back',
                      child: const SizedBox(
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
                  child: InkWell(
                    onTap: onHome,
                    borderRadius: BorderRadius.circular(8),
                    child: Tooltip(
                      message: 'Cash Book Home',
                      child: Text(
                        CashBookStrings.moduleTitle.toUpperCase(),
                        style: CashBookStyles.appBarTitle.copyWith(
                            letterSpacing: 0.3, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (showHomeAction && onHome != null)
                  IconButton(
                    tooltip: 'Cash Book Home',
                    onPressed: onHome,
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                  ),
                if (onExportCsv != null && onPrintPdf != null)
                  PopupMenuButton<String>(
                    tooltip: 'Export Cash Book',
                    icon: const Icon(Icons.ios_share_rounded,
                        color: Colors.white),
                    onSelected: (value) =>
                        value == 'csv' ? onExportCsv!() : onPrintPdf!(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                      PopupMenuItem(value: 'pdf', child: Text('Print / PDF')),
                    ],
                  ),
                SystemStatusBadge(status: status, showLabel: !compact),
              ],
            ),
          ),
        );
      },
    );
  }
}
