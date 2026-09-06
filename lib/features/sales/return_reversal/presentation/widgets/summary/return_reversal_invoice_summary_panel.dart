import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/screens/return_reversal_voucher_preview_screen.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';

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

class _ReturnCartMetalBreakdown {
  final String metal;
  var itemCount = 0;
  var netWeight = 0.0;
  var metalAmount = 0.0;
  var availableMaking = 0.0;
  var returnedMaking = 0.0;

  _ReturnCartMetalBreakdown(this.metal);

  double get returnValue => metalAmount + returnedMaking;

  void add(
    ReturnReversalSourceLineItem item,
    Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
  ) {
    final draft = _draftFor(item, inspectionDrafts);
    final adjustedMaking = _adjustedMakingAmount(item, inspectionDrafts);

    itemCount += 1;
    netWeight += draft.receivedNetWeight;
    metalAmount += _metalReturnAmount(item, inspectionDrafts);
    availableMaking += adjustedMaking;
    if (draft.includeMakingCharge) {
      returnedMaking += adjustedMaking;
    }
  }
}

class _MetalInvoiceBreakdown {
  final String metal;
  var itemCount = 0;
  var netWeight = 0.0;
  var itemValue = 0.0;
  var makingAmount = 0.0;
  var discountAmount = 0.0;
  var taxableAmount = 0.0;
  var gstAmount = 0.0;
  var invoiceTotal = 0.0;

  _MetalInvoiceBreakdown(this.metal);

  double get gstPercent {
    final taxable = displayTaxableValue;
    if (taxable <= 0 || gstAmount <= 0) {
      return 0;
    }
    return gstAmount / taxable * 100;
  }

  double get displayTaxableValue {
    if (taxableAmount > 0) {
      return taxableAmount;
    }
    return math.max(0.0, itemValue - discountAmount);
  }

  double get displayInvoiceTotal {
    if (invoiceTotal > 0) {
      return invoiceTotal;
    }
    return math.max(0.0, displayTaxableValue + gstAmount);
  }

  void add(ReturnReversalSourceLineItem item) {
    final lineValue = item.displayLineTotal;
    itemCount += 1;
    netWeight += item.netWeight;
    itemValue += lineValue;
    makingAmount += item.makingAmount;
    discountAmount += item.discountAmount;
    taxableAmount += item.taxableAmount;
    gstAmount += item.gstAmount;
    invoiceTotal += item.invoiceValue > 0
        ? item.invoiceValue
        : math.max(0.0, lineValue - item.discountAmount + item.gstAmount);
  }
}

class _MetalSummaryTile extends StatelessWidget {
  final _MetalInvoiceBreakdown breakdown;

  const _MetalSummaryTile(this.breakdown);

  Color get _accentColor {
    return breakdown.metal.contains('GOLD')
        ? SalesPosColors.brandGold
        : SalesPosColors.brandSilver;
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _formatMetalName(breakdown.metal);
    final gstLabel = breakdown.gstPercent > 0
        ? 'GST (${_formatPercent(breakdown.gstPercent)})'
        : 'GST';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$metalTitle Pricing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SalesPosStyles.bodyStrong.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCountLabel | ${breakdown.netWeight.toStringAsFixed(3)} g',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SalesPosStyles.caption.copyWith(
                        color: SalesPosColors.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatCurrency(breakdown.displayInvoiceTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyStrong.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SalesPosColors.bodyBorder.withValues(alpha: 0.72),
              ),
            ),
            child: Column(
              children: [
                _SubtleRow(
                  label: '$metalTitle Value',
                  value: _formatCurrency(breakdown.itemValue),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: 'Discount',
                  value: _formatCurrency(breakdown.discountAmount),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: 'Taxable Value',
                  value: _formatCurrency(breakdown.displayTaxableValue),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: gstLabel,
                  value: _formatCurrency(breakdown.gstAmount),
                ),
                const SizedBox(height: 9),
                _TotalRow(
                  label: '$metalTitle Total',
                  value: _formatCurrency(breakdown.displayInvoiceTotal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get itemCountLabel {
    final suffix = breakdown.itemCount == 1 ? 'item' : 'items';
    return '${breakdown.itemCount} $suffix';
  }
}

class _BookingAdvanceSummaryTile extends StatelessWidget {
  final _MetalInvoiceBreakdown breakdown;

  const _BookingAdvanceSummaryTile(this.breakdown);

  Color get _accentColor {
    return breakdown.metal.contains('GOLD')
        ? SalesPosColors.brandGold
        : SalesPosColors.brandSilver;
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _formatMetalName(breakdown.metal);
    final suffix = breakdown.itemCount == 1 ? 'line' : 'lines';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$metalTitle Booking',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.bodyStrong.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${breakdown.itemCount} $suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TotalRow(
            label: 'Advance Received',
            value: _formatCurrency(breakdown.displayInvoiceTotal),
          ),
        ],
      ),
    );
  }
}

