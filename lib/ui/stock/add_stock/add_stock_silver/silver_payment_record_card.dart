// =============================================================================
// FILE        : silver_payment_record_card.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : UI / Widget
// DESCRIPTION : Payment Record Card for Silver Add Stock screen.
//
//   Shows:
//     • Rate per KG input → live per-gram + total bill amount
//     • Payment mode toggles: Metal, Cash, UPI, Banking, Card
//     • Each enabled mode shows its input field
//     • Summary footer: Total Bill | Total Paid | Due Amount
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
          // ── HEADER ─────────────────────────────────────────────────────────
          _CardHeader(payment: payment, totalFine: totalFine),

          _divider(),

          // ── RATE SECTION ───────────────────────────────────────────────────
          _RateSection(payment: payment, totalFine: totalFine),

          if (hasFine && payment.hasRate) ...[
            const SizedBox(height: 16),

            // ── PAYMENT MODES TOGGLE ROW ──────────────────────────────────
            _PaymentModeRow(payment: payment),

            const SizedBox(height: 14),

            // ── ACTIVE PAYMENT FIELDS ─────────────────────────────────────
            _ActivePaymentFields(payment: payment, totalFine: totalFine),

            _divider(),

            // ── SUMMARY FOOTER ────────────────────────────────────────────
            _PaymentSummary(payment: payment, totalFine: totalFine),
          ],
        ],
      ),
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
            // Accent lines
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
        // Label
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

        // Rate input + live conversion chips row
        Row(
          children: [
            // Input field
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
            // Conversion chip
            _RateChip(
              topLabel: 'PER GRAM',
              value: payment.ratePerGramDisplay,
              color: _kSilverAccent,
            ),
          ],
        ),

        // Total Fine + Bill Amount row — only when we have fine and rate
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
          child: _PaymentField(
            mode: mode,
            payment: payment,
            totalFine: totalFine,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE PAYMENT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentField extends StatelessWidget {
  final SilverPaymentMode mode;
  final SilverPaymentController payment;
  final double totalFine;

  const _PaymentField({
    required this.mode,
    required this.payment,
    required this.totalFine,
  });

  TextEditingController get _ctrl {
    return switch (mode) {
      SilverPaymentMode.metalToMetal => payment.metalFineCtrl,
      SilverPaymentMode.cash => payment.cashCtrl,
      SilverPaymentMode.upi => payment.upiCtrl,
      SilverPaymentMode.banking => payment.bankingCtrl,
      SilverPaymentMode.card => payment.cardCtrl,
    };
  }

  bool get _isMetal => mode == SilverPaymentMode.metalToMetal;

  String get _suffix => _isMetal ? 'g (fine)' : '₹';

  String get _hint => _isMetal ? 'Fine weight given' : 'Amount paid';

  String? get _helperText {
    if (!_isMetal) return null;
    final given = payment.metalFineGiven;
    if (given <= 0) return null;
    final equiv = payment.metalFineEquivalentCash;
    return '= ₹ ${equiv.toStringAsFixed(2)} (${given.toStringAsFixed(3)} g × ${payment.ratePerGramDisplay})';
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
        hintText: _hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AddStockColors.textHint,
        ),
        helperText: _helperText,
        helperStyle: GoogleFonts.inter(
          fontSize: 11,
          color: _kMetalColor,
          fontWeight: FontWeight.w600,
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
        suffixText: _suffix,
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
                value: '₹ ${bill.toStringAsFixed(2)}',
                color: AddStockColors.textDark,
                bgColor: AddStockColors.inputBg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: 'TOTAL PAID',
                value: '₹ ${paid.toStringAsFixed(2)}',
                color: _kSettledColor,
                bgColor: _kSettledColor.withOpacity(0.06),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Due amount — full width highlighted
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
                          : '₹ ${due.toStringAsFixed(2)} pending on this batch',
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
