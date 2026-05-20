import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/dashboard/customer_card/customer_card_theme.dart';
import '../../logic/dashboard/customer_card/customer_card_logic.dart';
import '../../../models/dashboard/customer_stats_model.dart';

class NewCustomerCard extends StatefulWidget {
  const NewCustomerCard({super.key});

  @override
  State<NewCustomerCard> createState() => _NewCustomerCardState();
}

class _NewCustomerCardState extends State<NewCustomerCard> {
  // Logic Instance (Lifecycle Managed)
  late final CustomerCardLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = CustomerCardLogic(); // Fresh Instance
    _logic.init();
  }

  @override
  void dispose() {
    _logic.dispose(); // Cleanup zaroori hai
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CustomerStatsModel>(
      stream: _logic.statsStream,
      initialData: _logic.initialData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _logic.initialData;
        final bool isLoading = data.count == "--";

        // Dynamic Colors based on Growth
        final Color accentColor = data.isHighGrowth
            ? NewCustomerColors.iconGrowth
            : NewCustomerColors.iconDefault;

        final Color glowColor = data.isHighGrowth
            ? NewCustomerColors.glowGrowth
            : NewCustomerColors.glowDefault;

        return Container(
          height: NewCustomerStyles.cardHeight,
          decoration: NewCustomerStyles.premiumCardDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(NewCustomerStyles.borderRadius),
            child: Stack(
              children: [
                // ðŸ”¥ FIXED: Added missing bottom-left glow for depth
                Positioned.fill(child: _AmbientGlows(color: glowColor)),

                Padding(
                  padding: NewCustomerStyles.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: ShaderMask(
                              shaderCallback: (bounds) => NewCustomerColors
                                  .goldTextGradient
                                  .createShader(bounds),
                              child: const Text(
                                "New Registrations",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          _buildGlassIconBox(accentColor),
                        ],
                      ),

                      // --- BIG NUMBER (Animated) ---
                      isLoading
                          ? _buildShimmerBlock(width: 80, height: 40)
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              switchInCurve: Curves.elasticOut,
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Text(
                                data.count,
                                key: ValueKey<String>(data.count),
                                style: NewCustomerStyles.valueStyle,
                              ),
                            ),

                      // --- FOOTER ---
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: Icon(
                                data.isHighGrowth
                                    ? Icons.trending_up_rounded
                                    : Icons.horizontal_rule_rounded,
                                color: accentColor,
                                size: 14),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              data.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NewCustomerStyles.subtextStyle.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ),
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

  Widget _buildGlassIconBox(Color iconColor) {
    return Container(
      width: NewCustomerStyles.iconBoxSize,
      height: NewCustomerStyles.iconBoxSize,
      decoration: NewCustomerStyles.iconBoxDecoration,
      child: Center(
        child: Icon(NewCustomerIcons.customerIcon,
            color: iconColor, size: NewCustomerStyles.iconSize),
      ),
    );
  }

  Widget _buildShimmerBlock({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1500),
      child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(6))),
    );
  }
}

class _AmbientGlows extends StatelessWidget {
  final Color color;
  const _AmbientGlows({required this.color});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Top Right Glow
          Positioned(
            top: -50,
            right: -40,
            child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: 80, spreadRadius: 5)
                    ])),
          ),

          // 2. âœ… FIXED: Bottom Left Glow Bubble (Added)
          // Ye text ke peeche subtle shine dega
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: 60, spreadRadius: 10)
                    ])),
          ),
        ],
      ),
    );
  }
}
