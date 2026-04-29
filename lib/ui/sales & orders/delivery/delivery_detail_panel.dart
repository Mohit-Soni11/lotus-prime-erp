// =============================================================================
// FILE        : delivery_detail_panel.dart
// MODULE      : Sales → Delivery Management
// LAYER       : UI
// DESCRIPTION : Right side panel — shows full order details, items list,
//               financials, and action buttons (Mark Ready, Deliver, etc.)
//               Adapts: full delivery vs partial delivery vs due collection.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../logic/sales & orders/delivery/delivery_management_controller.dart';
import '../../../models/sales & orders/delivery/delivery_model.dart';
import '../../../models/sales & orders/delivery/delivery_enums.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';

class DeliveryDetailPanel extends StatelessWidget {
  final DeliveryManagementController ctrl;
  final VoidCallback onDelivered;

  const DeliveryDetailPanel({
    super.key,
    required this.ctrl,
    required this.onDelivered,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) {
        final order = ctrl.selectedOrder;
        if (order == null) return _NoSelectionState();

        return Container(
          decoration: DeliveryStyles.sidePanel,
          child: Column(children: [
            _PanelHeader(order: order, onClose: ctrl.clearSelection),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderDetailsSection(order: order),
                    const SizedBox(height: 16),
                    if (order.hasMultipleItems) ...[
                      _ItemsSection(ctrl: ctrl, order: order),
                      const SizedBox(height: 16),
                    ],
                    _FinancialsSection(order: order),
                    const SizedBox(height: 16),
                    _ActionSection(
                        ctrl: ctrl, order: order, onDelivered: onDelivered),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ── Panel Header ──────────────────────────────────────────────────────────────
class _PanelHeader extends StatelessWidget {
  final DeliveryOrderUiModel order;
  final VoidCallback onClose;
  const _PanelHeader({required this.order, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: DeliveryColors.shellPanelBg,
        border: Border(bottom: BorderSide(color: DeliveryColors.shellBorder)),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: DeliveryColors.brandGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(DeliveryIcons.moduleIcon,
              color: DeliveryColors.brandGold, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.deliveryNo, style: DeliveryStyles.deliveryNoText),
            Text(order.customerName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.shellTextTitle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          icon: const Icon(DeliveryIcons.close,
              color: DeliveryColors.shellTextMuted, size: 18),
          onPressed: onClose,
        ),
      ]),
    );
  }
}

// ── Order Details Section ─────────────────────────────────────────────────────
class _OrderDetailsSection extends StatelessWidget {
  final DeliveryOrderUiModel order;
  const _OrderDetailsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: DeliveryStrings.panelOrderDetails,
      child: Column(children: [
        _DetailRow(
            icon: DeliveryIcons.customer,
            label: 'Customer',
            value: order.customerName),
        _DetailRow(
            icon: DeliveryIcons.phone,
            label: 'Mobile',
            value: order.customerMobile),
        _DetailRow(
            icon: DeliveryIcons.item, label: 'Item', value: order.itemName),
        _DetailRow(
            icon: DeliveryIcons.weight,
            label: 'Metal',
            value:
                '${order.metalType} ${order.purity} • ${order.approxWeight.toStringAsFixed(3)}g'),
        if (order.karigarName != null)
          _DetailRow(
              icon: DeliveryIcons.karigar,
              label: 'Karigar',
              value: order.karigarName!),
        if (order.expectedDeliveryDate != null)
          _DetailRow(
            icon: DeliveryIcons.calendar,
            label: 'Delivery Date',
            value:
                DateFormat('dd MMM yyyy').format(order.expectedDeliveryDate!),
            valueColor: order.isOverdue ? DeliveryColors.urgencyOverdue : null,
          ),
        if (order.notes != null && order.notes!.isNotEmpty)
          _DetailRow(
              icon: DeliveryIcons.notes, label: 'Notes', value: order.notes!),
        if (order.linkedBillNo != null)
          _DetailRow(
              icon: DeliveryIcons.billLink,
              label: 'Bill No.',
              value: order.linkedBillNo!),
      ]),
    );
  }
}

// ── Items Section (multi-item) ────────────────────────────────────────────────
class _ItemsSection extends StatelessWidget {
  final DeliveryManagementController ctrl;
  final DeliveryOrderUiModel order;
  const _ItemsSection({required this.ctrl, required this.order});

  @override
  Widget build(BuildContext context) {
    final showSelect = order.status != DeliveryOrderStatus.delivered &&
        order.status != DeliveryOrderStatus.cancelled;

    return _Section(
      title: DeliveryStrings.panelItems,
      trailing: showSelect
          ? GestureDetector(
              onTap: ctrl.selectAllReadyItems,
              child: Text(
                DeliveryStrings.partialSelectAll,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.brandGold,
                ),
              ),
            )
          : null,
      child: Column(
        children: order.items.map((item) {
          final isSelected = ctrl.selectedItemIds.contains(item.id);
          final canSelect =
              showSelect && item.itemStatus == DeliveryItemStatus.ready;
          return GestureDetector(
            onTap: canSelect ? () => ctrl.toggleItemSelection(item.id) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? DeliveryColors.brandGold.withOpacity(0.08)
                    : DeliveryColors.bodyBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? DeliveryColors.brandGold.withOpacity(0.4)
                      : DeliveryColors.bodyBorder,
                ),
              ),
              child: Row(children: [
                if (canSelect)
                  Icon(
                    isSelected
                        ? DeliveryIcons.checkBox
                        : DeliveryIcons.checkBoxEmpty,
                    size: 18,
                    color: isSelected
                        ? DeliveryColors.brandGold
                        : DeliveryColors.bodyTextMuted,
                  )
                else
                  Icon(
                    _itemStatusIcon(item.itemStatus),
                    size: 18,
                    color: _itemStatusColor(item.itemStatus),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName, style: DeliveryStyles.cardTitle),
                      Text(
                        '${item.metalType} ${item.purity} • ${item.approxWeight.toStringAsFixed(3)}g',
                        style: DeliveryStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ),
                _ItemStatusPill(status: item.itemStatus),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _itemStatusIcon(DeliveryItemStatus s) {
    return switch (s) {
      DeliveryItemStatus.pending => DeliveryIcons.statusBooked,
      DeliveryItemStatus.ready => DeliveryIcons.statusReady,
      DeliveryItemStatus.delivered => DeliveryIcons.statusDelivered,
    };
  }

  Color _itemStatusColor(DeliveryItemStatus s) {
    return switch (s) {
      DeliveryItemStatus.pending => DeliveryColors.statusBooked,
      DeliveryItemStatus.ready => DeliveryColors.statusReady,
      DeliveryItemStatus.delivered => DeliveryColors.statusDelivered,
    };
  }
}

class _ItemStatusPill extends StatelessWidget {
  final DeliveryItemStatus status;
  const _ItemStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      DeliveryItemStatus.pending => (
          'Pending',
          DeliveryColors.statusBooked,
          DeliveryColors.statusBookedBg
        ),
      DeliveryItemStatus.ready => (
          'Ready',
          DeliveryColors.statusReady,
          DeliveryColors.statusReadyBg
        ),
      DeliveryItemStatus.delivered => (
          'Delivered',
          DeliveryColors.statusDelivered,
          DeliveryColors.statusDeliveredBg
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

// ── Financials Section ────────────────────────────────────────────────────────
class _FinancialsSection extends StatelessWidget {
  final DeliveryOrderUiModel order;
  const _FinancialsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: DeliveryStrings.panelFinancials,
      child: Column(children: [
        _FinRow(
            label: 'Advance Paid',
            value: '₹${_f(order.advancePaid)}',
            color: DeliveryColors.statusBooked),
        if (order.totalAmount > 0)
          _FinRow(
              label: 'Total Amount',
              value: '₹${_f(order.totalAmount)}',
              color: DeliveryColors.bodyTextMain),
        if (order.dueAmount > 0)
          _FinRow(
              label: 'Due Amount',
              value: '₹${_f(order.dueAmount)}',
              color: DeliveryColors.urgencyOverdue,
              highlight: true),
        const SizedBox(height: 4),
        _PaymentStatusRow(status: order.paymentStatus),
      ]),
    );
  }

  String _f(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
}

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlight;
  const _FinRow(
      {required this.label,
      required this.value,
      required this.color,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: DeliveryStyles.cardSubtitle),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ]),
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  final DeliveryPaymentStatus status;
  const _PaymentStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      DeliveryPaymentStatus.paid => (
          DeliveryStrings.paymentPaid,
          DeliveryColors.paymentPaid,
          DeliveryColors.paymentPaidBg
        ),
      DeliveryPaymentStatus.partial => (
          DeliveryStrings.paymentPartial,
          DeliveryColors.paymentPartial,
          DeliveryColors.paymentPartialBg
        ),
      DeliveryPaymentStatus.unpaid => (
          DeliveryStrings.paymentUnpaid,
          DeliveryColors.paymentUnpaid,
          DeliveryColors.paymentUnpaidBg
        ),
    };
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}

// ── Action Section ────────────────────────────────────────────────────────────
class _ActionSection extends StatelessWidget {
  final DeliveryManagementController ctrl;
  final DeliveryOrderUiModel order;
  final VoidCallback onDelivered;

  const _ActionSection({
    required this.ctrl,
    required this.order,
    required this.onDelivered,
  });

  @override
  Widget build(BuildContext context) {
    final status = order.status;

    // Completed / Cancelled — only show WhatsApp & bill link
    if (status == DeliveryOrderStatus.cancelled ||
        (status == DeliveryOrderStatus.delivered &&
            order.paymentStatus == DeliveryPaymentStatus.paid)) {
      return _Section(
        title: DeliveryStrings.panelActions,
        child: _ActionButton(
          label: DeliveryStrings.btnWhatsApp,
          icon: DeliveryIcons.whatsapp,
          color: DeliveryColors.actionWhatsApp,
          onTap: () => _openWhatsApp(order),
        ),
      );
    }

    // Due Ledger — collect payment
    if (status == DeliveryOrderStatus.delivered &&
        order.paymentStatus == DeliveryPaymentStatus.partial) {
      return _Section(
        title: DeliveryStrings.panelCollectDue,
        child: Column(children: [
          _AmountField(
              ctrl: ctrl.finalAmtCtrl, label: DeliveryStrings.lblAmountCollect),
          const SizedBox(height: 12),
          _ActionButton(
            label: DeliveryStrings.btnCollectDue,
            icon: DeliveryIcons.collectPayment,
            color: DeliveryColors.actionDeliver,
            isLoading: ctrl.isActionLoading,
            onTap: () async {
              final ok = await ctrl.collectDue(
                orderId: order.id,
                amountCollected: ctrl.finalAmountValue,
              );
              if (ok && context.mounted) {
                _showSnack(context, DeliveryStrings.snackDueCollected,
                    isError: false);
                onDelivered();
              }
            },
          ),
          const SizedBox(height: 8),
          _ActionButton(
            label: DeliveryStrings.btnWhatsApp,
            icon: DeliveryIcons.whatsapp,
            color: DeliveryColors.actionWhatsApp,
            outlined: true,
            onTap: () => _openWhatsAppDue(order),
          ),
        ]),
      );
    }

    // Active pipeline — BOOKED / IN_MAKING / READY
    return _Section(
      title: DeliveryStrings.panelDeliverOrder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status actions row
          if (status == DeliveryOrderStatus.booked)
            _ActionButton(
              label: DeliveryStrings.btnMarkInMaking,
              icon: DeliveryIcons.assignKarigar,
              color: DeliveryColors.actionInMaking,
              outlined: true,
              onTap: () async {
                final ok = await ctrl.markInMaking(order.id);
                if (ok && context.mounted)
                  _showSnack(context, DeliveryStrings.snackInMaking);
              },
            ),

          if (status == DeliveryOrderStatus.inMaking)
            _ActionButton(
              label: DeliveryStrings.btnMarkReady,
              icon: DeliveryIcons.markReady,
              color: DeliveryColors.actionReady,
              outlined: true,
              onTap: () async {
                final ok = await ctrl.markReady(order.id);
                if (ok && context.mounted)
                  _showSnack(context, DeliveryStrings.snackReadyMarked);
              },
            ),

          if (status == DeliveryOrderStatus.ready) ...[
            const SizedBox(height: 4),
            _AmountField(
                ctrl: ctrl.finalAmtCtrl, label: DeliveryStrings.lblFinalAmount),
            const SizedBox(height: 8),
            _AmountField(
                ctrl: ctrl.paidNowCtrl, label: DeliveryStrings.lblPaidNow),
            const SizedBox(height: 8),
            _DueSummaryRow(ctrl: ctrl, order: order),
            const SizedBox(height: 12),

            // Partial deliver button (multi-item)
            if (order.hasMultipleItems && ctrl.selectedItemIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionButton(
                  label:
                      '${DeliveryStrings.btnPartialDeliver} (${ctrl.selectedItemIds.length} items)',
                  icon: DeliveryIcons.partialDeliver,
                  color: DeliveryColors.actionReady,
                  outlined: true,
                  isLoading: ctrl.isActionLoading,
                  onTap: () async {
                    final ok = await ctrl.partialDeliver(
                      orderId: order.id,
                      finalAmount: ctrl.finalAmountValue,
                      paidNow: ctrl.paidNowValue,
                      advancePaid: order.advancePaid,
                    );
                    if (ok && context.mounted) {
                      _showSnack(context, DeliveryStrings.snackDelivered);
                      onDelivered();
                    }
                  },
                ),
              ),

            _ActionButton(
              label: DeliveryStrings.btnDeliver,
              icon: DeliveryIcons.deliver,
              color: DeliveryColors.actionDeliver,
              isLoading: ctrl.isActionLoading,
              onTap: () async {
                final ok = await ctrl.deliverOrder(
                  orderId: order.id,
                  finalAmount: ctrl.finalAmountValue,
                  paidNow: ctrl.paidNowValue,
                  advancePaid: order.advancePaid,
                );
                if (ok && context.mounted) {
                  _showSnack(context, DeliveryStrings.snackDelivered);
                  onDelivered();
                }
              },
            ),
          ],

          const SizedBox(height: 8),

          // WhatsApp ready notification
          _ActionButton(
            label: DeliveryStrings.btnWhatsApp,
            icon: DeliveryIcons.whatsapp,
            color: DeliveryColors.actionWhatsApp,
            outlined: true,
            onTap: () => _openWhatsApp(order),
          ),

          const SizedBox(height: 8),

          // Cancel
          _ActionButton(
            label: DeliveryStrings.btnCancel,
            icon: DeliveryIcons.cancel,
            color: DeliveryColors.actionCancel,
            outlined: true,
            onTap: () => _confirmCancel(context, order),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(DeliveryOrderUiModel o) {
    final msg = Uri.encodeComponent(
      DeliveryStrings.whatsAppReadyMsg(
          o.customerName, o.itemName, o.deliveryNo),
    );
    final phone = o.customerMobile.replaceAll(RegExp(r'[^0-9]'), '');
    launchUrl(Uri.parse('https://wa.me/91$phone?text=$msg'));
  }

  void _openWhatsAppDue(DeliveryOrderUiModel o) {
    final msg = Uri.encodeComponent(
      DeliveryStrings.whatsAppDueMsg(
        o.customerName,
        o.dueAmount.toStringAsFixed(2),
        o.deliveryNo,
      ),
    );
    final phone = o.customerMobile.replaceAll(RegExp(r'[^0-9]'), '');
    launchUrl(Uri.parse('https://wa.me/91$phone?text=$msg'));
  }

  void _confirmCancel(BuildContext context, DeliveryOrderUiModel o) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DeliveryColors.bodyPanelBg,
        title: const Text(DeliveryStrings.confirmCancelTitle,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(DeliveryStrings.confirmCancelMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(DeliveryStrings.btnCancel2),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryColors.actionCancel),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ctrl.cancelOrder(o.id);
              if (ok && context.mounted) {
                _showSnack(context, DeliveryStrings.snackCancelled);
              }
            },
            child: const Text(DeliveryStrings.btnConfirm,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? DeliveryColors.actionCancel : DeliveryColors.statusReady,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}

// ── Due Summary Row ───────────────────────────────────────────────────────────
class _DueSummaryRow extends StatelessWidget {
  final DeliveryManagementController ctrl;
  final DeliveryOrderUiModel order;
  const _DueSummaryRow({required this.ctrl, required this.order});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ctrl.finalAmtCtrl, ctrl.paidNowCtrl]),
      builder: (_, __) {
        final due = ctrl.dueAfterDelivery;
        if (due <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DeliveryColors.urgencyOverdueBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: DeliveryColors.urgencyOverdue.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(DeliveryIcons.dueAmount,
                size: 16, color: DeliveryColors.urgencyOverdue),
            const SizedBox(width: 8),
            Text(DeliveryStrings.lblDueAfter,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DeliveryColors.urgencyOverdue)),
            const Spacer(),
            Text(
              '₹${due.toStringAsFixed(2)}',
              style: DeliveryStyles.dueAmount,
            ),
          ]),
        );
      },
    );
  }
}

// ── Amount Input Field ────────────────────────────────────────────────────────
class _AmountField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  const _AmountField({required this.ctrl, required this.label});

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: DeliveryStyles.sectionHeader),
      const SizedBox(height: 6),
      Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: Container(
          height: 44,
          decoration: DeliveryStyles.inputDecoration(_focused),
          child: Row(children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('₹',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: DeliveryColors.brandGold)),
            ),
            Expanded(
              child: TextField(
                controller: widget.ctrl,
                style: DeliveryStyles.inputText,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                  hintText: DeliveryStrings.hintAmount,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.isLoading = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: widget.outlined
                ? (_hover ? widget.color.withOpacity(0.08) : Colors.transparent)
                : (_hover ? widget.color.withOpacity(0.85) : widget.color),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.outlined
                  ? widget.color.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.outlined ? widget.color : Colors.white,
                    ),
                  ),
                )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.outlined ? widget.color : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: widget.outlined ? widget.color : Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ]),
        ),
      ),
    );
  }
}

// ── Section Wrapper ───────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DeliveryStyles.bodyCard,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(title, style: DeliveryStyles.sectionHeader),
          const Spacer(),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 10),
        Divider(color: DeliveryColors.bodyBorder.withOpacity(0.7), height: 1),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 13, color: DeliveryColors.bodyTextMuted),
        const SizedBox(width: 7),
        Text(label, style: DeliveryStyles.cardSubtitle),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? DeliveryColors.bodyTextMain,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

// ── No Selection State ────────────────────────────────────────────────────────
class _NoSelectionState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DeliveryStyles.sidePanel,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              DeliveryIcons.moduleIcon,
              size: 52,
              color: DeliveryColors.bodyTextMuted.withOpacity(0.2),
            ),
            const SizedBox(height: 14),
            Text(
              'Select an order',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.bodyTextMuted.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose an order from the list to view its details.',
              style: TextStyle(
                fontSize: 12,
                color: DeliveryColors.bodyTextMuted.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
