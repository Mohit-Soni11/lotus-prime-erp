import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/theme/return_reversal_design_tokens.dart';
import 'package:lotus_erp/logic/dashboard/date_card/date_card_logic.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class ReturnReversalDocumentStatusCard extends StatefulWidget {
  final ReturnReversalController controller;

  const ReturnReversalDocumentStatusCard({
    super.key,
    required this.controller,
  });

  @override
  State<ReturnReversalDocumentStatusCard> createState() =>
      _ReturnReversalDocumentStatusCardState();
}

class _ReturnReversalDocumentStatusCardState
    extends State<ReturnReversalDocumentStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationType = widget.controller.state.operationType;
    final sourceDocument = widget.controller.state.selectedSourceDocument;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _DocumentCard(
          operationType: operationType,
          sourceDocument: sourceDocument,
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final ReturnReversalOperationType operationType;
  final ReturnReversalSourceDocument? sourceDocument;

  const _DocumentCard({
    required this.operationType,
    required this.sourceDocument,
  });

  String get _primaryLabel {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'INVOICE NO.'
        : 'BOOKING NO.';
  }

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Sales invoice reversal'
        : 'Advance booking reversal';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocumentHeader(
            loaded: sourceDocument != null,
            subtitle: _subtitle,
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 16),
            color: ReturnReversalDesignTokens.border,
          ),
          _DocumentContent(
            sourceDocument: sourceDocument,
            primaryLabel: _primaryLabel,
          ),
        ],
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  final bool loaded;
  final String subtitle;

  const _DocumentHeader({
    required this.loaded,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
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
                  const Text(
                    'DOCUMENT NUMBER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PurchaseEntryStyles.highVisHeader,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
              _DocumentBadge(loaded: loaded),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleBlock,
            const SizedBox(width: 40),
            _DocumentBadge(loaded: loaded),
          ],
        );
      },
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

class _DocumentBadge extends StatelessWidget {
  final bool loaded;

  const _DocumentBadge({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ReturnReversalDesignTokens.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReturnReversalDesignTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: loaded
                  ? PurchaseEntryColors.success
                  : ReturnReversalDesignTokens.accent,
            ),
            child: const SizedBox(width: 6, height: 6),
          ),
          const SizedBox(width: 6),
          Text(
            loaded ? 'LOADED' : 'PENDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: loaded
                  ? PurchaseEntryColors.success
                  : ReturnReversalDesignTokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentContent extends StatefulWidget {
  final ReturnReversalSourceDocument? sourceDocument;
  final String primaryLabel;

  const _DocumentContent({
    required this.sourceDocument,
    required this.primaryLabel,
  });

  @override
  State<_DocumentContent> createState() => _DocumentContentState();
}

class _DocumentContentState extends State<_DocumentContent> {
  late final DateCardLogic _dateLogic;

  @override
  void initState() {
    super.initState();
    _dateLogic = DateCardLogic()..init();
  }

  @override
  void dispose() {
    _dateLogic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final sourceDocumentBlock = _SourceDocumentBlock(
          sourceDocument: widget.sourceDocument,
          primaryLabel: widget.primaryLabel,
          compact: compact,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sourceDocumentBlock,
              const SizedBox(height: 14),
              StreamBuilder<DateCardModel>(
                stream: _dateLogic.timeStream,
                initialData: _dateLogic.initialData,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return _DateTimeChipGroup(data: snapshot.data!);
                },
              ),
            ],
          );
        }

        return SizedBox(
          height: 52,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              sourceDocumentBlock,
              const SizedBox(width: 24),
              const _VerticalRule(),
              const SizedBox(width: 20),
              StreamBuilder<DateCardModel>(
                stream: _dateLogic.timeStream,
                initialData: _dateLogic.initialData,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return _DateTimeChipGroup(data: snapshot.data!);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceDocumentBlock extends StatelessWidget {
  final ReturnReversalSourceDocument? sourceDocument;
  final String primaryLabel;
  final bool compact;

  const _SourceDocumentBlock({
    required this.sourceDocument,
    required this.primaryLabel,
    required this.compact,
  });

  String get _primaryValue => sourceDocument?.documentNo ?? 'NOT SELECTED';

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DocumentIconBox(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DocumentNumberBlock(label: primaryLabel, value: _primaryValue),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _DocumentIconBox(),
        const SizedBox(width: 16),
        _DocumentNumberBlock(label: primaryLabel, value: _primaryValue),
      ],
    );
  }
}

class _DocumentIconBox extends StatelessWidget {
  const _DocumentIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: ReturnReversalDesignTokens.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ReturnReversalDesignTokens.accent.withValues(alpha: 0.25),
        ),
      ),
      child: const Icon(
        Icons.manage_search_rounded,
        color: ReturnReversalDesignTokens.accent,
        size: 24,
      ),
    );
  }
}

class _DocumentNumberBlock extends StatelessWidget {
  final String label;
  final String value;

  const _DocumentNumberBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: ReturnReversalDesignTokens.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ReturnReversalDesignTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            ReturnReversalDesignTokens.border,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _DateTimeChipGroup extends StatelessWidget {
  final DateCardModel data;

  const _DateTimeChipGroup({required this.data});

  @override
  Widget build(BuildContext context) {
    final parts = data.time.split(':');
    final cleanTime =
        parts.length >= 2 ? '${parts[0]} : ${parts[1]}' : data.time;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DocumentChip(
          icon: PurchaseEntryIcons.calendarDate,
          iconColor: ReturnReversalDesignTokens.textPrimary,
          label: 'DATE',
          value: data.date.toUpperCase(),
          valueColor: ReturnReversalDesignTokens.textPrimary,
          fontSize: 13,
          background: ReturnReversalDesignTokens.background,
          border: ReturnReversalDesignTokens.border,
        ),
        _DocumentChip(
          icon: PurchaseEntryIcons.clockTime,
          iconColor: PurchaseEntryColors.success,
          label: 'TIME',
          value: cleanTime,
          valueColor: PurchaseEntryColors.success,
          fontSize: 14,
          background: PurchaseEntryColors.success.withValues(alpha: 0.07),
          border: PurchaseEntryColors.success.withValues(alpha: 0.25),
        ),
      ],
    );
  }
}

class _DocumentChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final double fontSize;
  final Color background;
  final Color border;

  const _DocumentChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.fontSize,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
