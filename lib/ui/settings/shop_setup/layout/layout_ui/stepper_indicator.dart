import 'package:flutter/material.dart';
import '../../../../../../theme/settings/shop_setup/layout/layout_theme.dart';
import '../../../../../../models/setting/shop_setup/shop_step_model.dart';

class StepperIndicator extends StatelessWidget {
  final List<ShopStepModel> steps;
  final int currentStep;
  final Function(int) onStepTap;

  const StepperIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: steps.length,
      separatorBuilder: (context, index) => const SizedBox(width: 32), // More spacing
      itemBuilder: (context, index) {
        return _buildStepTab(steps[index]);
      },
    );
  }

  Widget _buildStepTab(ShopStepModel step) {
    bool isActive = step.id == currentStep;
    bool isCompleted = step.id < currentStep;

    return InkWell(
      onTap: () => onStepTap(step.id),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: LayoutStyles.stepTitle.copyWith(
              // ✅ Updated: Uses 'textPlaceholder' instead of 'textDisabled'
              color: isActive 
                  ? LayoutColors.textTitle 
                  : (isCompleted ? LayoutColors.textBody : LayoutColors.textPlaceholder),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(step.title),
          ),
          
          const SizedBox(height: 8),
          
          // The Magic Gold Bar (Indicator)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            height: 2,
            width: isActive ? 20 : 0, // Grows when active
            decoration: BoxDecoration(
              // ✅ Updated: Uses 'goldPrimary'
              color: LayoutColors.goldPrimary, 
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive ? [
                // ✅ Updated: Gold Glow
                BoxShadow(color: LayoutColors.goldPrimary.withOpacity(0.6), blurRadius: 8)
              ] : [],
            ),
          ),
        ],
      ),
    );
  }
}