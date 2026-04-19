// =============================================================================
// FILE        : cash_register_card.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : UI
// DESCRIPTION : Python "totals_card" ka Flutter premium version.
//
//               LAYOUT:
//               ┌──────────────────────────────────────────────┐
//               │ 🏧 CASH REGISTER    Today's Summary  [📋]    │
//               │ ────────────────────────────────────────────  │
//               │ Opening Balance                    ₹ 5,000   │
//               │ ┌──────────────────┐ ┌──────────────────┐   │
//               │ │ ↑ Received       │ │ ↓ Paid / Out     │   │
//               │ │ ₹ 44,000         │ │ ₹ 18,200         │   │
//               │ └──────────────────┘ └──────────────────┘   │
//               │ ┌──────────────────────────────────────────┐ │
//               │ │  Net Cash In Drawer        ₹25,800  ✓   │ │
//               │ └──────────────────────────────────────────┘ │
//               └──────────────────────────────────────────────┘
//
//               REPORT BUTTON (top right):
//               • Icon: receipt_long_rounded
//               • Click → dayBookRoute (future report page)
//
//               ANIMATIONS:
//               • Card slide + fade entry
//               • Each amount — AnimatedSwitcher on data change
//               • Footer — shimmer effect on loading
//               • Report button — scale on press
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../logic/dashboard/cash_register/cash_register_logic.dart';
import '../../models/dashboard/cash_register_model.dart';
import '../../theme/dashboard/cash_register/cash_register_theme.dart';
import '../../constants/app_routes.dart';

class CashRegisterCard extends StatefulWidget {
  final Function(String routeId) onNavigate;

  const CashRegisterCard({
    super.key,
    required this.onNavigate,
  });

  @override
  State<CashRegisterCard> createState() => _CashRegisterCardState();
}

