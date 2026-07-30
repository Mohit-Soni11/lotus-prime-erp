import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosAmountPayableCard extends StatelessWidget {
  final double amount;

  const PosAmountPayableCard({
    super.key,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomerCredit = amount < 0;
    final accent =
        isCustomerCredit ? SalesPosColors.success : SalesPosColors.brandGold;
    final label = isCustomerCredit ? 'CUSTOMER CREDIT' : 'AMOUNT PAYABLE';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.50), width: 2.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  color:
                      isCustomerCredit ? accent : SalesPosColors.bodyTextMain,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${isCustomerCredit ? '- ' : ''}Rs ${amount.abs().toStringAsFixed(2)}',
                style: SalesPosStyles.grandTotalText.copyWith(color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PosPaymentStatusCard extends StatelessWidget {
  final bool isEmptyCart;
  final bool hasIncompleteDraft;
  final double balanceDue;
  final RefundMethod? returnMethod;

  const PosPaymentStatusCard({
    super.key,
    required this.isEmptyCart,
    required this.hasIncompleteDraft,
    required this.balanceDue,
    required this.returnMethod,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmptyCart) {
      return _NeutralPaymentCard();
    }

    final isDue = balanceDue > 0.005;
    final isReturn = balanceDue < -0.005;
    final isSettled = !isDue && !isReturn && !hasIncompleteDraft;
    final hasSettledReturn = isReturn && returnMethod != null;
    final tone = _toneFor(
      hasIncompleteDraft: hasIncompleteDraft,
      isDue: isDue,
      isReturn: isReturn,
      isSettled: isSettled,
      hasSettledReturn: hasSettledReturn,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.color.withValues(alpha: 0.10),
        border: Border.all(
          color: tone.color.withValues(alpha: 0.60),
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusLabel(
                  hasIncompleteDraft: hasIncompleteDraft,
                  isDue: isDue,
                  isReturn: isReturn,
                  isSettled: isSettled,
                  returnMethod: returnMethod,
                ),
                style: TextStyle(
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: tone.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs ${balanceDue.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: SalesPosStyles.fontHero,
                  fontWeight: FontWeight.w900,
                  color: tone.color,
                ),
              ),
            ],
          ),
          Icon(tone.icon, color: tone.color, size: 32),
        ],
      ),
    );
  }

  _PaymentTone _toneFor({
    required bool hasIncompleteDraft,
    required bool isDue,
    required bool isReturn,
    required bool isSettled,
    required bool hasSettledReturn,
  }) {
    if (hasIncompleteDraft) {
      return const _PaymentTone(
        SalesPosColors.warning,
        SalesPosIcons.dueWarning,
      );
    }
    if (isSettled || hasSettledReturn) {
      return const _PaymentTone(
        SalesPosColors.success,
        SalesPosIcons.settledVerified,
      );
    }
    if (isReturn) {
      return const _PaymentTone(
        SalesPosColors.warning,
        SalesPosIcons.returnChange,
      );
    }
    return const _PaymentTone(
      SalesPosColors.danger,
      SalesPosIcons.dueWarning,
    );
  }

  String _statusLabel({
    required bool hasIncompleteDraft,
    required bool isDue,
    required bool isReturn,
    required bool isSettled,
    required RefundMethod? returnMethod,
  }) {
    if (hasIncompleteDraft) return 'INVOICE NEEDS REVIEW';
    if (isSettled) return 'PAYMENT SETTLED';
    if (isReturn && returnMethod == RefundMethod.accountCredit) {
      return 'CUSTOMER CREDIT CREATED';
    }
    if (isReturn && returnMethod != null) {
      return 'CHANGE RETURNED VIA ${returnMethod.displayName}';
    }
    if (isReturn) return 'CHANGE TO RETURN';
    if (isDue) return 'BALANCE DUE';
    return 'PAYMENT SETTLED';
  }
}

class PosPaymentBreakdownCard extends StatelessWidget {
  final double amountPayable;
  final double amountReceived;
  final double balanceDue;
  final bool hasIncompleteDraft;

  const PosPaymentBreakdownCard({
    super.key,
    required this.amountPayable,
    required this.amountReceived,
    required this.balanceDue,
    required this.hasIncompleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final balanceLabel =
        balanceDue < -0.005 ? 'Change / Credit' : 'Balance Due';
    final balanceColor = hasIncompleteDraft
        ? SalesPosColors.warning
        : balanceDue > 0.005
            ? SalesPosColors.danger
            : balanceDue < -0.005
                ? SalesPosColors.warning
                : SalesPosColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: 'Amount Payable',
            value: _amount(amountPayable),
            valueColor: SalesPosColors.bodyTextMain,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            label: 'Amount Received',
            value: _amount(amountReceived),
            valueColor: SalesPosColors.success,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: SalesPosColors.bodyBorder, height: 1.5),
          ),
          _BreakdownRow(
            label: hasIncompleteDraft ? 'Review Required' : balanceLabel,
            value: _amount(balanceDue.abs()),
            valueColor: balanceColor,
            strong: true,
          ),
        ],
      ),
    );
  }

  String _amount(double value) => 'Rs ${value.abs().toStringAsFixed(2)}';
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool strong;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize:
                strong ? SalesPosStyles.fontBody : SalesPosStyles.fontLabel,
            fontWeight: FontWeight.w900,
            color: SalesPosColors.bodyTextMain.withValues(alpha: 0.86),
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize:
                strong ? SalesPosStyles.fontBody : SalesPosStyles.fontLabel,
            fontWeight: FontWeight.w900,
            color: valueColor,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _NeutralPaymentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'NO PAYMENT DUE',
          style: TextStyle(
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w900,
            color: SalesPosColors.bodyTextMain,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PaymentTone {
  final Color color;
  final IconData icon;

  const _PaymentTone(this.color, this.icon);
}
