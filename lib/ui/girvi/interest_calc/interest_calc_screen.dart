// =============================================================================
// FILE        : interest_calc_screen.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Screen
// DESCRIPTION : Interest Entry workspace for recording running girvi payments.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../database/db/app_database.dart';
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
  final _monthsCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  final _moneyFmt = NumberFormat('#,##,##0.00', 'en_IN');
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
    _monthsCtrl.dispose();
    _receiptCtrl.dispose();
    _notesCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _syncFields() {
    _syncingText = true;
    _setText(_amountCtrl, _ctrl.amountInput);
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

  Future<void> _showReceiptPreview({required Uint8List pdfBytes}) {
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
    final selectedLoanId = _ctrl.selectedLoan?.loan.id;
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
                        style: GirviStyles.caption.copyWith(
                          color: GirviColors.textMuted,
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
                        selectedLoanId: selectedLoanId,
                        moneyFmt: _moneyFmt,
                        dateFmt: _dateFmt,
                        onCustomerTap: () =>
                            _ctrl.selectCustomerAccount(account),
                        onLoanTap: _ctrl.selectLoan,
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
    final content = selected == null
        ? [
            if (selectedCustomer == null)
              const _EmptyState(
                icon: GirviIcons.customer,
                title: 'Select a Customer',
                message:
                    'Choose one customer from the left, then select the exact Girvi ticket for collection.',
                large: true,
              )
            else
              _CustomerReadyPanel(
                account: selectedCustomer,
                moneyFmt: _moneyFmt,
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
    final principalRepaid = _ctrl.principalRepaidForSelected;
    final interestCollected = _ctrl.interestCollectedForSelected;
    final totalCollected = _ctrl.totalCollectedForSelected;
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
                        color: GirviColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
                        fontSize: 14,
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
                        color: GirviColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 960;
              final principalPanel = _OverviewMoneyPanel(
                title: 'Principal',
                primaryLabel: 'Principal Amount',
                primaryValue: 'Rs ${_moneyFmt.format(principalDisbursed)}',
                secondaryLabel: 'Outstanding Balance',
                secondaryValue: 'Rs ${_moneyFmt.format(loan.loanAmount)}',
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
                primaryLabel: 'Interest Collected',
                primaryValue: 'Rs ${_moneyFmt.format(interestCollected)}',
                secondaryLabel: 'Interest Rate',
                secondaryValue: _formatInterestRate(loan.interestRate),
                tertiaryLabel: 'Due Now',
                tertiaryValue: 'Rs ${_moneyFmt.format(loan.accruedInterest)}',
                icon: GirviIcons.interestRate,
                color: GirviColors.warning,
              );

              final termsPanel = _OverviewTermsPanel(
                tenure: '${loan.durationMonths} months',
                startDate: _dateFmt.format(loan.startDate),
                maturityDate: loan.maturityDate == null
                    ? 'Not set'
                    : _dateFmt.format(loan.maturityDate!),
                paidTill: loan.lastInterestPaidDate == null
                    ? 'Not recorded'
                    : _dateFmt.format(loan.lastInterestPaidDate!),
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

  String _formatInterestRate(double value) {
    final normalized = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$normalized% / month';
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
            children: _ctrl.entryPaymentTypes.map((type) {
              return _SelectablePill(
                label: type.displayName,
                selected: _ctrl.paymentType == type,
                icon: _iconForPaymentType(type),
                color: _colorForPaymentType(type),
                onTap: () => _ctrl.setPaymentType(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          GirviRowTwo(
            left: GirviInputField(
              label: 'Amount Received',
              hint: '0.00',
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
              label: 'Months Covered',
              hint: '1',
              icon: GirviIcons.dates,
              controller: _monthsCtrl,
              enabled: _ctrl.isInterestEntry,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffixText: 'mo',
            ),
          ),
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
          if (_ctrl.isInterestEntry) ...[
            const SizedBox(height: 14),
            GirviRowTwo(
              left: _DateField(
                label: 'Interest Period From',
                value: _ctrl.interestFromDate == null
                    ? 'Select date'
                    : _dateFmt.format(_ctrl.interestFromDate!),
                icon: GirviIcons.dates,
                onTap: () => _pickDate(
                  initialDate: _ctrl.interestFromDate ?? data.loan.startDate,
                  onPicked: _ctrl.setInterestFromDate,
                ),
              ),
              right: _DateField(
                label: 'Interest Period To',
                value: _ctrl.interestToDate == null
                    ? 'Select date'
                    : _dateFmt.format(_ctrl.interestToDate!),
                icon: GirviIcons.dates,
                onTap: () => _pickDate(
                  initialDate: _ctrl.interestToDate ?? DateTime.now(),
                  onPicked: _ctrl.setInterestToDate,
                ),
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
            expectedInterest: _ctrl.expectedInterest,
            enteredAmount: _ctrl.amount,
            moneyFmt: _moneyFmt,
            isSaving: _ctrl.isSaving,
            onRecord: _recordPayment,
          ),
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

  const _CustomerReadyPanel({
    required this.account,
    required this.moneyFmt,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GirviColors.infoBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GirviColors.info.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                const _IconBox(
                  icon: GirviIcons.ticket,
                  color: GirviColors.info,
                  dark: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select the exact Girvi ticket from the customer stack on the left to open the collection desk.',
                    style: GoogleFonts.inter(
                      color: GirviColors.textBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
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
  final int? selectedLoanId;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final VoidCallback onCustomerTap;
  final ValueChanged<GirviLoanWithCustomer> onLoanTap;

  const _CustomerGirviCard({
    required this.account,
    required this.selected,
    required this.selectedLoanId,
    required this.moneyFmt,
    required this.dateFmt,
    required this.onCustomerTap,
    required this.onLoanTap,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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
                        style: GirviStyles.caption.copyWith(
                          color: GirviColors.textMuted,
                          fontSize: 11,
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
                AnimatedRotation(
                  turns: selected ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    GirviIcons.expandDown,
                    color: GirviColors.textMuted,
                    size: 20,
                  ),
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
                    style: GirviStyles.caption.copyWith(
                      fontSize: 11,
                      color: account.hasOverdueTickets
                          ? GirviColors.danger
                          : GirviColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: GirviColors.divider),
              const SizedBox(height: 8),
              Text(
                'Select Girvi Ticket',
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 7),
              for (var i = 0; i < account.loans.length; i++) ...[
                _TicketStackRow(
                  data: account.loans[i],
                  selected: account.loans[i].loan.id == selectedLoanId,
                  moneyFmt: moneyFmt,
                  dateFmt: dateFmt,
                  onTap: () => onLoanTap(account.loans[i]),
                ),
                if (i != account.loans.length - 1)
                  Container(height: 1, color: GirviColors.divider),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketStackRow extends StatelessWidget {
  final GirviLoanWithCustomer data;
  final bool selected;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  const _TicketStackRow({
    required this.data,
    required this.selected,
    required this.moneyFmt,
    required this.dateFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loan = data.loan;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? GirviColors.brandGold.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
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
                            fontSize: 12,
                            color: selected
                                ? GirviColors.brandDeep
                                : GirviColors.brandGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TinyTag(label: loan.statusLabel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loan.itemSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GirviStyles.caption.copyWith(
                      color: GirviColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loan.lastInterestPaidDate == null
                        ? 'Interest not received yet'
                        : 'Paid till ${dateFmt.format(loan.lastInterestPaidDate!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GirviStyles.caption.copyWith(
                      color: GirviColors.textMuted,
                      fontSize: 10,
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
                  'Rs ${moneyFmt.format(loan.loanAmount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Due Rs ${moneyFmt.format(loan.accruedInterest)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: loan.isOverdue
                        ? GirviColors.danger
                        : GirviColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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
  final double expectedInterest;
  final double enteredAmount;
  final NumberFormat moneyFmt;
  final bool isSaving;
  final VoidCallback onRecord;

  const _EntryReviewBar({
    required this.expectedInterest,
    required this.enteredAmount,
    required this.moneyFmt,
    required this.isSaving,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.successBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _ReviewMetric(
                  label: 'Expected Interest',
                  value: 'Rs ${moneyFmt.format(expectedInterest)}',
                ),
                _ReviewMetric(
                  label: 'Entry Amount',
                  value: 'Rs ${moneyFmt.format(enteredAmount)}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
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
                  : const Icon(GirviIcons.save, size: 18),
              label: Text(
                isSaving ? 'Saving...' : 'Record Payment',
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
    final period = payment.interestFromDate != null &&
            payment.interestToDate != null
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
                          fontSize: 13,
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
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textMuted,
                    fontSize: 11,
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
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Balance Rs ${moneyFmt.format(payment.balanceAfter)}',
                style: GirviStyles.caption.copyWith(
                  fontSize: 10,
                  color: GirviColors.textMuted,
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
                    fontSize: 13,
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
              color: GirviColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                primaryValue,
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 24,
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
        label: 'Paid Till',
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
                    fontSize: 13,
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
              color: GirviColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 13,
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
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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
              fontSize: 12,
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
            color: GirviColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
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
                fontSize: 10,
                color: GirviColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: color,
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
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: 18),
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
          color: color,
          fontSize: 10,
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
                fontSize: 11,
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

  const _TinyTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: GirviColors.brandGold.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          color: GirviColors.brandDeep,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReviewMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewMetric({
    required this.label,
    required this.value,
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
            fontSize: 11,
            color: GirviColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: GirviColors.textDark,
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
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
