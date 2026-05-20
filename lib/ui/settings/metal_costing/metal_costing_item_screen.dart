// =============================================================================
// FILE        : lib/ui/settings/metal_costing/metal_costing_item_screen.dart
// MODULE      : Metal Costing Analysis
// LAYER       : UI / Presentation
// DESCRIPTION : Level 3 â€” Item wise P&L list for one metal + purity.
//               Expandable cards: 3 prices + breakdown + 2 profits.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/settings/metal_costing/metal_costing_theme.dart';
import '../../../models/setting/metal_costing/metal_costing_model.dart';
import 'metal_costing_app_bar.dart';
import 'metal_costing_hub_screen.dart';

class MetalCostingItemScreen extends StatelessWidget {
  final MetalCardMeta metalMeta;
  final PuritySummary puritySummary;

  const MetalCostingItemScreen({
    super.key,
    required this.metalMeta,
    required this.puritySummary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MetalCostingColors.bodyBg,
      appBar: MetalCostingAppBar(
        screenTitle:
            '${metalMeta.label.toUpperCase()} Â· ${puritySummary.purity}',
        screenSubtitle: MetalCostingStrings.itemWisePL,
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: MetalCostingStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Text(
                '${MetalCostingStrings.itemWisePL.toUpperCase()} Â· '
                '${MetalCostingStrings.tapToExpand.toUpperCase()}',
                style: MetalCostingStyles.sectionLabel,
              ),
              const SizedBox(height: 16),
              ...puritySummary.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ItemCard(
                    item: item,
                    accent: metalMeta.accent,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ITEM CARD â€” Expandable
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ItemCard extends StatefulWidget {
  final MetalCostingItem item;
  final Color accent;

  const _ItemCard({required this.item, required this.accent});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotate = Tween<double>(begin: 0, end: 0.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  String _fmt(double v) => 'â‚¹${v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+\d$)'),
        (m) => '${m[1]},',
      )}';

  String _fmtRate(double r) => 'â‚¹${r.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+\d$)'),
        (m) => '${m[1]},',
      )}';

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final profit1 = item.profit1;
    final isProfit1Pos = (profit1 ?? 0) >= 0;

