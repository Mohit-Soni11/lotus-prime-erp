import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../logic/girvi/girvi_account_detail_controller.dart';
import '../../../logic/girvi/girvi_invoice_document_store.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../models/girvi/girvi_account_lifecycle_summary.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../repositories/girvi/girvi_details_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'parts/girvi_account_detail_layout.dart';
part 'parts/girvi_account_detail_panels.dart';
part 'parts/girvi_account_detail_payment_history.dart';
part 'parts/girvi_account_detail_shared.dart';
part 'parts/girvi_account_document_actions.dart';
part 'parts/girvi_account_documents_panel.dart';
part 'parts/girvi_account_lifecycle_widgets.dart';
part 'parts/girvi_account_pledged_photos.dart';
part 'parts/girvi_account_pledged_summary.dart';
part 'parts/girvi_account_pledged_specs.dart';
part 'parts/girvi_account_action_widgets.dart';
part 'parts/girvi_account_invoice_preview.dart';

class GirviAccountDetailScreen extends StatefulWidget {
  final int loanId;
  final VoidCallback onBack;
  final String? returnTo;

  const GirviAccountDetailScreen({
    super.key,
    required this.loanId,
    required this.onBack,
    this.returnTo,
  });

  @override
  State<GirviAccountDetailScreen> createState() =>
      _GirviAccountDetailScreenState();
}

class _GirviAccountDetailScreenState extends State<GirviAccountDetailScreen> {
  final AppDatabase _db = AppDatabase();
  late final GirviAccountDetailController _controller;

  final NumberFormat _moneyFormat = NumberFormat('#,##,##0', 'en_IN');
  final NumberFormat _preciseMoneyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  bool _openingGirviInvoice = false;
  bool _printingGirviInvoice = false;

  @override
  void initState() {
    super.initState();
    _controller = GirviAccountDetailController(_db)..load(widget.loanId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() => _controller.load(widget.loanId);

  void _setOpeningGirviInvoice(bool value) {
    if (mounted) setState(() => _openingGirviInvoice = value);
  }

  void _setPrintingGirviInvoice(bool value) {
    if (mounted) setState(() => _printingGirviInvoice = value);
  }

  void _openInterestEntry() {
    final account = _controller.account;
    if (account == null) return;

    context.go(
      Uri(
        path: RoutePaths.girviInterest,
        queryParameters: {
          'ticketNo': account.loan.ticketNo,
          'returnTo': widget.returnTo == 'riskCollections' ||
                  widget.returnTo == 'girviNotice'
              ? widget.returnTo!
              : 'girviLedger',
        },
      ).toString(),
    );
  }

  String _safePdfName(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  }

  void _showMessage(String message) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
    );
  }

  String _money(double value, {bool precise = false}) {
    final format = precise ? _preciseMoneyFormat : _moneyFormat;
    return 'Rs ${format.format(value)}';
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not set';
    return _dateFormat.format(value);
  }

  String _dateTime(DateTime? value) {
    if (value == null) return 'Not set';
    return _dateTimeFormat.format(value);
  }

  String _weight(double value) => '${value.toStringAsFixed(2)} g';

  String _accountStatusLabel(GirviLoanWithCustomer account) {
    final loan = account.loan;
    if (loan.deliveredAt != null) return 'Delivered and Closed';
    if (loan.girviStatus == GirviStatus.readyForDelivery) {
      return 'Settlement Complete - Delivery Pending';
    }
    if (loan.girviStatus == GirviStatus.partialRelease) {
      return 'Settlement Pending';
    }
    if (loan.girviStatus == GirviStatus.auctioned) return 'Closed';
    if (loan.girviStatus == GirviStatus.released) return 'Released';
    if (loan.isOverdue) return 'Overdue';
    return loan.statusLabel;
  }

  Color _accountStatusColor(GirviLoanWithCustomer account) {
    final status = account.loan.girviStatus;
    if (account.loan.deliveredAt != null) return GirviColors.success;
    if (status == GirviStatus.readyForDelivery) return GirviColors.success;
    if (status == GirviStatus.partialRelease) return GirviColors.warning;
    if (status == GirviStatus.auctioned) return GirviColors.textMuted;
    if (account.loan.isOverdue) return GirviColors.danger;
    return account.loan.statusColor;
  }

  bool _canOpenSettlementAction(GirviLoanWithCustomer account) {
    final status = account.loan.girviStatus;
    return status == GirviStatus.active ||
        status == GirviStatus.overdue ||
        status == GirviStatus.partialRelease ||
        status == GirviStatus.readyForDelivery;
  }

  String _settlementActionLabel(GirviLoanWithCustomer account) {
    if (account.loan.girviStatus == GirviStatus.readyForDelivery) {
      return 'Complete Delivery';
    }
    if (account.totalPayable > 0) return 'Collect Outstanding';
    return 'Settle Account';
  }

  String? _paymentCoverageLabel(GirviPaymentModel payment) {
    final from = payment.interestFromDate;
    final to = payment.interestToDate;
    if (from != null && to != null) {
      return '${_date(from)} to ${_date(to)}';
    }

    final months = payment.monthsCovered ?? 0;
    if (months > 0) return '$months month${months == 1 ? '' : 's'} covered';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviAppBar(
        screenTitle: 'GIRVI ACCOUNT',
        screenSubtitle: 'Ticket statement',
        onBack: widget.onBack,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const _AccountLoadingState();
          }

          if (_controller.errorMessage != null) {
            return _AccountErrorState(
              message: _controller.errorMessage!,
              onRetry: _reload,
              onBack: widget.onBack,
            );
          }

          final account = _controller.account;
          if (account == null) {
            return _AccountErrorState(
              message: 'Girvi account could not be found.',
              onRetry: _reload,
              onBack: widget.onBack,
            );
          }

          return _buildAccountDetailBody(account);
        },
      ),
    );
  }
}
