import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_routes.dart';
import '../../../logic/finance/account_book/account_book_controller.dart';
import '../../../logic/finance/account_book/account_book_export_service.dart';
import '../../../models/finance/account_book/account_book_month.dart';
import '../../../theme/finance/account_book/account_book_theme.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import '../../shared/system_status_badge.dart';
import '../cash_book/cash_book_app_bar.dart';
import 'account_book_day_list.dart';
import 'account_book_summary.dart';

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen> {
  late final AccountBookController controller;

  @override
  void initState() {
    super.initState();
    controller = AccountBookController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _chooseMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT ACCOUNT BOOK MONTH',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AccountBookTheme.gold,
            onPrimary: AccountBookTheme.ink,
            onSurface: AccountBookTheme.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) await controller.selectMonth(date);
  }

  Future<void> _export(bool pdf) async {
    final report = controller.report;
    if (report == null) return;
    try {
      if (pdf) {
        await AccountBookExportService.printPdf(report);
      } else {
        await AccountBookExportService.exportCsv(report);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account Book export failed: $error')));
      }
    }
  }

  Future<void> _openCashLedger() async {
    await context.push(RoutePaths.financeCashLedger);
    if (mounted) await controller.load();
  }

  Future<void> _openBankLedger() async {
    await context.push(RoutePaths.financeBankLedger);
    if (mounted) await controller.load();
  }

  Future<void> _openDayBook(DateTime day) async {
    final date = DateFormat('yyyy-MM-dd').format(day);
    await context.push('${RoutePaths.reportDayBook}?date=$date');
    if (mounted) await controller.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final report = controller.report;
          return Scaffold(
            backgroundColor: CashBookColors.bodyBg,
            appBar: CashBookAppBar(
              onBack: widget.onBack,
              status: controller.loading
                  ? SystemStatus.loading
                  : controller.error != null
                      ? SystemStatus.unavailable
                      : SystemStatus.online,
              onExportCsv: report == null || controller.loading
                  ? null
                  : () => _export(false),
              onPrintPdf: report == null || controller.loading
                  ? null
                  : () => _export(true),
            ),
            body: SafeArea(
                child: Column(children: [
              if (controller.loading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                  child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _header(),
                    const SizedBox(height: 14),
                    if (controller.error != null)
                      _error()
                    else if (report != null) ...[
                      AccountBookSummary(report: report),
                      const SizedBox(height: 18),
                      _activityHeader(report),
                      const SizedBox(height: 10),
                      AccountBookDayList(
                        report: report,
                        filter: controller.filter,
                        onOpenDayBook: _openDayBook,
                      ),
                    ],
                  ],
                ),
              )),
            ])),
          );
        },
      );

  Widget _header() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AccountBookTheme.surface,
            border: Border.all(color: AccountBookTheme.border, width: 1.2),
            borderRadius: BorderRadius.circular(14)),
        child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('MONTHLY ACCOUNT BOOK',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AccountBookTheme.ink)),
                Text(
                    'Complete Day Book activity for ${DateFormat('MMMM yyyy').format(controller.month)}',
                    style: AccountBookTheme.detail),
              ]),
              Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                        onPressed: _openCashLedger,
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Cash Ledger',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AccountBookTheme.ink,
                            side: const BorderSide(
                                color: AccountBookTheme.border, width: 1.2))),
                    OutlinedButton.icon(
                        onPressed: _openBankLedger,
                        icon: const Icon(Icons.account_balance_outlined,
                            size: 18),
                        label: const Text('Bank Ledger',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AccountBookTheme.ink,
                            side: const BorderSide(
                                color: AccountBookTheme.border, width: 1.2))),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          tooltip: 'Previous month',
                          onPressed: () => controller.shiftMonth(-1),
                          color: AccountBookTheme.ink,
                          icon: const Icon(Icons.chevron_left_rounded)),
                      OutlinedButton.icon(
                          onPressed: _chooseMonth,
                          icon: const Icon(Icons.calendar_month_outlined,
                              size: 18),
                          label: Text(
                              DateFormat('MMMM yyyy').format(controller.month),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AccountBookTheme.ink,
                              side: const BorderSide(
                                  color: AccountBookTheme.border, width: 1.2))),
                      IconButton(
                          tooltip: 'Next month',
                          onPressed: () => controller.shiftMonth(1),
                          color: AccountBookTheme.ink,
                          icon: const Icon(Icons.chevron_right_rounded)),
                      IconButton(
                          tooltip: 'Refresh',
                          onPressed: controller.load,
                          color: AccountBookTheme.ink,
                          icon: const Icon(Icons.refresh_rounded)),
                    ]),
                  ]),
            ]),
      );

  Widget _error() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AccountBookTheme.surface,
            border: Border.all(color: AccountBookTheme.expense, width: 1.2),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(controller.error!,
              style: AccountBookTheme.detail
                  .copyWith(color: AccountBookTheme.expense)),
          TextButton(
              onPressed: controller.load, child: const Text('Try again')),
        ]),
      );

  Widget _activityHeader(AccountBookMonth report) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAY-WISE ACTIVITY  ·  ${report.activityCount} ENTRIES',
              style: AccountBookTheme.heading),
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: [
            _chip(null, 'All', report.activityCount),
            _chip(AccountBookActivityType.money, 'Money',
                report.count(AccountBookActivityType.money)),
            _chip(AccountBookActivityType.document, 'Documents',
                report.count(AccountBookActivityType.document)),
            _chip(AccountBookActivityType.stock, 'Stock',
                report.count(AccountBookActivityType.stock)),
            _chip(AccountBookActivityType.girvi, 'Girvi',
                report.count(AccountBookActivityType.girvi)),
            _chip(AccountBookActivityType.balance, 'Balances',
                report.count(AccountBookActivityType.balance)),
          ]),
        ],
      );

  Widget _chip(AccountBookActivityType? type, String label, int count) =>
      ChoiceChip(
        label: Text('$label  $count', style: AccountBookTheme.label),
        selected: controller.filter == type,
        onSelected: (_) => controller.selectFilter(type),
        selectedColor: AccountBookTheme.selected,
        backgroundColor: AccountBookTheme.surface,
        side: const BorderSide(color: AccountBookTheme.border, width: 1.2),
        showCheckmark: false,
      );
}
