import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import '../../../database/db/app_database.dart';
import '../../../logic/girvi/girvi_account_detail_controller.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../logic/girvi/girvi_settlement_statement_pdf_service.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../repositories/girvi/girvi_details_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';

part 'parts/girvi_account_detail_layout.dart';
part 'parts/girvi_account_detail_panels.dart';
part 'parts/girvi_account_detail_payment_history.dart';
part 'parts/girvi_account_detail_shared.dart';

class GirviAccountDetailScreen extends StatefulWidget {
  final int loanId;
  final VoidCallback onBack;

  const GirviAccountDetailScreen({
    super.key,
    required this.loanId,
    required this.onBack,
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

  bool _openingGirviReceipt = false;

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

  void _openInterestEntry() {
    final account = _controller.account;
    if (account == null) return;

    context.go(
      Uri(
        path: RoutePaths.girviInterest,
        queryParameters: {
          'ticketNo': account.loan.ticketNo,
          'returnTo': 'girviLedger',
        },
      ).toString(),
    );
  }

  Future<void> _previewGirviReceipt() async {
    final account = _controller.account;
    if (account == null || _openingGirviReceipt) return;

    setState(() => _openingGirviReceipt = true);
    try {
      final frontBytes = await _buildOriginalReceiptPdf(account);
      final backBytes = await GirviSettlementStatementPdfService().build(
        account: account,
        payments: _controller.payments,
      );
      if (!mounted) return;

      await _showFlippableReceiptPreview(
        title: 'Girvi Receipt',
        subtitle: '${account.loan.ticketNo} | ${account.customerName}',
        frontTitle: 'Front Side - Original Girvi Receipt',
        backTitle: 'Back Side - Payment Ledger and Status',
        frontFileName: 'girvi_receipt_${account.loan.ticketNo}.pdf',
        backFileName: 'girvi_receipt_ledger_${account.loan.ticketNo}.pdf',
        frontBytes: frontBytes,
        backBytes: backBytes,
      );
    } catch (_) {
      if (mounted) _showMessage('Girvi receipt could not be opened.');
    } finally {
      if (mounted) setState(() => _openingGirviReceipt = false);
    }
  }

  Future<Uint8List> _buildOriginalReceiptPdf(
    GirviLoanWithCustomer account,
  ) async {
    final draft =
        await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
      customerId: account.loan.customerId,
      loanId: account.loan.id,
    );
    if (draft == null) {
      throw StateError('Girvi invoice draft could not be loaded.');
    }

    final invoiceController = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await invoiceController.generatePreview();
      final bytes = invoiceController.pdfBytes;
      if (bytes == null) {
        throw StateError('Girvi invoice PDF could not be generated.');
      }
      return bytes;
    } finally {
      invoiceController.dispose();
    }
  }

  Future<void> _showFlippableReceiptPreview({
    required String title,
    required String subtitle,
    required String frontTitle,
    required String backTitle,
    required String frontFileName,
    required String backFileName,
    required Uint8List frontBytes,
    required Uint8List backBytes,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => _FlippablePdfPreviewDialog(
        title: title,
        subtitle: subtitle,
        frontTitle: frontTitle,
        backTitle: backTitle,
        frontFileName: frontFileName,
        backFileName: backFileName,
        frontBytes: frontBytes,
        backBytes: backBytes,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GirviColors.shellBg,
        behavior: SnackBarBehavior.floating,
      ),
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
    if (loan.girviStatus == GirviStatus.auctioned) return 'Auctioned';
    if (loan.girviStatus == GirviStatus.released) return 'Released';
    if (loan.isOverdue) return 'Overdue';
    return loan.statusLabel;
  }

  Color _accountStatusColor(GirviLoanWithCustomer account) {
    final status = account.loan.girviStatus;
    if (account.loan.deliveredAt != null) return GirviColors.success;
    if (status == GirviStatus.readyForDelivery) return GirviColors.success;
    if (status == GirviStatus.partialRelease) return GirviColors.warning;
    if (status == GirviStatus.auctioned) return GirviColors.statusAuctioned;
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
    return 'Collect / Settle';
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
        actions: [
          _AccountHeaderButton(
            tooltip: 'Refresh account',
            icon: GirviIcons.refresh,
            onTap: _reload,
          ),
        ],
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
