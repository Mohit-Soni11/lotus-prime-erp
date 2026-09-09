// =============================================================================
// FILE        : booking_items_table.dart
// MODULE      : Sales / Booking & Advance
// DESCRIPTION : Responsive booking item grid shell.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'widgets/booking_item_grid_metrics.dart';
import 'widgets/booking_item_row.dart';
import 'widgets/booking_money_text.dart';

part 'widgets/booking_items_header.dart';
part 'widgets/booking_items_columns.dart';
part 'widgets/booking_items_empty_state.dart';
part 'widgets/booking_items_footer.dart';

class BookingItemsTable extends StatelessWidget {
  const BookingItemsTable({super.key, required this.ctrl});

  static const double _minimumGridWidth = BookingItemGridMetrics.gridWidth;

  final BookingAdvanceController ctrl;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): ctrl.addBookingItem,
        const SingleActivator(LogicalKeyboardKey.delete): ctrl.removeActiveItem,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: ctrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              color: BookingAdvanceColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BookingAdvanceColors.bodyBorder,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: BookingAdvanceColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BookingItemsHeader(controller: ctrl),
                LayoutBuilder(
                  builder: (_, constraints) {
                    final gridWidth = constraints.maxWidth < _minimumGridWidth
                        ? _minimumGridWidth
                        : constraints.maxWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: gridWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _BookingItemsColumnRow(),
                            ctrl.bookingItems.isEmpty
                                ? const _BookingItemsEmptyState()
                                : Column(
                                    children: List.generate(
                                      ctrl.bookingItems.length,
                                      (index) => BookingItemRow(
                                        index: index,
                                        item: ctrl.bookingItems[index],
                                        controller: ctrl,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _BookingItemsBottomBar(controller: ctrl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
