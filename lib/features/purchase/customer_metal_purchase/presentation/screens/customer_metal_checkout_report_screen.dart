import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/data/customer_metal_purchase_ledger_drift_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/exports/customer_metal_purchase_report_print_service.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_table.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_filters/customer_metal_purchase_filter_controls.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_metal_cards/customer_metal_purchase_metal_visuals.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

part '../widgets/checkout_report/customer_metal_checkout_report_controls.dart';
part '../widgets/checkout_report/customer_metal_checkout_period_picker.dart';
part '../widgets/checkout_report/customer_metal_checkout_report_models.dart';
part '../widgets/checkout_report/customer_metal_checkout_report_summary.dart';

class CustomerMetalCheckoutReportScreen extends StatefulWidget {
  final CustomerMetalPurchaseLedgerRepository? repository;

  const CustomerMetalCheckoutReportScreen({
    super.key,
    this.repository,
  });

  @override
  State<CustomerMetalCheckoutReportScreen> createState() =>
      _CustomerMetalCheckoutReportScreenState();
}

class _CustomerMetalCheckoutReportScreenState
    extends State<CustomerMetalCheckoutReportScreen> {
  late final CustomerMetalPurchaseLedgerRepository _repository;
  var _isLoading = true;
  String? _error;
  List<CustomerMetalPurchaseEntry> _checkoutEntries = const [];
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        DriftCustomerMetalPurchaseLedgerRepository(AppDatabase());
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadReport();
  }

  @override
  void dispose() {
    // AppDatabase is a process-wide singleton. Closing it from a screen would
    // break every later report/open action with "Can't re-open database".
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      appBar: CustomerMetalPurchaseLedgerAppBar(
        title: 'Customer Metal Checkout Report',
        onBack: () => _handleBack(context),
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PurchaseEntryColors.brandGold),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: CustomerMetalPurchaseEmptyState(
          message: 'Unable to load checkout report. $_error',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckoutReportControls(
            onPrint: _selectedMonthEntries.isEmpty ? null : _printSelectedMonth,
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            selectedSummary: _selectedMonthSummary,
            periodRangeLabel: _selectedPeriodRangeLabel,
            onChangePeriod: () => _openPeriodPicker(context),
          ),
          const SizedBox(height: 14),
          _SelectedMonthSummaryBand(summary: _selectedMonthSummary),
          const SizedBox(height: 18),
          _MonthLedgerSection(
            title:
                '${_monthName(_selectedMonth)} $_selectedYear Checkout Ledger',
            entries: _selectedMonthEntries,
          ),
        ],
      ),
    );
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await _repository.fetchLedger();
      final checkoutEntries = entries
          .where((entry) => entry.isTransferredToMelting)
          .where((entry) => entry.transferredToMeltingAt != null)
          .toList(growable: false)
        ..sort((left, right) {
          final dateCompare =
              _checkoutDate(right).compareTo(_checkoutDate(left));
          if (dateCompare != 0) {
            return dateCompare;
          }
          return right.id.compareTo(left.id);
        });

      if (!mounted) {
        return;
      }
      setState(() {
        _checkoutEntries = checkoutEntries;
        _selectedYear = _resolveInitialYear();
        _selectedMonth = _resolveInitialMonth(checkoutEntries, _selectedYear);
        _isLoading = false;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = exception.toString();
      });
    }
  }

  Future<void> _openPeriodPicker(BuildContext context) async {
    final picked = await showDialog<_YearMonth>(
      context: context,
      builder: (dialogContext) {
        return _CheckoutPeriodPickerDialog(
          initialYear: _selectedYear,
          initialMonth: _selectedMonth,
          availableYears: _availableYears,
          monthlySummariesFor: _monthlySummariesFor,
          fallbackMonthForYear: (year) =>
              _resolveInitialMonth(_checkoutEntries, year),
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedYear = picked.year;
      _selectedMonth = picked.month;
    });
  }

  Future<void> _printSelectedMonth() async {
    final entries = _selectedMonthEntries;
    final savedPath =
        await CustomerMetalPurchaseReportPrintService.saveReportPdf(
      periodLabel:
          'Checkout Report - ${_monthName(_selectedMonth)} $_selectedYear',
      dashboard: _buildDashboardSummary(entries),
      metalSummaries: _buildMetalSummaries(entries),
      entries: entries,
      ledgerDateLabel: 'Checkout Date',
      ledgerDateSelector: _checkoutDate,
      fileName: _selectedReportFileName(),
      dialogTitle: 'Download Customer Metal Checkout Report PDF',
    );
    if (!mounted || savedPath == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checkout report downloaded: $savedPath')),
    );
  }

  String _selectedReportFileName() {
    final periodSlug = '${_monthName(_selectedMonth)} $_selectedYear';
    return '${_slug('melting checkout report $periodSlug')}.pdf';
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.reportPurchase);
  }

  List<_CheckoutMonthSummary> _monthlySummariesFor(int year) {
    return [
      for (var month = 1; month <= 12; month++)
        _CheckoutMonthSummary(
          month: month,
          entries: _entriesForMonth(year, month),
        ),
    ];
  }

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    final dataYears = <int>{};
    for (final entry in _checkoutEntries) {
      final entryYear = _checkoutDate(entry).year;
      if (entryYear <= currentYear) {
        dataYears.add(entryYear);
      }
    }

    if (dataYears.isEmpty) {
      return [currentYear];
    }

    final startYear = dataYears.reduce(math.min);
    return [
      for (var year = currentYear; year >= startYear; year--) year,
    ];
  }

  List<CustomerMetalPurchaseEntry> get _selectedMonthEntries {
    return _entriesForMonth(_selectedYear, _selectedMonth);
  }

  _CheckoutMonthSummary get _selectedMonthSummary {
    return _CheckoutMonthSummary(
      month: _selectedMonth,
      entries: _selectedMonthEntries,
    );
  }

  String get _selectedPeriodRangeLabel {
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    return '01 ${_monthName(_selectedMonth)} $_selectedYear - $lastDay ${_monthName(_selectedMonth)} $_selectedYear';
  }

  List<CustomerMetalPurchaseEntry> _entriesForMonth(int year, int month) {
    return _checkoutEntries.where((entry) {
      final checkoutDate = _checkoutDate(entry);
      return checkoutDate.year == year && checkoutDate.month == month;
    }).toList(growable: false);
  }

  int _resolveInitialYear() {
    return _availableYears.first;
  }

  int _resolveInitialMonth(
    List<CustomerMetalPurchaseEntry> entries,
    int year,
  ) {
    final current = DateTime.now();
    final months = entries
        .where((entry) => _checkoutDate(entry).year == year)
        .map((entry) => _checkoutDate(entry).month)
        .toSet()
        .toList()
      ..sort();
    if (current.year == year && months.contains(current.month)) {
      return current.month;
    }
    if (current.year == year && months.isEmpty) {
      return current.month;
    }
    return months.isEmpty ? 1 : months.last;
  }

  CustomerMetalPurchaseDashboardSummary _buildDashboardSummary(
    List<CustomerMetalPurchaseEntry> entries,
  ) {
    final sellers = <String>{};
    final vouchers = <String>{};
    var grossWeight = 0.0;
    var netWeight = 0.0;
    var fineWeight = 0.0;
    var amount = 0.0;
    var paidAmount = 0.0;
    var pendingAmount = 0.0;
    var cashPaid = 0.0;
    var upiPaid = 0.0;
    var bankPaid = 0.0;
    var cardPaid = 0.0;

    for (final entry in entries) {
      sellers.add(entry.customerName.trim().toUpperCase());
      vouchers.add(entry.referenceNo.trim().toUpperCase());
      grossWeight += entry.grossWeight;
      netWeight += entry.netWeight;
      fineWeight += entry.fineWeight;
      amount += entry.amount;
      paidAmount += entry.paidAmount;
      pendingAmount += entry.pendingAmount;
      cashPaid += entry.cashPaid;
      upiPaid += entry.upiPaid;
      bankPaid += entry.bankPaid;
      cardPaid += entry.cardPaid;
    }

    return CustomerMetalPurchaseDashboardSummary(
      grossWeight: grossWeight,
      netWeight: netWeight,
      fineWeight: fineWeight,
      amount: amount,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      bankPaid: bankPaid,
      cardPaid: cardPaid,
      entryCount: entries.length,
      customerCount: sellers.where((value) => value.isNotEmpty).length,
      voucherCount: vouchers.where((value) => value.isNotEmpty).length,
    );
  }

  Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      _buildMetalSummaries(List<CustomerMetalPurchaseEntry> entries) {
    return {
      for (final metal in CustomerMetalPurchaseMetal.values)
        metal: buildCustomerMetalPurchaseSummary(
          metal: metal,
          entries: entries
              .where((entry) =>
                  entry.metalType.toUpperCase() == metal.storageValue)
              .toList(growable: false),
        ),
    };
  }

  DateTime _checkoutDate(CustomerMetalPurchaseEntry entry) {
    return entry.transferredToMeltingAt ?? entry.date;
  }
}
