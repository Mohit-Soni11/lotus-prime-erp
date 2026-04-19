import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; 
import '../../theme/dashboard/bill_card/bill_card_theme.dart'; 
import '../../logic/dashboard/bill_card/bill_card_logic.dart';
import '../../logic/dashboard/bill_card/bill_card_strings.dart';
import '../../models/dashboard/bill_stats_model.dart'; 

class BillGeneratedCard extends StatefulWidget {
  const BillGeneratedCard({super.key});

  @override
  State<BillGeneratedCard> createState() => _BillGeneratedCardState();
}

class _BillGeneratedCardState extends State<BillGeneratedCard> {
  // ✅ Instance based logic
  late final BillCardLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = BillCardLogic(); // Fresh Instance
    _logic.init(); 
  }

  @override
  void dispose() {
    _logic.dispose(); // Widget marne par logic bhi clean -> No Memory Leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BillStatsModel>(
      stream: _logic.statsStream,
      initialData: _logic.initialData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _logic.initialData;
        final bool isLoading = data.count == "--";

        return Container(
          height: BillCardStyles.cardHeight, 
          decoration: BillCardStyles.premiumCardDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BillCardStyles.borderRadius),
            child: Stack(
              children: [
                // 🔥 PERFORMANCE FIX: RepaintBoundary prevents background redraws
                const Positioned.fill(
                  child: RepaintBoundary(child: _AmbientGlows())
                ),

                Padding(
                  padding: BillCardStyles.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => BillCardColors.goldTextGradient.createShader(bounds),
                            child: const Text(
                              BillCardStrings.title,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700, 
                                color: Colors.white, 
                                fontFamily: 'Roboto',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildGlassIconBox(),
                        ],
                      ),

                      const Spacer(),

                      // --- BIG NUMBER ---
                      isLoading 
                        ? _buildShimmerBlock(width: 80, height: 40)
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            switchInCurve: Curves.elasticOut, // Thoda bounce effect
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Text(
                              data.count,
                              key: ValueKey<String>(data.count),
                              style: BillCardStyles.countStyle,
                            ),
                          ),

                      const Spacer(),

                      // --- FOOTER ---
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 14),
                          ),
                          const SizedBox(width: 8),
                          
                          const Text(BillCardStrings.subTitlePrefix, style: BillCardStyles.subLabelStyle),
                          const SizedBox(width: 4),
                          
                          Expanded(
                            child: isLoading
                              ? _buildShimmerBlock(width: 100, height: 14)
                              : Text(
                                  data.totalRevenue,
                                  style: BillCardStyles.subStyle.copyWith(
                                    color: Colors.white,
                                    shadows: [Shadow(color: Colors.black45, blurRadius: 2)]
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                          ),
                        ],
                      ),
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

  // ... (Baaki functions same hain, no change needed there)
  Widget _buildGlassIconBox() {
    return Container(
      width: BillCardStyles.iconBoxSize,
      height: BillCardStyles.iconBoxSize,
      decoration: BillCardStyles.iconBoxDecoration,
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [BillCardColors.accentGoldBright, BillCardColors.accentGold]).createShader(bounds),
          child: const Icon(BillCardIcons.billIcon, color: Colors.white, size: BillCardStyles.iconSize),
        ),
      ),
    );
  }

  Widget _buildShimmerBlock({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      period: const Duration(milliseconds: 1500),
      child: Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
    );
  }
}

// Background Glows
class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -50, right: -40,
          child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: BillCardColors.glowTopRight, boxShadow: [BoxShadow(color: BillCardColors.glowTopRight, blurRadius: 80, spreadRadius: 20)])),
        ),
        Positioned(
          bottom: -40, left: -30,
          child: Container(width: 120, height: 120, decoration: const BoxDecoration(shape: BoxShape.circle, color: BillCardColors.glowBottomLeft, boxShadow: [BoxShadow(color: BillCardColors.glowBottomLeft, blurRadius: 60, spreadRadius: 10)])),
        ),
      ],
    );
  }
}