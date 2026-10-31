import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

part 'return_reversal_customer_history.dart';
part 'return_reversal_customer_history_pills.dart';
part 'return_reversal_customer_inputs.dart';

class ReturnReversalCustomerDetailsCard extends StatefulWidget {
  final ReturnReversalController controller;

  const ReturnReversalCustomerDetailsCard({
    super.key,
    required this.controller,
  });

  @override
  State<ReturnReversalCustomerDetailsCard> createState() =>
      _ReturnReversalCustomerDetailsCardState();
}

class _ReturnReversalCustomerDetailsCardState
    extends State<ReturnReversalCustomerDetailsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationType = widget.controller.state.operationType;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SalesPosColors.customerCardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: SalesPosColors.shadowDark,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.30),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CustomerCardHeader(
                controller: widget.controller,
                operationType: operationType,
              ),
              const SizedBox(height: 16),
              _GoldDivider(),
              const SizedBox(height: 16),
              _CustomerInputGrid(
                controller: widget.controller,
                operationType: operationType,
              ),
              if (widget.controller.state.lookupMessage != null) ...[
                const SizedBox(height: 14),
                _LookupMessageBar(
                  message: widget.controller.state.lookupMessage!,
                ),
              ],
              if (widget.controller.state.lookupResult.hasDocuments) ...[
                const SizedBox(height: 14),
                _SourceHistoryStrip(controller: widget.controller),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCardHeader extends StatelessWidget {
  final ReturnReversalController controller;
  final ReturnReversalOperationType operationType;

  const _CustomerCardHeader({
    required this.controller,
    required this.operationType,
  });

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Find customer by mobile, name, invoice, or purchase number'
        : 'Find customer by mobile, name, or booking number';
  }

  String get _badge {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'RETURN SOURCE'
        : 'CANCEL SOURCE';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                SalesPosColors.goldGradientStart,
                SalesPosColors.brandGold,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: SalesPosColors.brandGold.withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            SalesPosIcons.profile,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CUSTOMER DETAILS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.highVisHeader,
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyText.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _SearchRecordsButton(controller: controller),
        const SizedBox(width: 10),
        _CustomerSourceBadge(label: _badge),
      ],
    );
  }
}

class _SearchRecordsButton extends StatelessWidget {
  final ReturnReversalController controller;

  const _SearchRecordsButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    return SizedBox(
      height: 36,
      child: FilledButton.icon(
        onPressed: state.isSearching ? null : () => controller.searchRecords(),
        icon: state.isSearching
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.manage_search_rounded, size: 18),
        label: Text(state.isSearching ? 'Searching' : 'Search Records'),
        style: FilledButton.styleFrom(
          backgroundColor: SalesPosColors.textDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              SalesPosColors.textDark.withValues(alpha: 0.84),
          disabledForegroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }
}

class _CustomerSourceBadge extends StatelessWidget {
  final String label;

  const _CustomerSourceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: SalesPosColors.brandGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.bold,
              color: SalesPosColors.goldHoverDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.50),
            SalesPosColors.brandGold.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _LookupMessageBar extends StatelessWidget {
  final String message;

  const _LookupMessageBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.warning.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: SalesPosColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SalesPosColors.textDark,
                fontSize: SalesPosStyles.fontLabel,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
