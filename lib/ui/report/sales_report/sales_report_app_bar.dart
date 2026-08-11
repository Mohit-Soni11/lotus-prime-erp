import 'package:flutter/material.dart';

import '../../../logic/report/sales_report/sales_report_export_service.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';

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

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: SalesReportStrings.back,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? SalesReportColors.shellBg
                  : SalesReportColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? SalesReportColors.brandGold
                    : SalesReportColors.shellBorder,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color:
                            SalesReportColors.brandGold.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              SalesReportIcons.back,
              color: _hovered
                  ? SalesReportColors.brandGold
                  : SalesReportColors.shellTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            SalesReportColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ModuleMark extends StatelessWidget {
  final bool isLoading;

  const _ModuleMark({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SalesReportColors.goldGradientStart,
            SalesReportColors.brandGold,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: SalesReportColors.brandGold.withValues(alpha: 0.46),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 15,
                height: 15,
                child: Center(
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : const Icon(
                SalesReportIcons.module,
                key: ValueKey('module'),
                color: Colors.white,
                size: 18,
              ),
      ),
    );
  }
}

class _HeaderTitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderTitleBlock({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SalesReportStyles.appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: SalesReportStyles.appBarSubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool loading;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(42, 42),
          backgroundColor: SalesReportColors.shellBorder.withValues(alpha: 0.3),
          foregroundColor: SalesReportColors.shellTitle,
          disabledForegroundColor:
              SalesReportColors.shellMuted.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: SalesReportColors.shellBorder),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SalesReportColors.brandGold,
                ),
              )
            : Icon(icon, size: 18),
      ),
    );
  }
}

class _HeaderExportMenu extends StatelessWidget {
  final List<SalesReportExportMenuItem> items;
  final ValueChanged<SalesReportExportAction>? onSelected;

  const _HeaderExportMenu({
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Download report',
      child: PopupMenuButton<SalesReportExportAction>(
        enabled: onSelected != null,
        tooltip: '',
        onSelected: onSelected,
        offset: const Offset(0, 48),
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
        itemBuilder: (_) => [
          for (final item in items)
            PopupMenuItem<SalesReportExportAction>(
              value: item.action,
              height: 44,
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: SalesReportColors.brandGold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SalesReportColors.shellBorder.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SalesReportColors.shellBorder),
          ),
          child: const Icon(
            SalesReportIcons.export,
            size: 18,
            color: SalesReportColors.shellTitle,
          ),
        ),
      ),
    );
  }
}

class _SystemOnlineBadge extends StatelessWidget {
  final AnimationController controller;

  const _SystemOnlineBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SalesReportColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: SalesReportColors.onlineGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _StatusWave(controller: controller, delay: 0),
                _StatusWave(controller: controller, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: SalesReportColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SalesReportColors.onlineGreen,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            SalesReportStrings.systemOnline,
            style: SalesReportStyles.onlineBadge,
          ),
        ],
      ),
    );
  }
}

class _StatusWave extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _StatusWave({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final value = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: 1 - value,
          child: Transform.scale(
            scale: 1 + (value * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SalesReportColors.onlineGreen.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
