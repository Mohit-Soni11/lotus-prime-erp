// =============================================================================
// FILE        : booking_status_bar.dart
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../logic/dashboard/date_card/date_card_logic.dart';

class BookingStatusBar extends StatefulWidget {
  final BookingAdvanceController ctrl;
  const BookingStatusBar({super.key, required this.ctrl});

  @override
  State<BookingStatusBar> createState() => _BookingStatusBarState();
}

class _BookingStatusBarState extends State<BookingStatusBar>
    with SingleTickerProviderStateMixin {
  late final DateCardLogic _dateLogic;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _dateLogic = DateCardLogic()..init();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _dateLogic.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Align(alignment: Alignment.centerLeft, child: _buildCard()),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final isLocked = widget.ctrl.bookingType == BookingType.locked;
    final accent = isLocked
        ? BookingAdvanceColors.lockedRateColor
        : BookingAdvanceColors.brandGold;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BookingAdvanceColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
              color: BookingAdvanceColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
          BoxShadow(
              color: BookingAdvanceColors.shadowDark,
              blurRadius: 20,
              offset: Offset(0, 6)),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line(20, 1.0),
                        const SizedBox(height: 3),
                        _line(13, 0.45),
                        const SizedBox(height: 3),
                        _line(7, 0.18),
                      ]),
                  const SizedBox(width: 12),
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(BookingAdvanceStrings.sectionBookingNo,
                            style: BookingAdvanceStyles.highVisHeader),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 260),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? BookingAdvanceColors.lockedRateColor
                                  : BookingAdvanceColors.bodyTextMuted),
                          child: Text(isLocked
                              ? BookingAdvanceStrings.lockedRate
                              : BookingAdvanceStrings.openRate),
                        ),
                      ]),
                ]),
                const SizedBox(width: 40),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: accent)),
                    const SizedBox(width: 6),
                    Text(BookingAdvanceStrings.bookingBadge,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: accent)),
                  ]),
                ),
              ],
            ),
            Container(
                height: 1,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                color: BookingAdvanceColors.bodyBorder),
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Stack(children: [
                      Positioned(
                          top: 0,
                          left: 8,
                          right: 8,
                          child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                Colors.transparent,
                                accent.withValues(alpha: 0.55),
                                Colors.transparent
                              ])))),
                      Center(
                          child: Icon(BookingAdvanceIcons.moduleIcon,
                              color: accent, size: 24)),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  // Booking number
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(BookingAdvanceStrings.bookingNoLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                color: BookingAdvanceColors.textDark,
                                height: 1)),
                        const SizedBox(height: 4),
                        Text(widget.ctrl.formattedBookingNo,
                            style: TextStyle(
                                color: accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                height: 1)),
                      ]),
                  const SizedBox(width: 24),
                  // Vertical rule
                  Container(
                      width: 1,
                      height: 34,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                            Colors.transparent,
                            BookingAdvanceColors.bodyBorder,
                            Colors.transparent
                          ]))),
                  const SizedBox(width: 20),
                  // Date + Time
                  StreamBuilder<DateCardModel>(
                    stream: _dateLogic.timeStream,
                    initialData: _dateLogic.initialData,
                    builder: (_, snap) {
                      final d = snap.data!;
                      final tp = d.time.split(':');
                      final t = tp.length >= 2 ? '${tp[0]} : ${tp[1]}' : d.time;
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        _chip(
                            BookingAdvanceIcons.calendarDate,
                            BookingAdvanceColors.textDark,
                            BookingAdvanceStrings.dateLabel,
                            d.date.toUpperCase(),
                            BookingAdvanceColors.textDark,
                            13,
                            BookingAdvanceColors.bodyBg,
                            BookingAdvanceColors.bodyBorder),
                        const SizedBox(width: 8),
                        Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                color: BookingAdvanceColors.bodyTextMuted,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        _chip(
                            BookingAdvanceIcons.clockTime,
                            BookingAdvanceColors.success,
                            BookingAdvanceStrings.timeLabel,
                            t,
                            BookingAdvanceColors.success,
                            14,
                            BookingAdvanceColors.success
                                .withValues(alpha: 0.07),
                            BookingAdvanceColors.success
                                .withValues(alpha: 0.25)),
                      ]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, Color ic, String sub, String val, Color vc,
      double vfs, Color bg, Color border) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: ic.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: ic, size: 14)),
        const SizedBox(width: 10),
        Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sub,
                  style: TextStyle(
                      color: ic.withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0)),
              const SizedBox(height: 2),
              Text(val,
                  style: TextStyle(
                      color: vc,
                      fontSize: vfs,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      height: 1)),
            ]),
      ]),
    );
  }

  Widget _line(double w, double o) => Container(
      width: w,
      height: 3,
      decoration: BoxDecoration(
          color: BookingAdvanceColors.brandGold.withValues(alpha: o),
          borderRadius: BorderRadius.circular(2)));
}
