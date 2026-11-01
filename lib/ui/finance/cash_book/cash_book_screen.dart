import 'package:flutter/material.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import '../../shared/system_status_badge.dart';
import 'cash_book_app_bar.dart';
import 'cash_book_body.dart';
import 'cash_book_entry_dialog.dart';

class CashBookScreen extends StatefulWidget {
  const CashBookScreen({super.key});

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends State<CashBookScreen> {
  late final CashBookController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CashBookController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.syncTodaysBills();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _showAddEntryDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => CashBookEntryDialog(ctrl: _ctrl),
    );
  }

  Future<void> _syncBills() async {
    await _ctrl.syncTodaysBills();
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.success,
      message: CashBookStrings.syncSuccess,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) => Scaffold(
        backgroundColor: CashBookColors.bodyBg,
        appBar: CashBookAppBar(
          onBack: () => Navigator.of(context).maybePop(),
          status: _ctrl.isLoading
              ? SystemStatus.loading
              : _ctrl.errorMessage != null
                  ? SystemStatus.unavailable
                  : SystemStatus.online,
          onAddEntry: _showAddEntryDialog,
          onSyncBills: _syncBills,
        ),
        body: SafeArea(
          child: CashBookBody(ctrl: _ctrl, onAddEntry: _showAddEntryDialog),
        ),
      ),
    );
  }
}
