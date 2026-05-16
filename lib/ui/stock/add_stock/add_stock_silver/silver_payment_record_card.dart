// =============================================================================
// FILE        : silver_payment_record_card.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : UI / Widget
// DESCRIPTION : Payment Record Card for Silver Add Stock screen.
//
//   Shows:
//     • Rate per KG input → live per-gram + total bill amount
//     • Payment mode toggles: Metal, Cash, UPI, Banking, Card
//     • Metal to Metal:
//         → Gross Weight input  (grams)
//         → Purity % input
//         → Auto-calculated Fine  (grossWeight × purity ÷ 100)
//         → Fine value in Rs  (fine × ratePerGram)
//     • Other modes: plain Rs amount fields
//     • Summary footer: Total Bill | Total Paid | Due Amount
//     • Due Settlement toggle (only when due > 0):
//         → "Fine dena hai" (show grams of fine owed)
//         → "Paisa dena hai" (show Rs owed)
//
// USAGE:
//   SilverPaymentRecordCard(
//     ctrl: silverStockController,
//     payment: silverStockController.payment,
//   )
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_payment_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ACCENT COLOURS — silver module
// ─────────────────────────────────────────────────────────────────────────────

const _kSilverAccent = Color(0xFF748A98);
const _kDueColor = Color(0xFFD9534F);
const _kSettledColor = Color(0xFF4CAF80);
const _kMetalColor = Color(0xFF8BA1AF);
const _kFineColor = Color(0xFF5B7A8A);

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class SilverPaymentRecordCard extends StatelessWidget {
  final SilverStockController ctrl;
  final SilverPaymentController payment;

  const SilverPaymentRecordCard({
    super.key,
    required this.ctrl,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([payment, ctrl]),
      builder: (context, _) {
        final totalFine = ctrl.totalFineWeight;
        final hasFine = totalFine > 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AddStockColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AddStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AddStockColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: AddStockColors.shadowMedium,
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ───────────────────────────────────────────────────
              _CardHeader(payment: payment, totalFine: totalFine),

              _divider(),

              // ── RATE SECTION ─────────────────────────────────────────────
              _RateSection(payment: payment, totalFine: totalFine),

              if (hasFine && payment.hasRate) ...[
                const SizedBox(height: 16),

                // ── PAYMENT MODES TOGGLE ROW ────────────────────────────
                _PaymentModeRow(payment: payment),

                const SizedBox(height: 14),

                // ── ACTIVE PAYMENT FIELDS ───────────────────────────────
                _ActivePaymentFields(payment: payment, totalFine: totalFine),

                _divider(),

                // ── SUMMARY FOOTER ──────────────────────────────────────
                _PaymentSummary(payment: payment, totalFine: totalFine),

                // ── DUE SETTLEMENT SECTION ──────────────────────────────
                if (payment.hasDue(totalFine)) ...[
                  const SizedBox(height: 12),
                  _DueSettlementSection(payment: payment, totalFine: totalFine),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        height: 1,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 16),
        color: AddStockColors.cardBorder,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;

  const _CardHeader({required this.payment, required this.totalFine});

  @override
  Widget build(BuildContext context) {
    final isSettled = payment.isSettled(totalFine);
    final hasPaid = payment.totalPaid > 0;
    final statusColor = isSettled && hasPaid
        ? _kSettledColor
        : hasPaid
            ? _kDueColor
            : _kSilverAccent;
    final statusLabel = isSettled && hasPaid
        ? 'SETTLED'
        : hasPaid
            ? 'PARTIAL'
            : 'PENDING';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _accentLine(20, _kSilverAccent, 1.0),
                const SizedBox(height: 3),
                _accentLine(13, _kSilverAccent, 0.45),
                const SizedBox(height: 3),
                _accentLine(7, _kSilverAccent, 0.18),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAYMENT RECORD',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AddStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rate, mode & settlement for this batch',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        _StatusPill(label: statusLabel, color: statusColor),
      ],
    );
  }

  Widget _accentLine(double width, Color color, double opacity) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: color.withOpacity(opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// RATE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _RateSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;

  const _RateSection({required this.payment, required this.totalFine});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SILVER RATE (PER KG)',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: AddStockColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: payment.ratePerKgCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AddStockColors.textDark,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 90000',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AddStockColors.textHint,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _kSilverAccent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.currency_rupee_rounded,
                        size: 15,
                        color: _kSilverAccent,
                      ),
                    ),
                  ),
                  suffixText: '/ kg',
                  suffixStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AddStockColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AddStockColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AddStockColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: _kSilverAccent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _RateChip(
              topLabel: 'PER GRAM',
              value: payment.ratePerGramDisplay,
              color: _kSilverAccent,
            ),
          ],
        ),
        if (totalFine > 0 && payment.hasRate) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'TOTAL FINE',
                  value: '${totalFine.toStringAsFixed(3)} g',
                  icon: Icons.balance_rounded,
                  color: _kMetalColor,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.close_rounded, size: 16, color: _kSilverAccent),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  label: 'RATE / G',
                  value: payment.ratePerGramDisplay,
                  icon: Icons.currency_rupee_rounded,
                  color: _kSilverAccent,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: _kSilverAccent),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _InfoTile(
                  label: 'TOTAL BILL',
                  value: payment.totalBillAmountDisplay(totalFine),
                  icon: Icons.receipt_rounded,
                  color: _kSettledColor,
                  highlighted: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT MODE TOGGLE ROW
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentModeRow extends StatelessWidget {
  final SilverPaymentController payment;

  const _PaymentModeRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAYMENT MODE',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: AddStockColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SilverPaymentMode.values
              .map((mode) => _ModeToggleChip(
                    mode: mode,
                    isEnabled: payment.isModeEnabled(mode),
                    onTap: () => payment.toggleMode(mode),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE PAYMENT FIELDS
// ─────────────────────────────────────────────────────────────────────────────

class _ActivePaymentFields extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;

  const _ActivePaymentFields({required this.payment, required this.totalFine});

  @override
  Widget build(BuildContext context) {
    final activeModes = SilverPaymentMode.values
        .where((m) => payment.isModeEnabled(m))
        .toList();

    if (activeModes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          'Tap a payment mode above to record payment',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AddStockColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: activeModes.map((mode) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: mode == SilverPaymentMode.metalToMetal
              ? _MetalToMetalField(payment: payment)
              : _CashPaymentField(mode: mode, payment: payment),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METAL TO METAL — NEW TWO-STEP FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _MetalToMetalField extends StatelessWidget {
  final SilverPaymentController payment;

  const _MetalToMetalField({required this.payment});

  @override
  Widget build(BuildContext context) {
    final hasCalc = payment.hasMetalCalculation;
    final fine = payment.metalFineCalculated;
    final cashEquiv = payment.metalFineEquivalentCash;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kFineColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kFineColor.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ──────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.balance_rounded, size: 14, color: _kFineColor),
              const SizedBox(width: 6),
              Text(
                'METAL TO METAL',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: _kFineColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Step 1: Gross Weight ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetalInputField(
                  controller: payment.metalGrossWeightCtrl,
                  label: 'GROSS WEIGHT',
                  hint: 'e.g. 100.500',
                  suffix: 'g',
                  icon: Icons.scale_rounded,
                ),
              ),
              const SizedBox(width: 10),
              // ── Step 2: Purity ─────────────────────────────────────────
              Expanded(
                child: _MetalInputField(
                  controller: payment.metalPurityCtrl,
                  label: 'PURITY',
                  hint: 'e.g. 92.5',
                  suffix: '%',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
            ],
          ),

          // ── Auto-calculated Fine ───────────────────────────────────────
          if (hasCalc) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kFineColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kFineColor.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  // ── Fine weight row ──────────────────────────────────
                  Row(
                    children: [
                      _calcStepChip(
                        label: payment.metalGrossWeight.toStringAsFixed(3),
                        unit: 'g',
                        color: _kMetalColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '×',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kFineColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _calcStepChip(
                        label: payment.metalPurity.toStringAsFixed(2),
                        unit: '%',
                        color: _kMetalColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '÷ 100 =',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kFineColor,
                        ),
                      ),
                      const Spacer(),
                      // Result: fine weight
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'FINE',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: _kFineColor.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${fine.toStringAsFixed(3)} g',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _kFineColor,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Cash equivalent row (only if rate set) ──────────
                  if (payment.hasRate) ...[
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      color: _kFineColor.withOpacity(0.15),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.currency_rupee_rounded,
                            size: 13, color: _kFineColor.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${fine.toStringAsFixed(3)} g  ×  ${payment.ratePerGramDisplay}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kFineColor.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'VALUE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: _kSettledColor.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              'Rs ${cashEquiv.toStringAsFixed(2)}',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: _kSettledColor,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _calcStepChip(
      {required String label, required String unit, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METAL INPUT FIELD (reusable for gross weight + purity)
// ─────────────────────────────────────────────────────────────────────────────

class _MetalInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final IconData icon;

  const _MetalInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AddStockColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kFineColor,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AddStockColors.textHint,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _kFineColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: _kFineColor),
          ),
        ),
        suffixText: suffix,
        suffixStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AddStockColors.textMuted,
        ),
        filled: true,
        fillColor: AddStockColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: _kFineColor.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: _kFineColor.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _kFineColor, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CASH PAYMENT FIELD (Cash, UPI, Banking, Card)
// ─────────────────────────────────────────────────────────────────────────────

class _CashPaymentField extends StatelessWidget {
  final SilverPaymentMode mode;
  final SilverPaymentController payment;

  const _CashPaymentField({required this.mode, required this.payment});

  TextEditingController get _ctrl {
    return switch (mode) {
      SilverPaymentMode.metalToMetal => payment.metalGrossWeightCtrl,
      SilverPaymentMode.cash => payment.cashCtrl,
      SilverPaymentMode.upi => payment.upiCtrl,
      SilverPaymentMode.banking => payment.bankingCtrl,
      SilverPaymentMode.card => payment.cardCtrl,
    };
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AddStockColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: mode.label,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AddStockColors.textMuted,
        ),
        hintText: 'Amount paid',
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AddStockColors.textHint,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _kSilverAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(mode.icon, size: 15, color: _kSilverAccent),
          ),
        ),
        suffixText: 'Rs',
        suffixStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AddStockColors.textMuted,
        ),
        filled: true,
        fillColor: AddStockColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AddStockColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AddStockColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kSilverAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT SUMMARY FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentSummary extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;

  const _PaymentSummary({required this.payment, required this.totalFine});

  @override
  Widget build(BuildContext context) {
    final bill = payment.totalBillAmount(totalFine);
    final paid = payment.totalPaid;
    final due = payment.dueAmount(totalFine);
    final isSettled = payment.isSettled(totalFine) && paid > 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'TOTAL BILL',
                value: 'Rs ${bill.toStringAsFixed(2)}',
                color: AddStockColors.textDark,
                bgColor: AddStockColors.inputBg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: 'TOTAL PAID',
                value: 'Rs ${paid.toStringAsFixed(2)}',
                color: _kSettledColor,
                bgColor: _kSettledColor.withOpacity(0.06),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSettled
                ? _kSettledColor.withOpacity(0.06)
                : _kDueColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSettled
                  ? _kSettledColor.withOpacity(0.25)
                  : _kDueColor.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSettled
                      ? _kSettledColor.withOpacity(0.12)
                      : _kDueColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSettled
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: isSettled ? _kSettledColor : _kDueColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSettled ? 'FULLY SETTLED' : 'DUE AMOUNT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isSettled
                            ? _kSettledColor.withOpacity(0.7)
                            : _kDueColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSettled
                          ? 'Payment complete'
                          : 'Rs ${due.toStringAsFixed(2)} pending on this batch',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isSettled ? _kSettledColor : _kDueColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: isSettled ? 'CLEAR' : 'DUE',
                color: isSettled ? _kSettledColor : _kDueColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DUE SETTLEMENT SECTION — NEW
// ─────────────────────────────────────────────────────────────────────────────

class _DueSettlementSection extends StatelessWidget {
  final SilverPaymentController payment;
  final double totalFine;

  const _DueSettlementSection({required this.payment, required this.totalFine});

  @override
  Widget build(BuildContext context) {
    final due = payment.dueAmount(totalFine);
    final dueAsFineg = payment.dueAmountAsFine(totalFine);
    final mode = payment.dueSettleMode;
    final isFineMode = mode == DueSettleMode.asFine;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kDueColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDueColor.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label ─────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: _kDueColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'DUE SETTLEMENT — Kaise settle karoge?',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: _kDueColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Toggle buttons ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DueModeButton(
                  label: 'Fine Dena Hai',
                  subLabel: 'Metal (grams)',
                  icon: Icons.balance_rounded,
                  isSelected: isFineMode,
                  onTap: () => payment.setDueSettleMode(DueSettleMode.asFine),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DueModeButton(
                  label: 'Paisa Dena Hai',
                  subLabel: 'Cash / UPI / Bank',
                  icon: Icons.currency_rupee_rounded,
                  isSelected: !isFineMode,
                  onTap: () => payment.setDueSettleMode(DueSettleMode.asCash),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Result display ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isFineMode
                  ? _kFineColor.withOpacity(0.07)
                  : _kDueColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFineMode
                    ? _kFineColor.withOpacity(0.22)
                    : _kDueColor.withOpacity(0.22),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isFineMode
                      ? Icons.balance_rounded
                      : Icons.currency_rupee_rounded,
                  size: 22,
                  color: isFineMode ? _kFineColor : _kDueColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFineMode
                            ? 'SUPPLIER KO DENA HAI (FINE)'
                            : 'SUPPLIER KO DENA HAI (PAISA)',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: (isFineMode ? _kFineColor : _kDueColor)
                              .withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFineMode
                            ? '${dueAsFineg.toStringAsFixed(3)} g fine'
                            : 'Rs ${due.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isFineMode ? _kFineColor : _kDueColor,
                          height: 1,
                        ),
                      ),
                      if (isFineMode && payment.hasRate) ...[
                        const SizedBox(height: 3),
                        Text(
                          '= Rs ${due.toStringAsFixed(2)} (${dueAsFineg.toStringAsFixed(3)} g × ${payment.ratePerGramDisplay})',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kFineColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// DUE MODE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _DueModeButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DueModeButton({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? _kDueColor : AddStockColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _kDueColor.withOpacity(0.08)
              : AddStockColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _kDueColor.withOpacity(0.40)
                : AddStockColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    subLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kDueColor,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateChip extends StatelessWidget {
  final String topLabel;
  final String value;
  final Color color;

  const _RateChip(
      {required this.topLabel, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topLabel,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlighted;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.08) : AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              highlighted ? color.withOpacity(0.28) : AddStockColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlighted ? color : AddStockColors.textDark,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggleChip extends StatelessWidget {
  final SilverPaymentMode mode;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ModeToggleChip({
    required this.mode,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = _kSilverAccent;
    final bgColor =
        isEnabled ? activeColor.withOpacity(0.10) : AddStockColors.inputBg;
    final borderColor =
        isEnabled ? activeColor.withOpacity(0.40) : AddStockColors.cardBorder;
    final textColor = isEnabled ? activeColor : AddStockColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(
              mode.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AddStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
