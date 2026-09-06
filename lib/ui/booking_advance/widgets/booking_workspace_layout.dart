import 'package:flutter/material.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../booking_customer_panel.dart';
import '../booking_items_table.dart';
import '../booking_right_panel.dart';
import '../booking_scrap_table.dart';
import '../booking_status_bar.dart';
import '../booking_top_control_bar.dart';

class BookingWorkspaceLayout extends StatelessWidget {
  const BookingWorkspaceLayout({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  static const double _railBreakpoint = 1180;

  final BookingAdvanceController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final useSideRail = constraints.maxWidth >= _railBreakpoint;
          final content = _BookingPrimaryColumn(
            controller: controller,
            scrollController: scrollController,
          );
          final rail = BookingRightPanel(
            ctrl: controller,
            onSaved: (message, isSuccess) => AppFeedback.show(
              context,
              type: isSuccess ? AppFeedbackType.success : AppFeedbackType.error,
              message: message,
            ),
          );

          if (!useSideRail) {
            return SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BookingPrimaryContent(controller: controller),
                  const SizedBox(height: 16),
                  SizedBox(height: 560, child: rail),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 70, child: content),
                const SizedBox(width: 18),
                Expanded(flex: 30, child: rail),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookingPrimaryColumn extends StatelessWidget {
  const _BookingPrimaryColumn({
    required this.controller,
    required this.scrollController,
  });

  final BookingAdvanceController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: _BookingPrimaryContent(controller: controller),
    );
  }
}

class _BookingPrimaryContent extends StatelessWidget {
  const _BookingPrimaryContent({required this.controller});

  final BookingAdvanceController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookingHeaderBand(controller: controller),
        const SizedBox(height: 14),
        BookingCustomerPanel(ctrl: controller),
        const SizedBox(height: 16),
        BookingItemsTable(ctrl: controller),
        const SizedBox(height: 16),
        BookingScrapTable(ctrl: controller),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _BookingHeaderBand extends StatelessWidget {
  const _BookingHeaderBand({required this.controller});

  final BookingAdvanceController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final sideBySide = constraints.maxWidth > 720;
        if (sideBySide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BookingTopControlBar(ctrl: controller),
                const SizedBox(width: 16),
                Expanded(child: BookingStatusBar(ctrl: controller)),
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingTopControlBar(ctrl: controller),
            const SizedBox(height: 12),
            BookingStatusBar(ctrl: controller),
          ],
        );
      },
    );
  }
}
