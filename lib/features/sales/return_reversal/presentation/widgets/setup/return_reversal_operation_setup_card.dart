import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/theme/return_reversal_design_tokens.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

class ReturnReversalOperationSetupCard extends StatelessWidget {
  final ReturnReversalController controller;

  const ReturnReversalOperationSetupCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final selectedType = controller.state.operationType;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SetupHeader(
              compact: compact,
              selectedType: selectedType,
            ),
            Container(
              height: 1,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: ReturnReversalDesignTokens.border,
            ),
            _OperationTabs(
              selectedType: selectedType,
              compact: compact,
              onChanged: controller.selectOperationType,
            ),
          ],
        );

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: compact ? double.infinity : 460,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: ReturnReversalDesignTokens.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ReturnReversalDesignTokens.border),
              boxShadow: const [
                BoxShadow(
                  color: PurchaseEntryColors.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: PurchaseEntryColors.shadowDark,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: content,
          ),
        );
      },
    );
  }
}

class _SetupHeader extends StatelessWidget {
  final bool compact;
  final ReturnReversalOperationType selectedType;

  const _SetupHeader({
    required this.compact,
    required this.selectedType,
  });

  String get _title {
    return selectedType == ReturnReversalOperationType.salesReturn
        ? 'RETURN SETUP'
        : 'CANCELLATION SETUP';
  }

  String get _subtitle {
    return selectedType == ReturnReversalOperationType.salesReturn
        ? 'Sales return and purchase return'
        : 'Booking cancellation only';
  }

  @override
  Widget build(BuildContext context) {
    final titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _accentLine(20, 1),
            const SizedBox(height: 3),
            _accentLine(13, 0.45),
            const SizedBox(height: 3),
            _accentLine(7, 0.18),
          ],
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PurchaseEntryStyles.highVisHeader,
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: ReturnReversalDesignTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          const _ReadinessBadge(),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        const _ReadinessBadge(),
      ],
    );
  }

  Widget _accentLine(double width, double opacity) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: ReturnReversalDesignTokens.accent.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ReadinessBadge extends StatelessWidget {
  const _ReadinessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ReturnReversalDesignTokens.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReturnReversalDesignTokens.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ReturnReversalDesignTokens.accent,
            ),
            child: SizedBox(width: 6, height: 6),
          ),
          SizedBox(width: 6),
          Text(
            'DESK READY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: ReturnReversalDesignTokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationTabs extends StatelessWidget {
  final ReturnReversalOperationType selectedType;
  final bool compact;
  final ValueChanged<ReturnReversalOperationType> onChanged;

  const _OperationTabs({
    required this.selectedType,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final returnTab = _OperationTab(
      type: ReturnReversalOperationType.salesReturn,
      title: 'RETURN',
      subtitle: 'Sales + Purchase',
      selected: selectedType == ReturnReversalOperationType.salesReturn,
      expanded: compact,
      onTap: () => onChanged(ReturnReversalOperationType.salesReturn),
    );
    final cancellationTab = _OperationTab(
      type: ReturnReversalOperationType.bookingCancellation,
      title: 'CANCELLATION',
      subtitle: 'Booking only',
      selected: selectedType == ReturnReversalOperationType.bookingCancellation,
      expanded: compact,
      onTap: () => onChanged(ReturnReversalOperationType.bookingCancellation),
    );

    return Container(
      height: compact ? null : 70,
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ReturnReversalDesignTokens.background.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ReturnReversalDesignTokens.border.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: PurchaseEntryColors.shadowLight.withValues(alpha: 0.75),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                returnTab,
                const SizedBox(height: 6),
                cancellationTab,
              ],
            )
          : Row(
              children: [
                Expanded(child: returnTab),
                const SizedBox(width: 6),
                Expanded(child: cancellationTab),
              ],
            ),
    );
  }
}

class _OperationTab extends StatefulWidget {
  final ReturnReversalOperationType type;
  final String title;
  final String subtitle;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _OperationTab({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_OperationTab> createState() => _OperationTabState();
}

class _OperationTabState extends State<_OperationTab> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final emphasized = active || _hovered;
    final accent = _accentColor;
    final foreground = active
        ? widget.type == ReturnReversalOperationType.bookingCancellation
            ? ReturnReversalDesignTokens.textPrimary
            : Colors.white
        : ReturnReversalDesignTokens.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: ReturnReversalDesignTokens.motionFast,
              curve: Curves.easeOutCubic,
              width: widget.expanded ? double.infinity : null,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.92),
                          accent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active
                    ? null
                    : _hovered
                        ? accent.withValues(alpha: 0.08)
                        : ReturnReversalDesignTokens.panel,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active
                      ? accent
                      : emphasized
                          ? accent.withValues(alpha: 0.38)
                          : ReturnReversalDesignTokens.border
                              .withValues(alpha: 0.18),
                ),
                boxShadow: emphasized
                    ? [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: active ? 0.28 : 0.12,
                          ),
                          blurRadius: active ? 10 : 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: ReturnReversalDesignTokens.motionFast,
                    width: active ? 8 : 6,
                    height: active ? 8 : 6,
                    decoration: BoxDecoration(
                      color:
                          active ? foreground : accent.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: foreground.withValues(alpha: 0.42),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active
                                ? foreground.withValues(alpha: 0.86)
                                : ReturnReversalDesignTokens.textPrimary
                                    .withValues(alpha: 0.78),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _accentColor {
    return widget.type == ReturnReversalOperationType.bookingCancellation
        ? SalesPosColors.brandGold
        : ReturnReversalDesignTokens.accent;
  }
}
