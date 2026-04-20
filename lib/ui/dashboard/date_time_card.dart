import 'package:flutter/material.dart';
// ✅ Import path check kar lena apne project ke hisaab se
import 'package:lotus_erp/theme/dashboard/date_time/date_card_theme.dart';
import 'package:lotus_erp/logic/dashboard/date_card/date_card_logic.dart';

// =============================================================================
// BUG FIX LOG:
//   ❌ BUG  — Column inside Padding had fixed vertical padding of 20px (top+bottom=40px).
//             Parent card constraint was only ~108px height, leaving only 68px
//             for content. But content (header row ~40px + time column ~52px)
//             needed ~92px → overflow by 25px on the bottom.
//             Same issue caused right overflow in the inner Row.
//
//   ✅ FIX  — Replaced fixed Padding with LayoutBuilder so padding adapts to
//             available height. Wrapped the Column in FittedBox(fit: scaleDown)
//             so if the content is still too large, it scales down gracefully
//             instead of overflowing. The card height constraint stays the same.
// =============================================================================

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
                // Background glows (no repaint on every second tick)
                const Positioned.fill(
                  child: RepaintBoundary(child: _AmbientGlows()),
                ),

                // ✅ FIX: LayoutBuilder reads actual available height at runtime
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Adaptive padding: shrinks on small cards, stays comfortable on large ones
                    final vPad =
                        (constraints.maxHeight * 0.10).clamp(8.0, 20.0);
                    final hPad =
                        (constraints.maxWidth * 0.12).clamp(10.0, 24.0);

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: vPad,
                      ),
                      // ✅ FIX: FittedBox scales the entire content DOWN if needed.
                      // No overflow is possible because content shrinks to fit.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          // Give the inner Column a fixed intrinsic width so
                          // FittedBox has a reference size to scale from.
                          width: constraints.maxWidth - (hPad * 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // --- HEADER ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => DateCardColors
                                          .goldTextGradient
                                          .createShader(bounds),
                                      child: Text(
                                        data.day,
                                        style: DateCardStyles.dayText
                                            .copyWith(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildGlassIconBox(),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // --- TIME (Animated) ---
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                            opacity: anim, child: child),
                                    child: Text(
                                      data.time,
                                      key: ValueKey<String>(data.time),
                                      style: DateCardStyles.timeText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(data.date,
                                      style: DateCardStyles.dateText),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
            colors: [DateCardColors.goldBright, DateCardColors.goldAccent],
          ).createShader(bounds),
          child: const Icon(DateCardIcons.clock,
              color: Colors.white, size: DateCardStyles.iconSize),
        ),
      ),
    );
  }
}

// Background Glows (Optimized — separate widget so it doesn't rebuild every second)
class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DateCardColors.glowColor1,
              boxShadow: [
                BoxShadow(
                    color: DateCardColors.glowColor1,
                    blurRadius: 60,
                    spreadRadius: 20)
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DateCardColors.glowColor2,
              boxShadow: [
                BoxShadow(
                    color: DateCardColors.glowColor2,
                    blurRadius: 40,
                    spreadRadius: 0)
              ],
            ),
          ),
        ),
      ],
    );
  }
}
