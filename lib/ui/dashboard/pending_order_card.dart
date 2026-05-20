import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/dashboard/pending_order/pending_order_card_theme.dart';
import '../../logic/dashboard/pending_card/pending_order_logic.dart';
import '../../models/dashboard/pending_stats_model.dart';

class PendingOrdersCard extends StatefulWidget {
  const PendingOrdersCard({super.key});

  @override
  State<PendingOrdersCard> createState() => _PendingOrdersCardState();
}

class _PendingOrdersCardState extends State<PendingOrdersCard>
    with SingleTickerProviderStateMixin {
  late final PendingOrderLogic _logic;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _logic = PendingOrderLogic();
    _logic.init();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logic.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PendingStatsModel>(
      stream: _logic.statsStream,
      initialData: _logic.initialData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _logic.initialData;
        final bool isLoading = data.totalCount == "--";

        return Container(
          height: PendingOrderStyles.cardHeight,
          decoration: PendingOrderStyles.premiumCardDecoration,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(PendingOrderStyles.borderRadius),
            child: Stack(
              children: [
                // ðŸ”¥ GLOWS: Controlled & Alive
                const Positioned.fill(child: _AmbientGlows()),

                Padding(
                  padding: PendingOrderStyles.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: ShaderMask(
                              shaderCallback: (bounds) => PendingOrderColors
                                  .orangeTextGradient
                                  .createShader(bounds),
                              child: const Text("Pending Orders",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Roboto',
                                      letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildGlassIconBox(),
                        ],
                      ),
                      const Spacer(),
                      isLoading
                          ? _buildShimmerBlock(width: 80, height: 40)
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              switchInCurve: Curves.elasticOut,
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Text(data.totalCount,
                                  key: ValueKey<String>(data.totalCount),
                                  style: PendingOrderStyles.valueStyle),
                            ),
                      const Spacer(),
                      Row(
                        children: [
                          _buildBlinkingDot(PendingOrderColors.goldStats),
                          const SizedBox(width: 6),
                          _buildMetalStat("Gold", data.goldCount),
                          const SizedBox(width: 24),
                          _buildBlinkingDot(PendingOrderColors.silverStats),
                          const SizedBox(width: 6),
                          _buildMetalStat("Silver", data.silverCount),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helpers
  Widget _buildMetalStat(String label, String count) => Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text("$label: ",
                style: PendingOrderStyles.subtextStyle
                    .copyWith(color: Colors.white54, fontSize: 12)),
            Text(count,
                style: PendingOrderStyles.subtextStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14))
          ]);
  Widget _buildBlinkingDot(Color color) => FadeTransition(
      opacity: _blinkController,
      child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 6,
                    spreadRadius: 1)
              ])));
  Widget _buildGlassIconBox() => Container(
      width: PendingOrderStyles.iconBoxSize,
      height: PendingOrderStyles.iconBoxSize,
      decoration: PendingOrderStyles.iconBoxDecoration,
      child: const Center(
          child: Icon(PendingOrderIcons.pendingIcon,
              color: PendingOrderColors.accentColor,
              size: PendingOrderStyles.iconSize)));
  Widget _buildShimmerBlock({required double width, required double height}) =>
      Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.3),
          period: const Duration(milliseconds: 1500),
          child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6))));
}

class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();
  @override
  Widget build(BuildContext context) {
    // âœ… Controlled Opacity for Pop without Burn
    final Color glowColor =
        PendingOrderColors.accentGlow.withValues(alpha: 0.4);
    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned(
              top: -60,
              right: -50,
              child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glowColor.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                            color: glowColor, blurRadius: 80, spreadRadius: 5)
                      ]))),
          Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glowColor.withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(
                            color: glowColor, blurRadius: 60, spreadRadius: 0)
                      ]))),
        ],
      ),
    );
  }
}
