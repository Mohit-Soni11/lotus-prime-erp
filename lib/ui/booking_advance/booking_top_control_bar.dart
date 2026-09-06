// =============================================================================
// FILE        : booking_top_control_bar.dart
// MODULE      : Sales / Booking & Advance
// DESCRIPTION : Booking rate preference controls.
//               Only OPEN RATE / LOCKED RATE toggle (NO GST).
//               Advance pe GST nahi lagta isliye GST toggle nahi hai.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';
import 'widgets/booking_money_text.dart';

class BookingTopControlBar extends StatelessWidget {
  final BookingAdvanceController ctrl;
  const BookingTopControlBar({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        final isLocked = ctrl.bookingType == BookingType.locked;

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
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
                              const Text(
                                  BookingAdvanceStrings.sectionPreferences,
                                  style: BookingAdvanceStyles.highVisHeader),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 260),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLocked
                                        ? BookingAdvanceColors.lockedRateColor
                                        : BookingAdvanceColors.openRateColor),
                                child: Text(isLocked
                                    ? BookingAdvanceStrings.lockedRate
                                    : BookingAdvanceStrings.openRate),
                              ),
                            ]),
                      ]),
                      const SizedBox(width: 40),
                      // Status pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isLocked
                                  ? BookingAdvanceColors.lockedRateColor
                                  : BookingAdvanceColors.openRateColor)
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: (isLocked
                                      ? BookingAdvanceColors.lockedRateColor
                                      : BookingAdvanceColors.openRateColor)
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLocked
                                      ? BookingAdvanceColors.lockedRateColor
                                      : BookingAdvanceColors.openRateColor)),
                          const SizedBox(width: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 260),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isLocked
                                    ? BookingAdvanceColors.lockedRateColor
                                    : BookingAdvanceColors.openRateColor),
                            child: Text(isLocked ? 'LOCKED' : 'OPEN'),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  Container(
                      height: 1,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      color: BookingAdvanceColors.bodyBorder),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: BookingAdvanceColors.bodyBg,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: BookingAdvanceColors.bodyBorder),
                        boxShadow: const [
                          BoxShadow(
                              color: BookingAdvanceColors.shadowLight,
                              blurRadius: 4,
                              offset: Offset(0, 1))
                        ]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _tab(
                          BookingAdvanceStrings.openRate,
                          !isLocked,
                          BookingAdvanceColors.openRateColor,
                          () => ctrl.toggleBookingType(BookingType.open)),
                      _tab(
                          BookingAdvanceStrings.lockedRate,
                          isLocked,
                          BookingAdvanceColors.lockedRateColor,
                          () => ctrl.toggleBookingType(BookingType.locked)),
                    ]),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: isLocked
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(BookingAdvanceIcons.lockedRate,
                                  color: BookingAdvanceColors.lockedRateColor,
                                  size: 16),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 180,
                                height: 40,
                                child: TextField(
                                  controller: ctrl.lockedRateCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: BookingAdvanceStyles.inputText,
                                  decoration: InputDecoration(
                                    hintText:
                                        '${BookingMoneyText.symbol} Rate / g',
                                    hintStyle: TextStyle(
                                        color: BookingAdvanceColors
                                            .bodyTextMuted
                                            .withValues(alpha: 0.6),
                                        fontSize: 13),
                                    filled: true,
                                    fillColor: BookingAdvanceColors
                                        .lockedRateColor
                                        .withValues(alpha: 0.04),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 0),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: BookingAdvanceColors
                                                .lockedRateColor
                                                .withValues(alpha: 0.3))),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: BookingAdvanceColors
                                                .lockedRateColor
                                                .withValues(alpha: 0.3))),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: BookingAdvanceColors
                                                .lockedRateColor,
                                            width: 2)),
                                  ),
                                ),
                              ),
                            ]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tab(
      String title, bool isActive, Color activeColor, VoidCallback onTap) {
    return SizedBox(
      width: 152,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: activeColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isActive ? 6 : 0,
                    height: isActive ? 6 : 0,
                    margin: EdgeInsets.only(right: isActive ? 6 : 0),
                    decoration: const BoxDecoration(
                        color: BookingAdvanceColors.textDark,
                        shape: BoxShape.circle)),
                Text(title,
                    style: TextStyle(
                        color: isActive
                            ? BookingAdvanceColors.textDark
                            : BookingAdvanceColors.bodyTextMuted,
                        fontWeight:
                            isActive ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 13)),
              ]),
        ),
      ),
    );
  }

  Widget _line(double w, double o) => Container(
      width: w,
      height: 3,
      decoration: BoxDecoration(
          color: BookingAdvanceColors.brandGold.withValues(alpha: o),
          borderRadius: BorderRadius.circular(2)));
}
