import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../../models/customer/customer_profile/customer_profile_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import '../../../finance/due_collection_entry/due_collection_entry_screen.dart';
import 'pos_customer_history_formatters.dart';

class PosCustomerHistoryCard extends StatelessWidget {
  final PosBillingController ctrl;

  const PosCustomerHistoryCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoadingHistory) {
      return const _HistoryShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryHeader(customerType: 'Loading'),
            SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SalesPosColors.brandGold,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading customer account...',
                  style: TextStyle(
                    color: SalesPosColors.textDark,
                    fontSize: SalesPosStyles.fontBody,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final history = ctrl.customerHistory;
    if (history == null) {
      return const _HistoryShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryHeader(customerType: 'New'),
            SizedBox(height: 12),
            _EmptyHistoryNotice(),
          ],
        ),
      );
    }

    final totalBills = history.bills.length;
    final dueBills = history.dues;
    final outstanding = history.outstanding;
    final hasDue = outstanding > 0.005;
    final activeAdvanceOrders = history.advanceOrders
        .where((order) => order.isPending || order.isReady)
        .toList(growable: false);
    final hasAdvance = activeAdvanceOrders.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SalesPosColors.customerCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDue
              ? SalesPosColors.danger.withValues(alpha: 0.38)
              : SalesPosColors.brandGold.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryHeader(customerType: history.type),
          const SizedBox(height: 12),
          _MetricGrid(
            tiles: [
              _MetricTile(
                icon: Icons.receipt_long_rounded,
                label: 'Total Bills',
                value: '$totalBills',
              ),
              _MetricTile(
                icon: Icons.access_time_rounded,
                label: 'Last Visit',
                value: PosCustomerHistoryFormatters.lastVisit(history.bills),
              ),
              _MetricTile(
                icon: hasDue
                    ? Icons.error_outline_rounded
                    : Icons.verified_rounded,
                label: 'Account',
                value: hasDue
                    ? PosCustomerHistoryFormatters.amount(outstanding)
                    : 'Settled',
                valueColor:
                    hasDue ? SalesPosColors.danger : SalesPosColors.success,
              ),
              _MetricTile(
                icon: hasDue
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_outline_rounded,
                label: 'Due',
                value: _invoiceCountLabel(dueBills.length),
                valueColor:
                    hasDue ? SalesPosColors.danger : SalesPosColors.success,
              ),
              _MetricTile(
                icon: Icons.event_note_rounded,
                label: 'Advance',
                value: hasAdvance
                    ? _invoiceCountLabel(activeAdvanceOrders.length)
                    : '0 invoices',
                valueColor: hasAdvance
                    ? SalesPosColors.brandGold
                    : SalesPosColors.textDark,
              ),
            ],
          ),
          if (hasAdvance) ...[
            const SizedBox(height: 10),
            _AdvanceSummary(
              ctrl: ctrl,
              orders: activeAdvanceOrders,
            ),
          ],
          if (hasDue) ...[
            const SizedBox(height: 10),
            _DueSummary(
              customerName: history.name,
              customerId: history.id,
              mobile: history.mobile,
              dueBills: dueBills,
              totalOutstanding: outstanding,
              onReturned: ctrl.refreshSelectedCustomerHistory,
            ),
          ],
        ],
      ),
    );
  }

  static String _invoiceCountLabel(int count) {
    return count == 1 ? '1 invoice' : '$count invoices';
  }
}

class _HistoryShell extends StatelessWidget {
  final Widget child;

