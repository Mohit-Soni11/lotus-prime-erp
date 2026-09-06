import 'package:flutter/material.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';

class BookingActionButtons extends StatelessWidget {
  const BookingActionButtons({
    super.key,
    required this.controller,
    required this.onSaved,
  });

  final BookingAdvanceController controller;
  final void Function(String message, bool isSuccess) onSaved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          InkWell(
            onTap: controller.isSaving ? null : () => _handleSave(),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: controller.isSaving
                  ? BoxDecoration(
                      color:
                          BookingAdvanceColors.brandGold.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : BookingAdvanceStyles.saveButton,
              child: Center(
                child: controller.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            BookingAdvanceIcons.saveBooking,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            controller.isEditMode
                                ? 'UPDATE BOOKING'
                                : BookingAdvanceStrings.btnSaveBooking,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (!controller.isEditMode) ...[
            const SizedBox(height: 10),
            _HoverOutlineButton(
              label: BookingAdvanceStrings.btnClearAll,
              icon: BookingAdvanceIcons.clearAll,
              onTap: controller.clearAll,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final result = await controller.saveBooking();
    onSaved(result.message, result.success);
  }
}

class _HoverOutlineButton extends StatefulWidget {
  const _HoverOutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_HoverOutlineButton> createState() => _HoverOutlineButtonState();
}

class _HoverOutlineButtonState extends State<_HoverOutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 48,
          decoration: BoxDecoration(
            color: _hovered
                ? BookingAdvanceColors.bodyPanelBg
                : BookingAdvanceColors.bodyBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? BookingAdvanceColors.danger.withValues(alpha: 0.5)
                  : BookingAdvanceColors.bodyBorder,
              width: _hovered ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: _hovered
                      ? BookingAdvanceColors.danger
                      : BookingAdvanceColors.bodyTextMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _hovered
                        ? BookingAdvanceColors.danger
                        : BookingAdvanceColors.bodyTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
