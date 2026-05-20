import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../../theme/settings/shop_setup/layout/layout_theme.dart';
import '../../../../../../models/setting/shop_setup/shop_step_model.dart';
import 'stepper_indicator.dart';

class SetupHeader extends StatefulWidget {
  final String title;
  final String subTitle;
  final List<ShopStepModel> steps;
  final int currentStep;
  final VoidCallback onBack;
  final Function(int) onJumpToStep;

  const SetupHeader({
    super.key,
    required this.title,
    required this.subTitle,
    required this.steps,
    required this.currentStep,
    required this.onBack,
    required this.onJumpToStep,
  });

  @override
  State<SetupHeader> createState() => _SetupHeaderState();
}

class _SetupHeaderState extends State<SetupHeader>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: double.infinity,
          height: LayoutStyles.headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            // Navy Blue tint for Glass
            color: LayoutColors.panelBg.withValues(alpha: 0.85),
            border: const Border(
              bottom: BorderSide(color: LayoutColors.borderStroke, width: 1),
            ),
          ),
          child: Row(
            children: [
              // ------------------------------------
              // 1ï¸âƒ£ LEFT: BACK + TITLE
              // ------------------------------------
              _buildNavyBackButton(),
              const SizedBox(width: 24),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SHOP CONFIGURATION", // âœ… Fixed Name
                    style: LayoutStyles.headerTitle,
                  ),
                  const SizedBox(height: 6),

                  // ðŸ”¥ THE RADAR PULSE WIDGET
                  const RadarStatusWidget(),
                ],
              ),

              const Spacer(),

              // ------------------------------------
              // 2ï¸âƒ£ RIGHT: STEPPER
              // ------------------------------------
              SizedBox(
                height: 50,
                child: StepperIndicator(
                  steps: widget.steps,
                  currentStep: widget.currentStep,
                  onStepTap: widget.onJumpToStep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavyBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(10),
        hoverColor: LayoutColors.goldPrimary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: LayoutColors.borderStroke),
            borderRadius: BorderRadius.circular(10),
            color: LayoutColors.scaffoldBg.withValues(alpha: 0.5),
          ),
          child: const Icon(LayoutIcons.backArrow,
              color: LayoutColors.textTitle, size: 18),
        ),
      ),
    );
  }
}

// ðŸ”¥ðŸ”¥ ADVANCED RADAR ANIMATION WIDGET ðŸ”¥ðŸ”¥
// Isko alag class banaya taaki performance best rahe
class RadarStatusWidget extends StatefulWidget {
  const RadarStatusWidget({super.key});

  @override
  State<RadarStatusWidget> createState() => _RadarStatusWidgetState();
}

class _RadarStatusWidgetState extends State<RadarStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Smooth 3 sec ripple
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ðŸ“¡ The Radar Visual
        SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wave 1 (Badi wali)
              _buildWave(delay: 0.0, size: 16),
              // Wave 2 (Choti wali)
              _buildWave(delay: 0.5, size: 16),

              // Core Solid Dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: LayoutColors.success, // Emerald Green
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: LayoutColors.success,
                          blurRadius: 6,
                          spreadRadius: 1)
                    ]),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Text
        const Text(
          "SYSTEM ONLINE",
          style: TextStyle(
            color: LayoutColors.success,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildWave({required double delay, required double size}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Animation Loop logic: 0.0 -> 1.0
        final double currentVal = (_controller.value + delay) % 1.0;
        final double scale = 1.0 + (currentVal * 1.5); // Grows 1.5x
        final double opacity = 1.0 - currentVal; // Fades out

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: LayoutColors.success.withValues(alpha: 0.5),
                    width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