class _SelectedReturnCard extends StatelessWidget {
  final bool isBookingCancellation;
  final int selectedCount;
  final List<_ReturnCartMetalBreakdown> breakdowns;

  const _SelectedReturnCard({
    required this.isBookingCancellation,
    required this.selectedCount,
    required this.breakdowns,
  });

  @override
  Widget build(BuildContext context) {
    final totalReturnValue = breakdowns.fold<double>(
      0,
      (total, breakdown) => total + breakdown.returnValue,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: Column(
        children: [
          _SubtleRow(
            label: isBookingCancellation ? 'Cancellation Lines' : 'Cart Items',
            value: selectedCount.toString(),
          ),
          if (breakdowns.isEmpty) ...[
            const SizedBox(height: 10),
            _EmptySummaryText(
              isBookingCancellation
                  ? 'No booking selected for cancellation.'
                  : 'No return items added to cart.',
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...breakdowns.map(
              (breakdown) => _ReturnCartMetalTile(
                breakdown,
                isBookingCancellation: isBookingCancellation,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _PillarRow(
            label: isBookingCancellation ? 'Refund Value' : 'Return Value',
            value: _formatCurrency(totalReturnValue),
          ),
        ],
      ),
    );
  }
}

class _ReturnCartMetalTile extends StatelessWidget {
  final _ReturnCartMetalBreakdown breakdown;
  final bool isBookingCancellation;

  const _ReturnCartMetalTile(
    this.breakdown, {
    required this.isBookingCancellation,
  });

  Color get _accentColor {
    return breakdown.metal.contains('GOLD')
        ? SalesPosColors.brandGold
        : SalesPosColors.brandSilver;
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _formatMetalName(breakdown.metal);
    final suffix = breakdown.itemCount == 1 ? 'item' : 'items';

    if (isBookingCancellation) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SalesPosColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accentColor.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$metalTitle Advance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.bodyStrong.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${breakdown.itemCount} $suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _SubtleRow(
              label: 'Advance Received',
              value: _formatCurrency(breakdown.returnValue),
            ),
            const SizedBox(height: 9),
            _TotalRow(
              label: 'Refund Total',
              value: _formatCurrency(breakdown.returnValue),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$metalTitle Return',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.bodyStrong.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${breakdown.itemCount} $suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _SubtleRow(
            label: '$metalTitle Net Weight',
            value: '${breakdown.netWeight.toStringAsFixed(3)} g',
          ),
          const SizedBox(height: 7),
          _SubtleRow(
            label: '$metalTitle Metal Amount',
            value: _formatCurrency(breakdown.metalAmount),
          ),
          const SizedBox(height: 7),
          _SubtleRow(
            label: '$metalTitle Making Available',
            value: _formatCurrency(breakdown.availableMaking),
          ),
          const SizedBox(height: 7),
          _SubtleRow(
            label: '$metalTitle Making Returned',
            value: _formatCurrency(breakdown.returnedMaking),
          ),
          const SizedBox(height: 9),
          _TotalRow(
            label: '$metalTitle Return Total',
            value: _formatCurrency(breakdown.returnValue),
          ),
        ],
      ),
    );
  }
}

class _MiniSectionLabel extends StatelessWidget {
  final String label;

  const _MiniSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: SalesPosStyles.caption.copyWith(
        color: SalesPosColors.brandGold,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHead({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(icon, color: SalesPosColors.brandGold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.highVisHeader,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
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
      ],
    );
  }
}

class _PaymentBreakupRow extends StatelessWidget {
  final ReturnReversalSourceDocument? sourceDocument;
  final bool isBookingCancellation;

