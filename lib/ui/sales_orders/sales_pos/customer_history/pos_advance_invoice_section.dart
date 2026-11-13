import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/documents/issued_pdf_preview_dialog.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../logic/booking_advance/booking_issued_pdf_loader.dart';
import '../../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../../models/customer/customer_profile/customer_profile_model.dart';
import 'pos_advance_carousel_arrow.dart';
import 'pos_advance_conversion_dialog.dart';
import 'pos_advance_invoice_card.dart';
import 'pos_advance_invoice_header.dart';

class PosAdvanceInvoiceSection extends StatefulWidget {
  const PosAdvanceInvoiceSection({
    super.key,
    required this.controller,
    required this.orders,
    this.onViewBooking,
    this.onUseInSale,
    this.pdfLoader = const BookingIssuedPdfLoader(),
  });

  final PosBillingController controller;
  final List<CustomerAdvanceOrderModel> orders;
  final Future<void> Function(CustomerAdvanceOrderModel)? onViewBooking;
  final Future<void> Function(CustomerAdvanceOrderModel)? onUseInSale;
  final BookingIssuedPdfLoader pdfLoader;

  @override
  State<PosAdvanceInvoiceSection> createState() =>
      _PosAdvanceInvoiceSectionState();
}

class _PosAdvanceInvoiceSectionState extends State<PosAdvanceInvoiceSection> {
  static const double _gap = 14;

  final FocusNode _focusNode = FocusNode(debugLabel: 'AdvanceInvoices');
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = 0;
  int? _busyOrderId;

  @override
  void didUpdateWidget(covariant PosAdvanceInvoiceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders.firstOrNull?.id != widget.orders.firstOrNull?.id) {
      _activeIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      return;
    }
    if (_activeIndex >= widget.orders.length) {
      _activeIndex = widget.orders.isEmpty ? 0 : widget.orders.length - 1;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final advanceTotal = widget.orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAdvancePaid,
    );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0DFCA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF76532B).withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: PosAdvanceInvoiceHeader(
                bookingCount: widget.orders.length,
                advanceTotal: advanceTotal,
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0E8D9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 23),
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _buildCarousel(constraints.maxWidth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(double width) {
    const arrowWidth = 36.0;
    const arrowGap = 10.0;
    final viewportWidth =
        (width - 2 * (arrowWidth + arrowGap)).clamp(1.0, width);
    final visibleCount = viewportWidth >= 1480
        ? 4
        : viewportWidth >= 1040
            ? 3
            : viewportWidth >= 660
                ? 2
                : 1;
    final cardWidth = visibleCount == 1
        ? viewportWidth.clamp(280.0, 390.0)
        : (viewportWidth - _gap * (visibleCount - 1)) / visibleCount;
    final canNavigate = widget.orders.length > visibleCount;

    return Row(
      children: [
        PosAdvanceCarouselArrow(
          icon: Icons.chevron_left_rounded,
          enabled: canNavigate && _activeIndex > 0,
          onTap: () => _moveSelection(-1, cardWidth),
        ),
        const SizedBox(width: arrowGap),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (var index = 0; index < widget.orders.length; index++) ...[
                  PosAdvanceInvoiceCard(
                    key: ValueKey(widget.orders[index].id),
                    order: widget.orders[index],
                    width: cardWidth,
                    isSelected: index == _activeIndex,
                    onViewBooking: () => _runAction(index, _viewBooking),
                    onUseInSale: () => _runAction(index, _useInSale),
                  ),
                  if (index != widget.orders.length - 1)
                    const SizedBox(width: _gap),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: arrowGap),
        PosAdvanceCarouselArrow(
          icon: Icons.chevron_right_rounded,
          enabled: canNavigate && _activeIndex < widget.orders.length - 1,
          onTap: () => _moveSelection(1, cardWidth),
        ),
      ],
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(-1, _currentCardWidth());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveSelection(1, _currentCardWidth());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  double _currentCardWidth() {
    final width = context.size?.width ?? 0;
    final viewport = (width - 2 * (36 + 10) - 24).clamp(1.0, width);
    final count = viewport >= 1480
        ? 4
        : viewport >= 1040
            ? 3
            : viewport >= 660
                ? 2
                : 1;
    return count == 1
        ? viewport.clamp(280.0, 390.0)
        : (viewport - _gap * (count - 1)) / count;
  }

  void _moveSelection(int direction, double cardWidth) {
    if (widget.orders.isEmpty) return;
    final next = (_activeIndex + direction).clamp(0, widget.orders.length - 1);
    if (next == _activeIndex) return;
    _focusNode.requestFocus();
    setState(() => _activeIndex = next);
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final cardStart = next * (cardWidth + _gap);
    final cardEnd = cardStart + cardWidth;
    final viewportStart = position.pixels;
    final viewportEnd = viewportStart + position.viewportDimension;
    final target = cardStart < viewportStart
        ? cardStart
        : cardEnd > viewportEnd
            ? cardEnd - position.viewportDimension
            : viewportStart;
    _scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _runAction(
    int index,
    Future<void> Function(CustomerAdvanceOrderModel) action,
  ) async {
    if (_busyOrderId != null) return;
    final order = widget.orders[index];
    _focusNode.requestFocus();
    setState(() {
      _activeIndex = index;
      _busyOrderId = order.id;
    });
    try {
      await action(order);
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _viewBooking(CustomerAdvanceOrderModel order) async {
    final handler = widget.onViewBooking;
    if (handler != null) return handler(order);
    await showIssuedPdfPreview(
      context: context,
      title: 'Booking ${order.orderNo}',
      pdfBytesFuture: widget.pdfLoader.load(
        orderId: order.id,
        bookingNumber: order.orderNo,
      ),
    );
  }

  Future<void> _useInSale(CustomerAdvanceOrderModel order) async {
    final handler = widget.onUseInSale;
    if (handler != null) return handler(order);
    if (widget.controller.hasDraftSaleInput &&
        !await confirmAdvanceConversion(context, order)) {
      return;
    }
    if (!mounted) return;

    final loaded = await widget.controller.initializeFromAdvanceOrder(order.id);
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: loaded ? AppFeedbackType.success : AppFeedbackType.error,
      message: loaded
          ? '${order.orderNo} loaded for sales conversion.'
          : widget.controller.advanceConversionError ??
              'Advance booking could not be loaded for conversion.',
    );
  }
}
