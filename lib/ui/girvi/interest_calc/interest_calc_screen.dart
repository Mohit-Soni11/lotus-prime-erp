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
part 'parts/interest_breakdown_widgets.dart';
part 'parts/interest_document_actions.dart';
part 'parts/interest_entry_review_widgets.dart';
part 'parts/interest_entry_layout.dart';
part 'parts/interest_focus_widgets.dart';
part 'parts/interest_overview_panels.dart';
part 'parts/interest_payment_actions.dart';
part 'parts/interest_payment_sections.dart';
part 'parts/interest_payment_support_widgets.dart';
part 'parts/interest_ready_delivery_panel.dart';
part 'parts/interest_receipt_actions.dart';
part 'parts/interest_release_settlement_widgets.dart';
part 'parts/interest_shared_atoms.dart';
part 'parts/interest_ticket_stack_widgets.dart';

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
    if (_ctrl.selectedLoan != null) {
      _ctrl.showBillSelectionForSelectedCustomer();
      return;
    }
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

  void _setOpeningReceipt(bool value) {
    if (!mounted) return;
    setState(() => _openingReceipt = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: GirviAppBar(
        screenTitle: GirviStrings.calcTitle,
        screenSubtitle: GirviStrings.calcSub,
        onBack: _handleBack,
        moduleIcon: GirviIcons.interestRate,
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
