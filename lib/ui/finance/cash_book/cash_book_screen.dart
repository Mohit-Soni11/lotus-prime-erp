import 'package:flutter/material.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../logic/finance/cash_book/cash_book_export_service.dart';
import '../../../logic/finance/cash_book/cash_book_history_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import '../../shared/system_status_badge.dart';
import 'cash_book_add_entry_button.dart';
import 'cash_book_app_bar.dart';
import 'cash_book_body.dart';
import 'cash_book_entry_dialog.dart';

class CashBookScreen extends StatefulWidget {
  const CashBookScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends State<CashBookScreen> {
  late final CashBookController _ctrl;
  late final CashBookHistoryController _history;
  late final Listenable _screenState;

  @override
  void initState() {
    super.initState();
    _ctrl = CashBookController();
    _history = CashBookHistoryController();
    _screenState = Listenable.merge([_ctrl, _history]);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _history.dispose();
    super.dispose();
  }

  void _showAddEntryDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => CashBookEntryDialog(ctrl: _ctrl),
    );
  }

  void _goHome() {
    _history.showDaily();
    _ctrl.setFilter(CashBookFilter.all);
    _ctrl.selectDate(DateTime.now());
  }

  void _handleBack() {
    if (_history.view == CashBookHistoryView.daily) {
      widget.onBack();
    } else {
      _goHome();
    }
  }

  Future<void> _exportCsv() async {
    try {
      final path = await CashBookExportService.exportCsv(_ctrl.exportData);
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash Book CSV exported.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash Book export failed.')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    try {
      await CashBookExportService.printPdf(_ctrl.exportData);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash Book PDF could not be opened.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _screenState,
      builder: (context, _) => Scaffold(
        backgroundColor: CashBookColors.bodyBg,
        appBar: CashBookAppBar(
          onBack: _handleBack,
          onHome: _goHome,
          showHomeAction: _history.view != CashBookHistoryView.daily,
          onExportCsv: _history.view != CashBookHistoryView.daily ||
                  _ctrl.isLoading ||
                  _ctrl.errorMessage != null
              ? null
              : _exportCsv,
          onPrintPdf: _history.view != CashBookHistoryView.daily ||
                  _ctrl.isLoading ||
                  _ctrl.errorMessage != null
              ? null
              : _printPdf,
          status: (_history.view == CashBookHistoryView.daily
                  ? _ctrl.isLoading
                  : _history.isLoading)
              ? SystemStatus.loading
              : (_history.view == CashBookHistoryView.daily
                          ? _ctrl.errorMessage
                          : _history.errorMessage) !=
                      null
                  ? SystemStatus.unavailable
                  : SystemStatus.online,
        ),
        body: SafeArea(
          child: CashBookBody(
            ctrl: _ctrl,
            history: _history,
          ),
        ),
        floatingActionButton: CashBookAddEntryButton(
          onPressed: _showAddEntryDialog,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
