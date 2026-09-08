import 'package:flutter/material.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';

class BookingActionButtons extends StatelessWidget {
  const BookingActionButtons({
    super.key,
    required this.controller,
    required this.onSaved,
    required this.onGenerateInvoice,
  });

  final BookingAdvanceController controller;
  final void Function(String message, bool isSuccess) onSaved;
  final void Function(List<int> orderIds) onGenerateInvoice;

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
          const SizedBox(height: 10),
          _SecondaryBookingActionButton(
            label: BookingAdvanceStrings.btnGenerateInvoice,
            icon: BookingAdvanceIcons.generateInvoice,
            enabled: !controller.isSaving,
            onTap: _handleGenerateInvoice,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final result = await controller.saveBooking();
    onSaved(result.message, result.success);
  }

  Future<void> _handleGenerateInvoice() async {
    final result = await controller.saveBooking();
    onSaved(result.message, result.success);
    if (result.success && result.orderIds.isNotEmpty) {
      onGenerateInvoice(result.orderIds);
    }
  }
}

class _SecondaryBookingActionButton extends StatefulWidget {
  const _SecondaryBookingActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final Future<void> Function() onTap;

  @override
  State<_SecondaryBookingActionButton> createState() =>
      _SecondaryBookingActionButtonState();
}

class _SecondaryBookingActionButtonState
    extends State<_SecondaryBookingActionButton> {
  bool _hovered = false;
  bool _isWorking = false;

  Future<void> _handleTap() async {
    if (!widget.enabled || _isWorking) return;
    setState(() => _isWorking = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !_isWorking;
    final color = active
        ? BookingAdvanceColors.brandGold
        : BookingAdvanceColors.bodyTextMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: active ? _handleTap : null,
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
              color: active
                  ? color.withValues(alpha: _hovered ? 0.70 : 0.42)
                  : BookingAdvanceColors.bodyBorder,
              width: active ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: _isWorking
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2.3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: color,
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