  const _HistoryShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SalesPosColors.customerCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.24),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final String customerType;

  const _HistoryHeader({required this.customerType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.25),
            ),
          ),
          child: const Icon(
            Icons.manage_history_rounded,
            size: 21,
            color: SalesPosColors.brandGold,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CUSTOMER ACCOUNT',
                style: SalesPosStyles.highVisHeader,
              ),
              SizedBox(height: 2),
              Text(
                'Invoices, advance bookings, visits and due status',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SalesPosColors.textDark,
                  fontSize: SalesPosStyles.fontBody,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            customerType.toUpperCase(),
            style: const TextStyle(
              color: SalesPosColors.goldHoverDark,
              fontSize: SalesPosStyles.fontLabel,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryNotice extends StatelessWidget {
  const _EmptyHistoryNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SalesPosColors.formInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.person_add_alt_1_rounded,
            size: 17,
            color: SalesPosColors.textDark,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'First invoice for this customer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SalesPosColors.textDark,
                fontSize: SalesPosStyles.fontBody,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricTile> tiles;

  const _MetricGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 1100
            ? 5
            : maxWidth >= 860
                ? 3
                : 2;
        final tileWidth = (maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: tileWidth,
                child: tile,
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = SalesPosColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.formInputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SalesPosColors.textDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SalesPosColors.textDark,
                    fontSize: SalesPosStyles.fontLabel,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: SalesPosStyles.fontBody,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvanceSummary extends StatefulWidget {
  final PosBillingController ctrl;
  final List<CustomerAdvanceOrderModel> orders;

  const _AdvanceSummary({
    required this.ctrl,
    required this.orders,
  });

  @override
  State<_AdvanceSummary> createState() => _AdvanceSummaryState();
}

class _AdvanceSummaryState extends State<_AdvanceSummary> {
  static const double _cardWidth = 274;
  static const double _cardHeight = 148;
  static const double _cardGap = 8;

  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  var _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'PosAdvanceBookingHistory');
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _AdvanceSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final canMoveBackward = widget.orders.length > 1 && _activeIndex > 0;
    final canMoveForward =
        widget.orders.length > 1 && _activeIndex < widget.orders.length - 1;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: SalesPosColors.brandGold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SalesPosColors.brandGold.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bookmark_added_rounded,
                      size: 18,
                      color: SalesPosColors.brandGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Advance Invoices',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SalesPosColors.goldHoverDark,
                            fontSize: SalesPosStyles.fontBody,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.orders.length == 1
                              ? '1 booking invoice ready for sales conversion'
                              : '${widget.orders.length} booking invoices ready for sales conversion',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SalesPosColors.textDark,
                            fontSize: SalesPosStyles.fontLabel,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: SalesPosColors.bodyBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Row(
                children: [
                  _AdvanceNavigationButton(
                    enabled: canMoveBackward,
                    icon: Icons.chevron_left_rounded,
                    height: _cardHeight,
                    onTap: () => _moveSelection(-1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (var index = 0;
                              index < widget.orders.length;
                              index += 1) ...[
                            _AdvanceInvoiceCard(
                              order: widget.orders[index],
                              selected: index == _activeIndex,
                              width: _cardWidth,
                              height: _cardHeight,
                              onTap: () {
                                _focusNode.requestFocus();
                                setState(() => _activeIndex = index);
                                _ensureVisible(index);
                                _convertAdvance(context, widget.orders[index]);
                              },
                            ),
                            if (index != widget.orders.length - 1)
                              const SizedBox(width: _cardGap),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AdvanceNavigationButton(
                    enabled: canMoveForward,
                    icon: Icons.chevron_right_rounded,
                    height: _cardHeight,
                    onTap: () => _moveSelection(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (widget.orders.isNotEmpty) {
        _convertAdvance(context, widget.orders[_activeIndex]);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveSelection(int direction) {
    if (widget.orders.isEmpty) {
      return;
    }
    final nextIndex = (_activeIndex + direction).clamp(
      0,
      widget.orders.length - 1,
    );
    if (nextIndex == _activeIndex) {
      return;
    }
    _focusNode.requestFocus();
    setState(() => _activeIndex = nextIndex);
    _ensureVisible(nextIndex);
  }

  void _ensureVisible(int index) {
    if (!_scrollController.hasClients) {
      return;
    }
    final cardStart = index * (_cardWidth + _cardGap);
    final cardEnd = cardStart + _cardWidth;
    final position = _scrollController.position;
    final visibleStart = position.pixels;
    final visibleEnd = visibleStart + position.viewportDimension;
    var targetOffset = visibleStart;

    if (cardStart < visibleStart) {
      targetOffset = cardStart;
    } else if (cardEnd > visibleEnd) {
      targetOffset = cardEnd - position.viewportDimension;
    } else {
      return;
    }

    _scrollController.animateTo(
      targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _convertAdvance(
    BuildContext context,
    CustomerAdvanceOrderModel order,
  ) async {
    if (widget.ctrl.hasDraftSaleInput) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Convert Advance Booking?'),
          content: const Text(
            'Current POS entry will be replaced with the selected advance booking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Convert'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final loaded = await widget.ctrl.initializeFromAdvanceOrder(order.id);
    if (!context.mounted) return;
    if (loaded) {
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: '${order.orderNo} loaded for sales conversion.',
      );
      return;
    }

    AppFeedback.show(
      context,
      type: AppFeedbackType.error,
      message: widget.ctrl.advanceConversionError ??
          'Advance booking could not be loaded for conversion.',
    );
  }
}

class _AdvanceNavigationButton extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final double height;
  final VoidCallback onTap;

  const _AdvanceNavigationButton({
    required this.enabled,
    required this.icon,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: height,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : SalesPosColors.bodyBg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: enabled
                  ? SalesPosColors.brandGold.withValues(alpha: 0.36)
                  : SalesPosColors.bodyBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: enabled
                ? SalesPosColors.brandGold
                : SalesPosColors.textDark.withValues(alpha: 0.52),
          ),
        ),
      ),
    );
  }
}

class _AdvanceInvoiceCard extends StatelessWidget {
  final CustomerAdvanceOrderModel order;
  final bool selected;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _AdvanceInvoiceCard({
    required this.order,
    required this.selected,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rateLabel = order.lockedRate > 0
        ? 'Locked ${PosCustomerHistoryFormatters.amount(order.lockedRate)}/g'
        : 'Open rate';
    final statusLabel = order.status.name.toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? SalesPosColors.brandGold.withValues(alpha: 0.13)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? SalesPosColors.brandGold
                  : SalesPosColors.brandGold.withValues(alpha: 0.28),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: SalesPosColors.goldHoverDark,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      order.orderNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SalesPosColors.textDark,
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  _AdvanceStatusChip(label: statusLabel),
                ],
              ),
              const SizedBox(height: 7),
              _AdvanceCardMetaLine(
                text: '${order.metalType} ${order.purity} | ${order.itemName}',
                isPrimary: true,
              ),
              const SizedBox(height: 6),
              _AdvanceCardMetaLine(
                text: 'Weight ${_formatWeight(order.approxWeight)} g',
              ),
              const SizedBox(height: 6),
              _AdvanceCardMetaLine(
                text: rateLabel,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Advance ${PosCustomerHistoryFormatters.amount(order.totalAdvancePaid)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SalesPosColors.goldHoverDark,
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: SalesPosColors.goldHoverDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWeight(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0005) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(3);
  }
}

class _AdvanceCardMetaLine extends StatelessWidget {
  final String text;
  final bool isPrimary;

  const _AdvanceCardMetaLine({
    required this.text,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPrimary
              ? SalesPosColors.textDark
              : SalesPosColors.goldHoverDark,
          fontSize:
              isPrimary ? SalesPosStyles.fontBody : SalesPosStyles.fontLabel,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          height: 1.1,
        ),
      ),
    );
  }
}

class _AdvanceStatusChip extends StatelessWidget {
  final String label;

  const _AdvanceStatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: SalesPosColors.goldHoverDark,
          fontSize: SalesPosStyles.fontCaption,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DueSummary extends StatelessWidget {
  final int customerId;
  final String customerName;
  final String mobile;
  final List<dynamic> dueBills;
  final double totalOutstanding;
  final Future<void> Function() onReturned;

  const _DueSummary({
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.dueBills,
    required this.totalOutstanding,
    required this.onReturned,
  });

  @override
  Widget build(BuildContext context) {
    final previewBills = dueBills.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: SalesPosColors.danger.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.danger.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: SalesPosColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: SalesPosColors.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outstanding Balance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SalesPosColors.danger,
                          fontSize: SalesPosStyles.fontBody,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueBills.length == 1
                            ? 'Pending against 1 invoice'
                            : 'Pending against ${dueBills.length} invoices',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SalesPosColors.textDark,
                          fontSize: SalesPosStyles.fontLabel,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  PosCustomerHistoryFormatters.amount(totalOutstanding),
                  style: const TextStyle(
                    color: SalesPosColors.danger,
                    fontSize: SalesPosStyles.fontInput,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (previewBills.isNotEmpty) ...[
            const Divider(height: 1, color: SalesPosColors.bodyBorder),
            ...previewBills.map(
              (due) => _DuePreviewRow(
                billNo: due.billNo,
                date: due.formattedDate,
                amount: due.dueAmount,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                if (dueBills.length > previewBills.length)
                  Text(
                    '+${dueBills.length - previewBills.length} more',
                    style: const TextStyle(
                      color: SalesPosColors.textDark,
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  const Spacer(),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _openDueCollection(context),
                    icon: const Icon(Icons.payments_outlined, size: 14),
                    label: const Text('Collect Due'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SalesPosColors.danger,
                      side: BorderSide(
                        color: SalesPosColors.danger.withValues(alpha: 0.55),
                      ),
                      textStyle: const TextStyle(
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDueCollection(BuildContext context) async {
    final firstBillNo = dueBills.isEmpty ? null : dueBills.first.billNo;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DueCollectionEntryScreen(
          initialCustomerId: customerId,
          initialCustomerName: customerName,
          initialMobile: mobile,
          initialBillNo: firstBillNo,
        ),
      ),
    );
    await onReturned();
  }
}

class _DuePreviewRow extends StatelessWidget {
  final String billNo;
  final String date;
  final double amount;

  const _DuePreviewRow({
    required this.billNo,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_outlined,
            size: 14,
            color: SalesPosColors.textDark,
          ),
          const SizedBox(width: 6),
          Text(
            billNo,
            style: const TextStyle(
              color: SalesPosColors.textDark,
              fontSize: SalesPosStyles.fontLabel,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.textDark,
                fontSize: SalesPosStyles.fontLabel,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: Text(
              PosCustomerHistoryFormatters.amount(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: SalesPosColors.danger,
                fontSize: SalesPosStyles.fontLabel,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
