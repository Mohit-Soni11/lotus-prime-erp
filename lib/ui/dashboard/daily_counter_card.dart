// =============================================================================
// FILE        : daily_counter_card.dart
// MODULE      : Dashboard / Daily Counter Activity
// LAYER       : UI
// DESCRIPTION : Aaj ka poora counter activity ek premium dark card mein.
//
//               LAYOUT:
//               ┌────────────────────────────────────────────────┐
//               │ 📊 DAILY COUNTER ACTIVITY      Dec 17, 2025    │
//               │ ─────────────────────────────────────────────  │
//               │  ┌────────────────────────┐ ┌───────────────┐  │
//               │  │  METAL MOVEMENT        │ │ FINANCE & DUE │  │
//               │  │  ┌────────┐ ┌────────┐ │ │ ┌───┐  ┌───┐ │  │
//               │  │  │ SOLD ✅│ │BOUGHT🛍│ │ │ │DUE│  │GRV│ │  │
//               │  │  │GOLD    │ │OLD GOLD│ │ │ │   │  │   │ │  │
//               │  │  │SILVER  │ │O.SILVER│ │ │ └───┘  └───┘ │  │
//               │  │  └────────┘ └────────┘ │ └───────────────┘  │
//               │  └────────────────────────┘                     │
//               └────────────────────────────────────────────────┘
//
//               ANIMATIONS:
//               • Card entry — slide + fade
//               • Group containers — staggered entry (100ms gap)
//               • Inner boxes — scale entry
//               • Amount — AnimatedSwitcher on data change
//               • Header gold shimmer effect
//               • Shimmer loading state
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../logic/dashboard/daily_counter/daily_counter_logic.dart';
import '../../models/dashboard/daily_counter_model.dart';
import '../../theme/dashboard/daily_counter/daily_counter_theme.dart';

class DailyCounterCard extends StatefulWidget {
  const DailyCounterCard({super.key});

  @override
  State<DailyCounterCard> createState() => _DailyCounterCardState();
}

