import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../logic/dashboard/payment_status/payment_status_logic.dart';
import '../../../models/dashboard/payment_status_model.dart';
import '../../../theme/dashboard/payment_status/payment_status_colors.dart';

class CollectedFlipCard extends StatefulWidget {
  const CollectedFlipCard({super.key, required this.summary});

  final PaymentSummary summary;

  @override
  State<CollectedFlipCard> createState() => _CollectedFlipCardState();
}

class _CollectedFlipCardState extends State<CollectedFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('payment-collected-flip'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _flip.value < 0.5 ? _flip.forward() : _flip.reverse(),
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final isBack = _flip.value >= 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(math.pi * _flip.value),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(isBack ? math.pi : 0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        PaymentStatusColors.paidAccent.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: PaymentStatusColors.paidAccent
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    alignment: Alignment.topCenter,
                    child: isBack ? _buildBreakdown() : _buildTotal(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotal() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COLLECTED TODAY',
                style: TextStyle(
                  color: PaymentStatusColors.amountPaid,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                )),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                PaymentStatusLogic.formatAmountFull(
                    widget.summary.totalCollected),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Tap to view cash and bank',
                style: TextStyle(
                    color: PaymentStatusColors.textSecondary, fontSize: 11)),
          ],
        ),
      );

  Widget _buildBreakdown() {
    final modes = widget.summary.bankByMode.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COLLECTION BY MODE',
              style: TextStyle(
                color: PaymentStatusColors.amountPaid,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
          _amountLine('Cash', widget.summary.cashCollected, bold: true),
          const SizedBox(height: 5),
          _amountLine('Bank', widget.summary.bankCollected, bold: true),
          for (final mode in modes)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 10),
              child: _amountLine(mode.key.replaceAll('_', ' '), mode.value),
            ),
          const SizedBox(height: 9),
          const Text('Tap to see total',
              style: TextStyle(
                  color: PaymentStatusColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _amountLine(String label, double amount, {bool bold = false}) => Row(
        children: [
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      bold ? Colors.white : PaymentStatusColors.textSecondary,
                  fontSize: bold ? 13 : 11,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                )),
          ),
          const SizedBox(width: 5),
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(PaymentStatusLogic.formatAmountFull(amount),
                  style: TextStyle(
                    color: bold ? PaymentStatusColors.amountPaid : Colors.white,
                    fontSize: bold ? 13 : 11,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
          ),
        ],
      );
}
