// =============================================================================
// FILE        : booking_right_panel.dart
// MODULE      : Sales / Booking & Advance
// DESCRIPTION : Composes the booking summary, payment hub, and action area.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'widgets/booking_action_buttons.dart';
import 'widgets/booking_payment_hub.dart';
import 'widgets/booking_summary_board.dart';

class BookingRightPanel extends StatelessWidget {
  const BookingRightPanel({
    super.key,
    required this.ctrl,
    required this.onSaved,
  });

  final BookingAdvanceController ctrl;
  final void Function(String message, bool isSuccess) onSaved;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) => Container(
        decoration: BookingAdvanceStyles.rightPanel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      BookingSummaryBoard(controller: ctrl),
                      const _BookingPanelDivider(),
                      BookingPaymentHub(controller: ctrl),
                    ],
                  ),
                ),
              ),
              const _BookingPanelDivider(),
              BookingActionButtons(
                controller: ctrl,
                onSaved: onSaved,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingPanelDivider extends StatelessWidget {
  const _BookingPanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BookingAdvanceColors.brandGold.withValues(alpha: 0.05),
            BookingAdvanceColors.bodyBorder,
            BookingAdvanceColors.brandGold.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}
