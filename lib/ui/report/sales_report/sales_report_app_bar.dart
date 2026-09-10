import 'package:flutter/material.dart';

import '../../../logic/report/sales_report/sales_report_export_service.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';

part 'sales_report_app_bar_widgets.dart';

class SalesReportExportMenuItem {
  final SalesReportExportAction action;
  final String label;
  final IconData icon;

  const SalesReportExportMenuItem({
    required this.action,
    required this.label,
    required this.icon,
  });
}

class SalesReportAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final ValueChanged<SalesReportExportAction>? onExportSelected;
  final List<SalesReportExportMenuItem> exportItems;
  final bool isLoading;
  final String title;
  final String subtitle;

  const SalesReportAppBar({
    super.key,
    required this.onBack,
    this.onRefresh,
    this.onExportSelected,
    this.exportItems = const [],
    this.isLoading = false,
    this.title = SalesReportStrings.moduleTitle,
    this.subtitle = SalesReportStrings.moduleSubtitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<SalesReportAppBar> createState() => _SalesReportAppBarState();
}

class _SalesReportAppBarState extends State<SalesReportAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _statusController;

  @override
  void initState() {
    super.initState();
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: SalesReportColors.shellPanel,
        border: const Border(
          bottom: BorderSide(color: SalesReportColors.shellBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _BackButton(onTap: widget.onBack),
            const SizedBox(width: 18),
            const _HeaderDivider(),
            const SizedBox(width: 18),
            _ModuleMark(isLoading: widget.isLoading),
            const SizedBox(width: 14),
            Expanded(
              child: _HeaderTitleBlock(
                title: widget.title,
                subtitle: widget.subtitle,
              ),
            ),
            if (widget.onExportSelected != null &&
                widget.exportItems.isNotEmpty) ...[
              _HeaderExportMenu(
                items: widget.exportItems,
                onSelected: widget.isLoading ? null : widget.onExportSelected!,
              ),
              const SizedBox(width: 8),
            ],
            if (widget.onRefresh != null) ...[
              _HeaderIconButton(
                icon: SalesReportIcons.refresh,
                tooltip: SalesReportStrings.refresh,
                onPressed: widget.isLoading ? null : widget.onRefresh,
                loading: widget.isLoading,
              ),
              const SizedBox(width: 10),
            ],
            _SystemOnlineBadge(controller: _statusController),
          ],
        ),
      ),
    );
  }
}
