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
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PosAdvanceInvoiceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
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
    widget.controller.removeListener(_onControllerChanged);
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
        child: _buildStandardContent(advanceTotal),
      ),
    );
  }

  Widget _buildStandardContent(double advanceTotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: PosAdvanceInvoiceHeader(
            bookingCount: widget.orders.length,
            advanceTotal: advanceTotal,
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0E8D9)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildCarousel(constraints.maxWidth),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel(double width) {
    const arrowWidth = 36.0;
    const arrowGap = 10.0;
    final visibleCount = width >= 1480
        ? 4
        : width >= 1040
            ? 3
            : width >= 660
                ? 2
                : 1;
    final canNavigate = widget.orders.length > visibleCount;
    final viewportWidth = canNavigate
        ? (width - 2 * (arrowWidth + arrowGap)).clamp(1.0, width)
        : width;
    final displayCount = widget.orders.length < visibleCount
        ? widget.orders.length
        : visibleCount;
    final cardWidth = displayCount <= 1
        ? viewportWidth.clamp(280.0, 330.0)
        : ((viewportWidth - _gap * (displayCount - 1)) / displayCount)
            .clamp(280.0, 360.0);

    return Row(
      children: [
        if (canNavigate) ...[
          PosAdvanceCarouselArrow(
            icon: Icons.chevron_left_rounded,
            enabled: _activeIndex > 0,
            onTap: () => _moveSelection(-1, cardWidth),
          ),
          const SizedBox(width: arrowGap),
        ],
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
                    isLoaded: widget.controller.convertedAdvanceOrderId ==
                        widget.orders[index].id,
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
        if (canNavigate) ...[
          const SizedBox(width: arrowGap),
          PosAdvanceCarouselArrow(
            icon: Icons.chevron_right_rounded,
            enabled: _activeIndex < widget.orders.length - 1,
            onTap: () => _moveSelection(1, cardWidth),
          ),
        ],
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
    final width = (context.size?.width ?? 0) - 24;
    final count = width >= 1480
        ? 4
        : width >= 1040
            ? 3
            : width >= 660
                ? 2
                : 1;
    final canNavigate = widget.orders.length > count;
    final viewport = canNavigate ? (width - 92).clamp(1.0, width) : width;
    final displayCount =
        widget.orders.length < count ? widget.orders.length : count;
    return displayCount <= 1
        ? viewport.clamp(280.0, 330.0)
        : ((viewport - _gap * (displayCount - 1)) / displayCount)
            .clamp(280.0, 360.0);
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
