import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:lotus_erp/core/printing/lotus_pdf_print_dispatcher.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../logic/girvi/interest_entry/girvi_interest_entry_controller.dart';
import '../../../logic/girvi/girvi_interest_period_text.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_invoice_draft.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../repositories/girvi/girvi_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../shared/girvi_shared_widgets.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'parts/interest_customer_panel.dart';
part 'parts/interest_entry_layout.dart';
part 'parts/interest_focus_widgets.dart';
part 'parts/interest_overview_panels.dart';
part 'parts/interest_payment_sections.dart';
part 'parts/interest_payment_settlement_widgets.dart';
part 'parts/interest_payment_support_widgets.dart';
part 'parts/interest_receipt_preview.dart';
part 'parts/interest_shared_atoms.dart';

class InterestCalcScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialTicketNo;

  const InterestCalcScreen({
    super.key,
    this.onBack,
    this.initialTicketNo,
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
  final _releaseDiscountCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  final _moneyFmt = NumberFormat('#,##,##0', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');
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
    _releaseDiscountCtrl.addListener(() {
      if (!_syncingText) {
        _ctrl.onReleaseDiscountChanged(_releaseDiscountCtrl.text);
      }
    });
    _monthsCtrl.addListener(() {
      if (!_syncingText) _ctrl.onMonthsChanged(_monthsCtrl.text);
    });
    _notesCtrl.addListener(() {
      if (!_syncingText) _ctrl.onNotesChanged(_notesCtrl.text);
    });

    _loadInitialState();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_syncFields);
    _ctrl.dispose();
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    _releasePrincipalCtrl.dispose();
    _releaseInterestCtrl.dispose();
    _releaseDiscountCtrl.dispose();
    _monthsCtrl.dispose();
    _notesCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    await _ctrl.load();
    if (!mounted) return;

    final ticketNo = widget.initialTicketNo?.trim();
    if (ticketNo != null && ticketNo.isNotEmpty) {
      _searchCtrl.text = ticketNo;
      await _ctrl.selectLoanByTicketNo(ticketNo);
      if (!mounted) return;
    }

    _fadeCtrl.forward();
  }

  void _syncFields() {
    _syncingText = true;
    _setText(_amountCtrl, _ctrl.amountInput);
    _setText(_releasePrincipalCtrl, _ctrl.releasePrincipalInput);
    _setText(_releaseInterestCtrl, _ctrl.releaseInterestInput);
    _setText(_releaseDiscountCtrl, _ctrl.releaseDiscountInput);
    _setText(_monthsCtrl, _ctrl.monthsInput);
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
    final selectedBeforeSave = _ctrl.selectedLoan;
    final wasReadyForDelivery = _ctrl.isReadyForDelivery;
    final isFullReleaseSettlement = _ctrl.paymentType ==
            GirviPaymentType.fullRelease &&
        !wasReadyForDelivery &&
        _ctrl.releaseSettlementValue + 0.01 >= _ctrl.releaseTotalDueForSelected;

    if (isFullReleaseSettlement) {
      final confirmed = await _confirmFullReleaseSettlement();
      if (!confirmed) return;
    }

    if (wasReadyForDelivery) {
      final confirmed = await _confirmReadyDelivery();
      if (!confirmed) return;
    }

    final ok = await _ctrl.recordPayment();
    if (!mounted || !ok) return;
    if ((isFullReleaseSettlement || wasReadyForDelivery) &&
        selectedBeforeSave != null) {
      await _showSettlementSavedDialog(
        selectedBeforeSave.loan.id,
        delivered: wasReadyForDelivery,
      );
    } else {
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: _ctrl.successMessage ?? 'Payment entry recorded.',
      );
    }
  }

  Future<bool> _confirmFullReleaseSettlement() async {
    final selected = _ctrl.selectedLoan;
    if (selected == null) return false;
    final principal = _ctrl.releasePrincipalDueForSelected;
    final totalInterest = _ctrl.netInterestDueForSelected;
    final discount = _ctrl.releaseDiscount;
    final interestAfterWaiver = math.max(
      totalInterest - discount,
      0.0,
    );
    final totalPayable = principal + interestAfterWaiver;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: GirviColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      GirviIcons.release,
                      color: GirviColors.success,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirm Final Settlement',
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Confirm that the final receivable amount has been collected for ticket ${selected.loan.ticketNo}.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DeliveryConfirmLine(
                      label: 'Customer',
                      value: selected.customerName,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Principal',
                      value: 'Rs ${_moneyFmt.format(principal)}',
                    ),
                    _DeliveryConfirmLine(
                      label: 'Total Interest',
                      value: 'Rs ${_moneyFmt.format(totalInterest)}',
                    ),
                    _DeliveryConfirmLine(
                      label: 'Interest Waiver',
                      value: discount > 0
                          ? '- Rs ${_moneyFmt.format(discount)}'
                          : 'Rs 0',
                      valueColor: discount > 0
                          ? GirviColors.success
                          : GirviColors.textMuted,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Total Receivable',
                      value: 'Rs ${_moneyFmt.format(totalPayable)}',
                      valueColor: GirviColors.textDark,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GirviColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: GirviColors.success.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        'After confirmation, this ticket will move to Ready for Delivery and settlement documents can be printed or saved.',
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GirviColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GirviColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(GirviIcons.release, size: 18),
                  label: Text(
                    'Confirm Settlement',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _confirmReadyDelivery() async {
    final selected = _ctrl.selectedLoan;
    if (selected == null) return false;
    final loan = selected.loan;
    final expectedDate = loan.expectedDeliveryDate == null
        ? 'Not set'
        : _dateFmt.format(loan.expectedDeliveryDate!);
    final nowLabel = _dateTimeFmt.format(DateTime.now());
    final principalReceived = _ctrl.principalRepaidForSelected +
        _ctrl.releasePrincipalCollectedForSelected;
    final interestReceived = _ctrl.interestCollectedForSelected;
    final discountGiven = _ctrl.releaseDiscountForSelected;
    final receivedTotal = principalReceived + interestReceived;
    final clearedTotal = receivedTotal + discountGiven;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: GirviColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: GirviColors.success,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirm Item Delivery',
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'This will mark ticket ${loan.ticketNo} as delivered and closed.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DeliveryConfirmLine(
                      label: 'Customer',
                      value: selected.customerName,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Expected Pickup',
                      value: expectedDate,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Delivery Time',
                      value: nowLabel,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Principal Received',
                      value: 'Rs ${_moneyFmt.format(principalReceived)}',
                    ),
                    _DeliveryConfirmLine(
                      label: 'Interest Received',
                      value: 'Rs ${_moneyFmt.format(interestReceived)}',
                    ),
                    if (discountGiven > 0)
                      _DeliveryConfirmLine(
                        label: 'Approved Waiver',
                        value: 'Rs ${_moneyFmt.format(discountGiven)}',
                        valueColor: GirviColors.info,
                      ),
                    _DeliveryConfirmLine(
                      label: 'Total Payable Cleared',
                      value: 'Rs ${_moneyFmt.format(clearedTotal)}',
                      valueColor: GirviColors.success,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GirviColors.warning.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: GirviColors.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: GirviColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Verify pledged item, customer identity and receipt before handover.',
                              style: GoogleFonts.inter(
                                color: GirviColors.textDark,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GirviColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GirviColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_rounded, size: 18),
                  label: Text(
                    'Confirm Delivery',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _showSettlementSavedDialog(
    int loanId, {
    bool delivered = false,
  }) {
    final title = delivered ? 'Delivery Completed' : 'Settlement Saved';
    final message = delivered
        ? 'The pledged item has been marked as delivered. You can view, print, or save the complete Girvi document set now.'
        : 'Final settlement is complete and the Girvi ticket is ready for delivery. You can view, print, or save the payment and release document now.';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GirviColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GirviColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: GirviColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _saveGirviReleaseDocumentForLoan(loanId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.info,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 17),
              label: Text(
                'Save PDF',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _printGirviReleaseDocumentForLoan(loanId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.warning,
                foregroundColor: GirviColors.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.print_rounded, size: 17),
              label: Text(
                'Print',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _previewGirviReleaseDocumentForLoan(loanId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.visibility_rounded, size: 17),
              label: Text(
                'View Document',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Uint8List?> _buildGirviReleaseDocumentPdfForLoan(int loanId) async {
    final repo = GirviRepository(_db);
    final accounts = await repo.getLoansWithCustomer(loanId: loanId);
    if (accounts.isEmpty) return null;
    final account = accounts.single;
    final draft =
        await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
      customerId: account.loan.customerId,
      loanId: loanId,
    );
    if (draft == null) return null;

    final templateId = await _selectGirviDocumentTemplate(
      title: 'Select Girvi PDF Design',
      actionLabel: 'Use Design',
    );
    if (templateId == null) return null;

    return _buildGirviTemplatePdfBytes(
      draft: draft.copyWith(mode: GirviReceiptMode.release),
      templateId: templateId,
    );
  }

  Future<void> _previewGirviReleaseDocumentForLoan(int loanId) async {
    try {
      final bytes = await _buildGirviReleaseDocumentPdfForLoan(loanId);
      if (!mounted) return;
      if (bytes == null) {
        return;
      }
      await _showGirviReleaseDocumentPreview(
        pdfBytes: bytes,
        fileName: 'girvi_release_$loanId.pdf',
      );
    } catch (_) {
      if (mounted) _showInfoFeedback('Girvi document could not be opened.');
    }
  }

  Future<void> _printGirviReleaseDocumentForLoan(int loanId) async {
    try {
      final bytes = await _buildGirviReleaseDocumentPdfForLoan(loanId);
      if (!mounted) return;
      if (bytes == null) {
        return;
      }

      final fileName = _girviReleaseDocumentFileName(loanId);
      final result = await const LotusPdfPrintDispatcher().dispatch(
        context: context,
        bytes: bytes,
        documentName: fileName,
        outputFileName: fileName,
        printerPickerTitle: 'Select Girvi Document Printer',
        virtualSaveDialogTitle: 'Save Girvi Print Output As',
      );
      if (!mounted) return;
      if (!result.completed && result != LotusPdfPrintResult.cancelled) {
        _showInfoFeedback('Girvi document could not be printed.');
      }
    } catch (_) {
      if (mounted) _showInfoFeedback('Girvi document could not be printed.');
    }
  }

  Future<void> _saveGirviReleaseDocumentForLoan(int loanId) async {
    try {
      final bytes = await _buildGirviReleaseDocumentPdfForLoan(loanId);
      if (!mounted) return;
      if (bytes == null) {
        return;
      }

      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Girvi Document PDF',
        fileName: _girviReleaseDocumentFileName(loanId),
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        lockParentWindow: true,
      );
      if (selectedPath == null) return;

      final outputPath = _ensurePdfExtension(selectedPath);
      final file = File(outputPath);
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        AppFeedback.success(
          context,
          message: 'Girvi document PDF saved successfully.',
        );
      }
    } catch (_) {
      if (mounted) _showInfoFeedback('Girvi document could not be saved.');
    }
  }

  String _girviReleaseDocumentFileName(int loanId) {
    return 'girvi_release_$loanId.pdf';
  }

  String _ensurePdfExtension(String path) {
    return path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
  }

  Future<Uint8List?> _buildGirviTemplatePdfBytes({
    required GirviInvoiceDraft draft,
    required String templateId,
  }) async {
    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await controller.generatePreview();
      await controller.switchTemplate(templateId);
      return controller.pdfBytes;
    } finally {
      controller.dispose();
    }
  }

  Future<String?> _selectGirviDocumentTemplate({
    required String title,
    required String actionLabel,
  }) {
    final templates = PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.girviReceipt,
    );
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: GirviColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGold.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_motion_rounded,
                      color: GirviColors.brandGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose the same Girvi invoice design used in the invoice hub.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final template in templates) ...[
                      _GirviDocumentTemplateTile(
                        template: template,
                        selected: template.id == selectedTemplateId,
                        onTap: () => setDialogState(
                          () => selectedTemplateId = template.id,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GirviColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedTemplateId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GirviColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    actionLabel,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGirviReleaseDocumentPreview({
    required Uint8List pdfBytes,
    required String fileName,
  }) {
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
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: fileName,
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

  void _setPaymentAmount(double value) {
    final nextValue = _formatEntryAmountInput(value);
    _syncingText = true;
    _setText(_amountCtrl, nextValue);
    _syncingText = false;
    _ctrl.onAmountChanged(nextValue);
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
        _showInfoFeedback('Girvi invoice details could not be loaded.');
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
          _showInfoFeedback('Girvi invoice PDF could not be generated.');
          return;
        }
        await _showReceiptPreview(pdfBytes: bytes);
      } finally {
        controller.dispose();
      }
    } catch (error) {
      if (mounted) {
        _showInfoFeedback('Girvi invoice preview could not be opened.');
      }
    } finally {
      if (mounted) setState(() => _openingReceipt = false);
    }
  }

  void _showInfoFeedback(String message) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
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
}

class _GirviDocumentTemplateTile extends StatelessWidget {
  const _GirviDocumentTemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final PrintTemplateDefinition template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEconomy = template.id == PrintTemplateRegistry.lotusEconomy.id;
    final isSignature = template.id == PrintTemplateRegistry.lotusSignature.id;
    final accent = isEconomy
        ? GirviColors.textDark
        : isSignature
            ? GirviColors.warning
            : GirviColors.brandGold;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : GirviColors.inputBg.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : GirviColors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 68,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 5, color: accent),
                  const SizedBox(height: 7),
                  Container(height: 4, color: GirviColors.cardBorder),
                  const SizedBox(height: 5),
                  Container(height: 4, color: GirviColors.cardBorder),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: Container(height: 4, color: accent)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          color: accent.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selected ? accent : GirviColors.textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textBody,
                      fontSize: 12.5,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? accent : GirviColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryConfirmLine extends StatelessWidget {
  const _DeliveryConfirmLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: GirviColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: valueColor ?? GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