  const _PaymentBreakupRow({
    required this.sourceDocument,
    required this.isBookingCancellation,
  });

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    if (document == null) {
      return _EmptySummaryText(
        isBookingCancellation
            ? 'Select a booking to view advance payment.'
            : 'Select an invoice to view payments.',
      );
    }
    if (document.type == ReturnReversalSourceDocumentType.advanceBooking) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PaymentChip(label: 'Advance', value: document.paidAmount),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (document.cashPaid > 0)
          _PaymentChip(label: 'Cash', value: document.cashPaid),
        if (document.upiPaid > 0)
          _PaymentChip(label: 'UPI', value: document.upiPaid),
        if (document.cardPaid > 0)
          _PaymentChip(label: 'Card', value: document.cardPaid),
        if (document.advancePaid > 0)
          _PaymentChip(label: 'Advance', value: document.advancePaid),
        if (document.cashPaid <= 0 &&
            document.upiPaid <= 0 &&
            document.cardPaid <= 0 &&
            document.advancePaid <= 0)
          _PaymentChip(label: 'Paid', value: document.paidAmount),
      ],
    );
  }
}

class _PaymentStatusBox extends StatelessWidget {
  final ReturnReversalSourceDocument? sourceDocument;

  const _PaymentStatusBox({required this.sourceDocument});

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    final paidAmount = document?.paidAmount ?? 0;
    final dueAmount = document?.dueAmount ?? 0;
    final isBooking =
        document?.type == ReturnReversalSourceDocumentType.advanceBooking;

    if (document == null) {
      return const _InlineInfoSurface(
        icon: Icons.receipt_long_rounded,
        title: 'Payment Snapshot',
        message: 'Payment details will appear after source selection.',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        children: [
          _SubtleRow(
            label: isBooking ? 'Advance Collected' : 'Collected',
            value: _formatCurrency(paidAmount),
          ),
          const SizedBox(height: 8),
          _SubtleRow(
            label: isBooking ? 'Refund Balance' : 'Balance Due',
            value: _formatCurrency(dueAmount),
          ),
        ],
      ),
    );
  }
}

class _SettlementReadinessStrip extends StatelessWidget {
  final bool isBookingCancellation;
  final ReturnReversalSourceDocument? sourceDocument;
  final int selectedLineCount;
  final double selectedReturnValue;
  final bool isProcessing;
  final bool isPosted;

  const _SettlementReadinessStrip({
    required this.isBookingCancellation,
    required this.sourceDocument,
    required this.selectedLineCount,
    required this.selectedReturnValue,
    required this.isProcessing,
    required this.isPosted,
  });

  @override
  Widget build(BuildContext context) {
    final state = _readinessState;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: state.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: state.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: state.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(state.icon, color: state.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.bodyStrong.copyWith(
                    color: state.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (selectedReturnValue > 0 && !isPosted) ...[
            const SizedBox(width: 10),
            _ReadinessAmountBadge(
              value: 'Ready ${_formatCurrency(selectedReturnValue)}',
            ),
          ],
        ],
      ),
    );
  }

  _ReadinessState get _readinessState {
    if (isProcessing) {
      return const _ReadinessState(
        icon: Icons.sync_rounded,
        title: 'Posting in Progress',
        message: 'Voucher and ledger entries are being saved.',
        color: SalesPosColors.brandGold,
      );
    }
    if (isPosted) {
      return _ReadinessState(
        icon: Icons.verified_rounded,
        title: isBookingCancellation
            ? 'Cancellation Voucher Ready'
            : 'Return Voucher Ready',
        message: isBookingCancellation
            ? 'Cancellation voucher is ready to print or share.'
            : 'Return voucher and invoice copies are ready to print or share.',
        color: SalesPosColors.success,
      );
    }
    if (sourceDocument == null) {
      return _ReadinessState(
        icon: Icons.manage_search_rounded,
        title: isBookingCancellation ? 'Booking Required' : 'Source Required',
        message: isBookingCancellation
            ? 'Select an advance booking before cancellation.'
            : 'Select a sales invoice or purchase voucher before return.',
        color: SalesPosColors.warning,
      );
    }
    if (selectedLineCount <= 0) {
      return _ReadinessState(
        icon: Icons.touch_app_rounded,
        title: isBookingCancellation
            ? 'Cancellation Not Prepared'
            : 'Return Cart Empty',
        message: isBookingCancellation
            ? 'Choose a cancellable booking line to prepare refund.'
            : 'Add pending invoice items to prepare return settlement.',
        color: SalesPosColors.warning,
      );
    }
    return _ReadinessState(
      icon: Icons.task_alt_rounded,
      title: isBookingCancellation ? 'Ready to Cancel' : 'Ready to Process',
      message: isBookingCancellation
          ? '$selectedLineCount booking line selected for refund.'
          : '$selectedLineCount item${selectedLineCount == 1 ? '' : 's'} selected for return.',
      color: SalesPosColors.success,
    );
  }
}

