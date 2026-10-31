import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/screens/return_reversal_voucher_preview_screen.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

part 'return_reversal_summary_metrics.dart';
part 'return_reversal_summary_settlement.dart';
part 'return_reversal_summary_actions.dart';

class ReturnReversalInvoiceSummaryPanel extends StatelessWidget {
  final ReturnReversalController controller;

  const ReturnReversalInvoiceSummaryPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final operationType = controller.state.operationType;
    final sourceDocument = controller.state.selectedSourceDocument;
    final returnCartLineItems = controller.state.returnCartLineItems;
    final inspectionDrafts = controller.state.lineInspectionDrafts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final summaryBoard = _SummaryBoard(
          operationType: operationType,
          sourceDocument: sourceDocument,
          returnCartLineItems: returnCartLineItems,
          inspectionDrafts: inspectionDrafts,
          isProcessing: controller.state.isProcessing,
          isPosted: controller.state.lastProcessResult != null,
        );

        return Container(
          decoration: BoxDecoration(
            color: SalesPosColors.billingRightPanelBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: SalesPosColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: SalesPosColors.shadowDark,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: hasBoundedHeight
                ? Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                          child: summaryBoard,
                        ),
                      ),
                      const _PanelDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: _SummaryActions(controller: controller),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: summaryBoard,
                      ),
                      const _PanelDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: _SummaryActions(controller: controller),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SummaryBoard extends StatelessWidget {
  final ReturnReversalOperationType operationType;
  final ReturnReversalSourceDocument? sourceDocument;
  final List<ReturnReversalSourceLineItem> returnCartLineItems;
  final Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts;
  final bool isProcessing;
  final bool isPosted;

  const _SummaryBoard({
    required this.operationType,
    required this.sourceDocument,
    required this.returnCartLineItems,
    required this.inspectionDrafts,
    required this.isProcessing,
    required this.isPosted,
  });

  String get _subtitle {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Original invoice, return cart, and settlement'
        : 'Advance refund and booking closure';
  }

  bool get _isBookingCancellation =>
      operationType == ReturnReversalOperationType.bookingCancellation;

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    final metalBreakdowns = _buildMetalBreakdowns(document);
    final returnCartBreakdowns = _buildReturnCartBreakdowns(
      returnCartLineItems,
      inspectionDrafts,
    );
    final selectedReturnValue = returnCartBreakdowns.fold<double>(
      0,
      (total, breakdown) => total + breakdown.returnValue,
    );
    final originalInvoiceTotal = document == null
        ? 0.0
        : document.finalAmount > 0
            ? document.finalAmount
            : metalBreakdowns.fold<double>(
                0,
                (total, breakdown) => total + breakdown.displayInvoiceTotal,
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          icon: SalesPosIcons.invoiceOutline,
          title: _isBookingCancellation
              ? 'CANCELLATION SETTLEMENT'
              : 'RETURN SETTLEMENT',
          subtitle: _subtitle,
        ),
        const SizedBox(height: 12),
        _SettlementReadinessStrip(
          isBookingCancellation: _isBookingCancellation,
          sourceDocument: document,
          selectedLineCount: returnCartLineItems.length,
          selectedReturnValue: selectedReturnValue,
          isProcessing: isProcessing,
          isPosted: isPosted,
        ),
        const SizedBox(height: 16),
        _MiniSectionLabel(
          _isBookingCancellation
              ? 'Booking Advance'
              : 'Original Invoice Pricing',
        ),
        const SizedBox(height: 8),
        if (metalBreakdowns.isEmpty)
          _EmptySummaryText(
            _isBookingCancellation
                ? 'Select a booking to view advance total.'
                : 'Select an invoice to view metal totals.',
          )
        else if (_isBookingCancellation)
          ...metalBreakdowns.map(_BookingAdvanceSummaryTile.new)
        else
          ...metalBreakdowns.map(_MetalSummaryTile.new),
        const SizedBox(height: 14),
        _InvoiceTotalBox(
          label: _isBookingCancellation
              ? 'Refundable Advance Total'
              : 'Original Invoice Total',
          value: _formatCurrency(originalInvoiceTotal),
        ),
        const SizedBox(height: 14),
        _MiniSectionLabel(
          _isBookingCancellation ? 'Advance Method' : 'Payment Method',
        ),
        const SizedBox(height: 8),
        _PaymentBreakupRow(
          sourceDocument: document,
          isBookingCancellation: _isBookingCancellation,
        ),
        const SizedBox(height: 12),
        _PaymentStatusBox(sourceDocument: document),
        const SizedBox(height: 16),
        _MiniSectionLabel(
          _isBookingCancellation ? 'Cancellation Settlement' : 'Return Cart',
        ),
        const SizedBox(height: 8),
        _SelectedReturnCard(
          isBookingCancellation: _isBookingCancellation,
          selectedCount: returnCartLineItems.length,
          breakdowns: returnCartBreakdowns,
        ),
      ],
    );
  }

  List<_MetalInvoiceBreakdown> _buildMetalBreakdowns(
    ReturnReversalSourceDocument? document,
  ) {
    if (document == null || document.lineItems.isEmpty) {
      return const [];
    }

    final grouped = <String, _MetalInvoiceBreakdown>{};
    for (final item in document.lineItems) {
      final metal = item.metalType.trim().isEmpty
          ? 'OTHER'
          : item.metalType.trim().toUpperCase();
      grouped.putIfAbsent(metal, () => _MetalInvoiceBreakdown(metal)).add(item);
    }

    final values = grouped.values.toList(growable: false)
      ..sort((a, b) {
        final aRank = _metalRank(a.metal);
        final bRank = _metalRank(b.metal);
        if (aRank != bRank) {
          return aRank.compareTo(bRank);
        }
        return a.metal.compareTo(b.metal);
      });
    return values;
  }

  List<_ReturnCartMetalBreakdown> _buildReturnCartBreakdowns(
    List<ReturnReversalSourceLineItem> lineItems,
    Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
  ) {
    if (lineItems.isEmpty) {
      return const [];
    }

    final grouped = <String, _ReturnCartMetalBreakdown>{};
    for (final item in lineItems) {
      final metal = item.metalType.trim().isEmpty
          ? 'OTHER'
          : item.metalType.trim().toUpperCase();
      grouped
          .putIfAbsent(metal, () => _ReturnCartMetalBreakdown(metal))
          .add(item, inspectionDrafts);
    }

    final values = grouped.values.toList(growable: false)
      ..sort((a, b) {
        final aRank = _metalRank(a.metal);
        final bRank = _metalRank(b.metal);
        if (aRank != bRank) {
          return aRank.compareTo(bRank);
        }
        return a.metal.compareTo(b.metal);
      });
    return values;
  }

  int _metalRank(String metal) {
    if (metal.contains('GOLD')) {
      return 0;
    }
    if (metal.contains('SILVER')) {
      return 1;
    }
    if (metal.contains('DIAMOND')) {
      return 2;
    }
    return 3;
  }
}
