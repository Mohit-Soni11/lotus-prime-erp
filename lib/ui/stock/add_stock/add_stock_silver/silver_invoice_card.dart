// =============================================================================
// FILE        : silver_invoice_card.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : UI / Component
// DESCRIPTION : Invoice Number card for Silver Add Stock (Step 2).
//               ✅ System Batch ID — auto-generated, read-only display.
//               ✅ Supplier Invoice ID — manual editable input (B2B / GST).
//               ✅ Live Date + Time chips via DateCardLogic stream.
//               ✅ Mirrors PosInvoiceStatusBar card design pattern.
//               ✅ Animated GST / NORMAL status pill (reads ctrl.gstEnabled).
//               ✅ 100% Silver-themed — future-proof, zero hardcoded values.
// DESIGN REF  : PosInvoiceStatusBar (card layout, chips, pill).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/stock/add_stock_controller.dart';
import '../../../../logic/dashboard/date_card/date_card_logic.dart';
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverInvoiceCard extends StatefulWidget {
  final AddStockController ctrl;

  const SilverInvoiceCard({super.key, required this.ctrl});

  @override
  State<SilverInvoiceCard> createState() => _SilverInvoiceCardState();
}

class _SilverInvoiceCardState extends State<SilverInvoiceCard>
    with SingleTickerProviderStateMixin {
  late final DateCardLogic _dateLogic;
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _dateLogic = DateCardLogic();
    _dateLogic.init();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    Future.microtask(() {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _dateLogic.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ListenableBuilder(
          listenable: widget.ctrl,
          builder: (_, __) => _buildCard(),
        ),
      ),
    );
  }

  // ── MAIN CARD ────────────────────────────────────────────────
  Widget _buildCard() {
    final ctrl = widget.ctrl;
    final isGst = ctrl.gstEnabled;
    final accentColor =
        isGst ? SilverStockColors.success : SilverStockColors.brandSilver;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SilverStockColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilverStockColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: SilverStockColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── HEADER ROW ────────────────────────────────────
          _buildHeaderRow(isGst, accentColor),

          const SizedBox(height: 14),

          // ── ACCENT DIVIDER ────────────────────────────────
          _buildAccentDivider(accentColor),

          const SizedBox(height: 16),

          // ── TOP CONTENT ROW: Icon + Batch ID + Date/Time ──
          _buildInvoiceRow(ctrl, isGst, accentColor),

          const SizedBox(height: 18),

          // ── SUPPLIER INVOICE INPUT ────────────────────────
          _buildSupplierInvoiceSection(ctrl, accentColor),
        ],
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────
  Widget _buildHeaderRow(bool isGst, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Accent lines block (POS-style)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _accentLine(20, accentColor, 1.0),
            const SizedBox(height: 3),
            _accentLine(13, accentColor, 0.45),
            const SizedBox(height: 3),
            _accentLine(7, accentColor, 0.18),
          ],
        ),
        const SizedBox(width: 12),

        // Title block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVOICE NUMBER',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: SilverStockColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isGst
                      ? SilverStockColors.success
                      : SilverStockColors.textMuted,
                ),
                child: Text(isGst ? 'Tax Invoice — GST' : 'Standard Estimate'),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Status pill (mirrors batch overview card)
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isGst
                ? SilverStockColors.success.withOpacity(0.07)
                : SilverStockColors.inputBgLocked,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isGst
                  ? SilverStockColors.success.withOpacity(0.35)
                  : SilverStockColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGst
                      ? SilverStockColors.success
                      : SilverStockColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isGst
                      ? SilverStockColors.success
                      : SilverStockColors.textMuted,
                ),
                child: Text(isGst ? 'GST BILL' : 'ESTIMATE'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ACCENT DIVIDER ───────────────────────────────────────────
  Widget _buildAccentDivider(Color accentColor) {
    return Container(
      height: 1,
      width: double.infinity,
      color: SilverStockColors.borderLight,
    );
  }

  // ── INVOICE ROW: Icon + Batch ID + Date/Time ─────────────────
  Widget _buildInvoiceRow(
      AddStockController ctrl, bool isGst, Color accentColor) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        final invoiceBlock = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Receipt icon box
            _buildIconBox(accentColor),
            const SizedBox(width: 14),

            // Batch ID block
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  SilverStockStrings.systemInvoiceId.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: SilverStockColors.textMuted,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ctrl.batchCode,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: accentColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        );

        final dateTimeBlock = StreamBuilder<DateCardModel>(
          stream: _dateLogic.timeStream,
          initialData: _dateLogic.initialData,
          builder: (_, snap) => _buildDateTimeRow(snap.data!),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              invoiceBlock,
              const SizedBox(height: 12),
              dateTimeBlock,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            invoiceBlock,
            // Vertical rule
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: 1,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      SilverStockColors.borderLight,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            dateTimeBlock,
          ],
        );
      },
    );
  }

  // ── INVOICE ICON BOX ─────────────────────────────────────────
  Widget _buildIconBox(Color accentColor) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Stack(
        children: [
          // Top shine line
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accentColor.withOpacity(0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.receipt_long_outlined,
              color: accentColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ── DATE + TIME CHIPS ────────────────────────────────────────
  Widget _buildDateTimeRow(DateCardModel data) {
    // Format: "12 : 30 PM" clean display
    final timeParts = data.time.split(':');
    final cleanTime =
        timeParts.length >= 2 ? '${timeParts[0]} : ${timeParts[1]}' : data.time;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChip(
          icon: Icons.calendar_today_rounded,
          iconColor: SilverStockColors.textDark,
          subLabel: 'DATE',
          value: data.date.toUpperCase(),
          valueColor: SilverStockColors.textDark,
          valueFontSize: 13,
          chipBg: SilverStockColors.inputBg,
          chipBorder: SilverStockColors.borderLight,
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: SilverStockColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        _buildChip(
          icon: Icons.access_time_rounded,
          iconColor: SilverStockColors.success,
          subLabel: 'TIME',
          value: cleanTime,
          valueColor: SilverStockColors.success,
          valueFontSize: 14,
          chipBg: SilverStockColors.success.withOpacity(0.07),
          chipBorder: SilverStockColors.success.withOpacity(0.25),
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required Color iconColor,
    required String subLabel,
    required String value,
    required Color valueColor,
    required double valueFontSize,
    required Color chipBg,
    required Color chipBorder,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subLabel,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: iconColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: valueColor,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SUPPLIER INVOICE INPUT ───────────────────────────────────
  Widget _buildSupplierInvoiceSection(
      AddStockController ctrl, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label row
        Row(
          children: [
            Icon(
              SilverStockIcons.invoiceSupplier,
              size: 14,
              color: SilverStockColors.textMuted,
            ),
            const SizedBox(width: 7),
            Text(
              SilverStockStrings.supplierInvoiceId.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: SilverStockColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SilverStockColors.inputBgLocked,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SilverStockColors.borderLight),
              ),
              child: Text(
                'OPTIONAL',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: SilverStockColors.textHint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input field
        SizedBox(
          height: 48,
          child: TextField(
            controller: ctrl.supplierInvoiceCtrl,
            style: SilverStockStyles.inputText,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g.  INV-2025-0042  or  SI/24-25/001',
              hintStyle: SilverStockStyles.fieldHint,
              prefixIcon: Icon(
                SilverStockIcons.invoiceSystem,
                size: 18,
                color: SilverStockColors.textMuted,
              ),
              filled: true,
              fillColor: SilverStockColors.inputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: SilverStockColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: SilverStockColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Compliance note
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: SilverStockColors.textHint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Enter your supplier\'s invoice reference for B2B GST traceability. '
                'Stored against this batch and available in Purchase records.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.55,
                  color: SilverStockColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── ACCENT LINE HELPER ───────────────────────────────────────
  Widget _accentLine(double width, Color color, double opacity) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
