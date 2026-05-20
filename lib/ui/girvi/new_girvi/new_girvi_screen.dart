// =============================================================================
// FILE        : new_girvi_screen.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Screen
// DESCRIPTION : Full production New Girvi Ticket screen.
//               Sections:
//               1. Customer Selection  2. Item Details  3. Weight Details
//               4. Valuation          5. Loan Terms     6. Disbursement
//               7. Dates              8. KYC            9. Notes
//               - App Bar extracted to new_girvi_app_bar.dart
//               Staggered animations, ListenableBuilder, zero setState.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/girvi/new_girvi_controller.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'new_girvi_app_bar.dart'; // NAYA IMPORT
import '../shared/girvi_shared_widgets.dart';
import '../shared/select_customer_dialog.dart';

class NewGirviScreen extends StatefulWidget {
  const NewGirviScreen({super.key});

  @override
  State<NewGirviScreen> createState() => _NewGirviScreenState();
}

class _NewGirviScreenState extends State<NewGirviScreen>
    with TickerProviderStateMixin {
  // â”€â”€ Controller â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final NewGirviController _ctrl;
  final AppDatabase _db = AppDatabase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // â”€â”€ Text Controllers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _itemDescCtrl = TextEditingController();
  final _grossWtCtrl = TextEditingController();
  final _stoneWtCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _loanAmtCtrl = TextEditingController();
  final _interestCtrl = TextEditingController(text: '2.0');
  final _durationCtrl = TextEditingController(text: '12');
  final _idProofNoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // â”€â”€ Focus Nodes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _itemDescFocus = FocusNode();
  final _grossWtFocus = FocusNode();
  final _stoneWtFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _loanAmtFocus = FocusNode();
  final _interestFocus = FocusNode();
  final _durationFocus = FocusNode();
  final _idProofNoFocus = FocusNode();

  // â”€â”€ Animations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const int _sectionCount = 9;
  late final List<AnimationController> _sectionAnim;
  late final List<Animation<double>> _sectionFade;
  late final List<Animation<Offset>> _sectionSlide;

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _ctrl = NewGirviController(_db);

    _sectionAnim = List.generate(
        _sectionCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 450)));
    _sectionFade = _sectionAnim
        .map((a) => CurvedAnimation(parent: a, curve: Curves.easeInOut))
        .toList();
    _sectionSlide = _sectionAnim
        .map((a) => Tween<Offset>(
                begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)))
        .toList();

    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 60 + i * 70), () {
        if (mounted) _sectionAnim[i].forward();
      });
    }

    // Wire text â†’ controller
    _grossWtCtrl
        .addListener(() => _ctrl.onGrossWeightChanged(_grossWtCtrl.text));
    _stoneWtCtrl
        .addListener(() => _ctrl.onStoneWeightChanged(_stoneWtCtrl.text));
    _rateCtrl.addListener(() => _ctrl.onRatePerGramChanged(_rateCtrl.text));
    _interestCtrl
        .addListener(() => _ctrl.onInterestRateChanged(_interestCtrl.text));
    _durationCtrl
        .addListener(() => _ctrl.onDurationChanged(_durationCtrl.text));

    _loanAmtCtrl.addListener(() {
      _ctrl.onLoanAmountChanged(_loanAmtCtrl.text);
    });

    _ctrl.addListener(_onControllerUpdate);
    _ctrl.initialize();
  }

  void _onControllerUpdate() {
    // Sync loanAmt field when controller recomputes via LTV slider
    final ctrlVal = _ctrl.loanAmount.toStringAsFixed(2);
    if (_loanAmtCtrl.text != ctrlVal && !_loanAmtFocus.hasFocus) {
      _loanAmtCtrl.text = ctrlVal == '0.00' ? '' : ctrlVal;
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    for (final c in [
      _itemDescCtrl,
      _grossWtCtrl,
      _stoneWtCtrl,
      _rateCtrl,
      _loanAmtCtrl,
      _interestCtrl,
      _durationCtrl,
      _idProofNoCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _itemDescFocus,
      _grossWtFocus,
      _stoneWtFocus,
      _rateFocus,
      _loanAmtFocus,
      _interestFocus,
      _durationFocus,
      _idProofNoFocus,
    ]) {
      f.dispose();
    }
    for (final a in _sectionAnim) {
      a.dispose();
    }
    super.dispose();
  }

  // â”€â”€ ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showError('Please fix the errors above before saving.');
      return;
    }
    if (!_ctrl.hasCustomer) {
      _showError('Please select a customer first.');
      return;
    }

    final ok = await _ctrl.saveLoan(
      itemDescription: _itemDescCtrl.text,
      idProofNumber: _idProofNoCtrl.text,
      notes: _notesCtrl.text,
    );

    if (ok && mounted) {
      _showSuccess(_ctrl.successMessage ?? GirviStrings.successGirviSaved);
      await Future.delayed(const Duration(milliseconds: 400));
      _resetAll();
    }
  }

  Future<void> _resetAll() async {
    _formKey.currentState?.reset();
    for (final c in [
      _itemDescCtrl,
      _grossWtCtrl,
      _stoneWtCtrl,
      _rateCtrl,
      _loanAmtCtrl,
      _idProofNoCtrl,
      _notesCtrl,
    ]) {
      c.clear();
    }
    _interestCtrl.text = '2.0';
    _durationCtrl.text = '12';
    await _ctrl.resetForm();
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(GirviIcons.markDone, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: GirviColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: GirviColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ctrl.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: GirviColors.brandGold,
            onPrimary: GirviColors.shellBg,
            surface: GirviColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) _ctrl.setStartDate(picked);
  }

  void _openCustomerSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectCustomerDialog(
        db: _db,
        onSelected: (customer) {
          _ctrl.selectCustomer(customer);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _sectionFade[i],
        child: SlideTransition(position: _sectionSlide[i], child: child),
      );

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      // NAYA APP BAR CALL YAHAN HAI
      appBar: NewGirviAppBar(
        onBack: () => Navigator.pop(context),
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // â”€â”€ Ticket Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverToBoxAdapter(child: _buildTicketBanner()),

                // â”€â”€ Error Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (_ctrl.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: GirviErrorBanner(message: _ctrl.errorMessage!),
                    ),
                  ),

                // â”€â”€ Sections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _animated(0, _buildSection0Customer()),
                      const SizedBox(height: 16),
                      _animated(1, _buildSection1ItemDetails()),
                      const SizedBox(height: 16),
                      _animated(2, _buildSection2Weight()),
                      const SizedBox(height: 16),
                      _animated(3, _buildSection3Valuation()),
                      const SizedBox(height: 16),
                      _animated(4, _buildSection4LoanTerms()),
                      const SizedBox(height: 16),
                      _animated(5, _buildSection5Disbursement()),
                      const SizedBox(height: 16),
                      _animated(6, _buildSection6Dates()),
                      const SizedBox(height: 16),
                      _animated(7, _buildSection7KYC()),
                      const SizedBox(height: 16),
                      _animated(8, _buildSection8Notes()),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // â”€â”€ Bottom Action Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // â”€â”€ TICKET BANNER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTicketBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: GirviColors.shellBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.brandGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: GirviColors.brandGold.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GirviColors.brandGold,
                GirviColors.brandGold.withValues(alpha: 0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(GirviIcons.ticket,
              color: GirviColors.shellBg, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TICKET NUMBER',
                style: GoogleFonts.inter(
                    color: GirviColors.shellTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(_ctrl.ticketNo.isEmpty ? 'Generating...' : _ctrl.ticketNo,
                style: GirviStyles.ticketNumber.copyWith(fontSize: 16)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: GirviColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: GirviColors.warning.withValues(alpha: 0.3)),
          ),
          child: Text('DRAFT',
              style: GoogleFonts.inter(
                  color: GirviColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 0: CUSTOMER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection0Customer() {
    return GirviSectionCard(
      icon: GirviIcons.customer,
      title: GirviStrings.secCustomer,
      subtitle: GirviStrings.descCustomer,
      accent: GirviColors.accentCustomer,
      child: _ctrl.hasCustomer
          ? _SelectedCustomerCard(
              customer: _ctrl.selectedCustomer!,
              onClear: _ctrl.clearCustomer,
            )
          : _SelectCustomerButton(onTap: _openCustomerSearch),
    );
  }

  // â”€â”€ SECTION 1: ITEM DETAILS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection1ItemDetails() {
    return GirviSectionCard(
      icon: GirviIcons.itemDetails,
      title: GirviStrings.secItem,
      subtitle: GirviStrings.descItem,
      accent: GirviColors.accentItem,
      child: Column(children: [
        GirviInputField(
          label: 'Item Description *',
          hint: 'e.g. Gold Necklace with pendant, 2 bangles',
          icon: GirviIcons.itemDetails,
          controller: _itemDescCtrl,
          focusNode: _itemDescFocus,
          nextFocus: _grossWtFocus,
          maxLines: 2,
          validator: _ctrl.validateItemDescription,
        ),
        const SizedBox(height: 14),
        GirviRowTwo(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item Count *', style: GirviStyles.fieldLabel),
              const SizedBox(height: 6),
              _ItemCountStepper(
                count: _ctrl.itemCount,
                onChanged: _ctrl.setItemCount,
              ),
            ],
          ),
          right: GirviDropdown<MetalType>(
            label: 'Metal Type *',
            icon: GirviIcons.gold,
            value: _ctrl.metalType,
            items: MetalType.values
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text('${e.emoji}  ${e.displayName}'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _ctrl.setMetalType(v);
            },
          ),
        ),
        const SizedBox(height: 14),
        GirviDropdown<MetalPurity>(
          label: 'Metal Purity *',
          icon: GirviIcons.valuation,
          value: _ctrl.metalPurity,
          items: MetalPurity.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.displayName),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) _ctrl.setMetalPurity(v);
          },
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 2: WEIGHT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection2Weight() {
    final netWt = _ctrl.netWeight;
    return GirviSectionCard(
      icon: GirviIcons.weight,
      title: GirviStrings.secWeight,
      subtitle: GirviStrings.descWeight,
      accent: GirviColors.accentWeight,
      child: Column(children: [
        GirviRowTwo(
          left: GirviInputField(
            label: 'Gross Weight (g) *',
            hint: '0.00',
            icon: GirviIcons.weight,
            controller: _grossWtCtrl,
            focusNode: _grossWtFocus,
            nextFocus: _stoneWtFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            suffixText: 'g',
            validator: _ctrl.validateGrossWeight,
          ),
          right: GirviInputField(
            label: 'Stone/Non-Metal (g)',
            hint: '0.00',
            icon: Icons.scatter_plot_outlined,
            controller: _stoneWtCtrl,
            focusNode: _stoneWtFocus,
            nextFocus: _rateFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            suffixText: 'g',
          ),
        ),
        const SizedBox(height: 14),
        // Net weight display
        GirviReadOnlyField(
          label: 'Net Metal Weight',
          value: '${netWt.toStringAsFixed(3)} grams',
          highlighted: true,
          valueColor: netWt > 0 ? GirviColors.brandGold : GirviColors.textMuted,
        ),
        if (_ctrl.grossWeight > 0 && _ctrl.stoneWeight > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GirviColors.infoBg,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: GirviColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(GirviIcons.info, color: GirviColors.info, size: 14),
              const SizedBox(width: 8),
              Text(
                'Deduction: ${_ctrl.stoneWeight.toStringAsFixed(2)}g '
                '(${(_ctrl.stoneWeight / _ctrl.grossWeight * 100).toStringAsFixed(1)}% of gross)',
                style: GoogleFonts.inter(
                    color: GirviColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // â”€â”€ SECTION 3: VALUATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection3Valuation() {
    return GirviSectionCard(
      icon: GirviIcons.valuation,
      title: GirviStrings.secValuation,
      subtitle: GirviStrings.descValuation,
      accent: GirviColors.accentValuation,
      child: Column(children: [
        GirviInputField(
          label: 'Market Rate (â‚¹/gram) *',
          hint: '0.00',
          icon: GirviIcons.valuation,
          controller: _rateCtrl,
          focusNode: _rateFocus,
          nextFocus: _loanAmtFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          prefixText: 'â‚¹ ',
          validator: _ctrl.validateRatePerGram,
        ),
        const SizedBox(height: 14),
        // Computed total value
        GirviReadOnlyField(
          label: 'Total Item Value',
          value: 'â‚¹ ${_fmt.format(_ctrl.totalValue)}',
          highlighted: _ctrl.totalValue > 0,
        ),
        if (_ctrl.totalValue > 0) ...[
          const SizedBox(height: 8),
          _LtvSuggestionRow(
            totalValue: _ctrl.totalValue,
            onSuggestionTap: (ltv) {
              _ctrl.onLtvChanged(ltv);
              _loanAmtCtrl.text = _ctrl.loanAmount.toStringAsFixed(2);
            },
          ),
        ],
      ]),
    );
  }

  // â”€â”€ SECTION 4: LOAN TERMS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection4LoanTerms() {
    return GirviSectionCard(
      icon: GirviIcons.loanTerms,
      title: GirviStrings.secLoanTerms,
      subtitle: GirviStrings.descLoanTerms,
      accent: GirviColors.accentLoan,
      child: Column(children: [
        GirviInputField(
          label: 'Loan Amount (â‚¹) *',
          hint: '0.00',
          icon: GirviIcons.loanTerms,
          controller: _loanAmtCtrl,
          focusNode: _loanAmtFocus,
          nextFocus: _interestFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          prefixText: 'â‚¹ ',
          validator: _ctrl.validateLoanAmount,
        ),
        const SizedBox(height: 8),
        // LTV indicator
        if (_ctrl.totalValue > 0)
          _LtvIndicator(
            ltv: _ctrl.computedLtv,
            onChanged: (ltv) {
              _ctrl.onLtvChanged(ltv);
              _loanAmtCtrl.text = _ctrl.loanAmount.toStringAsFixed(2);
            },
          ),
        const SizedBox(height: 14),
        GirviRowTwo(
          left: GirviInputField(
            label: 'Interest Rate (% / month) *',
            hint: '2.0',
            icon: GirviIcons.interestRate,
            controller: _interestCtrl,
            focusNode: _interestFocus,
            nextFocus: _durationFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            suffixText: '%',
            validator: _ctrl.validateInterestRate,
          ),
          right: GirviInputField(
            label: 'Duration (months) *',
            hint: '12',
            icon: GirviIcons.dates,
            controller: _durationCtrl,
            focusNode: _durationFocus,
            nextFocus: _idProofNoFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffixText: 'mo',
            validator: _ctrl.validateDuration,
          ),
        ),
        const SizedBox(height: 14),
        // Computed interest preview
        _InterestPreviewCard(
          principal: _ctrl.loanAmount,
          monthly: _ctrl.monthlyInterest,
          total: _ctrl.totalInterestAtMaturity,
          totalDue: _ctrl.totalDueAtMaturity,
          annualRate: _ctrl.interestRate * 12,
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 5: DISBURSEMENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection5Disbursement() {
    return GirviSectionCard(
      icon: GirviIcons.cash,
      title: GirviStrings.secDisbursement,
      subtitle: GirviStrings.descDisbursement,
      accent: GirviColors.accentInterest,
      child: Column(children: [
        Text('How will the loan amount be paid to the customer?',
            style: GirviStyles.caption.copyWith(fontSize: 12)),
        const SizedBox(height: 12),
        _PaymentModeSelector(
          selected: _ctrl.disbursementMode,
          onChanged: _ctrl.setDisbursementMode,
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 6: DATES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection6Dates() {
    return GirviSectionCard(
      icon: GirviIcons.dates,
      title: GirviStrings.secDates,
      subtitle: GirviStrings.descDates,
      accent: GirviColors.accentDates,
      child: Column(children: [
        GirviRowTwo(
          left: _DatePickerField(
            label: 'Start Date *',
            date: _ctrl.startDate,
            onTap: _pickStartDate,
          ),
          right: GirviReadOnlyField(
            label: 'Maturity Date',
            value: _dateFmt.format(_ctrl.maturityDate),
            valueColor: GirviColors.info,
            highlighted: false,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GirviColors.warningBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GirviColors.warningBorder),
          ),
          child: Row(children: [
            const Icon(GirviIcons.info, color: GirviColors.warning, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Loan matures on ${_dateFmt.format(_ctrl.maturityDate)} '
                '(${_ctrl.durationMonths} months from start date)',
                style: GoogleFonts.inter(
                    color: GirviColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 7: KYC â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection7KYC() {
    return GirviSectionCard(
      icon: GirviIcons.kyc,
      title: GirviStrings.secKyc,
      subtitle: GirviStrings.descKyc,
      accent: GirviColors.accentKyc,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: GirviColors.dangerBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GirviColors.dangerBorder),
          ),
          child: Row(children: [
            const Icon(Icons.privacy_tip_outlined,
                color: GirviColors.danger, size: 14),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'RBI guidelines require ID proof for pawn loans above â‚¹1000.',
                    style: GoogleFonts.inter(
                        color: GirviColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 14),
        GirviDropdown<GirviIdProofType?>(
          label: 'ID Proof Type',
          icon: GirviIcons.kyc,
          value: _ctrl.idProofType,
          items: [
            const DropdownMenuItem(
                value: null, child: Text('â€” Select ID Type â€”')),
            ...GirviIdProofType.values.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.displayName),
                )),
          ],
          onChanged: _ctrl.setIdProofType,
        ),
        const SizedBox(height: 14),
        GirviInputField(
          label: 'ID Proof Number',
          hint: 'Enter document number',
          icon: GirviIcons.kyc,
          controller: _idProofNoCtrl,
          focusNode: _idProofNoFocus,
          enabled: _ctrl.idProofType != null,
          keyboardType: TextInputType.text,
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 8: NOTES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection8Notes() {
    return GirviSectionCard(
      icon: GirviIcons.notes,
      title: GirviStrings.secNotes,
      subtitle: GirviStrings.descNotes,
      accent: GirviColors.accentNotes,
      child: GirviInputField(
        label: 'Internal Remarks',
        hint: 'e.g. Customer mentioned item is old family jewellery...',
        icon: GirviIcons.notes,
        controller: _notesCtrl,
        maxLines: 3,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  // â”€â”€ BOTTOM ACTION BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        border: const Border(top: BorderSide(color: GirviColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: GirviColors.shellBg.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (_, __) => Row(children: [
          // Reset
          GestureDetector(
            onTap: _resetAll,
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GirviColors.bodyBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GirviColors.cardBorder),
              ),
              child: const Icon(GirviIcons.refresh,
                  color: GirviColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Save
          Expanded(
            child: AnimatedOpacity(
              opacity: _ctrl.isSaving ? 0.7 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: _ctrl.isSaving ? null : _onSave,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GirviColors.brandGold,
                        GirviColors.brandGold.withValues(alpha: 0.85)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: GirviColors.brandGold.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _ctrl.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: GirviColors.shellBg, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              const Icon(GirviIcons.save,
                                  color: GirviColors.shellBg, size: 18),
                              const SizedBox(width: 8),
                              Text('Create Girvi Ticket',
                                  style: GirviStyles.saveButtonText),
                            ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS (private to this file)
// =============================================================================

class _SelectedCustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onClear;

  const _SelectedCustomerCard({required this.customer, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.successBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: GirviColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(GirviIcons.customer,
              color: GirviColors.success, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.name,
                  style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: GirviColors.textDark)),
              const SizedBox(height: 2),
              Text(customer.mobile,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: GirviColors.textMuted)),
              if (customer.city != null)
                Text(customer.city!,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: GirviColors.textHint)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onClear,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: const Icon(Icons.close_rounded,
                color: GirviColors.textMuted, size: 16),
          ),
        ),
      ]),
    );
  }
}

class _SelectCustomerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SelectCustomerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GirviColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GirviColors.brandGold.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(GirviIcons.search, color: GirviColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Text(GirviStrings.selectCustomerHint,
              style: GoogleFonts.inter(
                  color: GirviColors.brandGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ItemCountStepper extends StatelessWidget {
  final int count;
  final void Function(int) onChanged;

  const _ItemCountStepper({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GirviStyles.inputHeight,
      decoration: GirviStyles.inputNormal,
      child: Row(children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: () => onChanged(count - 1),
          enabled: count > 1,
        ),
        Expanded(
          child: Center(
            child: Text('$count',
                style: GirviStyles.fieldInput.copyWith(fontSize: 18)),
          ),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: () => onChanged(count + 1),
          enabled: count < 99,
        ),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: GirviStyles.inputHeight,
          alignment: Alignment.center,
          child: Icon(icon,
              color: enabled ? GirviColors.brandGold : GirviColors.textHint,
              size: 20),
        ),
      );
}

class _LtvSuggestionRow extends StatelessWidget {
  final double totalValue;
  final void Function(double ltv) onSuggestionTap;

  const _LtvSuggestionRow({
    required this.totalValue,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    const ltvs = [50.0, 60.0, 70.0, 75.0, 80.0];
    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick LTV Suggestions:',
            style: GirviStyles.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ltvs.map((ltv) {
              final amt = totalValue * (ltv / 100);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSuggestionTap(ltv),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: GirviColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: GirviColors.brandGold.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      Text('${ltv.toInt()}% LTV',
                          style: GoogleFonts.inter(
                              color: GirviColors.brandDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text('â‚¹${fmt.format(amt)}',
                          style: GoogleFonts.manrope(
                              color: GirviColors.textDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LtvIndicator extends StatelessWidget {
  final double ltv;
  final void Function(double) onChanged;

  const _LtvIndicator({required this.ltv, required this.onChanged});

  Color get _color {
    if (ltv <= 60) return GirviColors.success;
    if (ltv <= 75) return GirviColors.warning;
    return GirviColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('LTV Ratio', style: GirviStyles.fieldLabel),
          Text('${ltv.toStringAsFixed(1)}%',
              style: GoogleFonts.manrope(
                  fontSize: 16, fontWeight: FontWeight.w900, color: _color)),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _color,
            thumbColor: _color,
            inactiveTrackColor: GirviColors.divider,
            overlayColor: _color.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: ltv.clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['0%', '25%', '50%', '75%', '100%']
              .map((t) =>
                  Text(t, style: GirviStyles.caption.copyWith(fontSize: 9)))
              .toList(),
        ),
      ]),
    );
  }
}

class _InterestPreviewCard extends StatelessWidget {
  final double principal;
  final double monthly;
  final double total;
  final double totalDue;
  final double annualRate;

  const _InterestPreviewCard({
    required this.principal,
    required this.monthly,
    required this.total,
    required this.totalDue,
    required this.annualRate,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            GirviColors.shellBg,
            GirviColors.shellPanelBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.brandGold.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(GirviIcons.interestRate,
              color: GirviColors.brandGold, size: 16),
          const SizedBox(width: 8),
          Text('Interest Preview',
              style: GoogleFonts.inter(
                  color: GirviColors.shellTextTitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GirviColors.warningBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${annualRate.toStringAsFixed(0)}% p.a.',
                style: GoogleFonts.inter(
                    color: GirviColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PreviewStat('Monthly Interest', 'â‚¹ ${fmt.format(monthly)}',
                GirviColors.warning),
            _PreviewStat('Total Interest', 'â‚¹ ${fmt.format(total)}',
                GirviColors.danger),
            _PreviewStat('Total Due', 'â‚¹ ${fmt.format(totalDue)}',
                GirviColors.brandGold),
          ],
        ),
      ]),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PreviewStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: GoogleFonts.inter(
                color: GirviColors.shellTextMuted, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.manrope(
                color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ]);
}

class _PaymentModeSelector extends StatelessWidget {
  final GirviPaymentMode selected;
  final void Function(GirviPaymentMode) onChanged;

  const _PaymentModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GirviPaymentMode.values.map((mode) {
        final isSelected = mode == selected;
        return GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? GirviColors.brandGold.withValues(alpha: 0.12)
                  : GirviColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? GirviColors.brandGold : GirviColors.cardBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isSelected)
                const Icon(GirviIcons.markDone,
                    color: GirviColors.brandGold, size: 14)
              else
                Icon(_modeIcon(mode), color: GirviColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(mode.displayName,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? GirviColors.brandGold
                        : GirviColors.textBody,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  IconData _modeIcon(GirviPaymentMode m) {
    switch (m) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      default:
        return GirviIcons.bank;
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.fieldLabel),
          const SizedBox(height: 6),
          Container(
            height: GirviStyles.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: GirviStyles.inputNormal,
            child: Row(children: [
              const Icon(GirviIcons.dates,
                  color: GirviColors.accentDates, size: 18),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: GirviColors.cardBorder),
              const SizedBox(width: 10),
              Text(DateFormat('dd MMM yyyy').format(date),
                  style: GirviStyles.fieldInput),
              const Spacer(),
              const Icon(Icons.edit_calendar_rounded,
                  color: GirviColors.textHint, size: 16),
            ]),
          ),
        ],
      ),
    );
  }
}
