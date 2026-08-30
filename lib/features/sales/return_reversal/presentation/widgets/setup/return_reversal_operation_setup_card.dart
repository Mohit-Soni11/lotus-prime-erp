import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/theme/return_reversal_design_tokens.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

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
            _SetupHeader(compact: compact),
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
            width: compact ? double.infinity : null,
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
            child: compact ? content : IntrinsicWidth(child: content),
          ),
        );
      },
    );
  }
}

class _SetupHeader extends StatelessWidget {
  final bool compact;

  const _SetupHeader({required this.compact});

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
        const Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RETURN SETUP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PurchaseEntryStyles.highVisHeader,
              ),
              SizedBox(height: 4),
              Text(
                'Sales return and advance cancellation',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
        titleBlock,
        const SizedBox(width: 40),
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
              fontSize: 11,
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
    return Container(
      height: compact ? null : 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ReturnReversalDesignTokens.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReturnReversalDesignTokens.border),
        boxShadow: const [
          BoxShadow(
            color: PurchaseEntryColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: _tabChildren(expanded: true),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: _tabChildren(expanded: false),
            ),
    );
  }

  List<Widget> _tabChildren({required bool expanded}) {
    final returnTab = _OperationTab(
      type: ReturnReversalOperationType.salesReturn,
      title: 'RETURN',
      selected: selectedType == ReturnReversalOperationType.salesReturn,
      expanded: expanded,
      onTap: () => onChanged(ReturnReversalOperationType.salesReturn),
    );
    final cancellationTab = _OperationTab(
      type: ReturnReversalOperationType.bookingCancellation,
      title: 'CANCELLATION',
      selected: selectedType == ReturnReversalOperationType.bookingCancellation,
      expanded: expanded,
      onTap: () => onChanged(ReturnReversalOperationType.bookingCancellation),
    );

    return expanded
        ? [
            returnTab,
            const SizedBox(height: 4),
            cancellationTab,
          ]
        : [
            returnTab,
            const SizedBox(width: 4),
            cancellationTab,
          ];
  }
}

class _OperationTab extends StatefulWidget {
  final ReturnReversalOperationType type;
  final String title;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _OperationTab({
    required this.type,
    required this.title,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_OperationTab> createState() => _OperationTabState();
}

class _OperationTabState extends State<_OperationTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final emphasized = active || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: ReturnReversalDesignTokens.motionFast,
          curve: Curves.easeOutCubic,
          width: widget.expanded
              ? double.infinity
              : widget.type == ReturnReversalOperationType.salesReturn
                  ? 150
                  : 190,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? ReturnReversalDesignTokens.accent
                : ReturnReversalDesignTokens.panel,
            borderRadius: BorderRadius.circular(7),
            border: active
                ? null
                : Border.all(
                    color: emphasized
                        ? ReturnReversalDesignTokens.accent.withValues(
                            alpha: 0.45,
                          )
                        : Colors.transparent,
                  ),
            boxShadow: emphasized
                ? [
                    BoxShadow(
                      color: ReturnReversalDesignTokens.accent.withValues(
                        alpha: active ? 0.28 : 0.12,
                      ),
                      blurRadius: active ? 8 : 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : ReturnReversalDesignTokens.accent.withValues(
                          alpha: 0.16,
                        ),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 6, height: 6),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : ReturnReversalDesignTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
