import 'package:flutter/material.dart';
// ✅ Import path check kar lena apne project ke hisaab se
import 'package:lotus_erp/theme/dashboard/date_time/date_card_theme.dart';
import 'package:lotus_erp/logic/dashboard/date_card/date_card_logic.dart';

class DateAndTimeCard extends StatefulWidget {
  const DateAndTimeCard({super.key});

  @override
  State<DateAndTimeCard> createState() => _DateAndTimeCardState();
}

class _DateAndTimeCardState extends State<DateAndTimeCard> {
  late final DateCardLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = DateCardLogic();
    _logic.init();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateCardModel>(
      stream: _logic.timeStream,
      initialData: _logic.initialData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? DateCardModel.empty();

        return Container(
          height: DateCardStyles.cardHeight,
          decoration: DateCardStyles.premiumCardDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DateCardStyles.borderRadius),
            child: Stack(
              children: [
                // 🔥 OPTIMIZATION: RepaintBoundary prevents background redraws every second
                const Positioned.fill(
                  child: RepaintBoundary(child: _AmbientGlows()),
                ),

                Padding(
                  padding: DateCardStyles.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Matches BillCard alignment
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ✅ FIX: Flexible wrap kiya taaki text overflow na ho
                          Flexible(
                            child: ShaderMask(
                              shaderCallback: (bounds) => DateCardColors.goldTextGradient.createShader(bounds),
                              child: Text(
                                data.day,
                                style: DateCardStyles.dayText.copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildGlassIconBox(),
                        ],
                      ),
                      
                      // --- TIME (Animated) ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animation for smooth second ticks
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                            child: Text(
                              data.time,
                              key: ValueKey<String>(data.time), // Key change triggers animation
                              style: DateCardStyles.timeText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(data.date, style: DateCardStyles.dateText),
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

  Widget _buildGlassIconBox() {
    return Container(
      width: DateCardStyles.iconBoxSize,
      height: DateCardStyles.iconBoxSize,
      decoration: DateCardStyles.iconBoxDecoration,
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [DateCardColors.goldBright, DateCardColors.goldAccent]
          ).createShader(bounds),
          child: const Icon(DateCardIcons.clock, color: Colors.white, size: DateCardStyles.iconSize),
        ),
      ),
    );
  }
}

// Background Glows (Optimized)
class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -40, right: -40,
          child: Container(
            width: 150, height: 150, 
            decoration: const BoxDecoration(
              shape: BoxShape.circle, 
              color: DateCardColors.glowColor1, 
              boxShadow: [BoxShadow(color: DateCardColors.glowColor1, blurRadius: 60, spreadRadius: 20)]
            )
          ),
        ),
        Positioned(
          bottom: -20, left: -20,
          child: Container(
            width: 100, height: 100, 
            decoration: const BoxDecoration(
              shape: BoxShape.circle, 
              color: DateCardColors.glowColor2, 
              boxShadow: [BoxShadow(color: DateCardColors.glowColor2, blurRadius: 40, spreadRadius: 0)]
            )
          ),
        ),
      ],
    );
  }
}