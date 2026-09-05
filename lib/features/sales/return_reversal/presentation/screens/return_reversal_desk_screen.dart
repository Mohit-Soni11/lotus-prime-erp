import 'package:flutter/material.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/data/repositories/return_reversal_drift_repository.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/body/return_reversal_desk_body.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/theme/return_reversal_design_tokens.dart';
import 'package:lotus_erp/ui/shared/lotus_module_app_bar.dart';

class ReturnReversalDeskScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ReturnReversalController? controller;

  const ReturnReversalDeskScreen({
    super.key,
    required this.onBack,
    this.controller,
  });

  @override
  State<ReturnReversalDeskScreen> createState() =>
      _ReturnReversalDeskScreenState();
}

class _ReturnReversalDeskScreenState extends State<ReturnReversalDeskScreen> {
  late final ReturnReversalController _controller;
  late final bool _ownsController;
  String? _announcedVoucherNo;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        ReturnReversalController(
          repository: ReturnReversalDriftRepository(AppDatabase()),
        );
    _controller.addListener(_rebuild);
    if (_ownsController) {
      _controller.load();
    }
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
      _announcePostedVoucherIfNeeded();
    }
  }

  void _announcePostedVoucherIfNeeded() {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final result = _controller.state.lastProcessResult;
    if (result == null || result.voucherNo == _announcedVoucherNo) {
      return;
    }
    _announcedVoucherNo = result.voucherNo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final isCancellation =
          _controller.state.operationType.isBookingCancellation;
      AppFeedback.success(
        context,
        title: isCancellation ? 'Cancellation Posted' : 'Return Posted',
        message: _controller.state.processMessage ??
            '${result.voucherNo} posted successfully.',
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReturnReversalDesignTokens.background,
      appBar: LotusModuleAppBar(
        onBack: widget.onBack,
        icon: Icons.assignment_return_rounded,
        title: AppRoutes.getTitle(AppRoutes.salesReturnExchangeRoute),
      ),
      body: SafeArea(
        top: false,
        child: ReturnReversalDeskBody(controller: _controller),
      ),
    );
  }
}
