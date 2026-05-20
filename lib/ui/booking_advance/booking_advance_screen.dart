// =============================================================================
// FILE        : booking_advance_screen.dart
// MODULE      : Sales → Booking & Advance
// DESCRIPTION : MASTER SCREEN — exact same structure as PosMasterSaleScreen.
//               Left 70%: ControlBar + StatusBar + CustomerPanel + ItemsTable + ScrapTable
//               Right 30%: BookingRightPanel (Advance Payment + Save)
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';
import 'booking_advance_app_bar.dart';
import 'booking_top_control_bar.dart';
import 'booking_status_bar.dart';
import 'booking_customer_panel.dart';
import 'booking_items_table.dart';
import 'booking_scrap_table.dart';
import 'booking_right_panel.dart';

class BookingAdvanceScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const BookingAdvanceScreen({super.key, this.onBack});

  @override
  State<BookingAdvanceScreen> createState() => _BookingAdvanceScreenState();
}

class _BookingAdvanceScreenState extends State<BookingAdvanceScreen> {
  late final BookingAdvanceController _ctrl;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = BookingAdvanceController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: BookingAdvanceColors.bodyBg,
        appBar: BookingAdvanceAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════
                // LEFT COLUMN (70%) — same as POS left column
                // ═══════════════════════════════════════════════════════
                Expanded(
                  flex: 70,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── TOP ROW: Control Bar + Status Bar ──
                        LayoutBuilder(builder: (_, constraints) {
                          final sideBySide = constraints.maxWidth > 720;
                          if (sideBySide) {
                            return IntrinsicHeight(
                              child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    BookingTopControlBar(ctrl: _ctrl),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: BookingStatusBar(ctrl: _ctrl)),
                                  ]),
                            );
                          }
                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BookingTopControlBar(ctrl: _ctrl),
                                const SizedBox(height: 12),
                                BookingStatusBar(ctrl: _ctrl),
                              ]);
                        }),

                        const SizedBox(height: 14),

                        // ── CUSTOMER PANEL ──
                        BookingCustomerPanel(ctrl: _ctrl),

                        const SizedBox(height: 16),

                        // ── BOOKING ITEMS TABLE ──
                        BookingItemsTable(ctrl: _ctrl),

                        const SizedBox(height: 16),

                        // ── SCRAP / EXCHANGE TABLE ──
                        BookingScrapTable(ctrl: _ctrl),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                // ═══════════════════════════════════════════════════════
                // RIGHT COLUMN (30%) — Advance Payment + Save
                // ═══════════════════════════════════════════════════════
                Expanded(
                  flex: 30,
                  child: BookingRightPanel(
                    ctrl: _ctrl,
                    onSaved: (message, isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: isSuccess
                              ? BookingAdvanceColors.success
                              : BookingAdvanceColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
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
