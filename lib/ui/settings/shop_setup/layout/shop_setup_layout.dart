import 'package:flutter/material.dart';

// --- IMPORTS ---
import '../../../../theme/settings/shop_setup/layout/layout_theme.dart';
import '../../../../models/setting/shop_setup/shop_step_model.dart';
import '../layout/layout_ui/setup_header.dart';
import '../layout/layout_ui/setup_footer.dart';

class ShopSetupLayout extends StatelessWidget {
  // --- DATA INPUTS ---
  final Widget child;
  final List<ShopStepModel> steps;
  final int currentStep;

  // --- ACTIONS ---
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Function(int) onJumpToStep; // 🔥 Added: Jump Parameter
  final bool isLoading;

  const ShopSetupLayout({
    super.key,
    required this.child,
    required this.steps,
    required this.currentStep,
    required this.onBack,
    required this.onNext,
    required this.onJumpToStep, // 🔥 Added: Constructor me required
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeStepData =
        steps.firstWhere((s) => s.id == currentStep, orElse: () => steps[0]);

    return Scaffold(
      backgroundColor: LayoutColors.scaffoldBg,
      body: Column(
        children: [
          // 1. FIXED HEADER
          SetupHeader(
            title: activeStepData.title,
            subTitle: activeStepData.subTitle,
            steps: steps,
            currentStep: currentStep,
            onBack: onBack,
            onJumpToStep: onJumpToStep, // 🔥 Added: Header ko pass kiya
          ),

          // 2. SCROLLABLE BODY
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 50),
                    child: child,
                  ),
                ),
              ],
            ),
          ),

          // 3. FIXED FOOTER
          SetupFooter(
            onNext: onNext,
            isLoading: isLoading,
            isLastStep: currentStep == steps.length,
          ),
        ],
      ),
    );
  }
}
