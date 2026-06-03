import 'package:flutter/material.dart';

import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final bool isLoading;

  const DueReportAppBar({
    super.key,
    required this.onBack,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<DueReportAppBar> createState() => _DueReportAppBarState();
}

class _DueReportAppBarState extends State<DueReportAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: DueReportColors.appBarBg,
        border: const Border(
          bottom: BorderSide(color: DueReportColors.appBarBorder, width: 1),
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
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),
            const _VerticalDivider(),
            const SizedBox(width: 18),
            _ModuleIcon(isLoading: widget.isLoading),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DueReportStrings.title,
                    style: DueReportStyles.appBarTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
                  Text(
                    DueReportStrings.subtitle,
                    style: DueReportStyles.appBarSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _RefreshPill(
              isLoading: widget.isLoading,
              onRefresh: widget.onRefresh,
            ),
            const SizedBox(width: 10),
            _RadarWidget(controller: _radarCtrl),
          ],
        ),
      ),
    );
  }
}

class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
                ? DueReportColors.appBarSurface
                : DueReportColors.appBarBorder.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? DueReportColors.gold
                  : DueReportColors.appBarBorder,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: DueReportColors.gold.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            DueReportIcons.back,
            color: _hovered ? DueReportColors.gold : DueReportColors.textLight,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

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
            DueReportColors.appBarBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ModuleIcon extends StatelessWidget {
  final bool isLoading;

  const _ModuleIcon({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DueReportColors.goldBright, DueReportColors.gold],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: DueReportColors.gold.withValues(alpha: 0.44),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
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
                DueReportIcons.module,
                key: ValueKey('icon'),
                color: Colors.white,
                size: 18,
              ),
      ),
    );
  }
}

class _RefreshPill extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const _RefreshPill({required this.isLoading, required this.onRefresh});

  @override
  State<_RefreshPill> createState() => _RefreshPillState();
}

class _RefreshPillState extends State<_RefreshPill> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Tooltip(
        message: DueReportStrings.refresh,
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onRefresh,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _hovered
                  ? DueReportColors.gold.withValues(alpha: 0.16)
                  : DueReportColors.appBarSurface.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _hovered
                    ? DueReportColors.gold.withValues(alpha: 0.55)
                    : DueReportColors.appBarBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DueReportColors.gold,
                    ),
                  )
                else
                  const Icon(
                    DueReportIcons.refresh,
                    color: DueReportColors.gold,
                    size: 16,
                  ),
                const SizedBox(width: 7),
                const Text(
                  DueReportStrings.refresh,
                  style: TextStyle(
                    color: DueReportColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarWidget extends StatelessWidget {
  final AnimationController controller;

  const _RadarWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DueReportColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: DueReportColors.onlineGreen.withValues(alpha: 0.3),
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
                _RadarWave(controller: controller, delay: 0),
                _RadarWave(controller: controller, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: DueReportColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DueReportColors.onlineGreen,
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
          const Text(
            DueReportStrings.systemOnline,
            style: DueReportStyles.onlineBadge,
          ),
        ],
      ),
    );
  }
}

class _RadarWave extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _RadarWave({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final value = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - value,
          child: Transform.scale(
            scale: 1.0 + (value * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DueReportColors.onlineGreen.withValues(alpha: 0.5),
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
