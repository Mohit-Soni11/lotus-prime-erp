// =============================================================================
// FILE        : receive_karigar_screen.dart
// MODULE      : Karigar
// LAYER       : UI / Screen
// DESCRIPTION : Full production Receive from Karigar screen.
//               Sections: Select Issue â†’ Weight & Wastage Analysis â†’
//               Making Charges â†’ Payment Settlement â†’ Notes
//               Key UX: Live wastage computation with color-coded alerts,
//               auto making charge calculation, inline payment settlement.
//               - App Bar extracted to receive_karigar_app_bar.dart
//               - ListenableBuilder â€” zero setState in UI.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/karigar/receive_karigar_controller.dart';
import '../../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../../models/karigar/karigar_issue_model.dart';
import '../../../theme/karigar/karigar_theme.dart';
import 'receive_karigar_app_bar.dart'; // NAYA IMPORT
import '../shared/karigar_field_widgets.dart';
import '../shared/karigar_section_card.dart';

class ReceiveKarigarScreen extends StatefulWidget {
  final int? preSelectedIssueId;
  const ReceiveKarigarScreen({super.key, this.preSelectedIssueId});

  @override
  State<ReceiveKarigarScreen> createState() => _ReceiveKarigarScreenState();
}

class _ReceiveKarigarScreenState extends State<ReceiveKarigarScreen>
    with TickerProviderStateMixin {
  late final ReceiveKarigarController _ctrl;
  final AppDatabase _db = AppDatabase();
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _grossReceivedCtrl = TextEditingController();
  final _stoneWtCtrl = TextEditingController();
  final _makingRateCtrl = TextEditingController();
  final _makingAmountCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();

  // Focus nodes
  final _grossFocus = FocusNode();
  final _stoneFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _paidFocus = FocusNode();

  DateTime _receiptDate = DateTime.now();

  // Stagger animations
  static const int _secCount = 5;
  late final List<AnimationController> _secAnim;
  late final List<Animation<double>> _secFade;
  late final List<Animation<Offset>> _secSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = ReceiveKarigarController(_db);

    _secAnim = List.generate(
        _secCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500)));
    _secFade = _secAnim
        .map((a) => CurvedAnimation(parent: a, curve: Curves.easeInOut))
        .toList();
    _secSlide = _secAnim
        .map((a) => Tween<Offset>(
                begin: const Offset(0, 0.10), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)))
        .toList();

    for (int i = 0; i < _secCount; i++) {
      Future.delayed(Duration(milliseconds: 60 + i * 80), () {
        if (mounted) _secAnim[i].forward();
      });
    }

    // Wire weight listeners
    _grossReceivedCtrl.addListener(
        () => _ctrl.onGrossReceivedChanged(_grossReceivedCtrl.text));
    _stoneWtCtrl
        .addListener(() => _ctrl.onStoneWeightChanged(_stoneWtCtrl.text));
    _makingRateCtrl
        .addListener(() => _ctrl.onMakingRateChanged(_makingRateCtrl.text));

    _ctrl.initialize(preSelectedIssueId: widget.preSelectedIssueId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final c in [
      _grossReceivedCtrl,
      _stoneWtCtrl,
      _makingRateCtrl,
      _makingAmountCtrl,
      _paidCtrl,
      _qtyCtrl,
      _notesCtrl
    ]) {
      c.dispose();
    }
    for (final f in [
      _grossFocus,
      _stoneFocus,
      _rateFocus,
      _amountFocus,
      _paidFocus
    ]) {
      f.dispose();
    }
    for (final a in _secAnim) {
      a.dispose();
    }
    super.dispose();
  }

  // â”€â”€ ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final makingAmount =
        double.tryParse(_makingAmountCtrl.text) ?? _ctrl.computedMakingCharges;
    final paidAmount = double.tryParse(_paidCtrl.text) ?? 0.0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;

    final ok = await _ctrl.saveReceipt(
      receiptDate: _receiptDate,
      quantityReceived: qty,
      grossWeightReceived: double.tryParse(_grossReceivedCtrl.text) ?? 0.0,
      stoneWeight: double.tryParse(_stoneWtCtrl.text) ?? 0.0,
      makingChargesAmount: makingAmount,
      paidAmount: paidAmount,
      notes: _notesCtrl.text,
    );

    if (ok && mounted) {
      _showSuccessSnackbar(
          _ctrl.successMessage ?? KarigarStrings.successReceiptSaved);
      _resetAll();
    }
  }

  Future<void> _resetAll() async {
    _formKey.currentState?.reset();
    for (final c in [
      _grossReceivedCtrl,
      _stoneWtCtrl,
      _makingRateCtrl,
      _makingAmountCtrl,
      _paidCtrl,
      _notesCtrl
    ]) {
      c.clear();
    }
    _qtyCtrl.text = '1';
    setState(() => _receiptDate = DateTime.now());
    await _ctrl.resetForm();
  }

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(KarigarIcons.markDone, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: KarigarColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _pickReceiptDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: KarigarColors.brandGold,
            onPrimary: KarigarColors.shellBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _receiptDate = picked);
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _secFade[i],
        child: SlideTransition(position: _secSlide[i], child: child),
      );

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: KarigarColors.shellBg,
        // NAYA APP BAR CALL YAHAN HAI
        appBar: ReceiveKarigarAppBar(
          onBack: () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: Container(
            color: KarigarColors.bodyBg,
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (context, _) {
                // Auto-sync making amount from computed value
                if (_makingAmountCtrl.text.isEmpty &&
                    _ctrl.computedMakingCharges > 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _makingAmountCtrl.text =
                        _ctrl.computedMakingCharges.toStringAsFixed(2);
                  });
                }

                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: KarigarStyles.pagePadding,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_ctrl.hasError)
                          KarigarErrorBanner(
                            message: _ctrl.errorMessage!,
                            onDismiss: _ctrl.clearMessages,
                          ),

                        // â”€â”€ Section 1: Select Pending Issue â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            0,
                            KarigarSectionCard(
                              icon: KarigarIcons.issueDetails,
                              title: 'Select Pending Issue',
                              subtitle:
                                  'Choose which issue you are receiving goods for',
                              accent: KarigarColors.accentIssue,
                              child: _buildIssueSelectionSection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 2: Weight & Wastage â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            1,
                            KarigarSectionCard(
                              icon: KarigarIcons.wastage,
                              title: KarigarStrings.secWastage,
                              subtitle: KarigarStrings.descWastage,
                              accent: KarigarColors.accentWastage,
                              child: _buildWeightSection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 3: Making Charges â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            2,
                            KarigarSectionCard(
                              icon: KarigarIcons.charges,
                              title: KarigarStrings.secMakingCharges,
                              subtitle: KarigarStrings.descMakingCharges,
                              accent: KarigarColors.accentCharges,
                              child: _buildChargesSection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 4: Payment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            3,
                            KarigarSectionCard(
                              icon: KarigarIcons.payment,
                              title: KarigarStrings.secPayment,
                              subtitle: KarigarStrings.descPayment,
                              accent: KarigarColors.accentPayment,
                              child: _buildPaymentSection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 5: Notes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            4,
                            KarigarSectionCard(
                              icon: KarigarIcons.notes,
                              title: KarigarStrings.secNotes,
                              subtitle: KarigarStrings.descNotes,
                              accent: KarigarColors.accentNotes,
                              child: KarigarInputField(
                                label: KarigarStrings.lblNotes,
                                hint: KarigarStrings.hintNotes,
                                icon: KarigarIcons.notes,
                                controller: _notesCtrl,
                                maxLines: 3,
                              ),
                            )),
                        const SizedBox(height: 28),

                        _buildActionButtons(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECTION BUILDERS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildIssueSelectionSection() {
    if (_ctrl.isLoadingIssues) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
              color: KarigarColors.brandGold, strokeWidth: 2),
        ),
      );
    }

    if (_ctrl.pendingIssues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KarigarColors.warningBg,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: KarigarColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(KarigarIcons.info, color: KarigarColors.warning, size: 18),
          const SizedBox(width: 10),
          Text(KarigarStrings.noteNoIssues,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: KarigarColors.warning,
              )),
        ]),
      );
    }

    return Column(children: [
      // Selected issue display
      if (_ctrl.hasIssue) ...[
        _SelectedIssueCard(issue: _ctrl.selectedIssue!),
        const SizedBox(height: 14),
      ],

      // Issue picker
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Pending Issue', style: KarigarStyles.fieldLabel),
          const SizedBox(height: 6),
          Container(
            height: KarigarStyles.dropdownHeight,
            decoration: KarigarStyles.inputNormal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<KarigarIssueWithKarigar>(
                value: _ctrl.selectedIssue,
                isExpanded: true,
                dropdownColor: KarigarColors.cardBg,
                hint: Text(KarigarStrings.hintSelectIssue,
                    style: KarigarStyles.fieldHint),
                icon: const Icon(KarigarIcons.dropDown,
                    color: KarigarColors.textMuted, size: 20),
                items: _ctrl.pendingIssues
                    .map(
                      (issue) => DropdownMenuItem<KarigarIssueWithKarigar>(
                        value: issue,
                        child: Text(
                          '${issue.issueNumber} â€” ${issue.karigarName} (${issue.netWeightIssued.toStringAsFixed(3)}g)',
                          style:
                              KarigarStyles.fieldInput.copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) _ctrl.selectIssue(v);
                },
              ),
            ),
          ),
        ],
      ),

      // Receipt date
      const SizedBox(height: 16),
      _DatePickerRow(
        label: KarigarStrings.lblReceiptDate,
        value: DateFormat('dd MMM yyyy').format(_receiptDate),
        onTap: _pickReceiptDate,
      ),

      // Qty
      const SizedBox(height: 16),
      KarigarInputField(
        label: KarigarStrings.lblQuantity,
        hint: KarigarStrings.hintQuantity,
        icon: KarigarIcons.quantity,
        controller: _qtyCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.isEmpty) return 'Quantity is required';
          final i = int.tryParse(v);
          if (i == null || i < 1) return 'Minimum 1 piece';
          return null;
        },
      ),
    ]);
  }

  Widget _buildWeightSection() {
    return Column(children: [
      KarigarRowTwo(
        left: KarigarInputField(
          label: KarigarStrings.lblGrossReceived,
          hint: KarigarStrings.hintWeight,
          icon: KarigarIcons.weight,
          controller: _grossReceivedCtrl,
          focusNode: _grossFocus,
          nextFocus: _stoneFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Received weight required';
            final d = double.tryParse(v);
            if (d == null || d <= 0) return 'Enter valid weight';
            return null;
          },
        ),
        right: KarigarInputField(
          label: KarigarStrings.lblStoneWeight,
          hint: KarigarStrings.hintWeight,
          icon: KarigarIcons.metal,
          controller: _stoneWtCtrl,
          focusNode: _stoneFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
        ),
      ),
      const SizedBox(height: 16),

      Row(children: [
        Expanded(
            child: KarigarReadOnlyField(
          label: KarigarStrings.lblNetReceived,
          value: '${_ctrl.netWeightReceived.toStringAsFixed(3)}g',
          icon: KarigarIcons.weight,
          color: KarigarColors.success,
          note: KarigarStrings.noteNetReceived,
        )),
        const SizedBox(width: 14),
        Expanded(
            child: KarigarReadOnlyField(
          label: KarigarStrings.lblWastageWeight,
          value: '${_ctrl.wastageWeight.toStringAsFixed(3)}g',
          icon: KarigarIcons.wastage,
          color: _ctrl.isHighWastage
              ? KarigarColors.danger
              : KarigarColors.textMuted,
          note: KarigarStrings.noteWastage,
        )),
        const SizedBox(width: 14),
        Expanded(
            child: KarigarReadOnlyField(
          label: KarigarStrings.lblWastagePercent,
          value: '${_ctrl.wastagePercent.toStringAsFixed(2)}%',
          icon: KarigarIcons.wastage,
          color: _ctrl.isCriticalWastage
              ? KarigarColors.danger
              : _ctrl.isHighWastage
                  ? KarigarColors.warning
                  : KarigarColors.success,
        )),
      ]),

      // Wastage warning banner
      const SizedBox(height: 12),
      WastageBanner(wastagePercent: _ctrl.wastagePercent),
    ]);
  }

  Widget _buildChargesSection() {
    return Column(children: [
      KarigarRowTwo(
        left: KarigarDropdown<KarigarMakingType>(
          label: KarigarStrings.lblMakingType,
          icon: KarigarIcons.charges,
          value: _ctrl.makingType,
          items: KarigarMakingType.values,
          itemLabel: (e) => e.label,
          onChanged: (v) {
            if (v != null) {
              _ctrl.setMakingType(v);
              _makingRateCtrl.clear();
              _makingAmountCtrl.clear();
            }
          },
        ),
        right: KarigarInputField(
          label: KarigarStrings.lblMakingRate,
          hint: KarigarStrings.hintRate,
          icon: KarigarIcons.money,
          controller: _makingRateCtrl,
          focusNode: _rateFocus,
          nextFocus: _amountFocus,
          prefixText: 'â‚¹',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          onChanged: (_) {
            // Auto-calculate amount based on computed value
            final computed = _ctrl.computedMakingCharges;
            if (_makingRateCtrl.text.isNotEmpty) {
              _makingAmountCtrl.text = computed.toStringAsFixed(2);
            }
          },
        ),
      ),
      const SizedBox(height: 16),
      KarigarInputField(
        label: KarigarStrings.lblMakingAmount,
        hint: KarigarStrings.hintAmount,
        icon: KarigarIcons.money,
        controller: _makingAmountCtrl,
        focusNode: _amountFocus,
        nextFocus: _paidFocus,
        prefixText: 'â‚¹',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        ],
      ),
    ]);
  }

  Widget _buildPaymentSection() {
    final totalDue = double.tryParse(_makingAmountCtrl.text) ?? 0.0;
    final paid = double.tryParse(_paidCtrl.text) ?? 0.0;
    final balance = (totalDue - paid).clamp(0.0, double.infinity);

    return Column(children: [
      KarigarRowTwo(
        left: KarigarDropdown<KarigarPaymentStatus>(
          label: KarigarStrings.lblPaymentStatus,
          icon: KarigarIcons.payment,
          value: _ctrl.paymentStatus,
          items: KarigarPaymentStatus.values,
          itemLabel: (e) => e.label,
          onChanged: (v) {
            if (v != null) {
              _ctrl.setPaymentStatus(v);
              if (v == KarigarPaymentStatus.paid) {
                _paidCtrl.text = _makingAmountCtrl.text;
              } else if (v == KarigarPaymentStatus.unpaid) {
                _paidCtrl.text = '0.00';
              }
            }
          },
        ),
        right: KarigarInputField(
          label: KarigarStrings.lblPaidAmount,
          hint: KarigarStrings.hintAmount,
          icon: KarigarIcons.money,
          controller: _paidCtrl,
          focusNode: _paidFocus,
          prefixText: 'â‚¹',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Balance due display
      KarigarReadOnlyField(
        label: KarigarStrings.lblBalanceDue,
        value: 'â‚¹${balance.toStringAsFixed(2)}',
        icon: KarigarIcons.statsMoney,
        color: balance > 0 ? KarigarColors.danger : KarigarColors.success,
        note: KarigarStrings.noteBalanceDue,
      ),
    ]);
  }

  Widget _buildActionButtons() {
    return Row(children: [
      OutlinedButton.icon(
        onPressed: _ctrl.isSaving ? null : _resetAll,
        icon: const Icon(KarigarIcons.reset,
            size: 18, color: KarigarColors.textMuted),
        label:
            Text(KarigarStrings.btnReset, style: KarigarStyles.resetButtonText),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: KarigarColors.cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _ctrl.isSaving ? null : _onSave,
          icon: _ctrl.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(KarigarIcons.save,
                  size: 18, color: KarigarColors.shellBg),
          label: Text(
            _ctrl.isSaving
                ? KarigarStrings.btnSaving
                : KarigarStrings.btnSaveReceipt,
            style: KarigarStyles.saveButtonText,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: KarigarColors.brandGold,
            foregroundColor: KarigarColors.shellBg,
            disabledBackgroundColor:
                KarigarColors.brandGold.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ]);
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PRIVATE SUB-WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _SelectedIssueCard extends StatelessWidget {
  final KarigarIssueWithKarigar issue;
  const _SelectedIssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KarigarColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: KarigarColors.info.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(KarigarIcons.issueDetails,
                color: KarigarColors.info, size: 16),
            const SizedBox(width: 8),
            Text('Selected Issue',
                style: KarigarStyles.fieldLabel
                    .copyWith(color: KarigarColors.info)),
            const Spacer(),
            KarigarStatusPill(
              label: issue.statusEnum.label,
              color: KarigarColors.statusPending,
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.issueNumber, style: KarigarStyles.issueNumber),
                Text(issue.karigarName, style: KarigarStyles.jobTitle),
                Text(issue.itemDescription,
                    style: KarigarStyles.jobSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${issue.netWeightIssued.toStringAsFixed(3)}g',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: KarigarColors.brandGold,
                    )),
                Text('Net wt. issued', style: KarigarStyles.caption),
                const SizedBox(height: 2),
                Text('Issued: ${fmt.format(issue.issueDate)}',
                    style: KarigarStyles.caption),
              ],
            ),
          ]),
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KarigarStyles.fieldLabel),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: KarigarStyles.inputHeight,
            decoration: KarigarStyles.inputNormal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              const Icon(KarigarIcons.calendar,
                  color: KarigarColors.brandGold, size: 18),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: KarigarColors.cardBorder),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(value,
                      style: KarigarStyles.fieldInput.copyWith(fontSize: 13))),
              const Icon(Icons.edit_calendar_rounded,
                  color: KarigarColors.textHint, size: 16),
            ]),
          ),
        ),
      ],
    );
  }
}