    return Container(
      decoration: BoxDecoration(
        color: MetalCostingColors.cardBg,
        borderRadius: BorderRadius.circular(MetalCostingStyles.rCard),
        border: Border.all(color: MetalCostingColors.cardBorder, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: MetalCostingColors.shadowSubtle,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MetalCostingStyles.rCard),
        child: Column(
          children: [
            // â”€â”€ Header Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.itemName,
                              style: MetalCostingStyles.itemName),
                          const SizedBox(height: 3),
                          Text(
                            '${item.sku} Â· ${item.netWeight}g Â· '
                            'Tanch ${item.wastage.toStringAsFixed(1)}% Â· '
                            '${DateFormat('d MMM y').format(item.purchaseDate)}',
                            style: MetalCostingStyles.itemMeta,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Profit badge / In Stock badge
                    if (item.isSold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isProfit1Pos
                              ? MetalCostingColors.profitGreenBg
                              : MetalCostingColors.lossRedBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isProfit1Pos
                                ? MetalCostingColors.profitGreenBorder
                                : MetalCostingColors.lossRedBorder,
                          ),
                        ),
                        child: Text(
                          '${isProfit1Pos ? "+" : "âˆ’"}${_fmt(profit1!)}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isProfit1Pos
                                ? MetalCostingColors.profitGreen
                                : MetalCostingColors.lossRed,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: widget.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'In Stock',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.accent,
                          ),
                        ),
                      ),
                    if (item.hasReplacementLoss)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(MetalCostingIcons.warningIcon,
                            size: 18, color: MetalCostingColors.warning),
                      ),
                    const SizedBox(width: 8),
                    RotationTransition(
                      turns: _rotate,
                      child: const Icon(MetalCostingIcons.expandArrow,
                          size: 20, color: MetalCostingColors.textHint),
                    ),
                  ],
                ),
              ),
            ),

            // â”€â”€ Expanded Detail â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_open) ...[
              const Divider(color: MetalCostingColors.divider, height: 1),
              Container(
                color: MetalCostingColors.inputBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3 Price Boxes
                    _sectionLabel('3 PRICE COMPARISON'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _PriceBox(
                            label: MetalCostingStrings.purchaseCostLabel,
                            labelColor: const Color(0xFF185FA5),
                            amount: _fmt(item.purchaseCost),
                            amountColor: const Color(0xFF042C53),
                            sub: 'Rate: ${_fmtRate(item.purchaseRate / 100)}/g',
                            bg: const Color(0xFFE6F1FB),
                            border: const Color(0xFFB5D4F4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PriceBox(
                            label: MetalCostingStrings.currentValueLabel,
                            labelColor: MetalCostingColors.goldBrand,
                            amount: _fmt(item.currentValue),
                            amountColor: const Color(0xFF412402),
                            sub: 'Rate: ${_fmtRate(item.todayRate / 100)}/g',
                            bg: MetalCostingColors.goldCard,
                            border: MetalCostingColors.goldBrandBorder,
                            badge: item.rateWentUp
                                ? 'â–² +${_fmt(item.rateMoveAmount)}'
                                : 'â–¼ âˆ’${_fmt(item.rateMoveAmount)}',
                            badgeColor: item.rateWentUp
                                ? MetalCostingColors.profitGreen
                                : MetalCostingColors.lossRed,
                            badgeBg: item.rateWentUp
                                ? MetalCostingColors.profitGreenBg
                                : MetalCostingColors.lossRedBg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: item.isSold
                              ? _PriceBox(
                                  label: MetalCostingStrings.soldAtLabel,
                                  labelColor: MetalCostingColors.profitGreen,
                                  amount: _fmt(item.soldPrice!),
                                  amountColor: const Color(0xFF04342C),
                                  sub: item.soldDate != null
                                      ? DateFormat('d MMM y')
                                          .format(item.soldDate!)
                                      : '',
                                  bg: MetalCostingColors.profitGreenBg,
                                  border: MetalCostingColors.profitGreenBorder,
                                )
                              : const _PriceBox(
                                  label: MetalCostingStrings.notSoldLabel,
                                  labelColor: MetalCostingColors.textHint,
                                  amount: 'â€”',
                                  amountColor: MetalCostingColors.textMuted,
                                  sub: 'In stock',
                                  bg: MetalCostingColors.inputBg,
                                  border: MetalCostingColors.cardBorder,
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Calculation Breakdown
                    _sectionLabel(MetalCostingStrings.purchaseBreakdown),
                    const SizedBox(height: 8),
                    _CalcCard(
                      children: [
                        _CalcRow(
                          label: '${MetalCostingStrings.rateDiv100}  '
                              '(${_fmtRate(item.purchaseRate)} Ã· 100)',
                          val: '${_fmtRate(item.purchaseRate / 100)}/g',
                        ),
                        _CalcRow(
                            label: MetalCostingStrings.timesWeight,
                            val: '${item.netWeight}g'),
                        _CalcRow(
                            label: MetalCostingStrings.timesTanch,
                            val: '${item.wastage}%'),
                        _CalcRow(
                            label: MetalCostingStrings.fineMetalCost,
                            val: _fmt(item.fineMetalCostAtPurchase)),
                        if (item.makingCharge > 0)
                          _CalcRow(
                            label: '${MetalCostingStrings.makingCharge}  '
                                '(â‚¹${item.makingCharge.toStringAsFixed(0)} Ã— ${item.netWeight}g)',
                            val: _fmt(item.makingAmount),
                          ),
                        _CalcRow(
                          label: MetalCostingStrings.totalPurchaseCost,
                          val: _fmt(item.purchaseCost),
                          isTotal: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Current Value breakdown
                    _CalcCard(
                      header: '${MetalCostingStrings.currentBreakdown}  '
                          '${MetalCostingStrings.currentNote}',
                      children: [
                        _CalcRow(
                          label: 'Aaj ka rate Ã· 100  '
                              '(${_fmtRate(item.todayRate)} Ã· 100)',
                          val: '${_fmtRate(item.todayRate / 100)}/g',
                        ),
                        _CalcRow(
                            label: MetalCostingStrings.timesWeight,
                            val: '${item.netWeight}g'),
                        _CalcRow(
                            label: MetalCostingStrings.timesTanch,
                            val: '${item.wastage}%'),
                        _CalcRow(
                          label: MetalCostingStrings.currentMetalValue,
                          val: _fmt(item.currentValue),
                          isTotal: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Profit Analysis (sold only)
                    if (item.isSold) ...[
                      _sectionLabel(MetalCostingStrings.profitAnalysis),
                      const SizedBox(height: 8),

                      // Profit 1
                      const _ProfitNote(
                        label: MetalCostingStrings.profit1Label,
                        note: MetalCostingStrings.profit1Note,
                      ),
                      const SizedBox(height: 5),
                      _ProfitBadge(
                        title: profit1! >= 0
                            ? MetalCostingStrings.actualProfit
                            : MetalCostingStrings.actualLoss,
                        amount: profit1,
                        positive: profit1 >= 0,
                        note: 'Aapne ${_fmtRate(item.purchaseRate / 100)}/g '
                            'pe kharida tha â€” us waqt ka actual faayda.',
                      ),

                      const SizedBox(height: 10),

                      // Profit 2
                      const _ProfitNote(
                        label: MetalCostingStrings.profit2Label,
                        note: MetalCostingStrings.profit2Note,
                      ),
                      const SizedBox(height: 5),
                      _ProfitBadge(
                        title: item.hasReplacementLoss
                            ? MetalCostingStrings.replLoss
                            : MetalCostingStrings.replProfit,
                        amount: item.profit2!,
                        positive: !item.hasReplacementLoss,
                        isWarn: item.hasReplacementLoss,
                        note: item.hasReplacementLoss
                            ? MetalCostingStrings.replacementWarn
                            : 'Aaj same item lete to ${_fmt(item.currentValue)} '
                                'lagta â€” phir bhi ${_fmt(item.profit2!)} profit hota.',
                      ),
                    ] else ...[
                      // Unsold: rate movement
                      _sectionLabel(MetalCostingStrings.rateMovement),
                      const SizedBox(height: 8),
                      _ProfitBadge(
                        title: item.rateWentUp
                            ? MetalCostingStrings.metalGain
                            : MetalCostingStrings.metalLoss,
                        amount: item.rateMoveAmount,
                        positive: item.rateWentUp,
                        note: MetalCostingStrings.rateMoveSub,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: MetalCostingStyles.sectionLabel),
      );
}

// â”€â”€ Price Box â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PriceBox extends StatelessWidget {
  final String label, amount, sub;
  final Color labelColor, amountColor, bg, border;
  final String? badge;
  final Color? badgeColor, badgeBg;

  const _PriceBox({
    required this.label,
    required this.labelColor,
    required this.amount,
    required this.amountColor,
    required this.sub,
    required this.bg,
    required this.border,
    this.badge,
    this.badgeColor,
    this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MetalCostingStyles.rInner),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: labelColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (badge != null) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge!,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// â”€â”€ Calc Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CalcCard extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const _CalcCard({this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: MetalCostingStyles.calcBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Text(
              header!,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: MetalCostingColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
          ],
          ...children,
        ],
      ),
    );
  }
}

// â”€â”€ Calc Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CalcRow extends StatelessWidget {
  final String label, val;
  final bool isTotal;

  const _CalcRow(
      {required this.label, required this.val, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isTotal ? 6 : 2, bottom: 2),
      child: Column(
        children: [
          if (isTotal)
            const Divider(
                color: MetalCostingColors.divider, height: 1, thickness: 0.5),
          if (isTotal) const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: isTotal
                      ? GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: MetalCostingColors.profitGreen,
                        )
                      : MetalCostingStyles.calcRow,
                ),
              ),
              Text(
                val,
                style: isTotal
                    ? GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: MetalCostingColors.profitGreen,
                      )
                    : GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: MetalCostingColors.textBody,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Profit Note â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProfitNote extends StatelessWidget {
  final String label, note;
  const _ProfitNote({required this.label, required this.note});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.inter(
            fontSize: 10, color: MetalCostingColors.textMuted),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: MetalCostingColors.textBody),
          ),
          TextSpan(text: '  Â·  $note'),
        ],
      ),
    );
  }
}

