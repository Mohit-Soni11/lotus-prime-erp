// =============================================================================
// FILE        : delivery_order_card.dart
// MODULE      : Sales → Delivery Management
// LAYER       : UI
// DESCRIPTION : Order list card — shows customer, item, status pipeline badge,
//               urgency chip, payment status, delivery date.
//               Tapping opens the side detail panel.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../models/sales & orders/delivery/delivery_model.dart';
import '../../../models/sales & orders/delivery/delivery_enums.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';

import 'package:intl/intl.dart';

class DeliveryOrderCard extends StatefulWidget {
  final DeliveryOrderUiModel order;
  final bool isSelected;
  final VoidCallback onTap;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends State<DeliveryOrderCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: widget.isSelected
              ? DeliveryStyles.selectedCard
              : BoxDecoration(
                  color: _hover
                      ? DeliveryColors.cardHoverBg
                      : DeliveryColors.bodyPanelBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: o.isOverdue
                        ? DeliveryColors.urgencyOverdue.withOpacity(0.35)
                        : DeliveryColors.bodyBorder,
                    width: o.isOverdue ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DeliveryColors.shadowLight,
                      blurRadius: _hover ? 10 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Delivery No + Status badge ──
              Row(children: [
                Text(o.deliveryNo, style: DeliveryStyles.deliveryNoText),
                const Spacer(),
                _StatusBadge(status: o.status),
                if (o.urgency != null) ...[
                  const SizedBox(width: 6),
                  _UrgencyBadge(urgency: o.urgency!),
                ],
              ]),

              const SizedBox(height: 10),

              // ── Row 2: Customer ──
              Row(children: [
                const Icon(DeliveryIcons.customer,
                    size: 13, color: DeliveryColors.bodyTextMuted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    o.customerName,
                    style: DeliveryStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  o.customerMobile,
                  style: DeliveryStyles.cardSubtitle,
                ),
              ]),

              const SizedBox(height: 6),

              // ── Row 3: Item ──
              Row(children: [
                const Icon(DeliveryIcons.item,
                    size: 13, color: DeliveryColors.brandGold),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${o.itemName}  •  ${o.metalType} ${o.purity}  •  ${o.approxWeight.toStringAsFixed(3)}g',
                    style: DeliveryStyles.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),

              const SizedBox(height: 8),
              Divider(
                  color: DeliveryColors.bodyBorder.withOpacity(0.7), height: 1),
              const SizedBox(height: 8),

              // ── Row 4: Financials + Delivery date ──
              Row(children: [
                // Advance
                _FinancialChip(
                  label: 'Adv',
                  value: '₹${_fmt(o.advancePaid)}',
                  color: DeliveryColors.statusBooked,
                ),
                const SizedBox(width: 8),
                // Due
                if (o.dueAmount > 0)
                  _FinancialChip(
                    label: 'Due',
                    value: '₹${_fmt(o.dueAmount)}',
                    color: DeliveryColors.urgencyOverdue,
                    highlight: true,
                  ),
                const Spacer(),
                // Delivery date
                if (o.expectedDeliveryDate != null) ...[
                  Icon(
                    DeliveryIcons.calendar,
                    size: 12,
                    color: o.isOverdue
                        ? DeliveryColors.urgencyOverdue
                        : DeliveryColors.bodyTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM').format(o.expectedDeliveryDate!),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: o.isOverdue
                          ? DeliveryColors.urgencyOverdue
                          : DeliveryColors.bodyTextMuted,
                    ),
                  ),
                ],
              ]),

              // ── Row 5: Item count (multi-item orders) ──
              if (o.hasMultipleItems) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(DeliveryIcons.checkBox,
                      size: 12, color: DeliveryColors.bodyTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${o.deliveredItemCount}/${o.totalItemCount} items delivered',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DeliveryColors.bodyTextMuted,
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final DeliveryOrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (status) {
      DeliveryOrderStatus.booked => (
          DeliveryColors.statusBooked,
          DeliveryColors.statusBookedBg,
          DeliveryIcons.statusBooked
        ),
      DeliveryOrderStatus.inMaking => (
          DeliveryColors.statusInMaking,
          DeliveryColors.statusInMakingBg,
          DeliveryIcons.statusInMaking
        ),
      DeliveryOrderStatus.ready => (
          DeliveryColors.statusReady,
          DeliveryColors.statusReadyBg,
          DeliveryIcons.statusReady
        ),
      DeliveryOrderStatus.delivered => (
          DeliveryColors.statusDelivered,
          DeliveryColors.statusDeliveredBg,
          DeliveryIcons.statusDelivered
        ),
      DeliveryOrderStatus.cancelled => (
          DeliveryColors.statusCancelled,
          DeliveryColors.statusCancelledBg,
          DeliveryIcons.statusCancelled
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ]),
    );
  }
}

// ── Urgency Badge ─────────────────────────────────────────────────────────────
class _UrgencyBadge extends StatelessWidget {
  final DeliveryUrgency urgency;
  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (urgency) {
      DeliveryUrgency.overdue => (
          DeliveryStrings.urgencyOverdue,
          DeliveryColors.urgencyOverdue,
          DeliveryColors.urgencyOverdueBg
        ),
      DeliveryUrgency.today => (
          DeliveryStrings.urgencyToday,
          DeliveryColors.urgencyToday,
          DeliveryColors.urgencyTodayBg
        ),
      DeliveryUrgency.tomorrow => (
          DeliveryStrings.urgencyTomorrow,
          DeliveryColors.urgencyTomorrow,
          DeliveryColors.urgencyTomorrowBg
        ),
      DeliveryUrgency.thisWeek => (
          DeliveryStrings.urgencyTomorrow,
          DeliveryColors.urgencyTomorrow,
          DeliveryColors.urgencyTomorrowBg
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Financial Chip ─────────────────────────────────────────────────────────────
class _FinancialChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlight;

  const _FinancialChip({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(
        '$label: ',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: DeliveryColors.bodyTextMuted,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: highlight ? color : DeliveryColors.bodyTextMain,
        ),
      ),
    ]);
  }
}