class _CashRegisterCardState extends State<CashRegisterCard>
    with SingleTickerProviderStateMixin {

  late final CashRegisterLogic _logic;

  // Entry animation
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entrySlide;
  late final Animation<double>   _entryFade;

  // Report button press
  bool _reportPressed = false;

  @override
  void initState() {
    super.initState();
    _logic = CashRegisterLogic();
    _logic.init();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrySlide = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logic.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _entrySlide.value),
        child: Opacity(opacity: _entryFade.value, child: child),
      ),
      child: Container(
        decoration: CashRegisterStyles.cardDecoration,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(CashRegisterStyles.cardBorderRadius),
          child: Stack(children: [
            // Ambient glows
            const Positioned.fill(child: _AmbientGlows()),

            Padding(
              padding: CashRegisterStyles.cardPadding,
              child: StreamBuilder<CashRegisterModel>(
                stream: _logic.dataStream,
                initialData: _logic.initialData,
                builder: (context, snapshot) {
                  final data = snapshot.data ?? _logic.initialData;
                  if (data.isLoading) return _buildShimmer();
                  return _buildContent(data);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ==========================================
  // CONTENT
  // ==========================================
  Widget _buildContent(CashRegisterModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        // ── HEADER ──────────────────────────────────────────────────────
        _buildHeader(),

        const SizedBox(height: 6),

        // Gold divider line
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CashRegisterColors.accentGold.withOpacity(0.0),
                CashRegisterColors.accentGold.withOpacity(0.4),
                CashRegisterColors.accentGold.withOpacity(0.0),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── OPENING BALANCE ──────────────────────────────────────────────
        _buildOpeningBalance(data.openingBalanceStr),

        const SizedBox(height: 12),

        // ── RECEIVED + PAID BLOCKS ───────────────────────────────────────
        Row(children: [
          Expanded(child: _buildReceivedBlock(data.totalReceivedStr)),
          const SizedBox(width: 12),
          Expanded(child: _buildPaidBlock(data.totalPaidOutStr)),
        ]),

        const SizedBox(height: 16),

        // ── NET CASH FOOTER ──────────────────────────────────────────────
        _buildNetCashFooter(data.netCashDrawerStr),
      ],
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        // Gold icon box
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: CashRegisterColors.accentGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: CashRegisterColors.accentGold.withOpacity(0.25)),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (b) =>
                  CashRegisterColors.goldGradient.createShader(b),
              child: const Icon(CashRegisterIcons.header,
                  size: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Title + subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  CashRegisterColors.goldGradient.createShader(b),
              child: const Text('CASH REGISTER',
                  style: CashRegisterStyles.headerTitleStyle),
            ),
            const Text("Today's Summary",
                style: CashRegisterStyles.headerSubStyle),
          ],
        ),

        const Spacer(),

        // ✅ REPORT BUTTON — future report page ke liye
        GestureDetector(
          onTapDown: (_) => setState(() => _reportPressed = true),
          onTapCancel: () => setState(() => _reportPressed = false),
          onTapUp: (_) {
            setState(() => _reportPressed = false);
            widget.onNavigate(AppRoutes.dayBookRoute);
          },
          child: AnimatedScale(
            scale: _reportPressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Tooltip(
              message: 'View Day Book Report',
              child: Container(
                width: CashRegisterStyles.iconBtnSize,
                height: CashRegisterStyles.iconBtnSize,
                decoration: CashRegisterStyles.reportBtnDecoration,
                child: const Center(
                  child: Icon(
                    CashRegisterIcons.report,
                    size: 18,
                    color: CashRegisterColors.reportIconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── OPENING BALANCE ───────────────────────────────────────────────────────
  Widget _buildOpeningBalance(String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: CashRegisterStyles.openingDecoration,
      child: Row(
        children: [
          const Icon(CashRegisterIcons.opening,
              size: 16, color: CashRegisterColors.openingIcon),
          const SizedBox(width: 8),
          const Text('Opening Balance',
              style: CashRegisterStyles.openingLabelStyle),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              amount,
              key: ValueKey(amount),
              style: CashRegisterStyles.openingAmountStyle,
            ),
          ),
        ],
      ),
    );
  }

  // ── RECEIVED BLOCK ────────────────────────────────────────────────────────
  Widget _buildReceivedBlock(String amount) {
    return Container(
      padding: CashRegisterStyles.blockPadding,
      decoration: CashRegisterStyles.receivedDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(CashRegisterIcons.received,
                size: 14, color: CashRegisterColors.receivedAccent),
            const SizedBox(width: 5),
            const Text('Received',
              style: CashRegisterStyles.blockLabelStyle,
            ).withColor(CashRegisterColors.receivedAccent),
          ]),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              amount,
              key: ValueKey(amount),
              style: CashRegisterStyles.blockAmountStyle
                  .copyWith(color: CashRegisterColors.receivedText),
            ),
          ),
        ],
      ),
    );
  }

  // ── PAID BLOCK ────────────────────────────────────────────────────────────
  Widget _buildPaidBlock(String amount) {
    return Container(
      padding: CashRegisterStyles.blockPadding,
      decoration: CashRegisterStyles.paidDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(CashRegisterIcons.paid,
                size: 14, color: CashRegisterColors.paidAccent),
            const SizedBox(width: 5),
            const Text('Paid / Out',
              style: CashRegisterStyles.blockLabelStyle,
            ).withColor(CashRegisterColors.paidAccent),
          ]),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              amount,
              key: ValueKey(amount),
              style: CashRegisterStyles.blockAmountStyle
                  .copyWith(color: CashRegisterColors.paidText),
            ),
          ),
        ],
      ),
    );
  }

  // ── NET CASH FOOTER ───────────────────────────────────────────────────────
  Widget _buildNetCashFooter(String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: CashRegisterStyles.footerDecoration,
      child: Row(
        children: [
          // Label
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Net Cash In Drawer',
                  style: CashRegisterStyles.footerLabelStyle),
              Text('Closing Balance',
                  style: CashRegisterStyles.footerSubStyle),
            ],
          ),

          const Spacer(),

          // Amount + verified icon
          Row(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                amount,
                key: ValueKey(amount),
                style: CashRegisterStyles.footerAmountStyle,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CashRegisterIcons.net,
                size: 22, color: Color(0xFF1A2238)),
          ]),
        ],
      ),
    );
  }

  // ==========================================
  // SHIMMER
  // ==========================================
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: CashRegisterColors.shimmerBase,
      highlightColor: CashRegisterColors.shimmerHighlight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(children: [
            _sBox(36, 36, r: 10),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sBox(120, 12),
              const SizedBox(height: 4),
              _sBox(80, 10),
            ]),
            const Spacer(),
            _sBox(36, 36, r: 10),
          ]),
          const SizedBox(height: 20),
          _sBox(double.infinity, 46, r: 12),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _sBox(double.infinity, 70, r: 12)),
            const SizedBox(width: 12),
            Expanded(child: _sBox(double.infinity, 70, r: 12)),
          ]),
          const SizedBox(height: 16),
          _sBox(double.infinity, 58, r: 16),
        ],
      ),
    );
  }

  Widget _sBox(double w, double h, {double r = 6}) => Container(
    width: w == double.infinity ? null : w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// ── Extension for withColor ────────────────────────────────────────────────────
extension _TextExtension on Text {
  Text withColor(Color color) {
    return Text(
      data ?? '',
      key: key,
      style: (style ?? const TextStyle()).copyWith(color: color),
    );
  }
}

// ── Ambient Glows ─────────────────────────────────────────────────────────────
class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(children: [
        Positioned(
          top: -40, right: -30,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CashRegisterColors.accentGold.withOpacity(0.05),
              boxShadow: [BoxShadow(
                color: CashRegisterColors.accentGold.withOpacity(0.07),
                blurRadius: 70,
              )],
            ),
          ),
        ),
        Positioned(
          bottom: -20, left: -20,
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CashRegisterColors.receivedAccent.withOpacity(0.04),
              boxShadow: [BoxShadow(
                color: CashRegisterColors.receivedAccent.withOpacity(0.05),
                blurRadius: 50,
              )],
            ),
          ),
        ),
      ]),
    );
  }
}