class _DailyCounterCardState extends State<DailyCounterCard>
    with TickerProviderStateMixin {

  late final DailyCounterLogic _logic;

  // Card entry animation
  late final AnimationController _cardCtrl;
  late final Animation<double>   _cardSlide;
  late final Animation<double>   _cardFade;

  // Group staggered entry — 2 groups
  late final List<AnimationController> _groupCtrl;
  late final List<Animation<double>>   _groupScale;
  late final List<Animation<double>>   _groupFade;

  @override
  void initState() {
    super.initState();
    _logic = DailyCounterLogic();
    _logic.init();

    // Card entry
    _cardCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _cardSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));

    // Group staggered
    _groupCtrl = List.generate(2, (_) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450)));
    _groupScale = _groupCtrl.map((c) =>
      Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack))).toList();
    _groupFade = _groupCtrl.map((c) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    _playEntries();
  }

  Future<void> _playEntries() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _groupCtrl[0].forward();
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _groupCtrl[1].forward();
  }

  @override
  void dispose() {
    _logic.dispose();
    _cardCtrl.dispose();
    for (final c in _groupCtrl) c.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cardCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _cardSlide.value),
        child: Opacity(opacity: _cardFade.value, child: child),
      ),
      child: Container(
        decoration: DailyCounterStyles.cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DailyCounterStyles.cardBorderRadius),
          child: Stack(children: [
            // Ambient glows
            const Positioned.fill(child: _AmbientGlows()),

            Padding(
              padding: DailyCounterStyles.cardPadding,
              child: StreamBuilder<DailyCounterModel>(
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
  Widget _buildContent(DailyCounterModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── HEADER ───────────────────────────────────────────────────────
        _buildHeader(data.dateStr),

        const SizedBox(height: 6),

        // Divider with gold gradient
        ShaderMask(
          shaderCallback: (b) =>
              DailyCounterColors.goldGradient.createShader(b),
          child: Container(height: 1, color: Colors.white.withOpacity(0.3)),
        ),

        const SizedBox(height: 16),

        // ── TWO GROUP CONTAINERS ──────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              return Column(children: [
                _animatedGroup(0, _buildMetalMovementGroup(data.metalMovement)),
                const SizedBox(height: 12),
                _animatedGroup(1, _buildFinanceDueGroup(data.financeDue)),
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _animatedGroup(0, _buildMetalMovementGroup(data.metalMovement))),
                const SizedBox(width: 14),
                Expanded(child: _animatedGroup(1, _buildFinanceDueGroup(data.financeDue))),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(String dateStr) {
    return Row(
      children: [
        // Gold icon container
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: DailyCounterColors.accentGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DailyCounterColors.accentGold.withOpacity(0.25)),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (b) =>
                  DailyCounterColors.goldGradient.createShader(b),
              child: const Icon(DailyCounterIcons.header,
                size: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Title
        ShaderMask(
          shaderCallback: (b) =>
              DailyCounterColors.goldGradient.createShader(b),
          child: const Text('DAILY COUNTER ACTIVITY',
            style: DailyCounterStyles.headerStyle),
        ),

        const Spacer(),

        // Date badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(dateStr, style: DailyCounterStyles.dateStyle),
        ),
      ],
    );
  }

  // ── GROUP ANIMATION WRAPPER ───────────────────────────────────────────────
  Widget _animatedGroup(int i, Widget child) {
    return AnimatedBuilder(
      animation: _groupCtrl[i],
      builder: (_, c) => Transform.scale(
        scale: _groupScale[i].value,
        child: Opacity(opacity: _groupFade[i].value, child: c),
      ),
      child: child,
    );
  }

  // ==========================================
  // GROUP 1 — METAL MOVEMENT
  // ==========================================
  Widget _buildMetalMovementGroup(MetalMovementData data) {
    return Container(
      decoration: DailyCounterStyles.groupDecoration,
      padding: DailyCounterStyles.groupPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(children: [
            Icon(DailyCounterIcons.metalMovement,
              size: 14, color: DailyCounterColors.textMuted),
            const SizedBox(width: 6),
            const Text('METAL MOVEMENT (Today)',
              style: DailyCounterStyles.groupTitleStyle),
          ]),

          const SizedBox(height: 12),

          // Two inner boxes side by side
          Row(children: [
            Expanded(child: _buildSoldBox(data)),
            const SizedBox(width: 10),
            Expanded(child: _buildBoughtBox(data)),
          ]),
        ],
      ),
    );
  }

  // SOLD inner box
  Widget _buildSoldBox(MetalMovementData data) {
    return Container(
      padding: DailyCounterStyles.boxPadding,
      decoration: DailyCounterStyles.innerBox(DailyCounterColors.soldAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(children: [
            Container(
              width: DailyCounterStyles.iconBoxSize,
              height: DailyCounterStyles.iconBoxSize,
              decoration: DailyCounterStyles.iconBox(
                DailyCounterColors.soldIconBg,
                DailyCounterColors.soldAccent,
              ),
              child: Center(child: Icon(DailyCounterIcons.sold,
                size: DailyCounterStyles.iconSize,
                color: DailyCounterColors.soldAccent)),
            ),
            const SizedBox(width: 8),
            const Text('SOLD', style: DailyCounterStyles.boxTitleStyle),
          ]),

          const SizedBox(height: 10),

          // Divider
          Divider(height: 1,
            color: DailyCounterColors.soldAccent.withOpacity(0.25)),

          const SizedBox(height: 10),

          // Gold row
          _metalRow('GOLD',
            data.soldGold.weightStr, data.soldGold.piecesStr),

          const SizedBox(height: 8),

          // Silver row
          _metalRow('SILVER',
            data.soldSilver.weightStr, data.soldSilver.piecesStr),
        ],
      ),
    );
  }

  // BOUGHT inner box
  Widget _buildBoughtBox(MetalMovementData data) {
    return Container(
      padding: DailyCounterStyles.boxPadding,
      decoration: DailyCounterStyles.innerBox(DailyCounterColors.boughtAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(children: [
            Container(
              width: DailyCounterStyles.iconBoxSize,
              height: DailyCounterStyles.iconBoxSize,
              decoration: DailyCounterStyles.iconBox(
                DailyCounterColors.boughtIconBg,
                DailyCounterColors.boughtAccent,
              ),
              child: Center(child: Icon(DailyCounterIcons.bought,
                size: DailyCounterStyles.iconSize,
                color: DailyCounterColors.boughtAccent)),
            ),
            const SizedBox(width: 8),
            const Text('BOUGHT', style: DailyCounterStyles.boxTitleStyle),
          ]),

          const SizedBox(height: 10),

          Divider(height: 1,
            color: DailyCounterColors.boughtAccent.withOpacity(0.25)),

          const SizedBox(height: 10),

          _metalRow('OLD GOLD',
            data.boughtGold.weightStr, data.boughtGold.piecesStr),

          const SizedBox(height: 8),

          _metalRow('OLD SILVER',
            data.boughtSilver.weightStr, data.boughtSilver.piecesStr),
        ],
      ),
    );
  }

  // Metal row helper
  Widget _metalRow(String label, String weight, String pieces) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DailyCounterStyles.metalLabelStyle),
        const SizedBox(height: 3),
        Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(weight,
              key: ValueKey(weight),
              style: DailyCounterStyles.metalValueStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('|',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2), fontSize: 12)),
          ),
          Text(pieces, style: DailyCounterStyles.metalPiecesStyle),
        ]),
      ],
    );
  }

  // ==========================================
  // GROUP 2 — FINANCE & DUE
  // ==========================================
  Widget _buildFinanceDueGroup(FinanceDueData data) {
    return Container(
      decoration: DailyCounterStyles.groupDecoration,
      padding: DailyCounterStyles.groupPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(children: [
            Icon(DailyCounterIcons.financeDue,
              size: 14, color: DailyCounterColors.textMuted),
            const SizedBox(width: 6),
            const Text('FINANCE & DUE (Today)',
              style: DailyCounterStyles.groupTitleStyle),
          ]),

          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: _buildDueBox(data)),
            const SizedBox(width: 10),
            Expanded(child: _buildGirviBox(data)),
          ]),
        ],
      ),
    );
  }

  // DUE inner box
  Widget _buildDueBox(FinanceDueData data) {
    return Container(
      padding: DailyCounterStyles.boxPadding,
      decoration: DailyCounterStyles.innerBox(DailyCounterColors.dueAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(children: [
            Container(
              width: DailyCounterStyles.iconBoxSize,
              height: DailyCounterStyles.iconBoxSize,
              decoration: DailyCounterStyles.iconBox(
                DailyCounterColors.dueIconBg,
                DailyCounterColors.dueAccent,
              ),
              child: Center(child: Icon(DailyCounterIcons.due,
                size: DailyCounterStyles.iconSize,
                color: DailyCounterColors.dueAccent)),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('NEW DUE',
                style: DailyCounterStyles.boxTitleStyle,
                overflow: TextOverflow.ellipsis)),
          ]),

          const SizedBox(height: 10),

          Divider(height: 1,
            color: DailyCounterColors.dueAccent.withOpacity(0.25)),

          const SizedBox(height: 10),

          // Count row with big icon
          Row(children: [
            Icon(DailyCounterIcons.duePeople,
              size: DailyCounterStyles.bigIconSize,
              color: DailyCounterColors.dueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(data.dueCount,
                      key: ValueKey(data.dueCount),
                      style: DailyCounterStyles.bigCountStyle),
                  ),
                  const Text('Active', style: DailyCounterStyles.subLabelStyle),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // Amount pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: DailyCounterStyles.amountPill(
              DailyCounterColors.dueAccent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(DailyCounterIcons.rupee,
                  size: 14, color: DailyCounterColors.dueAccent),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(data.dueAmount,
                    key: ValueKey(data.dueAmount),
                    style: DailyCounterStyles.amountStyle(
                      DailyCounterColors.dueAccent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GIRVI inner box
  Widget _buildGirviBox(FinanceDueData data) {
    return Container(
      padding: DailyCounterStyles.boxPadding,
      decoration: DailyCounterStyles.innerBox(DailyCounterColors.girviAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: DailyCounterStyles.iconBoxSize,
              height: DailyCounterStyles.iconBoxSize,
              decoration: DailyCounterStyles.iconBox(
                DailyCounterColors.girviIconBg,
                DailyCounterColors.girviAccent,
              ),
              child: Center(child: Icon(DailyCounterIcons.girvi,
                size: DailyCounterStyles.iconSize,
                color: DailyCounterColors.girviAccent)),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('GIRVI',
                style: DailyCounterStyles.boxTitleStyle,
                overflow: TextOverflow.ellipsis)),
          ]),

          const SizedBox(height: 10),

          Divider(height: 1,
            color: DailyCounterColors.girviAccent.withOpacity(0.25)),

          const SizedBox(height: 10),

          Row(children: [
            Icon(DailyCounterIcons.girviWallet,
              size: DailyCounterStyles.bigIconSize,
              color: DailyCounterColors.girviAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(data.girviCount,
                      key: ValueKey(data.girviCount),
                      style: DailyCounterStyles.bigCountStyle),
                  ),
                  const Text('Disbursed',
                    style: DailyCounterStyles.subLabelStyle),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: DailyCounterStyles.amountPill(
              DailyCounterColors.girviAccent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(DailyCounterIcons.rupee,
                  size: 14, color: DailyCounterColors.girviAccent),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(data.girviAmount,
                    key: ValueKey(data.girviAmount),
                    style: DailyCounterStyles.amountStyle(
                      DailyCounterColors.girviAccent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHIMMER
  // ==========================================
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: DailyCounterColors.shimmerBase,
      highlightColor: DailyCounterColors.shimmerHighlight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header shimmer
          Row(children: [
            _sBox(36, 36, r: 10),
            const SizedBox(width: 10),
            _sBox(200, 14),
            const Spacer(),
            _sBox(90, 26, r: 20),
          ]),
          const SizedBox(height: 20),
          // Two group shimmers
          Row(children: [
            Expanded(child: _sBox(double.infinity, 160, r: 16)),
            const SizedBox(width: 14),
            Expanded(child: _sBox(double.infinity, 160, r: 16)),
          ]),
        ],
      ),
    );
  }

  Widget _sBox(double w, double h, {double r = 6}) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
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
            width: 150, height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DailyCounterColors.accentGold.withOpacity(0.04),
              boxShadow: [BoxShadow(
                color: DailyCounterColors.accentGold.withOpacity(0.06),
                blurRadius: 70, spreadRadius: 10)],
            ),
          ),
        ),
        Positioned(
          bottom: -20, left: -20,
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DailyCounterColors.soldAccent.withOpacity(0.03),
              boxShadow: [BoxShadow(
                color: DailyCounterColors.soldAccent.withOpacity(0.05),
                blurRadius: 50, spreadRadius: 5)],
            ),
          ),
        ),
      ]),
    );
  }
}