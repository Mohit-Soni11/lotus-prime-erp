// =============================================================================
// FILE        : interest_calc_screen.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Screen
// DESCRIPTION : Interest Entry workspace for recording running girvi payments.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../database/db/app_database.dart';
import '../../../core/router/app_router.dart';
import '../../../logic/girvi/girvi_controllers.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';

class InterestCalcScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const InterestCalcScreen({
    super.key,
    this.onBack,
  });

  @override
  State<InterestCalcScreen> createState() => _InterestCalcScreenState();
}

class _InterestCalcScreenState extends State<InterestCalcScreen>
    with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  late final GirviInterestEntryController _ctrl;

  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _releasePrincipalCtrl = TextEditingController();
  final _releaseInterestCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  final _moneyFmt = NumberFormat('#,##,##0', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');
  bool _syncingText = false;
  bool _openingReceipt = false;

  @override
  void initState() {
    super.initState();
    _ctrl = GirviInterestEntryController(_db)..addListener(_syncFields);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);

    _searchCtrl.addListener(() => _ctrl.onSearchChanged(_searchCtrl.text));
    _amountCtrl.addListener(() {
      if (!_syncingText) _ctrl.onAmountChanged(_amountCtrl.text);
    });
    _releasePrincipalCtrl.addListener(() {
      if (!_syncingText) {
        _ctrl.onReleasePrincipalChanged(_releasePrincipalCtrl.text);
      }
    });
    _releaseInterestCtrl.addListener(() {
      if (!_syncingText) {
        _ctrl.onReleaseInterestChanged(_releaseInterestCtrl.text);
      }
    });
    _monthsCtrl.addListener(() {
      if (!_syncingText) _ctrl.onMonthsChanged(_monthsCtrl.text);
    });
    _receiptCtrl.addListener(() {
      if (!_syncingText) _ctrl.onReceiptChanged(_receiptCtrl.text);
    });
    _notesCtrl.addListener(() {
      if (!_syncingText) _ctrl.onNotesChanged(_notesCtrl.text);
    });

    _ctrl.load().then((_) {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_syncFields);
    _ctrl.dispose();
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    _releasePrincipalCtrl.dispose();
    _releaseInterestCtrl.dispose();
    _monthsCtrl.dispose();
    _receiptCtrl.dispose();
    _notesCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _syncFields() {
    _syncingText = true;
    _setText(_amountCtrl, _ctrl.amountInput);
    _setText(_releasePrincipalCtrl, _ctrl.releasePrincipalInput);
    _setText(_releaseInterestCtrl, _ctrl.releaseInterestInput);
    _setText(_monthsCtrl, _ctrl.monthsInput);
    _setText(_receiptCtrl, _ctrl.receiptNo);
    _setText(_notesCtrl, _ctrl.notes);
    _syncingText = false;
  }

  void _setText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _handleBack() async {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    await Navigator.of(context).maybePop();
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: GirviColors.brandGold,
              onPrimary: GirviColors.shellBg,
              surface: GirviColors.cardBg,
              onSurface: GirviColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _recordPayment() async {
    final ok = await _ctrl.recordPayment();
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_ctrl.successMessage ?? 'Payment entry recorded.'),
        backgroundColor: GirviColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openNoticeAuction() {
    context.go(RoutePaths.girviNotice);
  }

  void _setPaymentAmount(double value) {
    final nextValue = _formatEntryAmountInput(value);
    _syncingText = true;
    _setText(_amountCtrl, nextValue);
    _syncingText = false;
    _ctrl.onAmountChanged(nextValue);
  }

  void _fillFullSettlement() {
    final principal =
        _formatEntryAmountInput(_ctrl.releasePrincipalDueForSelected);
    final interest = _formatEntryAmountInput(_ctrl.netInterestDueForSelected);
    _syncingText = true;
    _setText(_releasePrincipalCtrl, principal);
    _setText(_releaseInterestCtrl, interest);
    _syncingText = false;
    _ctrl.onReleasePrincipalChanged(principal);
    _ctrl.onReleaseInterestChanged(interest);
  }

  String _formatEntryAmountInput(double value) {
    if (value <= 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<void> _previewGirviReceipt(GirviLoanWithCustomer data) async {
    if (_openingReceipt) return;
    setState(() => _openingReceipt = true);
    try {
      final draft =
          await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
        customerId: data.loan.customerId,
        loanId: data.loan.id,
      );
      if (!mounted) return;
      if (draft == null) {
        _showInfoSnack('Girvi receipt details could not be loaded.');
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
          _showInfoSnack('Girvi receipt PDF could not be generated.');
          return;
        }
        await _showReceiptPreview(pdfBytes: bytes);
      } finally {
        controller.dispose();
      }
    } catch (error) {
      if (mounted) {
        _showInfoSnack('Girvi receipt preview could not be opened.');
      }
    } finally {
      if (mounted) setState(() => _openingReceipt = false);
    }
  }

  void _showInfoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GirviColors.shellBg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showReceiptPreview({required Uint8List pdfBytes}) async {
    final sides = await _rasterReceiptSides(pdfBytes);
    if (!mounted) return;
    if (sides.isEmpty) {
      return _showCleanReceiptPreview(pdfBytes: pdfBytes);
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Material(
        type: MaterialType.transparency,
        child: _GirviReceiptFlipPreview(
          sides: sides,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<List<PdfRaster>> _rasterReceiptSides(Uint8List pdfBytes) async {
    try {
      final info = await Printing.info();
      if (!info.canRaster) return const [];

      final sides = <PdfRaster>[];
      await for (final page in Printing.raster(pdfBytes, dpi: 144)) {
        sides.add(page);
        if (sides.length == 2) break;
      }
      return List.unmodifiable(sides);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _showCleanReceiptPreview({required Uint8List pdfBytes}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.74),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: false,
                maxPageWidth: 860,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviAppBar(
        screenTitle: GirviStrings.calcTitle,
        screenSubtitle: GirviStrings.calcSub,
        onBack: _handleBack,
        actions: [
          _HeaderIconButton(
            tooltip: 'Refresh entries',
            icon: GirviIcons.refresh,
            onTap: _ctrl.refresh,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: GirviColors.brandGold),
            );
          }

          return FadeTransition(
            opacity: _fade,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1180;
                final bodyHeight =
                    (constraints.maxHeight - 32).clamp(420, 1200);

                if (!isWide) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: GirviStyles.pagePadding,
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SizedBox(
                              height: 460,
                              child: _buildLoanPanel(),
                            ),
                            const SizedBox(height: 16),
                            _buildWorkspace(shrink: true),
                          ]),
                        ),
                      ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 410,
                        height: bodyHeight.toDouble(),
                        child: _buildLoanPanel(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: bodyHeight.toDouble(),
                          child: _buildWorkspace(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanPanel() {
    return Container(
      decoration: GirviStyles.card,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const _IconBox(
                    icon: GirviIcons.ticket, color: GirviColors.brandGold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Girvi Book',
                          style: GirviStyles.sectionTitle),
                      const SizedBox(height: 2),
                      Text(
                        '${_ctrl.openCustomerCount} customer${_ctrl.openCustomerCount == 1 ? '' : 's'} | ${_ctrl.openTicketCount} open ticket${_ctrl.openTicketCount == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountBadge(value: _ctrl.customerAccounts.length.toString()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: _SearchField(
              controller: _searchCtrl,
              hintText: 'Search customer, mobile, ticket or item',
            ),
          ),
          Expanded(
            child: _ctrl.customerAccounts.isEmpty
                ? _EmptyState(
                    icon: GirviIcons.search,
                    title: _ctrl.hasCustomerAccounts
                        ? 'No Matching Customer'
                        : 'No Open Girvi Customer',
                    message: _ctrl.hasCustomerAccounts
                        ? 'Adjust the search text to find the correct customer or ticket.'
                        : 'Create a girvi ticket first, then record payments here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _ctrl.customerAccounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final account = _ctrl.customerAccounts[index];
                      final selected =
                          account.customerId == _ctrl.selectedCustomerId;
                      return _CustomerGirviCard(
                        account: account,
                        selected: selected,
                        moneyFmt: _moneyFmt,
                        dateFmt: _dateFmt,
                        onCustomerTap: () =>
                            _ctrl.selectCustomerAccount(account),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace({bool shrink = false}) {
    final selected = _ctrl.selectedLoan;
    final selectedCustomer = _ctrl.selectedCustomerAccount;
    final content = selectedCustomer == null
        ? [
            const _EmptyState(
              icon: GirviIcons.customer,
              title: 'Select a Customer',
              message:
                  'Choose one customer from the left to view all open Girvi bills.',
              large: true,
            ),
          ]
        : selected == null
            ? [
                _CustomerReadyPanel(
                  account: selectedCustomer,
                  moneyFmt: _moneyFmt,
                  selectedLoanId: null,
                  onLoanTap: _ctrl.selectLoan,
                ),
                const SizedBox(height: 14),
                const _EmptyState(
                  icon: GirviIcons.ticket,
                  title: 'Select a Girvi Bill',
                  message:
                      'Open the exact bill from the list above to record interest or principal collection.',
                ),
              ]
            : [
                _buildSelectedSummary(selected),
                const SizedBox(height: 14),
                if (_ctrl.errorMessage != null) ...[
                  GirviErrorBanner(message: _ctrl.errorMessage!),
                  const SizedBox(height: 12),
                ],
                if (_ctrl.successMessage != null) ...[
                  _SuccessBanner(message: _ctrl.successMessage!),
                  const SizedBox(height: 12),
                ],
                _buildPaymentForm(selected),
                const SizedBox(height: 14),
                _buildPaymentHistory(),
                const SizedBox(height: 28),
              ];

    if (shrink) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: content,
    );
  }

  Widget _buildSelectedSummary(GirviLoanWithCustomer data) {
    final loan = data.loan;
    final principalDisbursed = _ctrl.principalDisbursedForSelected;
    final principalRepaid = _ctrl.principalRepaidForSelected +
        _ctrl.releasePrincipalCollectedForSelected;
    final interestCollected = _ctrl.interestCollectedForSelected;
    final totalCollected = _ctrl.totalCollectedForSelected;
    final grossInterestAccrued = _ctrl.grossInterestAccruedForSelected;
    final netInterestDue = _ctrl.netInterestDueForSelected;
    final advanceInterestCredit = _ctrl.advanceInterestCreditForSelected;
    final settlementComplete =
        loan.girviStatus == GirviStatus.readyForDelivery ||
            loan.girviStatus == GirviStatus.released;
    final currentMonthlyInterest =
        _ctrl.currentLedgerMonthlyInterestForSelected;
    final totalPayable = _ctrl.releasePrincipalDueForSelected + netInterestDue;
    final totalMonths = loan.monthsElapsed.ceil();
    final interestBreakdown = GirviLoanModel.calculateCompoundInterestBreakdown(
      principal: principalDisbursed,
      monthlyRatePercent: loan.interestRate,
      months: loan.monthsElapsed.ceil(),
    );
    final elapsedPeriod = GirviLoanModel.elapsedPeriodBetween(
      loan.startDate,
      loan.releaseDate ?? DateTime.now(),
    );
    final advanceMonths =
        advanceInterestCredit <= 0 || currentMonthlyInterest <= 0
            ? 0
            : (advanceInterestCredit / currentMonthlyInterest).floor();
    final principalProgress = principalDisbursed <= 0
        ? 0.0
        : (principalRepaid / principalDisbursed).clamp(0.0, 1.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GirviColors.cardBg,
            GirviColors.brandGold.withValues(alpha: 0.055),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GirviColors.brandGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: GirviColors.brandGold.withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  GirviIcons.ticket,
                  color: GirviColors.brandGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Overview',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      loan.ticketNo,
                      style: GoogleFonts.robotoMono(
                        color: GirviColors.brandGold,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data.customerName}  |  ${data.customerMobile}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        loan.itemSummary,
                        if ((data.customerCity ?? '').trim().isNotEmpty)
                          data.customerCity!.trim(),
                      ].join('  |  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusPill(
                        label: loan.statusLabel, color: loan.statusColor),
                    const SizedBox(height: 8),
                    _OverviewActionButton(
                      label: 'Change Bill',
                      icon: Icons.swap_horiz_rounded,
                      busy: false,
                      onTap: _ctrl.showBillSelectionForSelectedCustomer,
                    ),
                    const SizedBox(height: 8),
                    _OverviewActionButton(
                      label: _openingReceipt ? 'Opening...' : 'View Receipt',
                      icon: Icons.visibility_rounded,
                      busy: _openingReceipt,
                      onTap: () => _previewGirviReceipt(data),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CollectionFocusStrip(
            interestDue: netInterestDue,
            monthlyInterest: currentMonthlyInterest,
            totalPayable: totalPayable,
            unpaidMonths: totalMonths,
            advanceAmount: advanceInterestCredit,
            advanceMonths: advanceMonths,
            settlementComplete: settlementComplete,
            isOverdue: loan.isOverdue,
            moneyFmt: _moneyFmt,
          ),
          if (interestBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InterestBreakdownPanel(
              lines: interestBreakdown,
              totalMonths: totalMonths,
              elapsedPeriod: elapsedPeriod,
              totalInterest: grossInterestAccrued,
              moneyFmt: _moneyFmt,
            ),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 960;
              final principalPanel = _OverviewMoneyPanel(
                title: 'Principal',
                primaryLabel: 'Principal Amount',
                primaryValue: 'Rs ${_moneyFmt.format(principalDisbursed)}',
                secondaryLabel: 'Outstanding Balance',
                secondaryValue:
                    'Rs ${_moneyFmt.format(_ctrl.releasePrincipalDueForSelected)}',
                tertiaryLabel: principalRepaid > 0 ? 'Principal Repaid' : null,
                tertiaryValue: principalRepaid > 0
                    ? 'Rs ${_moneyFmt.format(principalRepaid)}'
                    : null,
                icon: GirviIcons.loanTerms,
                color: GirviColors.purple,
                progress: principalRepaid > 0 ? principalProgress : null,
              );

              final interestPanel = _OverviewMoneyPanel(
                title: 'Interest',
                primaryLabel: 'Due Now',
                primaryValue: 'Rs ${_moneyFmt.format(netInterestDue)}',
                secondaryLabel: advanceInterestCredit > 0
                    ? settlementComplete
                        ? 'Excess Received'
                        : 'Advance Credit'
                    : 'Gross Interest',
                secondaryValue: advanceInterestCredit > 0
                    ? 'Rs ${_moneyFmt.format(advanceInterestCredit)}'
                    : 'Rs ${_moneyFmt.format(grossInterestAccrued)}',
                tertiaryLabel: 'Interest Paid',
                tertiaryValue: 'Rs ${_moneyFmt.format(interestCollected)}',
                icon: GirviIcons.interestRate,
                color: advanceInterestCredit > 0
                    ? settlementComplete
                        ? GirviColors.danger
                        : GirviColors.success
                    : GirviColors.warning,
              );

              final termsPanel = _OverviewTermsPanel(
                tenure: '${loan.durationMonths} months',
                startDate: _dateFmt.format(loan.startDate),
                maturityDate: loan.maturityDate == null
                    ? 'Not set'
                    : _dateFmt.format(loan.maturityDate!),
                paidTill: 'Rs ${_moneyFmt.format(interestCollected)}',
                totalCollected: 'Rs ${_moneyFmt.format(totalCollected)}',
              );

              if (compact) {
                return Column(
                  children: [
                    principalPanel,
                    const SizedBox(height: 12),
                    interestPanel,
                    const SizedBox(height: 12),
                    termsPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: principalPanel),
                  const SizedBox(width: 12),
                  Expanded(child: interestPanel),
                  const SizedBox(width: 12),
                  Expanded(child: termsPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(GirviLoanWithCustomer data) {
    return GirviSectionCard(
      icon: GirviIcons.cash,
      title: 'Payment Entry',
      subtitle: 'Record verified collections against the selected ticket',
      accent: GirviColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Payment Type', style: GirviStyles.fieldLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._ctrl.entryPaymentTypes.map((type) {
                return _SelectablePill(
                  label: type.displayName,
                  selected: _ctrl.paymentType == type,
                  icon: _iconForPaymentType(type),
                  color: _colorForPaymentType(type),
                  onTap: () => _ctrl.setPaymentType(type),
                );
              }),
              _WorkflowActionPill(
                label: 'Notice / Auction',
                icon: GirviIcons.auctioned,
                color: GirviColors.danger,
                onTap: _openNoticeAuction,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_ctrl.isReadyForDelivery)
            _ReadyForDeliveryPanel(
              expectedDeliveryDate: data.loan.expectedDeliveryDate,
              principalCollected: _ctrl.principalRepaidForSelected +
                  _ctrl.releasePrincipalCollectedForSelected,
              interestCollected: _ctrl.interestCollectedForSelected,
              moneyFmt: _moneyFmt,
              dateFmt: _dateFmt,
              isSaving: _ctrl.isSaving,
              onDeliver: _recordPayment,
            )
          else ...[
            if (_ctrl.isInterestEntry)
              GirviRowTwo(
                left: GirviInputField(
                  label: 'Amount Received',
                  hint: '0',
                  icon: GirviIcons.cash,
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  prefixText: 'Rs ',
                ),
                right: GirviInputField(
                  label: 'Equivalent Months',
                  hint: '1',
                  icon: GirviIcons.dates,
                  controller: _monthsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffixText: 'mo',
                ),
              )
            else
              GirviRowTwo(
                left: GirviInputField(
                  label: 'Principal Amount Received',
                  hint: '0',
                  icon: GirviIcons.loanTerms,
                  controller: _releasePrincipalCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  prefixText: 'Rs ',
                ),
                right: GirviInputField(
                  label: 'Interest Amount Received',
                  hint: '0',
                  icon: GirviIcons.interestRate,
                  controller: _releaseInterestCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  prefixText: 'Rs ',
                ),
              ),
            const SizedBox(height: 10),
            if (_ctrl.isInterestEntry)
              _AmountShortcutRail(
                paymentType: _ctrl.paymentType,
                isInterestEntry: true,
                interestDue: _ctrl.netInterestDueForSelected,
                monthlyInterest: _ctrl.currentLedgerMonthlyInterestForSelected,
                principalOutstanding: data.loan.loanAmount,
                expectedInterest: _ctrl.expectedInterest,
                moneyFmt: _moneyFmt,
                onPick: _setPaymentAmount,
              )
            else
              _ReleaseSettlementBalanceStrip(
                principalDue: _ctrl.releasePrincipalDueForSelected,
                interestDue: _ctrl.netInterestDueForSelected,
                principalCollected: _ctrl.releasePrincipalCollectedForSelected,
                interestCollected: _ctrl.releaseInterestCollectedForSelected,
                moneyFmt: _moneyFmt,
                onFillFull: _fillFullSettlement,
              ),
            if (_ctrl.isInterestEntry) ...[
              const SizedBox(height: 10),
              _InterestLedgerBalanceStrip(
                grossInterest: _ctrl.grossInterestAccruedForSelected,
                interestPaid: _ctrl.interestCollectedForSelected,
                netDue: _ctrl.netInterestDueForSelected,
                equivalentMonths: _ctrl.interestMonthsCoveredByAmount,
                moneyFmt: _moneyFmt,
              ),
            ],
            const SizedBox(height: 14),
            GirviRowTwo(
              left: _DateField(
                label: 'Collection Date',
                value: _dateFmt.format(_ctrl.paymentDate),
                icon: GirviIcons.dates,
                onTap: () => _pickDate(
                  initialDate: _ctrl.paymentDate,
                  onPicked: _ctrl.setPaymentDate,
                ),
              ),
              right: GirviInputField(
                label: 'Receipt Number',
                hint: 'Auto generated',
                icon: GirviIcons.ticket,
                controller: _receiptCtrl,
              ),
            ),
            if (!_ctrl.isInterestEntry) ...[
              const SizedBox(height: 14),
              _DateField(
                label: 'Expected Settlement / Pickup Date',
                value: _dateFmt.format(_ctrl.expectedDeliveryDate),
                icon: GirviIcons.dates,
                onTap: () => _pickDate(
                  initialDate: _ctrl.expectedDeliveryDate,
                  onPicked: _ctrl.setExpectedDeliveryDate,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text('Payment Mode', style: GirviStyles.fieldLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: GirviPaymentMode.values.map((mode) {
                return _SelectablePill(
                  label: mode.displayName,
                  selected: _ctrl.paymentMode == mode,
                  icon: _iconForPaymentMode(mode),
                  color: GirviColors.brandGold,
                  onTap: () => _ctrl.setPaymentMode(mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            GirviInputField(
              label: 'Internal Notes',
              hint: 'Optional remarks for audit trail',
              icon: GirviIcons.notes,
              controller: _notesCtrl,
              minLines: 2,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 18),
            _EntryReviewBar(
              enteredAmount: _ctrl.isInterestEntry
                  ? _ctrl.amount
                  : _ctrl.releaseEntryTotal,
              paymentType: _ctrl.paymentType,
              interestDue: _ctrl.netInterestDueForSelected,
              principalOutstanding: _ctrl.releasePrincipalDueForSelected,
              moneyFmt: _moneyFmt,
              isSaving: _ctrl.isSaving,
              actionLabel: _ctrl.isInterestEntry
                  ? 'Record Interest Payment'
                  : _ctrl.releaseEntryTotal + 0.01 >=
                          _ctrl.releaseTotalDueForSelected
                      ? 'Complete Settlement'
                      : 'Record Partial Settlement',
              actionIcon:
                  _ctrl.isInterestEntry ? GirviIcons.save : GirviIcons.release,
              onRecord: _recordPayment,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return GirviSectionCard(
      icon: GirviIcons.list,
      title: 'Payment History',
      subtitle:
          '${_ctrl.payments.length} receipt${_ctrl.payments.length == 1 ? '' : 's'} recorded for this ticket',
      accent: GirviColors.info,
      child: _ctrl.payments.isEmpty
          ? const _EmptyState(
              icon: GirviIcons.list,
              title: 'No Payment Recorded',
              message: 'The first entry for this ticket will appear here.',
            )
          : Column(
              children: _ctrl.payments.map((payment) {
                return _PaymentHistoryRow(
                  payment: payment,
                  moneyFmt: _moneyFmt,
                  dateFmt: _dateFmt,
                );
              }).toList(),
            ),
    );
  }

  IconData _iconForPaymentType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
      case GirviPaymentType.partialInterest:
        return GirviIcons.interestRate;
      case GirviPaymentType.partialPrincipal:
        return GirviIcons.loanTerms;
      case GirviPaymentType.penalty:
        return GirviIcons.warning;
      case GirviPaymentType.fullRelease:
        return GirviIcons.release;
    }
  }

  Color _colorForPaymentType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
        return GirviColors.success;
      case GirviPaymentType.partialInterest:
        return GirviColors.warning;
      case GirviPaymentType.partialPrincipal:
        return GirviColors.purple;
      case GirviPaymentType.penalty:
        return GirviColors.danger;
      case GirviPaymentType.fullRelease:
        return GirviColors.info;
    }
  }

  IconData _iconForPaymentMode(GirviPaymentMode mode) {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      case GirviPaymentMode.neft:
      case GirviPaymentMode.bankTransfer:
      case GirviPaymentMode.cheque:
        return GirviIcons.bank;
    }
  }
}

class _GirviReceiptFlipPreview extends StatefulWidget {
  const _GirviReceiptFlipPreview({
    required this.sides,
    required this.onClose,
  });

  final List<PdfRaster> sides;
  final VoidCallback onClose;

  @override
  State<_GirviReceiptFlipPreview> createState() =>
      _GirviReceiptFlipPreviewState();
}

class _GirviReceiptFlipPreviewState extends State<_GirviReceiptFlipPreview>
    with SingleTickerProviderStateMixin {
  static const double _minZoom = 0.70;
  static const double _maxZoom = 4.0;

  late final AnimationController _flipController;
  late final TransformationController _viewController;
  DateTime? _lastPointerDownAt;
  Offset? _lastPointerDownPosition;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _viewController = TransformationController();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _viewController.dispose();
    super.dispose();
  }

  void _toggleSide() {
    if (widget.sides.length < 2 || _flipController.isAnimating) return;
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final lastAt = _lastPointerDownAt;
    final lastPosition = _lastPointerDownPosition;
    final isDoubleClick = lastAt != null &&
        now.difference(lastAt) <= const Duration(milliseconds: 360) &&
        lastPosition != null &&
        (event.position - lastPosition).distance <= 16;

    _lastPointerDownAt = now;
    _lastPointerDownPosition = event.position;

    if (isDoubleClick) {
      _lastPointerDownAt = null;
      _lastPointerDownPosition = null;
      _toggleSide();
    }
  }

  void _zoomBy(double factor) {
    final currentScale = _viewController.value.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    final nextScale =
        (currentScale * factor).clamp(_minZoom, _maxZoom).toDouble();
    if ((nextScale - currentScale).abs() < 0.01) return;
    _viewController.value = _viewController.value.clone()
      ..scale(nextScale / currentScale);
  }

  void _resetZoom() {
    _viewController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF111827)),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final firstSide = widget.sides.first;
                final aspectRatio = firstSide.width / firstSide.height;
                return Listener(
                  onPointerDown: _handlePointerDown,
                  child: InteractiveViewer(
                    transformationController: _viewController,
                    minScale: _minZoom,
                    maxScale: _maxZoom,
                    scaleFactor: 160,
                    trackpadScrollCausesScale: true,
                    boundaryMargin: const EdgeInsets.all(320),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              math.min(constraints.maxWidth * 0.94, 1180.0),
                          maxHeight: constraints.maxHeight * 0.94,
                        ),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: MouseRegion(
                            cursor: widget.sides.length > 1
                                ? SystemMouseCursors.click
                                : MouseCursor.defer,
                            child: AnimatedBuilder(
                              animation: _flipController,
                              builder: (context, _) {
                                final angle = _flipController.value * math.pi;
                                final showingBack = angle > math.pi / 2 &&
                                    widget.sides.length > 1;
                                final side = showingBack
                                    ? widget.sides[1]
                                    : widget.sides.first;

                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0012)
                                    ..rotateY(angle),
                                  child: showingBack
                                      ? Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(math.pi),
                                          child: _GirviReceiptFlipSide(
                                            raster: side,
                                          ),
                                        )
                                      : _GirviReceiptFlipSide(raster: side),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Material(
              color: Colors.black.withValues(alpha: 0.62),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close preview',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: _FlipHint(canFlip: widget.sides.length > 1),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: _FlipPreviewToolbar(
              canFlip: widget.sides.length > 1,
              onFlip: _toggleSide,
              onZoomIn: () => _zoomBy(1.18),
              onZoomOut: () => _zoomBy(0.84),
              onReset: _resetZoom,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipHint extends StatelessWidget {
  const _FlipHint({required this.canFlip});

  final bool canFlip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canFlip ? Icons.touch_app_rounded : Icons.receipt_long_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              canFlip ? 'Double click to flip front/back' : 'Receipt preview',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipPreviewToolbar extends StatelessWidget {
  const _FlipPreviewToolbar({
    required this.canFlip,
    required this.onFlip,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final bool canFlip;
  final VoidCallback onFlip;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FlipPreviewToolButton(
              tooltip: 'Zoom out',
              icon: Icons.remove_rounded,
              onPressed: onZoomOut,
            ),
            _FlipPreviewToolButton(
              tooltip: 'Reset zoom',
              icon: Icons.center_focus_strong_rounded,
              onPressed: onReset,
            ),
            _FlipPreviewToolButton(
              tooltip: 'Zoom in',
              icon: Icons.add_rounded,
              onPressed: onZoomIn,
            ),
            if (canFlip)
              _FlipPreviewToolButton(
                tooltip: 'Flip page',
                icon: Icons.flip_rounded,
                onPressed: onFlip,
              ),
          ],
        ),
      ),
    );
  }
}

class _FlipPreviewToolButton extends StatelessWidget {
  const _FlipPreviewToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}

class _GirviReceiptFlipSide extends StatelessWidget {
  const _GirviReceiptFlipSide({required this.raster});

  final PdfRaster raster;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image(
          image: PdfRasterImage(raster),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? GirviColors.brandGold.withValues(alpha: 0.16)
                  : GirviColors.shellPanelBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _hovered ? GirviColors.brandGold : GirviColors.shellBorder,
              ),
            ),
            child: Icon(
              widget.icon,
              color:
                  _hovered ? GirviColors.brandGold : GirviColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _SearchField({
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: GirviStyles.inputNormal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(GirviIcons.search, color: GirviColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: GirviStyles.fieldInput.copyWith(fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GirviStyles.fieldHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerReadyPanel extends StatelessWidget {
  final GirviCustomerGirviAccount account;
  final NumberFormat moneyFmt;
  final int? selectedLoanId;
  final ValueChanged<GirviLoanWithCustomer> onLoanTap;

  const _CustomerReadyPanel({
    required this.account,
    required this.moneyFmt,
    required this.selectedLoanId,
    required this.onLoanTap,
  });

  @override
  Widget build(BuildContext context) {
    return GirviSectionCard(
      icon: GirviIcons.customer,
      title: account.customerName,
      subtitle:
          '${account.ticketCount} open Girvi ticket${account.ticketCount == 1 ? '' : 's'} available for this customer',
      accent: account.hasOverdueTickets ? GirviColors.danger : GirviColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _MiniMoney(
                label: 'Outstanding',
                value: 'Rs ${moneyFmt.format(account.outstandingPrincipal)}',
                color: GirviColors.purple,
              ),
              const SizedBox(width: 10),
              _MiniMoney(
                label: 'Interest Due',
                value: 'Rs ${moneyFmt.format(account.interestDue)}',
                color: account.hasOverdueTickets
                    ? GirviColors.danger
                    : GirviColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GirviColors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const _IconBox(
                      icon: GirviIcons.ticket,
                      color: GirviColors.info,
                      dark: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Girvi Bills',
                            style: GoogleFonts.inter(
                              color: GirviColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select the exact bill to open the collection desk.',
                            style: GoogleFonts.inter(
                              color: GirviColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CountBadge(value: account.ticketCount.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < account.loans.length; i++) ...[
                  _TicketStackRow(
                    data: account.loans[i],
                    selected: account.loans[i].loan.id == selectedLoanId,
                    moneyFmt: moneyFmt,
                    onTap: () => onLoanTap(account.loans[i]),
                  ),
                  if (i != account.loans.length - 1)
                    Container(height: 1, color: GirviColors.divider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerGirviCard extends StatelessWidget {
  final GirviCustomerGirviAccount account;
  final bool selected;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final VoidCallback onCustomerTap;

  const _CustomerGirviCard({
    required this.account,
    required this.selected,
    required this.moneyFmt,
    required this.dateFmt,
    required this.onCustomerTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCustomerTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? GirviColors.brandGold.withValues(alpha: 0.08)
              : GirviColors.inputBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? GirviColors.brandGold : GirviColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBox(
                  icon: GirviIcons.customer,
                  color: selected
                      ? GirviColors.brandGold
                      : account.hasOverdueTickets
                          ? GirviColors.danger
                          : GirviColors.info,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          account.customerMobile,
                          if ((account.customerCity ?? '').trim().isNotEmpty)
                            account.customerCity!.trim(),
                        ].join(' | '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label:
                      '${account.ticketCount} ticket${account.ticketCount == 1 ? '' : 's'}',
                  color: account.hasOverdueTickets
                      ? GirviColors.danger
                      : GirviColors.success,
                ),
                const SizedBox(width: 6),
                Icon(
                  selected ? GirviIcons.markDone : Icons.chevron_right_rounded,
                  color:
                      selected ? GirviColors.brandGold : GirviColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniMoney(
                  label: 'Outstanding',
                  value: 'Rs ${moneyFmt.format(account.outstandingPrincipal)}',
                  color: GirviColors.purple,
                ),
                const SizedBox(width: 10),
                _MiniMoney(
                  label: 'Interest Due',
                  value: 'Rs ${moneyFmt.format(account.interestDue)}',
                  color: account.hasOverdueTickets
                      ? GirviColors.danger
                      : GirviColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(GirviIcons.dates,
                    size: 13, color: GirviColors.textMuted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    account.hasOverdueTickets
                        ? '${account.overdueTicketCount} overdue ticket${account.overdueTicketCount == 1 ? '' : 's'} need attention'
                        : 'Latest activity ${dateFmt.format(account.latestActivity)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: account.hasOverdueTickets
                          ? GirviColors.danger
                          : GirviColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketStackRow extends StatefulWidget {
  final GirviLoanWithCustomer data;
  final bool selected;
  final NumberFormat moneyFmt;
  final VoidCallback onTap;

  const _TicketStackRow({
    required this.data,
    required this.selected,
    required this.moneyFmt,
    required this.onTap,
  });

  @override
  State<_TicketStackRow> createState() => _TicketStackRowState();
}

class _TicketStackRowState extends State<_TicketStackRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final loan = widget.data.loan;
    final highlighted = widget.selected || _hovered;
    final accent = widget.selected
        ? GirviColors.brandGold
        : loan.isOverdue
            ? GirviColors.danger
            : GirviColors.info;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          scale: _hovered && !widget.selected ? 1.006 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? GirviColors.brandGold.withValues(alpha: 0.15)
                  : _hovered
                      ? GirviColors.info.withValues(alpha: 0.07)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.selected
                    ? GirviColors.brandGold
                    : _hovered
                        ? GirviColors.info.withValues(alpha: 0.32)
                        : Colors.transparent,
                width: widget.selected ? 1.4 : 1,
              ),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 4,
                  height: 62,
                  decoration: BoxDecoration(
                    color: highlighted ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: loan.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    GirviIcons.ticket,
                    color: loan.statusColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              loan.ticketNo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GirviStyles.ticketNumber.copyWith(
                                fontSize: 13,
                                color: widget.selected
                                    ? GirviColors.brandDeep
                                    : GirviColors.brandGold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _TinyTag(label: loan.statusLabel),
                          if (widget.selected) ...[
                            const SizedBox(width: 6),
                            const _TinyTag(
                              label: 'Selected',
                              color: GirviColors.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loan.itemSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.data.interestPaidTotal <= 0
                            ? 'Interest not received yet'
                            : 'Interest paid Rs ${widget.moneyFmt.format(widget.data.interestPaidTotal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs ${widget.moneyFmt.format(widget.data.principalDue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Due Rs ${widget.moneyFmt.format(widget.data.netInterestDue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: widget.selected
                      ? const Icon(
                          GirviIcons.markDone,
                          key: ValueKey('selected'),
                          color: GirviColors.brandGold,
                          size: 20,
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          key: ValueKey(_hovered),
                          color: _hovered
                              ? GirviColors.info
                              : GirviColors.textMuted,
                          size: 20,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : GirviColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : GirviColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? color : GirviColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? GirviColors.textDark : GirviColors.textBody,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowActionPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WorkflowActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_WorkflowActionPill> createState() => _WorkflowActionPillState();
}

class _WorkflowActionPillState extends State<_WorkflowActionPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hovered ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.color.withValues(alpha: _hovered ? 0.42 : 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 17),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GirviStyles.fieldLabel),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: GirviStyles.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: GirviStyles.inputNormal,
            child: Row(
              children: [
                Icon(icon, color: GirviColors.brandGold, size: 18),
                const SizedBox(width: 10),
                Container(width: 1, height: 22, color: GirviColors.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GirviStyles.fieldInput,
                  ),
                ),
                const Icon(
                  GirviIcons.expandDown,
                  color: GirviColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryReviewBar extends StatelessWidget {
  final double enteredAmount;
  final GirviPaymentType paymentType;
  final double interestDue;
  final double principalOutstanding;
  final NumberFormat moneyFmt;
  final bool isSaving;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onRecord;

  const _EntryReviewBar({
    required this.enteredAmount,
    required this.paymentType,
    required this.interestDue,
    required this.principalOutstanding,
    required this.moneyFmt,
    required this.isSaving,
    required this.actionLabel,
    required this.actionIcon,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final signal = _EntryReviewSignal.resolve(
      paymentType: paymentType,
      enteredAmount: enteredAmount,
      interestDue: interestDue,
      principalOutstanding: principalOutstanding,
      moneyFmt: moneyFmt,
    );
    final actionButton = SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onRecord,
        style: ElevatedButton.styleFrom(
          backgroundColor: GirviColors.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: GirviColors.textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(actionIcon, size: 18),
        label: Text(
          isSaving ? 'Saving...' : actionLabel,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signal.color.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(signal.icon, color: signal.color, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      signal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                signal.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _ReviewMetric(
                    label: signal.referenceLabel,
                    value: signal.referenceValue,
                  ),
                  _ReviewMetric(
                    label: 'Entry Amount',
                    value: 'Rs ${moneyFmt.format(enteredAmount)}',
                  ),
                  _ReviewMetric(
                    label: signal.balanceLabel,
                    value: signal.balanceValue,
                    valueColor: signal.color,
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 14),
                actionButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              actionButton,
            ],
          );
        },
      ),
    );
  }
}

class _EntryReviewSignal {
  final String title;
  final String message;
  final String referenceLabel;
  final String referenceValue;
  final String balanceLabel;
  final String balanceValue;
  final IconData icon;
  final Color color;

  const _EntryReviewSignal({
    required this.title,
    required this.message,
    required this.referenceLabel,
    required this.referenceValue,
    required this.balanceLabel,
    required this.balanceValue,
    required this.icon,
    required this.color,
  });

  static _EntryReviewSignal resolve({
    required GirviPaymentType paymentType,
    required double enteredAmount,
    required double interestDue,
    required double principalOutstanding,
    required NumberFormat moneyFmt,
  }) {
    String amount(double value) => 'Rs ${moneyFmt.format(value)}';

    if (enteredAmount <= 0) {
      final pending = _referenceValue(
        paymentType: paymentType,
        interestDue: interestDue,
        principalOutstanding: principalOutstanding,
      );
      return _EntryReviewSignal(
        title: 'Amount Required',
        message: 'Enter the received amount before recording this entry.',
        referenceLabel: _referenceLabel(paymentType),
        referenceValue: amount(pending),
        balanceLabel: 'Pending',
        balanceValue: amount(pending),
        icon: GirviIcons.warning,
        color: GirviColors.warning,
      );
    }

    switch (paymentType) {
      case GirviPaymentType.interest:
        final remaining = math.max(interestDue - enteredAmount, 0.0);
        final advance = math.max(enteredAmount - interestDue, 0.0);
        if (interestDue <= 0) {
          return _EntryReviewSignal(
            title: 'Advance Interest Credit',
            message:
                'This amount will be held as advance credit against future interest.',
            referenceLabel: 'Net Interest Due',
            referenceValue: amount(interestDue),
            balanceLabel: 'Advance',
            balanceValue: amount(enteredAmount),
            icon: GirviIcons.markDone,
            color: GirviColors.success,
          );
        }
        if (remaining > 0) {
          return _EntryReviewSignal(
            title: 'Interest Part Received',
            message: '${amount(remaining)} interest will remain due.',
            referenceLabel: 'Net Interest Due',
            referenceValue: amount(interestDue),
            balanceLabel: 'After Entry',
            balanceValue: amount(remaining),
            icon: GirviIcons.interestRate,
            color: GirviColors.info,
          );
        }
        return _EntryReviewSignal(
          title: advance > 0 ? 'Advance Interest Credit' : 'Interest Cleared',
          message: advance > 0
              ? '${amount(advance)} will auto-adjust against future interest.'
              : 'This entry clears the current net interest due.',
          referenceLabel: 'Net Interest Due',
          referenceValue: amount(interestDue),
          balanceLabel: advance > 0 ? 'Advance' : 'After Entry',
          balanceValue: amount(advance),
          icon: GirviIcons.markDone,
          color: advance > 0 ? GirviColors.info : GirviColors.success,
        );

      case GirviPaymentType.partialInterest:
        final remaining = math.max(interestDue - enteredAmount, 0.0);
        return _EntryReviewSignal(
          title: remaining > 0 ? 'Partial Interest' : 'Interest Cleared',
          message: remaining > 0
              ? '${amount(remaining)} interest will still remain due.'
              : 'This entry covers the current interest due.',
          referenceLabel: 'Interest Due',
          referenceValue: amount(interestDue),
          balanceLabel: 'After Entry',
          balanceValue: amount(remaining),
          icon: remaining > 0 ? GirviIcons.interestRate : GirviIcons.markDone,
          color: remaining > 0 ? GirviColors.warning : GirviColors.success,
        );

      case GirviPaymentType.partialPrincipal:
        final balance = math.max(principalOutstanding - enteredAmount, 0.0);
        return _EntryReviewSignal(
          title: balance > 0 ? 'Principal Part Payment' : 'Principal Cleared',
          message: '${amount(balance)} principal will remain after this entry.',
          referenceLabel: 'Principal Outstanding',
          referenceValue: amount(principalOutstanding),
          balanceLabel: 'After Entry',
          balanceValue: amount(balance),
          icon: GirviIcons.loanTerms,
          color: balance > 0 ? GirviColors.purple : GirviColors.success,
        );

      case GirviPaymentType.penalty:
        return _EntryReviewSignal(
          title: 'Penalty Entry Ready',
          message: 'Penalty collection will be recorded against this ticket.',
          referenceLabel: 'Interest Due',
          referenceValue: amount(interestDue),
          balanceLabel: 'Penalty',
          balanceValue: amount(enteredAmount),
          icon: GirviIcons.warning,
          color: GirviColors.danger,
        );

      case GirviPaymentType.fullRelease:
        final totalPayable = principalOutstanding + interestDue;
        final balance = math.max(totalPayable - enteredAmount, 0.0);
        return _EntryReviewSignal(
          title: balance > 0 ? 'Release Short' : 'Release Ready',
          message: '${amount(balance)} will remain after this entry.',
          referenceLabel: 'Total Payable',
          referenceValue: amount(totalPayable),
          balanceLabel: 'After Entry',
          balanceValue: amount(balance),
          icon: GirviIcons.release,
          color: balance > 0 ? GirviColors.warning : GirviColors.success,
        );
    }
  }

  static String _referenceLabel(GirviPaymentType paymentType) {
    switch (paymentType) {
      case GirviPaymentType.interest:
        return 'Net Interest Due';
      case GirviPaymentType.partialInterest:
        return 'Interest Due';
      case GirviPaymentType.partialPrincipal:
        return 'Principal Outstanding';
      case GirviPaymentType.penalty:
        return 'Interest Due';
      case GirviPaymentType.fullRelease:
        return 'Total Payable';
    }
  }

  static double _referenceValue({
    required GirviPaymentType paymentType,
    required double interestDue,
    required double principalOutstanding,
  }) {
    switch (paymentType) {
      case GirviPaymentType.interest:
        return interestDue;
      case GirviPaymentType.partialInterest:
      case GirviPaymentType.penalty:
        return interestDue;
      case GirviPaymentType.partialPrincipal:
        return principalOutstanding;
      case GirviPaymentType.fullRelease:
        return principalOutstanding + interestDue;
    }
  }
}

class _ReleaseSettlementBalanceStrip extends StatelessWidget {
  final double principalDue;
  final double interestDue;
  final double principalCollected;
  final double interestCollected;
  final NumberFormat moneyFmt;
  final VoidCallback onFillFull;

  const _ReleaseSettlementBalanceStrip({
    required this.principalDue,
    required this.interestDue,
    required this.principalCollected,
    required this.interestCollected,
    required this.moneyFmt,
    required this.onFillFull,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.purple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.purple.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _FocusMetric(
                label: 'Principal Due',
                value: 'Rs ${moneyFmt.format(principalDue)}',
                color: GirviColors.purple,
                wide: true,
              ),
              _FocusMetric(
                label: 'Interest Due',
                value: 'Rs ${moneyFmt.format(interestDue)}',
                color: GirviColors.warning,
                wide: true,
              ),
              _FocusMetric(
                label: 'Already Settled',
                value:
                    'Rs ${moneyFmt.format(principalCollected + interestCollected)}',
                color: GirviColors.success,
                wide: true,
              ),
              _FocusMetric(
                label: 'Total Balance',
                value: 'Rs ${moneyFmt.format(principalDue + interestDue)}',
                color: GirviColors.danger,
                wide: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onFillFull,
              icon: const Icon(Icons.done_all_rounded, size: 17),
              label: const Text('Fill Full Settlement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GirviColors.success,
                side: BorderSide(
                  color: GirviColors.success.withValues(alpha: 0.42),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyForDeliveryPanel extends StatelessWidget {
  final DateTime? expectedDeliveryDate;
  final double principalCollected;
  final double interestCollected;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final bool isSaving;
  final VoidCallback onDeliver;

  const _ReadyForDeliveryPanel({
    required this.expectedDeliveryDate,
    required this.principalCollected,
    required this.interestCollected,
    required this.moneyFmt,
    required this.dateFmt,
    required this.isSaving,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.success.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.release,
                color: GirviColors.success,
                dark: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settlement Complete',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Payment is complete. Item remains in shop custody until handover.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _FocusMetric(
                label: 'Principal Received',
                value: 'Rs ${moneyFmt.format(principalCollected)}',
                color: GirviColors.purple,
                wide: true,
              ),
              _FocusMetric(
                label: 'Interest Received',
                value: 'Rs ${moneyFmt.format(interestCollected)}',
                color: GirviColors.warning,
                wide: true,
              ),
              _FocusMetric(
                label: 'Expected Pickup',
                value: expectedDeliveryDate == null
                    ? 'Not set'
                    : dateFmt.format(expectedDeliveryDate!),
                color: GirviColors.info,
                wide: true,
              ),
              const _FocusMetric(
                label: 'Custody Status',
                value: 'In Shop',
                color: GirviColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onDeliver,
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.inventory_2_rounded, size: 18),
              label: Text(
                isSaving ? 'Delivering...' : 'Confirm Item Delivered',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestLedgerBalanceStrip extends StatelessWidget {
  final double grossInterest;
  final double interestPaid;
  final double netDue;
  final int equivalentMonths;
  final NumberFormat moneyFmt;

  const _InterestLedgerBalanceStrip({
    required this.grossInterest,
    required this.interestPaid,
    required this.netDue,
    required this.equivalentMonths,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        equivalentMonths <= 0 ? 'Under 1 mo' : '$equivalentMonths mo';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _FocusMetric(
            label: 'Gross Interest',
            value: 'Rs ${moneyFmt.format(grossInterest)}',
            color: GirviColors.warning,
            wide: true,
          ),
          _FocusMetric(
            label: 'Interest Paid',
            value: 'Rs ${moneyFmt.format(interestPaid)}',
            color: GirviColors.success,
            wide: true,
          ),
          _FocusMetric(
            label: 'Net Due',
            value: 'Rs ${moneyFmt.format(netDue)}',
            color: netDue > 0 ? GirviColors.danger : GirviColors.success,
            wide: true,
          ),
          _FocusMetric(
            label: 'Entry Equals',
            value: monthLabel,
            color: GirviColors.info,
          ),
        ],
      ),
    );
  }
}

class _AmountShortcutRail extends StatelessWidget {
  final GirviPaymentType paymentType;
  final bool isInterestEntry;
  final double interestDue;
  final double monthlyInterest;
  final double principalOutstanding;
  final double expectedInterest;
  final NumberFormat moneyFmt;
  final ValueChanged<double> onPick;

  const _AmountShortcutRail({
    required this.paymentType,
    required this.isInterestEntry,
    required this.interestDue,
    required this.monthlyInterest,
    required this.principalOutstanding,
    required this.expectedInterest,
    required this.moneyFmt,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = <_AmountShortcut>[
      if (isInterestEntry && interestDue > 0)
        _AmountShortcut('Full Due', interestDue, GirviColors.warning),
      if (isInterestEntry && expectedInterest > 0)
        _AmountShortcut('Expected', expectedInterest, GirviColors.success),
      if (isInterestEntry && monthlyInterest > 0)
        _AmountShortcut('1 Month', monthlyInterest, GirviColors.info),
      if (paymentType == GirviPaymentType.partialPrincipal &&
          principalOutstanding > 0)
        _AmountShortcut(
          'Full Principal',
          principalOutstanding,
          GirviColors.purple,
        ),
    ];

    final uniqueShortcuts = <_AmountShortcut>[];
    for (final shortcut in shortcuts) {
      final alreadyExists = uniqueShortcuts.any(
        (item) => (item.amount - shortcut.amount).abs() < 0.01,
      );
      if (!alreadyExists) uniqueShortcuts.add(shortcut);
    }

    if (uniqueShortcuts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final shortcut in uniqueShortcuts)
          _AmountShortcutButton(
            label: shortcut.label,
            value: 'Rs ${moneyFmt.format(shortcut.amount)}',
            color: shortcut.color,
            onTap: () => onPick(shortcut.amount),
          ),
      ],
    );
  }
}

class _AmountShortcut {
  final String label;
  final double amount;
  final Color color;

  const _AmountShortcut(this.label, this.amount, this.color);
}

class _AmountShortcutButton extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _AmountShortcutButton({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AmountShortcutButton> createState() => _AmountShortcutButtonState();
}

class _AmountShortcutButtonState extends State<_AmountShortcutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hovered ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.color.withValues(alpha: _hovered ? 0.42 : 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on_rounded, color: widget.color, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.value,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  final GirviPaymentModel payment;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;

  const _PaymentHistoryRow({
    required this.payment,
    required this.moneyFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(payment.type);
    final period = payment.type == GirviPaymentType.fullRelease
        ? 'Principal Rs ${moneyFmt.format(payment.principalComponent)} | Interest Rs ${moneyFmt.format(payment.interestComponent)}'
        : payment.interestFromDate != null && payment.interestToDate != null
            ? '${dateFmt.format(payment.interestFromDate!)} - ${dateFmt.format(payment.interestToDate!)}'
            : payment.monthsCovered == null
                ? 'No interest period'
                : '${payment.monthsCovered} month${payment.monthsCovered == 1 ? '' : 's'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        children: [
          _IconBox(icon: _iconForType(payment.type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        payment.type.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (payment.receiptNo != null) ...[
                      const SizedBox(width: 8),
                      _TinyTag(label: payment.receiptNo!),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFmt.format(payment.paymentDate)}  |  ${payment.mode.displayName}  |  $period',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${moneyFmt.format(payment.amount)}',
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                payment.type == GirviPaymentType.fullRelease
                    ? 'Settlement Balance Rs ${moneyFmt.format(payment.balanceAfter)}'
                    : 'Balance Rs ${moneyFmt.format(payment.balanceAfter)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: GirviColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
      case GirviPaymentType.partialInterest:
        return GirviIcons.interestRate;
      case GirviPaymentType.partialPrincipal:
        return GirviIcons.loanTerms;
      case GirviPaymentType.fullRelease:
        return GirviIcons.release;
      case GirviPaymentType.penalty:
        return GirviIcons.warning;
    }
  }

  static Color _colorForType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
        return GirviColors.success;
      case GirviPaymentType.partialInterest:
        return GirviColors.warning;
      case GirviPaymentType.partialPrincipal:
        return GirviColors.purple;
      case GirviPaymentType.fullRelease:
        return GirviColors.info;
      case GirviPaymentType.penalty:
        return GirviColors.danger;
    }
  }
}

class _CollectionFocusStrip extends StatelessWidget {
  final double interestDue;
  final double monthlyInterest;
  final double totalPayable;
  final int unpaidMonths;
  final double advanceAmount;
  final int advanceMonths;
  final bool settlementComplete;
  final bool isOverdue;
  final NumberFormat moneyFmt;

  const _CollectionFocusStrip({
    required this.interestDue,
    required this.monthlyInterest,
    required this.totalPayable,
    required this.unpaidMonths,
    required this.advanceAmount,
    required this.advanceMonths,
    required this.settlementComplete,
    required this.isOverdue,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final hasAdvance = advanceMonths > 0 && !settlementComplete;
    final accent = settlementComplete
        ? GirviColors.success
        : hasAdvance
            ? GirviColors.success
            : isOverdue
                ? GirviColors.danger
                : unpaidMonths > 0
                    ? GirviColors.warning
                    : GirviColors.success;
    final statusText = settlementComplete
        ? 'Settlement complete - item awaiting delivery'
        : hasAdvance
            ? 'Advance credit about $advanceMonths month${advanceMonths == 1 ? '' : 's'}'
            : isOverdue
                ? 'Overdue'
                : unpaidMonths > 0
                    ? '$unpaidMonths month${unpaidMonths == 1 ? '' : 's'} due'
                    : 'No month due';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final leading = Row(
            children: [
              _IconBox(
                  icon: GirviIcons.interestRate, color: accent, dark: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection Focus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 9,
            runSpacing: 9,
            children: settlementComplete
                ? [
                    _FocusMetric(
                      label: 'Due Now',
                      value: 'Rs ${moneyFmt.format(interestDue)}',
                      color: GirviColors.success,
                    ),
                    _FocusMetric(
                      label: 'Excess Received',
                      value: 'Rs ${moneyFmt.format(advanceAmount)}',
                      color: advanceAmount > 0
                          ? GirviColors.danger
                          : GirviColors.success,
                      wide: true,
                    ),
                    const _FocusMetric(
                      label: 'Custody',
                      value: 'In Shop',
                      color: GirviColors.info,
                    ),
                    _FocusMetric(
                      label: 'Total Payable',
                      value: 'Rs ${moneyFmt.format(totalPayable)}',
                      color: GirviColors.success,
                      wide: true,
                    ),
                  ]
                : hasAdvance
                    ? [
                        _FocusMetric(
                          label: 'Due Now',
                          value: 'Rs ${moneyFmt.format(interestDue)}',
                          color: GirviColors.success,
                        ),
                        _FocusMetric(
                          label: 'Advance Credit',
                          value: 'Rs ${moneyFmt.format(advanceAmount)}',
                          color: GirviColors.success,
                          wide: true,
                        ),
                        _FocusMetric(
                          label: 'Advance Months',
                          value:
                              '$advanceMonths month${advanceMonths == 1 ? '' : 's'}',
                          color: GirviColors.info,
                        ),
                        _FocusMetric(
                          label: 'Monthly Interest',
                          value: 'Rs ${moneyFmt.format(monthlyInterest)}',
                          color: GirviColors.brandGold,
                          wide: true,
                        ),
                      ]
                    : [
                        _FocusMetric(
                          label: 'Due Now',
                          value: 'Rs ${moneyFmt.format(interestDue)}',
                          color: accent,
                          wide: true,
                        ),
                        _FocusMetric(
                          label: 'Months Due',
                          value:
                              '$unpaidMonths month${unpaidMonths == 1 ? '' : 's'}',
                          color: accent,
                        ),
                        _FocusMetric(
                          label: 'Monthly Interest',
                          value: 'Rs ${moneyFmt.format(monthlyInterest)}',
                          color: GirviColors.info,
                          wide: true,
                        ),
                        _FocusMetric(
                          label: 'Total Payable',
                          value: 'Rs ${moneyFmt.format(totalPayable)}',
                          color: GirviColors.purple,
                          wide: true,
                        ),
                      ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leading,
                const SizedBox(height: 12),
                metrics,
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 250, child: leading),
              const SizedBox(width: 12),
              Expanded(child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _FocusMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _FocusMetric({
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 198 : 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestBreakdownPanel extends StatelessWidget {
  final List<GirviInterestBreakdownLine> lines;
  final int totalMonths;
  final GirviElapsedPeriod elapsedPeriod;
  final double totalInterest;
  final NumberFormat moneyFmt;

  const _InterestBreakdownPanel({
    required this.lines,
    required this.totalMonths,
    required this.elapsedPeriod,
    required this.totalInterest,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.warning.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.interestRate,
                color: GirviColors.warning,
                dark: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest Breakdown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Actual ${elapsedPeriod.displayLabel} | Chargeable $totalMonths month${totalMonths == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _BreakdownTotalPill(
                label: 'Total Interest',
                value: 'Rs ${moneyFmt.format(totalInterest)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _BreakdownPeriodChip(
                label: 'Years',
                value: elapsedPeriod.years.toString(),
                color: GirviColors.purple,
              ),
              _BreakdownPeriodChip(
                label: 'Months',
                value: elapsedPeriod.months.toString(),
                color: GirviColors.info,
              ),
              _BreakdownPeriodChip(
                label: 'Days',
                value: elapsedPeriod.days.toString(),
                color: GirviColors.warning,
              ),
              _BreakdownPeriodChip(
                label: 'Chargeable',
                value: '$totalMonths mo',
                color: GirviColors.success,
                wide: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lines.length; i++) ...[
            _InterestBreakdownRow(
              line: lines[i],
              moneyFmt: moneyFmt,
            ),
            if (i != lines.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _InterestBreakdownRow extends StatelessWidget {
  final GirviInterestBreakdownLine line;
  final NumberFormat moneyFmt;

  const _InterestBreakdownRow({
    required this.line,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final title = line.cycleNumber == 1
        ? 'First ${line.months} month${line.months == 1 ? '' : 's'}'
        : 'After ${GirviLoanModel.compoundCycleMonths * (line.cycleNumber - 1)} months - ${line.months} month${line.months == 1 ? '' : 's'}';
    final subtitle =
        'Base Rs ${moneyFmt.format(line.principalBase)} | Monthly Rs ${moneyFmt.format(line.monthlyInterest)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: line.cycleNumber == 1
            ? GirviColors.warning.withValues(alpha: 0.08)
            : GirviColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: line.cycleNumber == 1
              ? GirviColors.warning.withValues(alpha: 0.20)
              : GirviColors.info.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          _CountBadge(value: line.cycleNumber.toString().padLeft(2, '0')),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (line.capitalizedAfterLine) ...[
            const SizedBox(width: 10),
            const _TinyTag(
              label: 'Capitalized',
              color: GirviColors.purple,
            ),
          ],
          const SizedBox(width: 12),
          Text(
            'Rs ${moneyFmt.format(line.interestAmount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownPeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _BreakdownPeriodChip({
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 150 : 112,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownTotalPill extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownTotalPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GirviColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.warning.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMoneyPanel extends StatelessWidget {
  final String title;
  final String primaryLabel;
  final String primaryValue;
  final String? secondaryLabel;
  final String? secondaryValue;
  final String? tertiaryLabel;
  final String? tertiaryValue;
  final IconData icon;
  final Color color;
  final double? progress;

  const _OverviewMoneyPanel({
    required this.title,
    required this.primaryLabel,
    required this.primaryValue,
    this.secondaryLabel,
    this.secondaryValue,
    this.tertiaryLabel,
    this.tertiaryValue,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final supporting = <_OverviewMiniValue>[
      if (secondaryLabel != null && secondaryValue != null)
        _OverviewMiniValue(
          label: secondaryLabel!,
          value: secondaryValue!,
          color: color,
        ),
      if (tertiaryLabel != null && tertiaryValue != null)
        _OverviewMiniValue(
          label: tertiaryLabel!,
          value: tertiaryValue!,
          color: color,
        ),
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color, dark: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            primaryLabel,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                primaryValue,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            _ProgressTrack(value: progress!, color: color),
          ],
          if (supporting.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < supporting.length; i++) ...[
                  Expanded(child: supporting[i]),
                  if (i != supporting.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewTermsPanel extends StatelessWidget {
  final String tenure;
  final String startDate;
  final String maturityDate;
  final String paidTill;
  final String totalCollected;

  const _OverviewTermsPanel({
    required this.tenure,
    required this.startDate,
    required this.maturityDate,
    required this.paidTill,
    required this.totalCollected,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _OverviewInfoTile(
        label: 'Tenure',
        value: tenure,
        icon: GirviIcons.dates,
        color: GirviColors.info,
      ),
      _OverviewInfoTile(
        label: 'Start Date',
        value: startDate,
        icon: GirviIcons.dates,
        color: GirviColors.brandGold,
      ),
      _OverviewInfoTile(
        label: 'Maturity',
        value: maturityDate,
        icon: GirviIcons.dates,
        color: GirviColors.purple,
      ),
      _OverviewInfoTile(
        label: 'Interest Paid',
        value: paidTill,
        icon: GirviIcons.markDone,
        color: GirviColors.success,
      ),
      _OverviewInfoTile(
        label: 'Total Collected',
        value: totalCollected,
        icon: GirviIcons.cash,
        color: GirviColors.info,
        wide: true,
      ),
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: GirviColors.info.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.info,
                color: GirviColors.info,
                dark: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terms & Timeline',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 320;
              if (!twoColumns) {
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i != tiles.length - 1) const SizedBox(height: 9),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 9),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(child: tiles[2]),
                      const SizedBox(width: 9),
                      Expanded(child: tiles[3]),
                    ],
                  ),
                  const SizedBox(height: 9),
                  tiles[4],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewMiniValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewMiniValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _OverviewInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: wide ? 58 : 64),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressTrack({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: safeValue,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(safeValue * 100).toStringAsFixed(0)}% principal recovered',
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MiniMoney extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMoney({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 12,
                color: GirviColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool dark;

  const _IconBox({
    required this.icon,
    required this.color,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dark ? 42 : 38,
      height: dark ? 42 : 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: dark ? 22 : 20),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: GirviColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OverviewActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onTap;

  const _OverviewActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GirviColors.shellBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: GirviColors.shellBorder),
          boxShadow: const [
            BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GirviColors.brandGold,
                ),
              )
            else
              Icon(icon, color: GirviColors.brandGold, size: 15),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                color: GirviColors.shellTextTitle,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String value;

  const _CountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        value,
        style: GoogleFonts.manrope(
          color: GirviColors.brandDeep,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyTag({
    required this.label,
    this.color = GirviColors.brandGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          color: color == GirviColors.brandGold
              ? GirviColors.brandDeep
              : GirviColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GirviStyles.caption.copyWith(
            fontSize: 12,
            color: GirviColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: valueColor ?? GirviColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;

  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GirviColors.successBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.successBorder),
      ),
      child: Row(
        children: [
          const Icon(
            GirviIcons.markDone,
            color: GirviColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: GirviColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool large;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(large ? 42 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: large ? 72 : 54,
              height: large ? 72 : 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GirviColors.brandGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: GirviColors.brandGold,
                size: large ? 32 : 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: large ? 18 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: large ? 14 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
