// =============================================================================
// FILE        : booking_right_panel.dart
// MODULE      : Sales → Booking & Advance
// DESCRIPTION : Right panel — same structure as PosRightBillingPanel.
//               Shows: Booking Summary + Advance Payment (Cash/UPI/Card) +
//                      Scrap Metal Value + Total Advance + Balance Due + Save
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';

class BookingRightPanel extends StatefulWidget {
  final BookingAdvanceController ctrl;
  final Function(String, bool) onSaved;
  const BookingRightPanel({super.key, required this.ctrl, required this.onSaved});

  @override
  State<BookingRightPanel> createState() => _BookingRightPanelState();
}

class _BookingRightPanelState extends State<BookingRightPanel> {
  BookingAdvanceController get ctrl => widget.ctrl;

  Widget _divider() => Container(height: 2.0,
    decoration: BoxDecoration(gradient: LinearGradient(colors: [
      BookingAdvanceColors.brandGold.withOpacity(0.05),
      BookingAdvanceColors.bodyBorder,
      BookingAdvanceColors.brandGold.withOpacity(0.05),
    ])));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) => Container(
        decoration: BookingAdvanceStyles.rightPanel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(children: [
            Expanded(child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: [
                _buildSummaryBoard(),
                _divider(),
                _buildPaymentHub(),
              ]),
            )),
            _divider(),
            _buildActionButtons(context),
          ]),
        ),
      ),
    );
  }

  // ── BOOKING SUMMARY BOARD ─────────────────────────────────────────────────
  Widget _buildSummaryBoard() {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final isLocked = ctrl.bookingType == BookingType.locked;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHead(icon: BookingAdvanceIcons.summaryIcon, title: BookingAdvanceStrings.sectionSummary, subtitle: BookingAdvanceStrings.summarySubtitle),

        const SizedBox(height: 14),

        // Customer
        _row('Customer', ctrl.nameCtrl.text.isNotEmpty ? ctrl.nameCtrl.text : '—',
          valueColor: ctrl.nameCtrl.text.isNotEmpty ? BookingAdvanceColors.textDark : BookingAdvanceColors.bodyTextMuted),

        // Items count
        _row('Total Items', '${ctrl.bookingItems.length} item(s)'),

        // Rate type
        _row('Rate Type', isLocked ? BookingAdvanceStrings.lockedBadge : BookingAdvanceStrings.openBadge,
          valueColor: isLocked ? BookingAdvanceColors.lockedRateColor : BookingAdvanceColors.openRateColor),

        // Locked rate
        if (isLocked && ctrl.lockedRate > 0)
          _row('Locked Rate', '₹ ${fmt.format(ctrl.lockedRate.toInt())} / 10g',
            valueColor: BookingAdvanceColors.lockedRateColor),

        // Delivery date
        if (ctrl.deliveryDate != null)
          _row('Delivery Date', DateFormat('dd MMM yyyy').format(ctrl.deliveryDate!)),

        const SizedBox(height: 12),

        // Booking value box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: BookingAdvanceColors.bodyBg, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BookingAdvanceColors.bodyBorder, width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('APPROX. BOOKING VALUE', style: BookingAdvanceStyles.totalRowLabel),
            Text('₹ ${fmt.format(ctrl.totalBookingVal.toInt())}', style: BookingAdvanceStyles.totalRowValue),
          ]),
        ),

        // Scrap value row
        if (ctrl.scrapItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: BookingAdvanceColors.danger.withOpacity(0.04), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BookingAdvanceColors.danger.withOpacity(0.25))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.recycling_rounded, color: BookingAdvanceColors.danger, size: 16),
                const SizedBox(width: 8),
                const Text('SCRAP METAL VALUE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: BookingAdvanceColors.danger, letterSpacing: 0.5)),
              ]),
              Text('₹ ${fmt.format(ctrl.totalScrapVal.toInt())}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: BookingAdvanceColors.danger)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── ADVANCE PAYMENT HUB ───────────────────────────────────────────────────
  Widget _buildPaymentHub() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHead(icon: BookingAdvanceIcons.advancePayment, title: BookingAdvanceStrings.sectionPayment, subtitle: BookingAdvanceStrings.paymentSubtitle),
        const SizedBox(height: 16),

        // Cash
        _payRow(BookingAdvanceStrings.lblCash, BookingAdvanceIcons.cash, BookingAdvanceColors.cashColor, ctrl.cashCtrl),
        const SizedBox(height: 10),
        // UPI
        _payRow(BookingAdvanceStrings.lblUpi, BookingAdvanceIcons.upi, BookingAdvanceColors.upiColor, ctrl.upiCtrl),
        const SizedBox(height: 10),
        // Card
        _payRow(BookingAdvanceStrings.lblCard, BookingAdvanceIcons.card, BookingAdvanceColors.cardColor, ctrl.cardCtrl),

        const SizedBox(height: 16),

        // TOTAL ADVANCE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [BookingAdvanceColors.brandGold.withOpacity(0.08), BookingAdvanceColors.brandGold.withOpacity(0.03)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BookingAdvanceColors.brandGold.withOpacity(0.3), width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(BookingAdvanceStrings.lblAdvanceTotal,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: BookingAdvanceColors.textDark)),
            const SizedBox(height: 4),
            Text('₹  ${NumberFormat('#,##,###').format(ctrl.totalAdvance.toInt())}',
              style: BookingAdvanceStyles.grandTotalText),
            if (ctrl.totalAdvance > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: BookingAdvanceColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text(BookingAdvanceStrings.advanceReceived,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BookingAdvanceColors.success)),
              ),
            ],
          ]),
        ),

        // BALANCE DUE
        if (ctrl.totalBookingVal > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ctrl.balanceDue > 0 ? BookingAdvanceColors.warning.withOpacity(0.06) : BookingAdvanceColors.success.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ctrl.balanceDue > 0 ? BookingAdvanceColors.warning.withOpacity(0.3) : BookingAdvanceColors.success.withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('BALANCE DUE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                color: ctrl.balanceDue > 0 ? BookingAdvanceColors.warning : BookingAdvanceColors.success)),
              Text('₹ ${NumberFormat('#,##,###').format(ctrl.balanceDue.abs().toInt())}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                  color: ctrl.balanceDue > 0 ? BookingAdvanceColors.warning : BookingAdvanceColors.success)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _payRow(String label, IconData icon, Color color, TextEditingController payCtrl) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(width: 120, child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, color: color, size: 15)),
        const SizedBox(width: 8),
        Flexible(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.3))),
      ])),
      const SizedBox(width: 10),
      Expanded(child: SizedBox(height: 44, child: TextField(
        controller: payCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        style: BookingAdvanceStyles.inputText,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: BookingAdvanceColors.bodyTextMuted.withOpacity(0.6), fontSize: 14),
          prefixText: '₹  ',
          prefixStyle: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
          filled: true, fillColor: color.withOpacity(0.03),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(borderSide: BorderSide(color: color.withOpacity(0.25)), borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: color.withOpacity(0.25)), borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2), borderRadius: BorderRadius.circular(8)),
        ),
      ))),
    ]);
  }

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(children: [
        // SAVE
        GestureDetector(
          onTap: ctrl.isSaving ? null : () => _handleSave(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: ctrl.isSaving
                ? BoxDecoration(color: BookingAdvanceColors.brandGold.withOpacity(0.5), borderRadius: BorderRadius.circular(12))
                : BookingAdvanceStyles.saveButton,
            child: Center(child: ctrl.isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(BookingAdvanceIcons.saveBooking, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(BookingAdvanceStrings.btnSaveBooking,
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ])),
          ),
        ),
        const SizedBox(height: 10),
        // CLEAR
        _HoverOutlineBtn(label: BookingAdvanceStrings.btnClearAll, icon: BookingAdvanceIcons.clearAll, onTap: ctrl.clearAll),
      ]),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final result = await ctrl.saveBooking();
    widget.onSaved(result.message, result.success);
  }

  Widget _sectionHead({required IconData icon, required String title, required String subtitle}) {
    return Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [BookingAdvanceColors.goldGradientStart, BookingAdvanceColors.brandGold]),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [BoxShadow(color: BookingAdvanceColors.brandGold.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: Colors.white, size: 17)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: BookingAdvanceColors.textDark, letterSpacing: 0.5)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: BookingAdvanceColors.bodyTextMuted.withOpacity(0.8), fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _row(String label, String val, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: BookingAdvanceStyles.summaryLabel),
        Flexible(child: Text(val, textAlign: TextAlign.right,
          style: BookingAdvanceStyles.summaryValue.copyWith(color: valueColor))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HoverOutlineBtn extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _HoverOutlineBtn({required this.label, required this.icon, required this.onTap});
  @override State<_HoverOutlineBtn> createState() => _HoverOutlineBtnState();
}
class _HoverOutlineBtnState extends State<_HoverOutlineBtn> {
  bool _h = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 220), height: 48,
          decoration: BoxDecoration(
            color: _h ? BookingAdvanceColors.bodyPanelBg : BookingAdvanceColors.bodyBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _h ? BookingAdvanceColors.danger.withOpacity(0.5) : BookingAdvanceColors.bodyBorder,
              width: _h ? 1.5 : 1.0)),
          child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, size: 18, color: _h ? BookingAdvanceColors.danger : BookingAdvanceColors.bodyTextMuted),
            const SizedBox(width: 8),
            Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5,
              color: _h ? BookingAdvanceColors.danger : BookingAdvanceColors.bodyTextMuted)),
          ]))),
      ),
    );
  }
}