import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../models/live_rates/live_rates_model.dart';
import '../../logic/dashboard/live_rates/live_rates_logic.dart';
import '../../theme/dashboard/live_rates/live_rates_theme.dart';

// ============================================================
// ðŸ’Ž LIVE RATES CARD
// Dashboard mein "Sales Analytics Coming Soon" ke jagah lagega.
// Gold + Silver rates with shimmer, animations, expand/collapse.
// ============================================================

class LiveRatesCard extends StatefulWidget {
  const LiveRatesCard({super.key});

  @override
  State<LiveRatesCard> createState() => _LiveRatesCardState();
}

class _LiveRatesCardState extends State<LiveRatesCard>
    with TickerProviderStateMixin {
  late final LiveRatesLogic _logic;

  // Expand/Collapse animation
  late final AnimationController _expandController;
  late final Animation<double> _expandAnim;

  // Pulse animation for live indicator dot
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Shimmer for price text on load
  late final AnimationController _shimmerController;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _logic = LiveRatesLogic();
    _logic.init();

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _logic.dispose();
    _expandController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _logic.toggleExpand();
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveRatesModel>(
      stream: _logic.ratesStream,
      initialData: _logic.initialData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _logic.initialData;
        final isLoading = data.gold24k == '--';

        return Container(
          decoration: LiveRatesStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildHeader(data, isLoading),

              // â”€â”€ ALWAYS VISIBLE: MAIN RATES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _buildMainRatesRow(data, isLoading),
              ),

              const SizedBox(height: 12),

              // â”€â”€ SHOW MORE / LESS TOGGLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildToggleButton(),

              // â”€â”€ EXPANDABLE SECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SizeTransition(
                sizeFactor: _expandAnim,
                axisAlignment: -1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildExpandedContent(data, isLoading),
                ),
              ),

              // â”€â”€ FOOTER: TIMESTAMP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (!_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _buildTimestamp(data),
                ),
            ],
          ),
        );
      },
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HEADER
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader(LiveRatesModel data, bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        gradient: LiveRatesColors.headerGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(
              color: LiveRatesColors.goldMain.withValues(alpha: 0.2),
              width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Gold icon with glow
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveRatesColors.goldBg,
              border: Border.all(
                  color: LiveRatesColors.goldMain.withValues(alpha: 0.4),
                  width: 1),
              boxShadow: [
                BoxShadow(
                  color: LiveRatesColors.goldMain.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.show_chart_rounded,
                  color: LiveRatesColors.goldMain, size: 18),
            ),
          ),
          const SizedBox(width: 10),

          // Title with gold gradient
          ShaderMask(
            shaderCallback: (bounds) =>
                LiveRatesColors.goldGradient.createShader(bounds),
            child: const Text(
              LiveRatesStrings.cardTitle,
              style: LiveRatesStyles.cardTitleStyle,
            ),
          ),

          const Spacer(),

          // Demo badge (DB mein data nahi hai tab)
          if (!data.isFromDb && !isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: LiveRatesColors.demoBadgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: LiveRatesColors.demoBadgeText.withValues(alpha: 0.4),
                    width: 0.5),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: LiveRatesColors.demoBadgeText,
                  letterSpacing: 1.5,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Pulsing live dot
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LiveRatesColors.upGreen
                        .withValues(alpha: _pulseAnim.value),
                    boxShadow: [
                      BoxShadow(
                        color: LiveRatesColors.upGreen
                            .withValues(alpha: _pulseAnim.value * 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: LiveRatesColors.upGreen
                        .withValues(alpha: _pulseAnim.value),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // MAIN RATES ROW: Gold + Divider + Silver
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMainRatesRow(LiveRatesModel data, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GOLD SECTION
          Expanded(child: _buildMetalSection(data, isLoading, isGold: true)),

          // Vertical Divider
          Container(
            width: 1,
            height: 130,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  LiveRatesColors.goldMain.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // SILVER SECTION
          Expanded(child: _buildMetalSection(data, isLoading, isGold: false)),
        ],
      ),
    );
  }

  Widget _buildMetalSection(LiveRatesModel data, bool isLoading,
      {required bool isGold}) {
    final mainRate = isGold ? data.gold24k : data.silverRateKg;
    final changePercent =
        isGold ? data.goldChangePercent : data.silverChangePercent;
    final isUp = isGold ? data.goldIsUp : data.silverIsUp;
    final color =
        isGold ? LiveRatesColors.goldMain : LiveRatesColors.silverMain;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: LiveRatesStyles.sectionDecoration(isGold: isGold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label + icon
          Row(
            children: [
              Icon(
                isGold ? Icons.circle : Icons.circle_outlined,
                size: 8,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                isGold
                    ? LiveRatesStrings.goldRatesLabel
                    : LiveRatesStrings.silverRatesLabel,
                style: LiveRatesStyles.sectionLabelStyle.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metal name + change badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGold
                    ? LiveRatesStrings.goldTitle
                    : LiveRatesStrings.silverTitle,
                style: LiveRatesStyles.metalTitleStyle.copyWith(color: color),
              ),
              _buildChangeBadge(changePercent, isUp, isLoading),
            ],
          ),
          const SizedBox(height: 8),

          // Big Price
          isLoading
              ? _buildShimmer(width: 110, height: 30)
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: ShaderMask(
                    key: ValueKey(mainRate),
                    shaderCallback: (bounds) =>
                        LiveRatesColors.goldGradient.createShader(bounds),
                    child: Text(
                      'â‚¹ $mainRate',
                      style: LiveRatesStyles.bigPriceStyle
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
          const SizedBox(height: 2),

          // Unit
          Text(
            isGold ? LiveRatesStrings.perTenGm : LiveRatesStrings.perKg,
            style: LiveRatesStyles.unitStyle,
          ),

          const SizedBox(height: 10),

          // Sub rates
          isGold
              ? _buildSubRateRow(LiveRatesStrings.kt22, data.gold22k, isLoading)
              : _buildSubRateRow(
                  LiveRatesStrings.jewellery, data.silverJewellery, isLoading),
          const SizedBox(height: 4),
          isGold
              ? _buildSubRateRow(LiveRatesStrings.kt18, data.gold18k, isLoading)
              : _buildSubRateRow(
                  LiveRatesStrings.idols, data.silverIdols, isLoading),
        ],
      ),
    );
  }

  Widget _buildSubRateRow(String label, String value, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LiveRatesColors.goldMain.withValues(alpha: 0.6))),
            const SizedBox(width: 5),
            Text(label, style: LiveRatesStyles.subLabelStyle),
          ],
        ),
        isLoading
            ? _buildShimmer(width: 60, height: 12)
            : Text('â‚¹ $value', style: LiveRatesStyles.subPriceStyle),
      ],
    );
  }

  Widget _buildChangeBadge(String percent, bool isUp, bool isLoading) {
    if (isLoading) return _buildShimmer(width: 50, height: 20);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isUp ? LiveRatesColors.upGreenBg : LiveRatesColors.downRedBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isUp
              ? LiveRatesColors.upGreen.withValues(alpha: 0.3)
              : LiveRatesColors.downRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: isUp ? LiveRatesColors.upGreen : LiveRatesColors.downRed,
          ),
          const SizedBox(width: 2),
          Text(
            percent,
            style: LiveRatesStyles.changeStyle.copyWith(
              color: isUp ? LiveRatesColors.upGreen : LiveRatesColors.downRed,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TOGGLE BUTTON
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: LiveRatesColors.goldMain.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: LiveRatesColors.goldMain.withValues(alpha: 0.2),
              width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded
                  ? LiveRatesStrings.showLess
                  : LiveRatesStrings.showMore,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LiveRatesColors.goldMain,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: LiveRatesColors.goldMain),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // EXPANDED CONTENT: Old Gold + Price Tracker + Market Analysis
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildExpandedContent(LiveRatesModel data, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // OLD GOLD PURCHASE RATES
        _buildOldGoldSection(data, isLoading),
        const SizedBox(height: 16),

        // PRICE TRACKER TABLE
        _buildPriceTrackerSection(data, isLoading),
        const SizedBox(height: 16),

        // FOOTER TIMESTAMP (expanded state mein)
        _buildTimestamp(data),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // OLD GOLD PURCHASE RATES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildOldGoldSection(LiveRatesModel data, bool isLoading) {
    return Container(
      decoration: LiveRatesStyles.expandedSectionDecoration,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LiveRatesColors.headerGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: LiveRatesColors.goldMain, size: 16),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) =>
                      LiveRatesColors.goldGradient.createShader(b),
                  child: const Text(
                    LiveRatesStrings.purchaseHeader,
                    style: LiveRatesStyles.trackerHeaderStyle,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gold Buy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LiveRatesStrings.goldBuyLabel,
                        style: LiveRatesStyles.metalTitleStyle
                            .copyWith(color: LiveRatesColors.goldMain),
                      ),
                      const SizedBox(height: 8),
                      _buildOldRateRow(LiveRatesStrings.buy24k,
                          data.oldGold24kBuy, isLoading),
                      const SizedBox(height: 4),
                      _buildOldRateRow(LiveRatesStrings.buy22k,
                          data.oldGold22kBuy, isLoading),
                      const SizedBox(height: 4),
                      _buildOldRateRow(LiveRatesStrings.buy18k,
                          data.oldGold18kBuy, isLoading),
                    ],
                  ),
                ),

                // Thin divider
                Container(
                  width: 1,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: LiveRatesColors.divider,
                ),

                // Silver Buy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LiveRatesStrings.silverBuyLabel,
                        style: LiveRatesStyles.metalTitleStyle
                            .copyWith(color: LiveRatesColors.silverMain),
                      ),
                      const SizedBox(height: 8),
                      _buildOldRateRow(LiveRatesStrings.silverBuyRate,
                          data.oldSilverBuy, isLoading),
                      const SizedBox(height: 4),
                      _buildOldRateRow(
                          LiveRatesStrings.idols, data.silverIdols, isLoading),
                      const SizedBox(height: 4),
                      _buildOldRateRow(LiveRatesStrings.jewellery,
                          data.silverJewellery, isLoading),
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

  Widget _buildOldRateRow(String label, String value, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: LiveRatesStyles.subLabelStyle),
        isLoading
            ? _buildShimmer(width: 65, height: 12)
            : Text('â‚¹ $value',
                style: LiveRatesStyles.subPriceStyle
                    .copyWith(color: LiveRatesColors.goldText)),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PRICE TRACKER TABLE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPriceTrackerSection(LiveRatesModel data, bool isLoading) {
    // Last 5 days static labels (will be dynamic in future)
    final days = _getLast5Days();

    return Container(
      decoration: LiveRatesStyles.expandedSectionDecoration,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LiveRatesColors.headerGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timeline_rounded,
                    color: LiveRatesColors.goldMain, size: 16),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) =>
                      LiveRatesColors.goldGradient.createShader(b),
                  child: const Text(
                    LiveRatesStrings.priceTrackerHeader,
                    style: LiveRatesStyles.trackerHeaderStyle,
                  ),
                ),
              ],
            ),
          ),

          // Table
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header row
                _buildTrackerHeaderRow(days),
                const SizedBox(height: 6),

                // Gold row
                _buildTrackerDataRow(
                  isGold: true,
                  currentRate: data.gold24k,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 4),

                // Silver row
                _buildTrackerDataRow(
                  isGold: false,
                  currentRate: data.silverRateKg,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerHeaderRow(List<String> days) {
    return Row(
      children: [
        // Label column
        const SizedBox(
          width: 55,
          child: Text('', style: LiveRatesStyles.subLabelStyle),
        ),
        // Day columns
        ...days.map((d) => Expanded(
              child: Center(
                child: Text(d,
                    style: LiveRatesStyles.subLabelStyle.copyWith(
                      fontSize: 10,
                      letterSpacing: 0,
                    )),
              ),
            )),
        // Today
        SizedBox(
          width: 70,
          child: Center(
            child: Text(
              'Today',
              style: LiveRatesStyles.subLabelStyle.copyWith(
                fontSize: 10,
                color: LiveRatesColors.goldMain,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerDataRow({
    required bool isGold,
    required String currentRate,
    required bool isLoading,
  }) {
    // Demo historical prices (static â€” future mein DB se aayega)
    final List<String> demoGold = [
      '71,000',
      '71,300',
      '72,400',
      '72,400',
      '74,000'
    ];
    final List<String> demoSilver = [
      '38,000',
      '37,700',
      '38,000',
      '38,100',
      '38,100'
    ];
    final historicalRates = isGold ? demoGold : demoSilver;
    final color =
        isGold ? LiveRatesColors.goldMain : LiveRatesColors.silverMain;
    final label = isGold ? 'GOLD' : 'SILVER';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isGold
            ? LiveRatesColors.goldBg.withValues(alpha: 0.5)
            : LiveRatesColors.silverBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 55,
            child: Text(
              label,
              style: LiveRatesStyles.metalTitleStyle
                  .copyWith(fontSize: 11, color: color),
            ),
          ),

          // Historical
          ...historicalRates.map((rate) => Expanded(
                child: Center(
                  child: Text(
                    'â‚¹$rate',
                    style: const TextStyle(
                      fontSize: 10,
                      color: LiveRatesColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )),

          // Today (highlighted)
          SizedBox(
            width: 70,
            child: Center(
              child: isLoading
                  ? _buildShimmer(width: 55, height: 12)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: color.withValues(alpha: 0.4), width: 0.5),
                      ),
                      child: Text(
                        'â‚¹$currentRate',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TIMESTAMP FOOTER
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTimestamp(LiveRatesModel data) {
    final formatted =
        DateFormat('MMM dd, yyyy â€“ hh:mm a').format(data.rateDate);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 11, color: LiveRatesColors.textMuted),
            const SizedBox(width: 4),
            Text(
              '${LiveRatesStrings.lastUpdated}: $formatted',
              style: LiveRatesStyles.timestampStyle,
            ),
          ],
        ),
        if (!data.isFromDb)
          GestureDetector(
            onTap: () {
              // Future: Settings route pe navigate karo
            },
            child: const Text(
              LiveRatesStrings.setRatesTip,
              style: TextStyle(
                fontSize: 10,
                color: LiveRatesColors.goldMain,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: LiveRatesColors.goldMain,
              ),
            ),
          ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HELPERS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<String> _getLast5Days() {
    final now = DateTime.now();
    final format = DateFormat('d MMM');
    return List.generate(
        5, (i) => format.format(now.subtract(Duration(days: 5 - i))));
  }

  Widget _buildShimmer({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: LiveRatesColors.shimmerBase,
      highlightColor: LiveRatesColors.shimmerHighlight,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: LiveRatesColors.shimmerBase,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// AMBIENT GLOW BACKGROUND (Reusable)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class LiveRatesAmbientGlow extends StatelessWidget {
  const LiveRatesAmbientGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -30,
          right: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LiveRatesColors.goldGlow,
              boxShadow: [
                BoxShadow(
                    color: LiveRatesColors.goldGlow,
                    blurRadius: 60,
                    spreadRadius: 20),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: -10,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LiveRatesColors.silverGlow,
              boxShadow: [
                BoxShadow(
                    color: LiveRatesColors.silverGlow,
                    blurRadius: 40,
                    spreadRadius: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
