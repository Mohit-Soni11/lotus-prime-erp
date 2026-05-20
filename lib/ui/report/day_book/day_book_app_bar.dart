// =============================================================================
// FILE        : day_book_app_bar.dart
// MODULE      : Reports & Analytics â†’ Day Book
// LAYER       : UI
// DESCRIPTION : Dark-shell AppBar â€” matches Booking Advance & Cash Book pattern.
//               âœ… Gold icon + radar blink live indicator
//               âœ… Gold hover back button
//               âœ… Date navigation (prev / today / next)
//               âœ… Export PDF / Excel / WhatsApp buttons
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import '../../../logic/report/day_book/day_book_controller.dart';

class DayBookAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final DayBookController ctrl;

  const DayBookAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<DayBookAppBar> createState() => _DayBookAppBarState();
}

class _DayBookAppBarState extends State<DayBookAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          height: 70.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: DayBookStyles.shellPanel,
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              // â”€â”€ Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _HoverBackButton(onTap: widget.onBack),
              const SizedBox(width: 16),

              // â”€â”€ Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _divider(),
              const SizedBox(width: 16),

              // â”€â”€ Module Icon + Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      DayBookColors.goldGradStart,
                      DayBookColors.brandGold
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: DayBookColors.brandGold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Icon(
                  DayBookIcons.moduleIcon,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DayBookStrings.appBarTitle,
                      style: DayBookStyles.appBarTitle),
                  const SizedBox(height: 4),
                  _RadarWidget(blinkCtrl: _blinkCtrl),
                ],
              ),

              const Spacer(),

              // â”€â”€ Date Navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _DateNav(ctrl: widget.ctrl),
              const SizedBox(width: 12),

              _divider(),
              const SizedBox(width: 12),

              // â”€â”€ Export Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _ExportButtons(ctrl: widget.ctrl),
            ]),
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              DayBookColors.shellBorder,
              Colors.transparent
            ],
          ),
        ),
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Date Navigation Widget
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DateNav extends StatelessWidget {
  final DayBookController ctrl;
  const _DateNav({required this.ctrl});

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return 'Today';
    }
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Prev
        _NavButton(
          icon: DayBookIcons.prevDay,
          onTap: ctrl.goToPreviousDay,
        ),
        const SizedBox(width: 4),

        // Date label (tappable â€” opens picker)
        GestureDetector(
          onTap: () => ctrl.selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DayBookColors.shellBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DayBookColors.shellBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(DayBookIcons.calendarNav,
                    color: DayBookColors.brandGold, size: 14),
                const SizedBox(width: 6),
                Text(
                  _formatDate(ctrl.selectedDate),
                  style: const TextStyle(
                    color: DayBookColors.shellTitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Next
        _NavButton(
          icon: DayBookIcons.nextDay,
          onTap: ctrl.canGoNext ? ctrl.goToNextDay : null,
        ),

        // Today shortcut
        if (!ctrl.isToday) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: ctrl.goToToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DayBookColors.brandGoldLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: DayBookColors.brandGold.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: DayBookColors.brandGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              DayBookColors.shellBorder.withValues(alpha: enabled ? 0.5 : 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DayBookColors.shellBorder),
        ),
        child: Icon(
          icon,
          color: enabled ? DayBookColors.shellTitle : DayBookColors.shellMuted,
          size: 16,
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Export Buttons
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ExportButtons extends StatelessWidget {
  final DayBookController ctrl;
  const _ExportButtons({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBtn(
            icon: DayBookIcons.exportPdf,
            tooltip: DayBookStrings.exportPdf,
            onTap: () {}),
        const SizedBox(width: 6),
        _IconBtn(
            icon: DayBookIcons.exportExcel,
            tooltip: DayBookStrings.exportExcel,
            onTap: () {}),
        const SizedBox(width: 6),
        _IconBtn(
            icon: DayBookIcons.shareWa,
            tooltip: DayBookStrings.shareWa,
            onTap: () {}),
      ],
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.tooltip, required this.onTap});
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _h
                  ? DayBookColors.brandGoldLight
                  : DayBookColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _h ? DayBookColors.brandGold : DayBookColors.shellBorder,
                width: _h ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _h ? DayBookColors.brandGold : DayBookColors.shellMuted,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Hover Back Button (exact pattern from Booking Advance)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});
  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _h ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _h
                  ? DayBookColors.shellBg
                  : DayBookColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _h ? DayBookColors.brandGold : DayBookColors.shellBorder,
                width: _h ? 1.5 : 1.0,
              ),
              boxShadow: _h
                  ? [
                      BoxShadow(
                        color: DayBookColors.brandGold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Icon(
              DayBookIcons.backArrow,
              color: _h ? DayBookColors.brandGold : DayBookColors.shellTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Radar / Online Widget (exact same as Booking Advance)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RadarWidget extends StatelessWidget {
  final AnimationController blinkCtrl;
  const _RadarWidget({required this.blinkCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
          width: 14,
          height: 14,
          child: Stack(alignment: Alignment.center, children: [
            _wave(blinkCtrl, 0.0),
            _wave(blinkCtrl, 0.5),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: DayBookColors.onlineGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DayBookColors.onlineGreen,
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ])),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: DayBookColors.onlineGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: DayBookColors.onlineGreen.withValues(alpha: 0.25)),
        ),
        child: const Text(
          DayBookStrings.systemOnline,
          style: TextStyle(
            color: DayBookColors.onlineGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ]);
  }

  Widget _wave(AnimationController ctrl, double delay) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final v = (ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - v,
          child: Transform.scale(
            scale: 1.0 + (v * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DayBookColors.onlineGreen.withValues(alpha: 0.5),
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
