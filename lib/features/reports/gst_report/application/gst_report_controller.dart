import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../data/gst_report_repository.dart';
import '../domain/gst_filing_period.dart';
import '../domain/gst_quarter_filing_ledger.dart';
import '../domain/gst_report_models.dart';

class GstReportController extends ChangeNotifier {
  static const Duration _liveRefreshInterval = Duration(seconds: 30);

  GstReportController({
    GstReportRepository? repository,
    GstReportPeriod? initialPeriod,
    GstReportTab initialTab = GstReportTab.dashboard,
  })  : _repository = repository ?? GstReportRepository(),
        _period = initialPeriod ?? GstReportPeriod.currentMonth(),
        _selectedTab = initialTab {
    load();
    _liveRefreshTimer = Timer.periodic(_liveRefreshInterval, (_) {
      if (!_isLoading && !_isLiveRefreshing) {
        load(silent: true);
      }
    });
  }

  final GstReportRepository _repository;

  GstReportPeriod _period;
  GstReportSnapshot? _snapshot;
  GstFilingWorkflowSnapshot? _workflowSnapshot;
  GstQuarterFilingLedger? _quarterLedger;
  GstReportTab _selectedTab;
  bool _isLoading = true;
  bool _isLiveRefreshing = false;
  bool _disposed = false;
  Timer? _liveRefreshTimer;
  String? _errorMessage;

  GstReportPeriod get period => _period;
  GstReportSnapshot? get snapshot => _snapshot;
  GstFilingWorkflowSnapshot? get workflowSnapshot => _workflowSnapshot;
  GstQuarterFilingLedger? get quarterLedger => _quarterLedger;
  GstReportTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSelectedMonthInFuture => !canSelectMonth(_period.month);
  DateTime get filingCompletionOpensAt {
    return DateTime(_period.startDate.year, _period.startDate.month + 1);
  }

  Future<void> load({bool silent = false}) async {
    if (silent) {
      _isLiveRefreshing = true;
    }
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      _notifyListeners();
    }

    try {
      _snapshot = await _repository.fetch(_period);
      _workflowSnapshot =
          await _repository.fetchFilingWorkflowSnapshot(_period);
      _quarterLedger = await _repository.fetchQuarterFilingLedger(_period);
      _errorMessage = null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'GstReportController.load failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _snapshot ??= GstReportSnapshot.empty(_period);
      _workflowSnapshot ??= _emptyWorkflowSnapshot(_period);
      _quarterLedger ??= _emptyQuarterLedger(_period);
      _errorMessage = 'Unable to load GST report.';
    } finally {
      if (silent) {
        _isLiveRefreshing = false;
      }
      _isLoading = false;
      _notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  void selectTab(GstReportTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyListeners();
  }

  void setReportMonth(DateTime month) {
    if (!canSelectMonth(month)) return;
    final nextPeriod = GstReportPeriod.forMonth(month);
    if (_period.startDate == nextPeriod.startDate) return;
    _period = nextPeriod;
    load();
  }

  void shiftReportMonth(int monthOffset) {
    setReportMonth(
      DateTime(_period.startDate.year, _period.startDate.month + monthOffset),
    );
  }

  bool canShiftReportMonth(int monthOffset) {
    final next = DateTime(
      _period.startDate.year,
      _period.startDate.month + monthOffset,
    );
    return canSelectMonth(next);
  }

  bool canSelectMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    return !normalized.isAfter(currentMonth);
  }

  bool canCompleteTask(GstFilingTask task) {
    if (!canCompleteSelectedPeriod) return false;
    if (task != GstFilingTask.quarterReturnFiled) return true;
    return GstFilingPeriod.fromMonth(_period.month).isQuarterClosingMonth;
  }

  bool get canCompleteSelectedPeriod {
    final today = DateUtils.dateOnly(DateTime.now());
    final opensAt = DateUtils.dateOnly(filingCompletionOpensAt);
    return !isSelectedMonthInFuture && !today.isBefore(opensAt);
  }

  bool isSegmentFilingComplete(GstFilingSegment segment) {
    final task = _taskForSegment(segment);
    return _workflowSnapshot?.isTaskComplete(task) ?? false;
  }

  Future<void> completeSegmentFiling(GstFilingSegment segment) async {
    final snapshot = _snapshot;
    if (snapshot == null || !canCompleteSelectedPeriod) return;
    if (isSegmentFilingComplete(segment)) return;

    final tasks = _completionTasksForSegment(segment);
    try {
      for (final task in tasks) {
        final taskSnapshot = await _snapshotForTask(task, snapshot);
        await _repository.setFilingTaskCompletion(
          period: _period,
          task: task,
          completed: true,
          amountSnapshot: taskSnapshot.amount,
          invoiceCountSnapshot: taskSnapshot.invoiceCount,
        );
      }
      _workflowSnapshot =
          await _repository.fetchFilingWorkflowSnapshot(_period);
      _quarterLedger = await _repository.fetchQuarterFilingLedger(_period);
      _notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        'GstReportController.completeSegmentFiling failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to complete GST filing status.';
      _notifyListeners();
    }
  }

  Future<void> toggleFilingTask(GstFilingTask task) async {
    final snapshot = _snapshot;
    if (snapshot == null || !canCompleteTask(task)) return;

    final current = _workflowSnapshot?.statusFor(task);
    final nextCompleted = !(current?.completed ?? false);
    final taskSnapshot = await _snapshotForTask(task, snapshot);

    try {
      await _repository.setFilingTaskCompletion(
        period: _period,
        task: task,
        completed: nextCompleted,
        amountSnapshot: taskSnapshot.amount,
        invoiceCountSnapshot: taskSnapshot.invoiceCount,
      );
      _workflowSnapshot =
          await _repository.fetchFilingWorkflowSnapshot(_period);
      _quarterLedger = await _repository.fetchQuarterFilingLedger(_period);
      _notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        'GstReportController.toggleFilingTask failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to update GST filing status.';
      _notifyListeners();
    }
  }