class _ReadinessState {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _ReadinessState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}

class _ReadinessAmountBadge extends StatelessWidget {
  final String value;

  const _ReadinessAmountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SalesPosColors.success.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesPosStyles.bodyStrong.copyWith(
          color: SalesPosColors.success,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InlineInfoSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineInfoSurface({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: SalesPosColors.brandGold,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.brandGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final double value;

  const _PaymentChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Text(
        '$label ${_formatCurrency(value)}',
        style: SalesPosStyles.caption.copyWith(
          color: SalesPosColors.textDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InvoiceTotalBox extends StatelessWidget {
  final String label;
  final String value;

  const _InvoiceTotalBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: _PillarRow(label: label, value: value),
    );
  }
}

class _EmptySummaryText extends StatelessWidget {
  final String text;

  const _EmptySummaryText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SalesPosStyles.bodyText.copyWith(
        color: SalesPosColors.textDark,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SubtleRow extends StatelessWidget {
  final String label;
  final String value;

  const _SubtleRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.bodyText.copyWith(
              color: SalesPosColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: SalesPosStyles.bodyStrong.copyWith(
            color: SalesPosColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TotalRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.bodyStrong,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: SalesPosStyles.bodyStrong.copyWith(
              color: SalesPosColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  final String label;
  final String value;

  const _PillarRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.bodyStrong,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: SalesPosColors.brandGold,
            fontSize: SalesPosStyles.fontValue,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.05),
            SalesPosColors.bodyBorder,
            SalesPosColors.brandGold.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}

class _SummaryActions extends StatelessWidget {
  final ReturnReversalController controller;

  const _SummaryActions({required this.controller});

  String get _buttonLabel {
    return controller.state.operationType ==
            ReturnReversalOperationType.salesReturn
        ? 'Process Return'
        : 'Process Cancellation';
  }

  String _voucherButtonLabel(ReturnReversalState state) {
    if (state.selectedSourceDocument == null) {
      return state.operationType.isBookingCancellation
          ? 'Select Booking First'
          : 'Select Source First';
    }
    if (!state.hasReturnCartLineItems &&
        !state.invoiceLineItems.any((lineItem) => lineItem.isReversed) &&
        state.lastProcessResult == null) {
      return state.operationType.isBookingCancellation
          ? 'Prepare Cancellation First'
          : 'Add Return Item First';
    }
    return state.operationType.isBookingCancellation
        ? 'Generate Cancellation Voucher'
        : 'Generate Return Voucher';
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final canProcess = state.hasReturnCartLineItems && !state.isProcessing;
    final hasReturnedLines =
        state.invoiceLineItems.any((lineItem) => lineItem.isReversed);
    final canGenerateVoucher = state.selectedSourceDocument != null &&
        !state.isProcessing &&
        (state.hasReturnCartLineItems ||
            hasReturnedLines ||
            state.lastProcessResult != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.processMessage != null) ...[
          _ProcessMessageBar(
            message: state.processMessage!,
            success: true,
          ),
          const SizedBox(height: 10),
        ],
        if (state.errorMessage != null) ...[
          _ProcessMessageBar(
            message: state.errorMessage!,
            success: false,
          ),
          const SizedBox(height: 10),
        ],
        _PrimarySummaryButton(
          label: _buttonLabel,
          enabled: canProcess,
          isProcessing: state.isProcessing,
          onPressed: controller.processReturn,
        ),
        const SizedBox(height: 10),
        _SecondarySummaryButton(
          label: _voucherButtonLabel(state),
          enabled: canGenerateVoucher,
          onPressed: () {
            ReturnReversalVoucherPreviewScreen.push(
              context,
              controller: controller,
            );
          },
        ),
      ],
    );
  }
}

class _PrimarySummaryButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final bool isProcessing;
  final VoidCallback onPressed;

  const _PrimarySummaryButton({
    required this.label,
    required this.enabled,
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  State<_PrimarySummaryButton> createState() => _PrimarySummaryButtonState();
}

class _PrimarySummaryButtonState extends State<_PrimarySummaryButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled || widget.isProcessing;
    final foreground = active
        ? SalesPosColors.textDark
        : SalesPosColors.textDark.withValues(alpha: 0.74);
    return SizedBox(
      height: 50,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: Listener(
            onPointerDown:
                widget.enabled ? (_) => setState(() => _pressed = true) : null,
            onPointerUp:
                widget.enabled ? (_) => setState(() => _pressed = false) : null,
            onPointerCancel:
                widget.enabled ? (_) => setState(() => _pressed = false) : null,
            child: AnimatedScale(
              scale: _pressed ? 0.985 : 1,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? widget.onPressed : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: active
                          ? LinearGradient(
                              colors: [
                                SalesPosColors.goldGradientStart,
                                _hovered
                                    ? SalesPosColors.goldHoverDark
                                    : SalesPosColors.brandGold,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: active
                          ? null
                          : SalesPosColors.brandGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: SalesPosColors.brandGold.withValues(
                          alpha: active ? 0.92 : 0.54,
                        ),
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: SalesPosColors.brandGold.withValues(
                                  alpha: _hovered ? 0.42 : 0.30,
                                ),
                                blurRadius: _hovered ? 20 : 15,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.36),
                                blurRadius: 5,
                                offset: const Offset(0, -1),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: SalesPosColors.brandGold.withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isProcessing)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: foreground,
                              ),
                            )
                          else
                            Icon(
                              Icons.assignment_turned_in_rounded,
                              color: active
                                  ? foreground
                                  : SalesPosColors.brandGold,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.isProcessing ? 'Posting' : widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SalesPosStyles.buttonText.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessMessageBar extends StatelessWidget {
  final String message;
  final bool success;

  const _ProcessMessageBar({
    required this.message,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? SalesPosColors.success : SalesPosColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondarySummaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _SecondarySummaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.receipt_long_rounded, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          animationDuration: const Duration(milliseconds: 140),
          textStyle: WidgetStatePropertyAll(
            SalesPosStyles.buttonText.copyWith(fontWeight: FontWeight.w900),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SalesPosColors.textDark.withValues(alpha: 0.72);
            }
            return SalesPosColors.textDark;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SalesPosColors.bodyPanelBg.withValues(alpha: 0.76);
            }
            if (states.contains(WidgetState.pressed)) {
              return SalesPosColors.brandGold.withValues(alpha: 0.18);
            }
            if (states.contains(WidgetState.hovered)) {
              return SalesPosColors.brandGold.withValues(alpha: 0.10);
            }
            return SalesPosColors.bodyPanelBg;
          }),
          overlayColor: WidgetStatePropertyAll(
            SalesPosColors.brandGold.withValues(alpha: 0.08),
          ),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SalesPosColors.textDark.withValues(alpha: 0.56);
            }
            return SalesPosColors.brandGold;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: SalesPosColors.bodyBorder.withValues(alpha: 0.92),
                width: 1.5,
              );
            }
            return BorderSide(
              color: SalesPosColors.brandGold.withValues(alpha: 0.70),
              width: 1.5,
            );
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          shadowColor: WidgetStatePropertyAll(
            SalesPosColors.brandGold.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }
}

String _formatMetalName(String metal) {
  final normalized = metal.trim().toUpperCase();
  if (normalized.isEmpty) {
    return 'Other';
  }
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty
          ? word
          : '${word.substring(0, 1)}${word.substring(1).toLowerCase()}')
      .join(' ');
}

double _receivedWeightRatio(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  if (lineItem.netWeight <= 0) {
    return 1;
  }
  final receivedWeight = inspectionDrafts[lineItem.lineNo]?.receivedNetWeight ??
      lineItem.netWeight;
  return (receivedWeight / lineItem.netWeight).clamp(0.0, 1.0);
}

ReturnReversalLineInspectionDraft _draftFor(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return inspectionDrafts[lineItem.lineNo] ??
      ReturnReversalLineInspectionDraft.fromLine(lineItem);
}

double _adjustedLineAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return lineItem.displayLineTotal *
      _receivedWeightRatio(lineItem, inspectionDrafts);
}

double _adjustedMakingAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return lineItem.makingAmount *
      _receivedWeightRatio(lineItem, inspectionDrafts);
}

double _metalReturnAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return math.max(
    0.0,
    _adjustedLineAmount(lineItem, inspectionDrafts) -
        _adjustedMakingAmount(lineItem, inspectionDrafts),
  );
}

String _formatPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) {
    return '${rounded.toStringAsFixed(0)}%';
  }
  return '${value.toStringAsFixed(2)}%';
}

String _formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().round().toString();
  if (digits.length <= 3) {
    return 'Rs $sign$digits';
  }
  final lastThree = digits.substring(digits.length - 3);
  final leading = digits.substring(0, digits.length - 3);
  final groupedLeading = leading.replaceAllMapped(
    RegExp(r'\B(?=(\d{2})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs $sign$groupedLeading,$lastThree';
}
