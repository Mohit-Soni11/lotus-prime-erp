import 'package:flutter/material.dart';

import '../exports/gst_report_export_service.dart';
import '../theme/gst_report_theme.dart';

class GstReportExportMenuItem {
  const GstReportExportMenuItem({
    required this.action,
    required this.label,
    required this.icon,
    required this.section,
    this.subtitle = '',
    this.primary = false,
  });

  final GstReportExportAction action;
  final String label;
  final IconData icon;
  final String section;
  final String subtitle;
  final bool primary;
}

class GstReportAppBar extends StatefulWidget implements PreferredSizeWidget {
  const GstReportAppBar({
    super.key,
    required this.onBack,
    this.onRefresh,
    this.onExportSelected,
    this.exportItems = const [],
    this.isLoading = false,
  });

  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final ValueChanged<GstReportExportAction>? onExportSelected;
  final List<GstReportExportMenuItem> exportItems;
  final bool isLoading;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<GstReportAppBar> createState() => _GstReportAppBarState();
}

class _GstReportAppBarState extends State<GstReportAppBar>
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
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: GstReportColors.shellPanel,
        border: const Border(
          bottom: BorderSide(color: GstReportColors.shellBorder),
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
            const Expanded(child: _HeaderTitleBlock()),
            if (widget.onExportSelected != null &&
                widget.exportItems.isNotEmpty) ...[
              _HeaderExportMenu(
                items: widget.exportItems,
                onSelected: widget.isLoading ? null : widget.onExportSelected,
              ),
              const SizedBox(width: 8),
            ],
            if (widget.onRefresh != null) ...[
              _HeaderIconButton(
                icon: GstReportIcons.refresh,
                tooltip: GstReportStrings.refresh,
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
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: GstReportStrings.back,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? GstReportColors.shellBg
                  : GstReportColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? GstReportColors.brandGold
                    : GstReportColors.shellBorder,
                width: _hovered ? 1.5 : 1,
              ),
            ),
            child: Icon(
              GstReportIcons.back,
              color: _hovered
                  ? GstReportColors.brandGold
                  : GstReportColors.shellTitle,
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
            GstReportColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ModuleMark extends StatelessWidget {
  const _ModuleMark({required this.isLoading});

  final bool isLoading;

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
            GstReportColors.goldGradientStart,
            GstReportColors.brandGold,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: GstReportColors.brandGold.withValues(alpha: 0.46),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('gst-loading-mark'),
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
                GstReportIcons.module,
                key: ValueKey('gst-module-mark'),
                color: Colors.white,
                size: 18,
              ),
      ),
    );
  }
}

class _HeaderTitleBlock extends StatelessWidget {
  const _HeaderTitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GstReportStrings.moduleTitle,
          style: GstReportStyles.appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          GstReportStrings.moduleSubtitle,
          style: GstReportStyles.appBarSubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(42, 42),
          backgroundColor: GstReportColors.shellBorder.withValues(alpha: 0.3),
          foregroundColor: GstReportColors.shellTitle,
          disabledForegroundColor:
              GstReportColors.shellMuted.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: GstReportColors.shellBorder),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GstReportColors.brandGold,
                ),
              )
            : Icon(icon, size: 18),
      ),
    );
  }
}

class _HeaderExportMenu extends StatelessWidget {
  const _HeaderExportMenu({
    required this.items,
    required this.onSelected,
  });

  final List<GstReportExportMenuItem> items;
  final ValueChanged<GstReportExportAction>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Export GST report',
      child: PopupMenuButton<GstReportExportAction>(
        enabled: onSelected != null,
        tooltip: '',
        onSelected: onSelected,
        offset: const Offset(0, 48),
        constraints: const BoxConstraints(minWidth: 380, maxWidth: 430),
        itemBuilder: (_) => _menuEntries(),
        child: Container(
          width: 104,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GstReportColors.shellBorder.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GstReportColors.shellBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                GstReportIcons.export,
                size: 18,
                color: GstReportColors.shellTitle,
              ),
              SizedBox(width: 8),
              Text(
                'EXPORT',
                style: TextStyle(
                  color: GstReportColors.shellTitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<GstReportExportAction>> _menuEntries() {
    final entries = <PopupMenuEntry<GstReportExportAction>>[];
    String? currentSection;
    for (final item in items) {
      if (item.section != currentSection) {
        currentSection = item.section;
        entries.add(_ExportSectionHeader(title: item.section));
      }
      entries.add(
        PopupMenuItem<GstReportExportAction>(
          key: ValueKey('gst-report-export-${item.action.name}'),
          value: item.action,
          height: item.subtitle.isEmpty ? 44 : 58,
          child: _ExportMenuRow(item: item),
        ),
      );
    }
    return entries;
  }
}

class _ExportSectionHeader extends PopupMenuEntry<GstReportExportAction> {
  const _ExportSectionHeader({required this.title});

  final String title;

  @override
  double get height => 30;

  @override
  bool represents(GstReportExportAction? value) => false;

  @override
  State<_ExportSectionHeader> createState() => _ExportSectionHeaderState();
}

class _ExportSectionHeaderState extends State<_ExportSectionHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 5),
      child: Text(
        widget.title.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GstReportStyles.body.copyWith(
          color: GstReportColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExportMenuRow extends StatelessWidget {
  const _ExportMenuRow({required this.item});

  final GstReportExportMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.primary ? GstReportColors.brandGold : GstReportColors.taxGreen;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: item.primary ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(item.icon, size: 17, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GstReportStyles.body.copyWith(
                  color: GstReportColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SystemOnlineBadge extends StatelessWidget {
  const _SystemOnlineBadge({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GstReportColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: GstReportColors.onlineGreen.withValues(alpha: 0.3),
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
                    color: GstReportColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GstReportColors.onlineGreen,
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
            GstReportStrings.systemOnline,
            style: GstReportStyles.onlineBadge,
          ),
        ],
      ),
    );
  }
}

class _StatusWave extends StatelessWidget {
  const _StatusWave({required this.controller, required this.delay});

  final AnimationController controller;
  final double delay;

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
                  color: GstReportColors.onlineGreen.withValues(alpha: 0.5),
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