  List<GstFilingTask> _completionTasksForSegment(GstFilingSegment segment) {
    final filing = GstFilingPeriod.fromMonth(_period.month);
    final tasks = <GstFilingTask>[
      if (filing.hasMonthlyTaxPayment) GstFilingTask.monthlyTaxPayment,
      _taskForSegment(segment),
    ];
    if (segment == GstFilingSegment.b2b && filing.iffDueDate != null) {
      tasks.add(GstFilingTask.b2bIffUpload);
    }
    if (filing.isQuarterClosingMonth) {
      tasks.add(GstFilingTask.quarterReturnFiled);
    }
    return tasks.toSet().toList(growable: false);
  }

  GstFilingTask _taskForSegment(GstFilingSegment segment) {
    switch (segment) {
      case GstFilingSegment.b2b:
        return GstFilingTask.b2bReturnFiled;
      case GstFilingSegment.b2c:
        return GstFilingTask.b2cReturnFiled;
    }
  }

  Future<_FilingTaskSnapshot> _snapshotForTask(
    GstFilingTask task,
    GstReportSnapshot snapshot,
  ) async {
    switch (task) {
      case GstFilingTask.monthlyTaxPayment:
        return _FilingTaskSnapshot(
          amount: snapshot.dashboard.totalGst,
          invoiceCount: snapshot.dashboard.gstInvoiceCount,
        );
      case GstFilingTask.b2bIffUpload:
      case GstFilingTask.b2bReturnFiled:
        return _FilingTaskSnapshot(
          amount: _sum(snapshot.gstr1B2bInvoices, (row) => row.gstAmount),
          invoiceCount: snapshot.gstr1B2bInvoices.length,
        );
      case GstFilingTask.b2cReturnFiled:
        return _FilingTaskSnapshot(
          amount: _sum(snapshot.gstr1B2cInvoices, (row) => row.gstAmount),
          invoiceCount: snapshot.gstr1B2cInvoices.length,
        );
      case GstFilingTask.quarterReturnFiled:
        final filing = GstFilingPeriod.fromMonth(_period.month);
        final quarterSnapshot = await _repository.fetch(GstReportPeriod(
          startDate: filing.quarterStartMonth,
          endDate: DateTime(
            filing.quarterEndMonth.year,
            filing.quarterEndMonth.month + 1,
            0,
            23,
            59,
            59,
          ),
        ));
        return _FilingTaskSnapshot(
          amount: quarterSnapshot.dashboard.totalGst,
          invoiceCount: quarterSnapshot.dashboard.gstInvoiceCount,
        );
    }
  }

  GstFilingWorkflowSnapshot _emptyWorkflowSnapshot(GstReportPeriod period) {
    final filing = GstFilingPeriod.fromMonth(period.month);
    return GstFilingWorkflowSnapshot.empty(
      periodMonth: period.month,
      quarterKey: filing.quarterKey,
      quarterLabel: '${filing.quarterLabel} ${filing.quarterRangeLabel}',
    );
  }

  GstQuarterFilingLedger _emptyQuarterLedger(GstReportPeriod period) {
    final filing = GstFilingPeriod.fromMonth(period.month);
    return GstQuarterFilingLedger(
      filing: filing,
      months: [
        for (final month in filing.quarterMonths)
          _emptyQuarterMonthLedger(month),
      ],
      quarterReturnStatus: GstFilingTaskStatus.empty(
        task: GstFilingTask.quarterReturnFiled,
        periodMonth: filing.quarterEndMonth,
        quarterKey: filing.quarterKey,
        quarterLabel: '${filing.quarterLabel} ${filing.quarterRangeLabel}',
      ),
      quarterTaxLiability: 0,
      quarterInvoiceCount: 0,
    );
  }

  GstQuarterFilingMonthLedger _emptyQuarterMonthLedger(DateTime month) {
    final filing = GstFilingPeriod.fromMonth(month);
    final quarterLabel = '${filing.quarterLabel} ${filing.quarterRangeLabel}';
    GstFilingTaskStatus status(GstFilingTask task) {
      return GstFilingTaskStatus.empty(
        task: task,
        periodMonth: filing.month,
        quarterKey: filing.quarterKey,
        quarterLabel: quarterLabel,
      );
    }

    return GstQuarterFilingMonthLedger(
      filing: filing,
      taxLiability: 0,
      invoiceCount: 0,
      b2bInvoiceCount: 0,
      b2bTaxLiability: 0,
      b2cInvoiceCount: 0,
      b2cTaxLiability: 0,
      monthlyPaymentStatus: status(GstFilingTask.monthlyTaxPayment),
      b2bIffStatus: status(GstFilingTask.b2bIffUpload),
      b2bReturnStatus: status(GstFilingTask.b2bReturnFiled),
      b2cReturnStatus: status(GstFilingTask.b2cReturnFiled),
    );
  }

  double _sum<T>(Iterable<T> rows, double Function(T row) selector) {
    return rows.fold<double>(0, (sum, row) => sum + selector(row));
  }
}

class _FilingTaskSnapshot {
  const _FilingTaskSnapshot({
    required this.amount,
    required this.invoiceCount,
  });

  final double amount;
  final int invoiceCount;
}
