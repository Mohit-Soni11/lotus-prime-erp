import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import '../../../database/db/app_database.dart';
import '../../../logic/girvi/girvi_controllers.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'girvi_list_app_bar.dart';

part 'parts/girvi_ledger_controls.dart';
part 'parts/girvi_ledger_detail_panel.dart';
part 'parts/girvi_ledger_layout.dart';
part 'parts/girvi_ledger_overview.dart';
part 'parts/girvi_ledger_shared.dart';
part 'parts/girvi_ledger_ticket_list.dart';

class GirviListScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNewGirvi;

  const GirviListScreen({
    super.key,
    this.onBack,
    this.onNewGirvi,
  });

  @override
  State<GirviListScreen> createState() => _GirviListScreenState();
}

class _GirviListScreenState extends State<GirviListScreen>
    with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _searchController = TextEditingController();

  late final GirviListController _controller;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final NumberFormat _moneyFormat = NumberFormat('#,##,##0', 'en_IN');
  final NumberFormat _preciseMoneyFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  int? _selectedLoanId;
  bool _openingInvoicePdf = false;

  @override
  void initState() {
    super.initState();
    _controller = GirviListController(_db);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _searchController.addListener(
      _handleSearchChanged,
    );
    _loadLedger();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadLedger() async {
    _fadeController.reset();
    await _controller.load();
    if (!mounted) return;
    _syncSelectionWithVisibleTickets();
    _fadeController.forward();
  }

  Future<void> _reloadLedger() async {
    _fadeController.reset();
    await _controller.reload();
    if (!mounted) return;
    _syncSelectionWithVisibleTickets();
    _fadeController.forward();
  }

  void _handleSearchChanged() {
    _controller.onSearchChanged(_searchController.text);
    _syncSelectionWithVisibleTickets();
  }

  GirviLoanWithCustomer? get _selectedLoan {
    final loans = _controller.loans;
    if (loans.isEmpty) return null;

    final selectedId = _selectedLoanId;
    if (selectedId != null) {
      for (final item in loans) {
        if (item.loan.id == selectedId) return item;
      }
    }

    return loans.first;
  }

  bool _isSelected(GirviLoanWithCustomer item) {
    return _selectedLoan?.loan.id == item.loan.id;
  }

  void _selectLoan(GirviLoanWithCustomer item) {
    setState(() => _selectedLoanId = item.loan.id);
    unawaited(_controller.loadPaymentsForLoan(item.loan.id));
  }

  Future<void> _openTicketAccount(GirviLoanWithCustomer item) async {
    _selectLoan(item);
    if (!mounted) return;
    context.go(RoutePaths.girviAccountFor(item.loan.id));
  }

  void _setFilter(GirviFilter filter) {
    _controller.setFilter(filter);
    _syncSelectionWithVisibleTickets();
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _openNewGirvi() {
    widget.onNewGirvi?.call();
  }

  void _openInterestEntry(GirviLoanWithCustomer item) {
    final route = RouteMapper.toPath(AppRoutes.interestCalcRoute);
    final uri = Uri(
      path: route,
      queryParameters: {
        'ticketNo': item.loan.ticketNo,
        'returnTo': 'girviLedger',
      },
    );
    context.go(uri.toString());
  }

  Future<void> _previewGirviInvoicePdf(GirviLoanWithCustomer item) async {
    if (_openingInvoicePdf) return;
    setState(() => _openingInvoicePdf = true);
    try {
      final draft =
          await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
        customerId: item.loan.customerId,
        loanId: item.loan.id,
      );
      if (!mounted) return;
      if (draft == null) {
        _showLedgerMessage('Girvi invoice details could not be loaded.');
        return;
      }

      final controller = GirviInvoiceHubController(
        draft: draft,
        onFinalize: () async => true,
      );
      try {
        await controller.generatePreview();
        if (!mounted) return;

        final bytes = controller.pdfBytes;
        if (bytes == null) {
          _showLedgerMessage('Girvi invoice PDF could not be generated.');
          return;
        }

        await _showInvoicePdfPreview(
          ticketNo: item.loan.ticketNo,
          customerName: item.customerName,
          pdfBytes: bytes,
        );
      } finally {
        controller.dispose();
      }
    } catch (_) {
      if (mounted) {
        _showLedgerMessage('Girvi invoice preview could not be opened.');
      }
    } finally {
      if (mounted) setState(() => _openingInvoicePdf = false);
    }
  }

  Future<void> _showInvoicePdfPreview({
    required String ticketNo,
    required String customerName,
    required Uint8List pdfBytes,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Column(
          children: [
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GirviColors.brandGold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(
                      GirviIcons.print,
                      color: GirviColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Girvi Invoice PDF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$ticketNo | $customerName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                maxPageWidth: 860,
                pdfFileName: 'girvi_$ticketNo.pdf',
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLedgerMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GirviColors.shellBg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _syncSelectionWithVisibleTickets() {
    final visibleLoans = _controller.loans;
    if (visibleLoans.isEmpty) {
      if (_selectedLoanId != null) setState(() => _selectedLoanId = null);
      return;
    }

    final selectedStillVisible = visibleLoans.any(
      (item) => item.loan.id == _selectedLoanId,
    );
    final nextSelection =
        selectedStillVisible ? _selectedLoanId! : visibleLoans.first.loan.id;

    if (_selectedLoanId != nextSelection) {
      setState(() => _selectedLoanId = nextSelection);
    }
    unawaited(_controller.loadPaymentsForLoan(nextSelection));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviListAppBar(
        onBack: widget.onBack ?? () => Navigator.maybePop(context),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const _GirviLedgerLoadingState();
          }

          if (_controller.errorMessage != null) {
            return _GirviLedgerErrorState(
              message: _controller.errorMessage!,
              onRetry: _reloadLedger,
            );
          }

          return _buildLedgerBody();
        },
      ),
    );
  }
}
