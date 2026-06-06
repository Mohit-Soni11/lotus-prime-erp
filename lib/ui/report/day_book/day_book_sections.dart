import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

String _money(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: '${DayBookStrings.currencyCode} ',
    decimalDigits: decimals,
  ).format(value);
}

String _weight(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 3;
  return '${value.toStringAsFixed(decimals)} ${DayBookStrings.grams}';
}

class DayBookSummaryRail extends StatelessWidget {
  final DayBookController ctrl;
  final VoidCallback onReconcile;
  final bool compact;

  const DayBookSummaryRail({
    super.key,
    required this.ctrl,
    required this.onReconcile,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final summary = ctrl.summary!;
    final netPositive = summary.netCash >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateIdentity(summary: summary, isToday: ctrl.isToday),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: DayBookStyles.panel(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DayBookStrings.closingBalance,
                style: DayBookStyles.label,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(summary.closingCash),
                  style: DayBookStyles.valueHero,
                ),
              ),
              const SizedBox(height: 14),
              _BalanceLine(
                label: DayBookStrings.openingBalance,
                value: _money(summary.openingCash),
                icon: DayBookIcons.openingBalance,
                color: DayBookColors.information,
              ),
              const SizedBox(height: 10),
              _BalanceLine(
                label: DayBookStrings.netMovement,
                value:
                    '${netPositive ? '+' : '-'}${_money(summary.netCash.abs())}',
                icon: DayBookIcons.netMovement,
                color: netPositive
                    ? DayBookColors.positive
                    : DayBookColors.negative,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RailMetric(
                label: DayBookStrings.cashReceived,
                value: _money(summary.cashIn.total),
                icon: DayBookIcons.cashIn,
                color: DayBookColors.positive,
                background: DayBookColors.positiveSoft,
                border: DayBookColors.positiveBorder,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RailMetric(
                label: DayBookStrings.cashPaid,
                value: _money(summary.cashOut.total),
                icon: DayBookIcons.cashOut,
                color: DayBookColors.negative,
                background: DayBookColors.negativeSoft,
                border: DayBookColors.negativeBorder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: DayBookStyles.panel(),
          child: Column(
            children: [
              _CompactStat(
                label: DayBookStrings.taxInvoices,
                value: '${summary.totalGstBills}',
              ),
              const Divider(height: 20, color: DayBookColors.bodyBorder),
              _CompactStat(
                label: DayBookStrings.regularInvoices,
                value: '${summary.totalNonGstBills}',
              ),
              const Divider(height: 20, color: DayBookColors.bodyBorder),
              _CompactStat(
                label: DayBookStrings.gstCollected,
                value: _money(summary.totalGstCollected),
              ),
            ],
          ),
        ),
        if (summary.anomalies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: DayBookStyles.softPanel(
              color: DayBookColors.warningSoft,
              borderColor: DayBookColors.warningBorder,
            ),
            child: Row(
              children: [
                const Icon(
                  DayBookIcons.alert,
                  size: 17,
                  color: DayBookColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${summary.anomalies.length} item${summary.anomalies.length == 1 ? '' : 's'} require review',
                    style: DayBookStyles.labelStrong.copyWith(
                      color: DayBookColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (ctrl.isToday) ...[
          const SizedBox(height: 12),
          _DayStatusAction(
            locked: summary.isDayLocked,
            onPressed: summary.isDayLocked ? null : onReconcile,
          ),
        ],
        if (!compact) const SizedBox(height: 24),
      ],
    );
  }
}

class DayBookOverview extends StatelessWidget {
  final DayBookSummary summary;

  const DayBookOverview({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.netCash >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DayBookStrings.overview, style: DayBookStyles.pageTitle),
        const SizedBox(height: 4),
        Text(
          DayBookStrings.overviewSubtitle,
          style: DayBookStyles.sectionSubtitle,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 5
                : constraints.maxWidth >= 760
                    ? 3
                    : constraints.maxWidth >= 520
                        ? 2
                        : 1;
            const spacing = 10.0;
            final itemWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            final items = [
              _KpiData(
                label: DayBookStrings.openingBalance,
                value: _money(summary.openingCash),
                icon: DayBookIcons.openingBalance,
                color: DayBookColors.information,
                background: DayBookColors.informationSoft,
                border: DayBookColors.informationBorder,
              ),
              _KpiData(
                label: DayBookStrings.cashReceived,
                value: _money(summary.cashIn.total),
                icon: DayBookIcons.cashIn,
                color: DayBookColors.positive,
                background: DayBookColors.positiveSoft,
                border: DayBookColors.positiveBorder,
              ),
              _KpiData(
                label: DayBookStrings.cashPaid,
                value: _money(summary.cashOut.total),
                icon: DayBookIcons.cashOut,
                color: DayBookColors.negative,
                background: DayBookColors.negativeSoft,
                border: DayBookColors.negativeBorder,
              ),
              _KpiData(
                label: DayBookStrings.netMovement,
                value:
                    '${netPositive ? '+' : '-'}${_money(summary.netCash.abs())}',
                icon: DayBookIcons.netMovement,
                color: netPositive
                    ? DayBookColors.positive
                    : DayBookColors.negative,
                background: netPositive
                    ? DayBookColors.positiveSoft
                    : DayBookColors.negativeSoft,
                border: netPositive
                    ? DayBookColors.positiveBorder
                    : DayBookColors.negativeBorder,
              ),
              _KpiData(
                label: DayBookStrings.closingBalance,
                value: _money(summary.closingCash),
                icon: DayBookIcons.closingBalance,
                color: DayBookColors.goldMetal,
                background: DayBookColors.brandGoldSoft,
                border: DayBookColors.brandGoldBorder,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var index = 0; index < items.length; index++)
                  SizedBox(
                    width: itemWidth,
                    child: _KpiCard(data: items[index], index: index),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class DayBookOpeningPosition extends StatelessWidget {
  final DayBookSummary summary;

  const DayBookOpeningPosition({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _PositionMetricData(
        label: DayBookStrings.openingCash,
        value: _money(summary.openingCash),
        icon: DayBookIcons.openingBalance,
        color: DayBookColors.brandGold,
      ),
      _PositionMetricData(
        label: DayBookStrings.openingGold,
        value: _weight(summary.openingGoldGrams),
        icon: DayBookIcons.gold,
        color: DayBookColors.goldMetal,
      ),
      _PositionMetricData(
        label: DayBookStrings.openingSilver,
        value: _weight(summary.openingSilverGrams),
        icon: DayBookIcons.silver,
        color: DayBookColors.shellMuted,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DayBookColors.shellPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DayBookColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720
              ? 3
              : constraints.maxWidth >= 460
                  ? 2
                  : 1;
          const spacing = 12.0;
          final width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    DayBookIcons.openingBalance,
                    color: DayBookColors.brandGold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DayBookStrings.openingPosition,
                      style: DayBookStyles.labelStrong.copyWith(
                        color: DayBookColors.shellTitle,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('d MMM yyyy').format(summary.date),
                    style: DayBookStyles.appBarSubtitle,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DayBookStrings.openingPositionSubtitle,
                style: DayBookStyles.appBarSubtitle,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: _OpeningPositionMetric(data: metric),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class DayBookClosingPosition extends StatelessWidget {
  final DayBookSummary summary;

  const DayBookClosingPosition({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.netCash >= 0;
    final metrics = [
      _PositionMetricData(
        label: DayBookStrings.closingCash,
        value: _money(summary.closingCash),
        icon: DayBookIcons.closingBalance,
        color: DayBookColors.positive,
      ),
      _PositionMetricData(
        label: DayBookStrings.closingGold,
        value: _weight(summary.closingGold),
        icon: DayBookIcons.gold,
        color: DayBookColors.goldMetal,
      ),
      _PositionMetricData(
        label: DayBookStrings.closingSilver,
        value: _weight(summary.closingSilver),
        icon: DayBookIcons.silver,
        color: DayBookColors.silverMetal,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DayBookStyles.softPanel(
        color: DayBookColors.positiveSoft,
        borderColor: DayBookColors.positiveBorder,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final headline = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: DayBookColors.positive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  DayBookIcons.netMovement,
                  color: DayBookColors.positive,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DayBookStrings.closingPosition,
                      style: DayBookStyles.labelStrong,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DayBookStrings.closingPositionSubtitle,
                      style: DayBookStyles.label,
                    ),
                  ],
                ),
              ),
            ],
          );
          final netValue = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(DayBookStrings.netCashFlow, style: DayBookStyles.label),
              const SizedBox(height: 2),
              Text(
                '${netPositive ? '+' : '-'}${_money(summary.netCash.abs())}',
                style: DayBookStyles.valueLarge.copyWith(
                  color: netPositive
                      ? DayBookColors.positive
                      : DayBookColors.negative,
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                headline,
                const SizedBox(height: 14),
                netValue,
              ] else
                Row(
                  children: [
                    Expanded(child: headline),
                    const SizedBox(width: 16),
                    netValue,
                  ],
                ),
              const Divider(height: 28, color: DayBookColors.positiveBorder),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: compact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 20) / 3,
                      child: _ClosingPositionMetric(data: metric),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class DayBookAlerts extends StatelessWidget {
  final DayBookController ctrl;

  const DayBookAlerts({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final alerts = ctrl.summary!.anomalies;
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var index = 0; index < alerts.length; index++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: DayBookStyles.softPanel(
              color: DayBookColors.warningSoft,
              borderColor: DayBookColors.warningBorder,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  DayBookIcons.alert,
                  size: 19,
                  color: DayBookColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DayBookStrings.attentionRequired,
                        style: DayBookStyles.labelStrong.copyWith(
                          color: DayBookColors.warning,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alerts[index].message,
                        style: DayBookStyles.label.copyWith(
                          color: DayBookColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => ctrl.dismissAnomaly(index),
                  child: const Text(DayBookStrings.dismiss),
                ),
              ],
            ),
          ),
          if (index != alerts.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class CashMovementPanel extends StatelessWidget {
  final DayBookSummary summary;

  const CashMovementPanel({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final inflow = summary.cashIn;
    final outflow = summary.cashOut;

    final incomeRows = <_LedgerLineData>[
      _LedgerLineData(
        DayBookStrings.directSales,
        inflow.retailSalesTotal,
        DayBookIcons.sales,
      ),
      _LedgerLineData(
        DayBookStrings.dueCollection,
        inflow.dueCollection,
        Icons.receipt_long_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.bookingAdvance,
        inflow.advance,
        Icons.bookmark_added_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.deliveryCollection,
        inflow.orderDelivery,
        Icons.local_shipping_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.girviCollection,
        inflow.girviReturn,
        Icons.lock_open_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.loanReceived,
        inflow.loanReceived,
        Icons.account_balance_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.interestReceived,
        inflow.interestRec,
        Icons.percent_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.miscellaneousIncome,
        inflow.miscIncome,
        Icons.more_horiz_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.otherIncome,
        inflow.otherIncome,
        Icons.add_card_rounded,
      ),
    ].where((item) => item.amount != 0).toList();

    final expenseRows = <_LedgerLineData>[
      _LedgerLineData(
        DayBookStrings.operatingExpenses,
        outflow.operationalExpenses,
        Icons.storefront_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.purchasePayments,
        outflow.purchasePayment,
        Icons.inventory_2_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.girviDisbursement,
        outflow.girviGiven,
        Icons.lock_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.miscellaneousExpense,
        outflow.miscExpense,
        Icons.more_horiz_rounded,
      ),
      _LedgerLineData(
        DayBookStrings.otherExpense,
        outflow.otherExpense,
        Icons.outbox_rounded,
      ),
    ].where((item) => item.amount != 0).toList();

    return _WorkspacePanel(
      title: DayBookStrings.cashMovement,
      subtitle: DayBookStrings.cashMovementSubtitle,
      icon: DayBookIcons.netMovement,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 720;
          final income = _CashLedgerColumn(
            title: DayBookStrings.moneyReceived,
            total: inflow.total,
            rows: incomeRows,
            color: DayBookColors.positive,
            background: DayBookColors.positiveSoft,
            border: DayBookColors.positiveBorder,
          );
          final expenses = _CashLedgerColumn(
            title: DayBookStrings.moneyPaid,
            total: outflow.total,
            rows: expenseRows,
            color: DayBookColors.negative,
            background: DayBookColors.negativeSoft,
            border: DayBookColors.negativeBorder,
          );

          if (stack) {
            return Column(
              children: [
                income,
                const SizedBox(height: 16),
                expenses,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: income),
              const SizedBox(width: 16),
              Expanded(child: expenses),
            ],
          );
        },
      ),
    );
  }
}

class SalesTaxPanel extends StatelessWidget {
  final DayBookSummary summary;

  const SalesTaxPanel({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final gst = summary.cashIn.gstSales;
    final regular = summary.cashIn.nonGstSales;

    return _WorkspacePanel(
      title: DayBookStrings.salesAndTax,
      subtitle: DayBookStrings.salesAndTaxSubtitle,
      icon: DayBookIcons.taxInvoice,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 680;
          final taxCard = _InvoiceTypePanel(
            title: DayBookStrings.taxInvoices,
            icon: DayBookIcons.taxInvoice,
            count: gst.billCount,
            total: gst.finalAmount,
            color: DayBookColors.positive,
            background: DayBookColors.positiveSoft,
            border: DayBookColors.positiveBorder,
            detailRows: [
              _ValuePair(DayBookStrings.taxableValue, gst.taxableAmount),
              _ValuePair(DayBookStrings.cgst, gst.cgst),
              _ValuePair(DayBookStrings.sgst, gst.sgst),
              _ValuePair(DayBookStrings.gstCollected, gst.gstCollected),
            ],
          );
          final regularCard = _InvoiceTypePanel(
            title: DayBookStrings.regularInvoices,
            icon: DayBookIcons.regularInvoice,
            count: regular.billCount,
            total: regular.totalAmount,
            color: DayBookColors.information,
            background: DayBookColors.informationSoft,
            border: DayBookColors.informationBorder,
            detailRows: const [],
          );

          if (stack) {
            return Column(
              children: [
                taxCard,
                const SizedBox(height: 12),
                regularCard,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: taxCard),
              const SizedBox(width: 12),
              Expanded(child: regularCard),
            ],
          );
        },
      ),
    );
  }
}

class PaymentMixPanel extends StatelessWidget {
  final DayBookSummary summary;

  const PaymentMixPanel({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final data = summary.paymentBreakup;
    final rows = [
      _PaymentData(
        DayBookStrings.physicalCash,
        data.cash,
        DayBookIcons.cash,
        DayBookColors.cashMode,
      ),
      _PaymentData(
        DayBookStrings.upi,
        data.upi,
        DayBookIcons.upi,
        DayBookColors.upiMode,
      ),
      _PaymentData(
        DayBookStrings.card,
        data.card,
        DayBookIcons.card,
        DayBookColors.cardMode,
      ),
      _PaymentData(
        DayBookStrings.bankTransfer,
        data.bank,
        DayBookIcons.bank,
        DayBookColors.bankMode,
      ),
      _PaymentData(
        DayBookStrings.cheque,
        data.cheque,
        DayBookIcons.cheque,
        DayBookColors.chequeMode,
      ),
    ];

    return _WorkspacePanel(
      title: DayBookStrings.paymentMix,
      subtitle: DayBookStrings.paymentMixSubtitle,
      icon: DayBookIcons.card,
      trailing: Text(
        _money(data.total),
        style: DayBookStyles.value,
      ),
      child: data.total <= 0
          ? const _PanelEmptyState(
              icon: DayBookIcons.card,
              message: DayBookStrings.noPaymentData,
            )
          : Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  _PaymentRow(data: rows[index], total: data.total),
                  if (index != rows.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class MetalMovementPanel extends StatefulWidget {
  final DayBookSummary summary;

  const MetalMovementPanel({super.key, required this.summary});

  @override
  State<MetalMovementPanel> createState() => _MetalMovementPanelState();
}

class _MetalMovementPanelState extends State<MetalMovementPanel> {
  String? _selectedMetal;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final incoming = <_MetalLedgerData>[
      _MetalLedgerData(
        DayBookStrings.karigarReceipts,
        summary.metalIn.karigarFinishedGoods,
      ),
      _MetalLedgerData(
        DayBookStrings.girviSecurity,
        summary.metalIn.girviSecurityDeposit,
      ),
      _MetalLedgerData(
        DayBookStrings.oldGoldPurchase,
        summary.metalIn.urdPurchase,
      ),
      _MetalLedgerData(
        DayBookStrings.salesReturn,
        summary.metalIn.salesReturnReversal,
      ),
    ].where((item) => _hasWeight(item.weight)).toList();

    final outgoing = <_MetalLedgerData>[
      _MetalLedgerData(
        DayBookStrings.retailDispatch,
        summary.metalOut.retailDispatch,
      ),
      _MetalLedgerData(
        DayBookStrings.karigarIssue,
        summary.metalOut.karigarIssue,
      ),
    ].where((item) => _hasWeight(item.weight)).toList();

    final metals = <String>{
      ...summary.metalIn.total.metals,
      ...summary.metalOut.total.metals,
    }.toList()
      ..sort(_compareMetals);

    if (metals.isNotEmpty && !metals.contains(_selectedMetal)) {
      _selectedMetal = metals.first;
    }

    return _WorkspacePanel(
      title: DayBookStrings.metalMovement,
      subtitle: DayBookStrings.metalMovementSubtitle,
      icon: DayBookIcons.vault,
      child: metals.isEmpty
          ? const _PanelEmptyState(
              icon: DayBookIcons.vault,
              message: DayBookStrings.noMetalMovement,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 980
                        ? 4
                        : constraints.maxWidth >= 620
                            ? 2
                            : 1;
                    const spacing = 12.0;
                    final width =
                        (constraints.maxWidth - (spacing * (columns - 1))) /
                            columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final metal in metals)
                          SizedBox(
                            width: width,
                            child: _MetalSummaryCard(
                              metal: metal,
                              received:
                                  summary.metalIn.total.totalForMetal(metal),
                              issued:
                                  summary.metalOut.total.totalForMetal(metal),
                              purityCount: _puritiesFor(
                                metal,
                                summary.metalIn.total,
                                summary.metalOut.total,
                              ).length,
                              selected: metal == _selectedMetal,
                              onTap: () =>
                                  setState(() => _selectedMetal = metal),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _MetalDetailPanel(
                    key: ValueKey(_selectedMetal),
                    metal: _selectedMetal!,
                    incoming: incoming,
                    outgoing: outgoing,
                    totalIn: summary.metalIn.total,
                    totalOut: summary.metalOut.total,
                  ),
                ),
              ],
            ),
    );
  }

  int _compareMetals(String left, String right) {
    const order = ['Gold', 'Silver', 'Diamond', 'Platinum'];
    final leftIndex = order.indexOf(left);
    final rightIndex = order.indexOf(right);
    if (leftIndex == -1 && rightIndex == -1) return left.compareTo(right);
    if (leftIndex == -1) return 1;
    if (rightIndex == -1) return -1;
    return leftIndex.compareTo(rightIndex);
  }
}

class ForecastPanel extends StatelessWidget {
  final PredictedClosing prediction;

  const ForecastPanel({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final positive = prediction.isPositiveTrend;
    final color = positive ? DayBookColors.positive : DayBookColors.negative;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DayBookStyles.softPanel(
        color:
            positive ? DayBookColors.positiveSoft : DayBookColors.negativeSoft,
        borderColor: positive
            ? DayBookColors.positiveBorder
            : DayBookColors.negativeBorder,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final identity = Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(DayBookIcons.forecast, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DayBookStrings.forecast,
                      style: DayBookStyles.labelStrong,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DayBookStrings.forecastSubtitle,
                      style: DayBookStyles.label,
                    ),
                  ],
                ),
              ),
            ],
          );
          final amount = Text(
            _money(prediction.predictedCash),
            style: DayBookStyles.valueLarge.copyWith(color: color),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: amount,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              amount,
            ],
          );
        },
      ),
    );
  }
}

class DayBookClosePanel extends StatelessWidget {
  final DayBookSummary summary;
  final bool isToday;
  final VoidCallback onReconcile;

  const DayBookClosePanel({
    super.key,
    required this.summary,
    required this.isToday,
    required this.onReconcile,
  });

  @override
  Widget build(BuildContext context) {
    if (!isToday) return const SizedBox.shrink();

    if (summary.isDayLocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.positiveSoft,
          borderColor: DayBookColors.positiveBorder,
        ),
        child: Row(
          children: [
            const Icon(
              DayBookIcons.check,
              color: DayBookColors.positive,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DayBookStrings.dayLocked,
                    style: DayBookStyles.labelStrong.copyWith(
                      color: DayBookColors.positive,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DayBookStrings.dayLockedSubtitle,
                    style: DayBookStyles.label,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DayBookColors.shellPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DayBookColors.shellBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DayBookColors.brandGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  DayBookIcons.reconcile,
                  color: DayBookColors.brandGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DayBookStrings.endOfDay,
                      style: DayBookStyles.labelStrong.copyWith(
                        color: DayBookColors.shellTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DayBookStrings.endOfDaySubtitle,
                      style: DayBookStyles.appBarSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: onReconcile,
            style: FilledButton.styleFrom(
              backgroundColor: DayBookColors.brandGold,
              foregroundColor: DayBookColors.shellBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(DayBookIcons.reconcile, size: 16),
            label: const Text(DayBookStrings.reconcileCash),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 14),
                action,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _DateIdentity extends StatelessWidget {
  final DayBookSummary summary;
  final bool isToday;

  const _DateIdentity({required this.summary, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DayBookColors.brandGoldSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DayBookColors.brandGoldBorder),
          ),
          child: const Icon(
            DayBookIcons.calendar,
            size: 18,
            color: DayBookColors.brandGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'Today' : DateFormat('EEEE').format(summary.date),
                style: DayBookStyles.labelStrong,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('d MMMM yyyy').format(summary.date),
                style: DayBookStyles.label,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BalanceLine({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: DayBookStyles.label)),
        Text(value, style: DayBookStyles.value.copyWith(color: color)),
      ],
    );
  }
}

class _RailMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;

  const _RailMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(12),
      decoration: DayBookStyles.softPanel(
        color: background,
        borderColor: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 14),
          Text(label, style: DayBookStyles.label.copyWith(color: color)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: DayBookStyles.value.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;

  const _CompactStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: DayBookStyles.label)),
        Text(value, style: DayBookStyles.value),
      ],
    );
  }
}

class _DayStatusAction extends StatelessWidget {
  final bool locked;
  final VoidCallback? onPressed;

  const _DayStatusAction({required this.locked, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor:
              locked ? DayBookColors.positiveSoft : DayBookColors.shellPanel,
          disabledBackgroundColor: DayBookColors.positiveSoft,
          foregroundColor:
              locked ? DayBookColors.positive : DayBookColors.shellTitle,
          disabledForegroundColor: DayBookColors.positive,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: locked
                  ? DayBookColors.positiveBorder
                  : DayBookColors.shellBorder,
            ),
          ),
        ),
        icon: Icon(
          locked ? DayBookIcons.check : DayBookIcons.reconcile,
          size: 17,
          color: locked ? DayBookColors.positive : DayBookColors.brandGold,
        ),
        label: Text(
          locked ? DayBookStrings.dayLocked : DayBookStrings.reconcileCash,
        ),
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final int index;

  const _KpiCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 108),
        padding: const EdgeInsets.all(14),
        decoration: DayBookStyles.softPanel(
          color: data.background,
          borderColor: data.border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data.icon, size: 17, color: data.color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    data.label,
                    style: DayBookStyles.label.copyWith(color: data.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.value,
                style: DayBookStyles.valueLarge.copyWith(color: data.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PositionMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _OpeningPositionMetric extends StatelessWidget {
  final _PositionMetricData data;

  const _OpeningPositionMetric({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: DayBookColors.shellBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DayBookColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: data.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label, style: DayBookStyles.appBarSubtitle),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: DayBookStyles.value.copyWith(
                      color: DayBookColors.shellTitle,
                    ),
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

class _ClosingPositionMetric extends StatelessWidget {
  final _PositionMetricData data;

  const _ClosingPositionMetric({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DayBookColors.bodyPanel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DayBookColors.positiveBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.label, style: DayBookStyles.label),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(data.value, style: DayBookStyles.value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspacePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _WorkspacePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DayBookStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: DayBookColors.bodySubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DayBookColors.bodyBorder),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: DayBookColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: DayBookStyles.sectionTitle),
                      const SizedBox(height: 2),
                      Text(subtitle, style: DayBookStyles.sectionSubtitle),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: DayBookColors.bodyBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CashLedgerColumn extends StatelessWidget {
  final String title;
  final double total;
  final List<_LedgerLineData> rows;
  final Color color;
  final Color background;
  final Color border;

  const _CashLedgerColumn({
    required this.title,
    required this.total,
    required this.rows,
    required this.color,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: DayBookStyles.softPanel(
            color: background,
            borderColor: border,
          ),
          child: Row(
            children: [
              Icon(
                color == DayBookColors.positive
                    ? DayBookIcons.cashIn
                    : DayBookIcons.cashOut,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong.copyWith(color: color),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _money(total),
                    maxLines: 1,
                    style: DayBookStyles.value.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('No entries recorded', style: DayBookStyles.label),
          )
        else
          for (var index = 0; index < rows.length; index++) ...[
            _LedgerLine(data: rows[index], color: color),
            if (index != rows.length - 1)
              const Divider(height: 1, color: DayBookColors.bodyBorder),
          ],
      ],
    );
  }
}

class _LedgerLineData {
  final String label;
  final double amount;
  final IconData icon;

  const _LedgerLineData(this.label, this.amount, this.icon);
}

class _LedgerLine extends StatefulWidget {
  final _LedgerLineData data;
  final Color color;

  const _LedgerLine({required this.data, required this.color});

  @override
  State<_LedgerLine> createState() => _LedgerLineState();
}

class _LedgerLineState extends State<_LedgerLine> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        color: _hovered ? DayBookColors.cardHover : Colors.transparent,
        child: Row(
          children: [
            Icon(widget.data.icon, size: 16, color: widget.color),
            const SizedBox(width: 9),
            Expanded(
              flex: 3,
              child: Text(
                widget.data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DayBookStyles.labelStrong,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _money(widget.data.amount),
                  maxLines: 1,
                  style: DayBookStyles.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuePair {
  final String label;
  final double value;

  const _ValuePair(this.label, this.value);
}

class _InvoiceTypePanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final double total;
  final Color color;
  final Color background;
  final Color border;
  final List<_ValuePair> detailRows;

  const _InvoiceTypePanel({
    required this.title,
    required this.icon,
    required this.count,
    required this.total,
    required this.color,
    required this.background,
    required this.border,
    required this.detailRows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DayBookStyles.softPanel(
        color: background,
        borderColor: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: DayBookStyles.labelStrong.copyWith(color: color),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count ${DayBookStrings.invoices}',
                  style: DayBookStyles.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(DayBookStrings.invoiceValue, style: DayBookStyles.label),
          const SizedBox(height: 3),
          Text(
            _money(total),
            style: DayBookStyles.valueLarge.copyWith(color: color),
          ),
          if (detailRows.isNotEmpty) ...[
            const Divider(height: 24, color: DayBookColors.bodyBorder),
            for (var index = 0; index < detailRows.length; index++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      detailRows[index].label,
                      style: DayBookStyles.label,
                    ),
                  ),
                  Text(
                    _money(detailRows[index].value),
                    style: DayBookStyles.value,
                  ),
                ],
              ),
              if (index != detailRows.length - 1) const SizedBox(height: 9),
            ],
          ],
        ],
      ),
    );
  }
}

class _PaymentData {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _PaymentData(this.label, this.amount, this.icon, this.color);
}

class _PaymentRow extends StatelessWidget {
  final _PaymentData data;
  final double total;

  const _PaymentRow({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (data.amount / total).clamp(0.0, 1.0);
    final percentage = ratio * 100;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(data.icon, size: 17, color: data.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(data.label, style: DayBookStyles.labelStrong),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(percentage == percentage.roundToDouble() ? 0 : 1)}%',
                    style: DayBookStyles.label.copyWith(color: data.color),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: DayBookColors.bodyBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(data.color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 112,
          child: Text(
            _money(data.amount),
            style: DayBookStyles.value,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _PanelEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PanelEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 30, color: DayBookColors.textMuted),
          const SizedBox(height: 8),
          Text(message, style: DayBookStyles.label),
        ],
      ),
    );
  }
}

class _MetalLedgerData {
  final String label;
  final MetalWeight weight;

  const _MetalLedgerData(this.label, this.weight);
}

bool _hasWeight(MetalWeight weight) {
  return !weight.isEmpty;
}

List<String> _puritiesFor(
  String metal,
  MetalWeight incoming,
  MetalWeight outgoing,
) {
  final purities = <String>{
    ...incoming.puritiesFor(metal).keys,
    ...outgoing.puritiesFor(metal).keys,
  }.toList();
  purities.sort((left, right) {
    final leftNumber = int.tryParse(left.replaceAll(RegExp(r'[^0-9]'), ''));
    final rightNumber = int.tryParse(right.replaceAll(RegExp(r'[^0-9]'), ''));
    if (leftNumber != null && rightNumber != null) {
      return rightNumber.compareTo(leftNumber);
    }
    return left.compareTo(right);
  });
  return purities;
}

class _MetalSummaryCard extends StatelessWidget {
  final String metal;
  final double received;
  final double issued;
  final int purityCount;
  final bool selected;
  final VoidCallback onTap;

  const _MetalSummaryCard({
    required this.metal,
    required this.received,
    required this.issued,
    required this.purityCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _metalColor(metal);
    final net = received - issued;
    return Semantics(
      button: true,
      selected: selected,
      label: '$metal metal movement',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 156),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color:
                  selected ? _metalSoftColor(metal) : DayBookColors.bodyPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : DayBookColors.bodyBorder,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_metalIcon(metal), color: color, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(metal, style: DayBookStyles.sectionTitle),
                          const SizedBox(height: 2),
                          Text(
                            '$purityCount ${purityCount == 1 ? 'purity' : 'purities'}',
                            style: DayBookStyles.label,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right_rounded,
                      color: selected ? color : DayBookColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetalMiniMetric(
                        label: DayBookStrings.metalReceived,
                        value: received,
                        color: DayBookColors.positive,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: DayBookColors.bodyBorder,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetalMiniMetric(
                        label: DayBookStrings.metalIssued,
                        value: issued,
                        color: DayBookColors.negative,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DayBookStrings.netWeight,
                        style: DayBookStyles.label,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${net >= 0 ? '+' : '-'}${_weight(net.abs())}',
                          style: DayBookStyles.value.copyWith(
                            color: net >= 0
                                ? DayBookColors.positive
                                : DayBookColors.negative,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalMiniMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MetalMiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DayBookStyles.label),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _weight(value),
            style: DayBookStyles.value.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _MetalDetailPanel extends StatelessWidget {
  final String metal;
  final List<_MetalLedgerData> incoming;
  final List<_MetalLedgerData> outgoing;
  final MetalWeight totalIn;
  final MetalWeight totalOut;

  const _MetalDetailPanel({
    super.key,
    required this.metal,
    required this.incoming,
    required this.outgoing,
    required this.totalIn,
    required this.totalOut,
  });

  @override
  Widget build(BuildContext context) {
    final color = _metalColor(metal);
    final purities = _puritiesFor(metal, totalIn, totalOut);
    final sources = <_MetalSourceData>[
      for (final row in incoming)
        if (row.weight.totalForMetal(metal) != 0)
          _MetalSourceData(
            row.label,
            row.weight.totalForMetal(metal),
            true,
          ),
      for (final row in outgoing)
        if (row.weight.totalForMetal(metal) != 0)
          _MetalSourceData(
            row.label,
            row.weight.totalForMetal(metal),
            false,
          ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DayBookColors.bodySubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DayBookColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_metalIcon(metal), color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$metal ${DayBookStrings.purityBreakdown}',
                      style: DayBookStyles.sectionTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Only purities with movement on this date are shown.',
                      style: DayBookStyles.sectionSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < purities.length; index++) ...[
            _PurityMovementRow(
              purity: purities[index],
              received: totalIn.puritiesFor(metal)[purities[index]] ?? 0,
              issued: totalOut.puritiesFor(metal)[purities[index]] ?? 0,
              color: color,
            ),
            if (index != purities.length - 1) const SizedBox(height: 8),
          ],
          if (sources.isNotEmpty) ...[
            const Divider(height: 28, color: DayBookColors.bodyBorder),
            Text(
              DayBookStrings.movementSources,
              style: DayBookStyles.labelStrong,
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < sources.length; index++) ...[
              _MetalSourceChip(source: sources[index]),
              if (index != sources.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _PurityMovementRow extends StatelessWidget {
  final String purity;
  final double received;
  final double issued;
  final Color color;

  const _PurityMovementRow({
    required this.purity,
    required this.received,
    required this.issued,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final net = received - issued;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final metrics = [
          _PurityMetric(
            label: DayBookStrings.metalReceived,
            value: received,
            color: DayBookColors.positive,
          ),
          _PurityMetric(
            label: DayBookStrings.metalIssued,
            value: issued,
            color: DayBookColors.negative,
          ),
          _PurityMetric(
            label: DayBookStrings.netWeight,
            value: net,
            color: net >= 0 ? DayBookColors.positive : DayBookColors.negative,
            signed: true,
          ),
        ];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DayBookColors.bodyPanel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DayBookColors.bodyBorder),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PurityBadge(purity: purity, color: color),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var index = 0;
                            index < metrics.length;
                            index++) ...[
                          Expanded(child: metrics[index]),
                          if (index != metrics.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: _PurityBadge(purity: purity, color: color),
                    ),
                    for (final metric in metrics) Expanded(child: metric),
                  ],
                ),
        );
      },
    );
  }
}

class _PurityBadge extends StatelessWidget {
  final String purity;
  final Color color;

  const _PurityBadge({required this.purity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            purity,
            style: DayBookStyles.labelStrong.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PurityMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool signed;

  const _PurityMetric({
    required this.label,
    required this.value,
    required this.color,
    this.signed = false,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = signed ? (value >= 0 ? '+' : '-') : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: DayBookStyles.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            '$prefix${_weight(value.abs())}',
            style: DayBookStyles.value.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _MetalSourceData {
  final String label;
  final double amount;
  final bool incoming;

  const _MetalSourceData(this.label, this.amount, this.incoming);
}

class _MetalSourceChip extends StatelessWidget {
  final _MetalSourceData source;

  const _MetalSourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final color =
        source.incoming ? DayBookColors.positive : DayBookColors.negative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: source.incoming
            ? DayBookColors.positiveSoft
            : DayBookColors.negativeSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: source.incoming
              ? DayBookColors.positiveBorder
              : DayBookColors.negativeBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            source.incoming ? DayBookIcons.metalIn : DayBookIcons.metalOut,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              source.label,
              style: DayBookStyles.labelStrong,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _weight(source.amount),
                style: DayBookStyles.labelStrong.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _metalColor(String metal) {
  switch (metal) {
    case 'Gold':
      return DayBookColors.goldMetal;
    case 'Silver':
      return DayBookColors.silverMetal;
    case 'Platinum':
      return DayBookColors.platinumMetal;
    case 'Diamond':
      return DayBookColors.diamondMetal;
    default:
      return DayBookColors.purple;
  }
}

Color _metalSoftColor(String metal) {
  switch (metal) {
    case 'Gold':
      return DayBookColors.goldMetalSoft;
    case 'Silver':
      return DayBookColors.silverMetalSoft;
    case 'Platinum':
      return DayBookColors.platinumMetalSoft;
    case 'Diamond':
      return DayBookColors.diamondMetalSoft;
    default:
      return DayBookColors.purpleSoft;
  }
}

IconData _metalIcon(String metal) {
  switch (metal) {
    case 'Gold':
      return DayBookIcons.gold;
    case 'Silver':
      return DayBookIcons.silver;
    case 'Platinum':
      return DayBookIcons.platinum;
    case 'Diamond':
      return DayBookIcons.diamond;
    default:
      return DayBookIcons.vault;
  }
}
