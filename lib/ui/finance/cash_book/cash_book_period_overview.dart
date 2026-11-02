import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/finance/cash_book/cash_book_history_controller.dart';
import '../../../models/finance/cash_book/cash_book_period_summary.dart';
import '../../../models/finance/cash_book/cash_transaction_model.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import 'cash_book_error_state.dart';

class CashBookPeriodOverview extends StatelessWidget {
  const CashBookPeriodOverview({
    super.key,
    required this.controller,
    this.shrinkWrap = false,
  });

  final CashBookHistoryController controller;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage case final message?) {
      return CashBookErrorState(message: message, onRetry: controller.retry);
    }

    final monthly = controller.view == CashBookHistoryView.monthly;
    final periods = List<CashBookPeriodSummary>.from(
      monthly ? controller.snapshot.months : controller.snapshot.years,
    )..sort((a, b) {
        final yearOrder = b.year.compareTo(a.year);
        if (yearOrder != 0) return yearOrder;
        return (b.month ?? 0).compareTo(a.month ?? 0);
      });

    if (periods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No cash transactions recorded yet.',
              textAlign: TextAlign.center,
              style: CashBookStyles.labelSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: periods.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => index == 0
          ? _OverviewHeading(monthly: monthly, count: periods.length)
          : _PeriodTile(period: periods[index - 1]),
    );
  }
}

class _OverviewHeading extends StatelessWidget {
  const _OverviewHeading({required this.monthly, required this.count});

  final bool monthly;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Text(
              monthly ? 'Monthly Cash Activity' : 'Yearly Cash Activity',
              style: CashBookStyles.sectionTitle);
          final countLabel = Text(
              '$count ${monthly ? 'months' : 'years'} with transactions',
              style: CashBookStyles.labelSecondary);
          if (constraints.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 4), countLabel],
            );
          }
          return Row(children: [Expanded(child: title), countLabel]);
        },
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.period});

  final CashBookPeriodSummary period;

  @override
  Widget build(BuildContext context) {
    final title = period.month == null
        ? period.year.toString()
        : DateFormat('MMMM yyyy').format(DateTime(period.year, period.month!));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CashBookColors.bodyPanel,
        border: Border.all(color: CashBookColors.bodyBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: CashBookStyles.sectionTitle.copyWith(fontSize: 16)),
              ),
              Text('${period.transactionCount} transactions',
                  style: CashBookStyles.labelSecondary),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 650 ? 2 : 4;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: 12,
                children: [
                  _PeriodMetric('Opening', period.openingBalance, width),
                  _PeriodMetric('Cash In', period.cashIn, width,
                      color: CashBookColors.incomeText),
                  _PeriodMetric('Cash Out', period.cashOut, width,
                      color: CashBookColors.expenseText),
                  _PeriodMetric('Closing', period.closingBalance, width,
                      color: period.closingBalance < 0
                          ? CashBookColors.expenseText
                          : CashBookColors.textDark),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Net movement: ${CashTransactionModel.formatAmount(period.netMovement)}',
            style: CashBookStyles.labelSecondary,
          ),
        ],
      ),
    );
  }
}

class _PeriodMetric extends StatelessWidget {
  const _PeriodMetric(this.label, this.value, this.width, {this.color});

  final String label;
  final double value;
  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CashBookStyles.labelMuted),
          const SizedBox(height: 3),
          Text(CashTransactionModel.formatAmount(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CashBookStyles.labelPrimary.copyWith(
                fontWeight: FontWeight.w800,
                color: color ?? CashBookColors.textDark,
              )),
        ],
      ),
    );
  }
}
