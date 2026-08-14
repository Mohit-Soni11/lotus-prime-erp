import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../data/gst_report_repository.dart';
import '../domain/gst_report_models.dart';

class GstReportController extends ChangeNotifier {
  GstReportController({
    GstReportRepository? repository,
    GstReportPeriod? initialPeriod,
    GstReportTab initialTab = GstReportTab.dashboard,
  })  : _repository = repository ?? GstReportRepository(),
        _period = initialPeriod ?? GstReportPeriod.currentMonth(),
        _selectedTab = initialTab {
    load();
  }

  final GstReportRepository _repository;

  GstReportPeriod _period;
  GstReportSnapshot? _snapshot;
  GstReportTab _selectedTab;
  bool _isLoading = true;
  String? _errorMessage;

  GstReportPeriod get period => _period;
  GstReportSnapshot? get snapshot => _snapshot;
  GstReportTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _snapshot = await _repository.fetch(_period);
      _errorMessage = null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'GstReportController.load failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _snapshot ??= GstReportSnapshot.empty(_period);
      _errorMessage = 'Unable to load GST report.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectTab(GstReportTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  void setReportMonth(DateTime month) {
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
}