// â”€â”€ Profit Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProfitBadge extends StatelessWidget {
  final String title;
  final double amount;
  final bool positive;
  final bool isWarn;
  final String? note;

  const _ProfitBadge({
    required this.title,
    required this.amount,
    required this.positive,
    this.isWarn = false,
    this.note,
  });

  String _fmt(double v) => 'â‚¹${v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+\d$)'),
        (m) => '${m[1]},',
      )}';

  @override
  Widget build(BuildContext context) {
    final bg = isWarn
        ? MetalCostingColors.warnAmberBg
        : positive
            ? MetalCostingColors.profitGreenBg
            : MetalCostingColors.lossRedBg;
    final border = isWarn
        ? MetalCostingColors.warnAmberBorder
        : positive
            ? MetalCostingColors.profitGreenBorder
            : MetalCostingColors.lossRedBorder;
    final color = isWarn
        ? MetalCostingColors.warnAmberText
        : positive
            ? MetalCostingColors.profitGreen
            : MetalCostingColors.lossRed;
    final icon = isWarn
        ? 'âš ï¸ '
        : positive
            ? 'â–² '
            : 'â–¼ ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MetalCostingStyles.rInner),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '$icon${_fmt(amount)}',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 5),
            Text(
              note!,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isWarn
                    ? const Color(0xFF856404)
                    : MetalCostingColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
