// =============================================================================
// FILE        : issue_karigar_screen.dart
// MODULE      : Karigar
// LAYER       : UI / Screen
// DESCRIPTION : Full production Issue to Karigar screen.
//               Design matches Add Stock / New Sale POS exactly:
//               - Dark shell AppBar separated to issue_karigar_app_bar.dart
//               - Cream body background (#F9F6F0)
//               - White cards with colored accent borders
//               - Staggered fade + slide section entry animations
//               - ListenableBuilder â€” zero setState in UI
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/karigar/issue_karigar_controller.dart';
import '../../../logic/karigar/karigar_master_controller.dart';
import '../../../models/karigar/karigar_enums/karigar_enums.dart';
import '../../../theme/karigar/karigar_theme.dart';
import 'issue_karigar_app_bar.dart';
import '../shared/karigar_field_widgets.dart';
import '../shared/karigar_section_card.dart';
import '../shared/add_karigar_dialog.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class IssueKarigarScreen extends StatefulWidget {
  const IssueKarigarScreen({super.key});

  @override
  State<IssueKarigarScreen> createState() => _IssueKarigarScreenState();
}

class _IssueKarigarScreenState extends State<IssueKarigarScreen>
    with TickerProviderStateMixin {
  // â”€â”€ Controllers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final IssueKarigarController _ctrl;
  late final KarigarMasterController _masterCtrl;
  final AppDatabase _db = AppDatabase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // â”€â”€ Text Controllers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _descCtrl = TextEditingController();
  final _grossWtCtrl = TextEditingController();
  final _stoneWtCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();

  // â”€â”€ Focus Nodes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _descFocus = FocusNode();
  final _grossWtFocus = FocusNode();
  final _stoneWtFocus = FocusNode();
  final _qtyFocus = FocusNode();

  // â”€â”€ Date state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  DateTime _issueDate = DateTime.now();
  DateTime? _expectedDelivery;

  // â”€â”€ Section Animations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const int _sectionCount = 5;
  late final List<AnimationController> _sectionAnim;
  late final List<Animation<double>> _sectionFade;
  late final List<Animation<Offset>> _sectionSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = IssueKarigarController(_db);
    _masterCtrl = KarigarMasterController(_db);

    // Staggered entry animations
    _sectionAnim = List.generate(
        _sectionCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500)));
    _sectionFade = _sectionAnim
        .map((a) => CurvedAnimation(parent: a, curve: Curves.easeInOut))
        .toList();
    _sectionSlide = _sectionAnim
        .map((a) => Tween<Offset>(
                begin: const Offset(0, 0.10), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)))
        .toList();

    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 60 + i * 80), () {
        if (mounted) _sectionAnim[i].forward();
      });
    }

    // Wire weight listeners
    _grossWtCtrl
        .addListener(() => _ctrl.onGrossWeightChanged(_grossWtCtrl.text));
    _stoneWtCtrl
        .addListener(() => _ctrl.onStoneWeightChanged(_stoneWtCtrl.text));

    _ctrl.initialize();
    _masterCtrl.loadKarigars();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _masterCtrl.dispose();
    for (final c in [
      _descCtrl,
      _grossWtCtrl,
      _stoneWtCtrl,
      _qtyCtrl,
      _notesCtrl
    ]) {
      c.dispose();
    }
    for (final f in [_descFocus, _grossWtFocus, _stoneWtFocus, _qtyFocus]) {
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await _ctrl.saveIssue(
      itemDescription: _descCtrl.text,
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      grossWeight: double.tryParse(_grossWtCtrl.text) ?? 0.0,
      stoneWeight: double.tryParse(_stoneWtCtrl.text) ?? 0.0,
      issueDate: _issueDate,
      expectedDelivery: _expectedDelivery,
      notes: _notesCtrl.text,
    );

    if (ok && mounted) {
      _showSuccessFeedback(
          _ctrl.successMessage ?? KarigarStrings.successIssueSaved);
      _resetAll();
    }
  }

  Future<void> _resetAll() async {
    _formKey.currentState?.reset();
    for (final c in [_descCtrl, _grossWtCtrl, _stoneWtCtrl, _notesCtrl]) {
      c.clear();
    }
    _qtyCtrl.text = '1';
    setState(() {
      _issueDate = DateTime.now();
      _expectedDelivery = null;
    });
    await _ctrl.resetForm();
  }

  void _showSuccessFeedback(String msg) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.success,
      message: msg,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _pickDate({required bool isIssueDate}) async {
    final initial = isIssueDate
        ? _issueDate
        : (_expectedDelivery ?? DateTime.now().add(const Duration(days: 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: KarigarColors.brandGold,
            onPrimary: KarigarColors.shellBg,
            surface: KarigarColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expectedDelivery = picked;
        }
      });
    }
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _sectionFade[i],
        child: SlideTransition(position: _sectionSlide[i], child: child),
      );

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: KarigarColors.shellBg,
        // Extracted App Bar call
        appBar: IssueKarigarAppBar(
          onBack: () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: Container(
            color: KarigarColors.bodyBg,
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (context, _) {
                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: KarigarStyles.pagePadding,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error banner
                        if (_ctrl.hasError)
                          KarigarErrorBanner(
                            message: _ctrl.errorMessage!,
                            onDismiss: _ctrl.clearMessages,
                          ),

                        // â”€â”€ Section 1: Select Karigar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            0,
                            KarigarSectionCard(
                              icon: KarigarIcons.karigarSel,
                              title: KarigarStrings.secSelectKarigar,
                              subtitle: KarigarStrings.descSelectKarigar,
                              accent: KarigarColors.accentKarigar,
                              child: _buildKarigarSection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 2: Issue Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            1,
                            KarigarSectionCard(
                              icon: KarigarIcons.issueDetails,
                              title: KarigarStrings.secIssueDetails,
                              subtitle: KarigarStrings.descIssueDetails,
                              accent: KarigarColors.accentIssue,
                              child: _buildIssueDetailsSection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 3: Metal Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            2,
                            KarigarSectionCard(
                              icon: KarigarIcons.metal,
                              title: KarigarStrings.secMetalDetails,
                              subtitle: KarigarStrings.descMetalDetails,
                              accent: KarigarColors.accentMetal,
                              child: _buildMetalSection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 4: Delivery Timeline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            3,
                            KarigarSectionCard(
                              icon: KarigarIcons.delivery,
                              title: KarigarStrings.secDelivery,
                              subtitle: KarigarStrings.descDelivery,
                              accent: KarigarColors.accentDelivery,
                              child: _buildDeliverySection(),
                            )),
                        const SizedBox(height: 20),

                        // â”€â”€ Section 5: Notes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        _animated(
                            4,
                            KarigarSectionCard(
                              icon: KarigarIcons.notes,
                              title: KarigarStrings.secNotes,
                              subtitle: KarigarStrings.descNotes,
                              accent: KarigarColors.accentNotes,
                              child: _buildNotesSection(),
                            )),
                        const SizedBox(height: 28),

                        // â”€â”€ Action Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  Widget _buildKarigarSection() {
    return ListenableBuilder(
      listenable: _masterCtrl,
      builder: (context, _) {
        if (_masterCtrl.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: KarigarColors.brandGold,
                strokeWidth: 2,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected karigar display
            if (_ctrl.hasKarigar) ...[
              _SelectedKarigarCard(
                karigar: _ctrl.selectedKarigar!,
                onClear: _ctrl.clearKarigar,
              ),
              const SizedBox(height: 14),
            ],

            // Karigar selector button
            _KarigarPickerButton(
              hasKarigar: _ctrl.hasKarigar,
              masterCtrl: _masterCtrl,
              onSelected: _ctrl.selectKarigar,
              onAddNew: () => _showAddKarigarDialog(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIssueDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Issue Number (read-only)
        KarigarReadOnlyField(
          label: KarigarStrings.lblIssueNumber,
          value: _ctrl.issueNumber,
          icon: KarigarIcons.issueNumber,
          color: KarigarColors.brandGold,
        ),
        const SizedBox(height: 16),

        // Item Description
        KarigarInputField(
          label: KarigarStrings.lblItemDesc,
          hint: KarigarStrings.hintItemDesc,
          icon: KarigarIcons.description,
          controller: _descCtrl,
          focusNode: _descFocus,
          nextFocus: _qtyFocus,
          maxLines: 2,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Description is required';
            if (v.trim().length < 2) return 'Description is too short';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Category + Quantity
        KarigarRowTwo(
          left: KarigarDropdown<KarigarItemCategory>(
            label: KarigarStrings.lblCategory,
            icon: KarigarIcons.category,
            value: _ctrl.itemCategory,
            items: KarigarItemCategory.values,
            itemLabel: (e) => e.label,
            onChanged: (v) {
              if (v != null) _ctrl.setItemCategory(v);
            },
          ),
          right: KarigarInputField(
            label: KarigarStrings.lblQuantity,
            hint: KarigarStrings.hintQuantity,
            icon: KarigarIcons.quantity,
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Quantity is required';
              final i = int.tryParse(v);
              if (i == null || i < 1) return 'Minimum 1 piece';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetalSection() {
    final hasPurity = _ctrl.purityOptions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metal Type + Purity
        KarigarRowTwo(
          left: KarigarDropdown<KarigarMetalType>(
            label: KarigarStrings.lblMetalType,
            icon: KarigarIcons.metal,
            value: _ctrl.metalType,
            items: KarigarMetalType.values,
            itemLabel: (e) => e.label,
            onChanged: (v) {
              if (v != null) _ctrl.setMetalType(v);
            },
          ),
          right: hasPurity
              ? KarigarDropdown<String>(
                  label: KarigarStrings.lblPurity,
                  icon: KarigarIcons.purity,
                  value: _ctrl.purity,
                  items: _ctrl.purityOptions,
                  itemLabel: (e) => e,
                  onChanged: (v) {
                    if (v != null) _ctrl.setPurity(v);
                  },
                )
              : const KarigarDisabledField(
                  label: KarigarStrings.lblPurity,
                  icon: KarigarIcons.purity,
                  value: 'N/A for this metal',
                ),
        ),
        const SizedBox(height: 16),

        // Gross | Stone | Net Weight
        Row(children: [
          Expanded(
              child: KarigarInputField(
            label: KarigarStrings.lblGrossWeight,
            hint: KarigarStrings.hintWeight,
            icon: KarigarIcons.weight,
            controller: _grossWtCtrl,
            focusNode: _grossWtFocus,
            nextFocus: _stoneWtFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Gross weight required';
              final d = double.tryParse(v);
              if (d == null || d <= 0) return 'Enter valid weight';
              return null;
            },
          )),
          const SizedBox(width: 14),
          Expanded(
              child: KarigarInputField(
            label: KarigarStrings.lblStoneWeight,
            hint: KarigarStrings.hintWeight,
            icon: KarigarIcons.metal,
            controller: _stoneWtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
          )),
          const SizedBox(width: 14),
          Expanded(
              child: KarigarReadOnlyField(
            label: KarigarStrings.lblNetWeight,
            value: _ctrl.netWeight.toStringAsFixed(3),
            icon: KarigarIcons.weight,
            color: KarigarColors.success,
            note: KarigarStrings.noteNetWeight,
          )),
        ]),
      ],
    );
  }

  Widget _buildDeliverySection() {
    final fmt = DateFormat('dd MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KarigarRowTwo(
          left: _DatePickerField(
            label: KarigarStrings.lblIssueDate,
            value: fmt.format(_issueDate),
            onTap: () => _pickDate(isIssueDate: true),
          ),
          right: _DatePickerField(
            label: KarigarStrings.lblExpectedReturn,
            value: _expectedDelivery != null
                ? fmt.format(_expectedDelivery!)
                : 'Select date (optional)',
            onTap: () => _pickDate(isIssueDate: false),
            isOptional: true,
          ),
        ),

        // Status dropdown
        const SizedBox(height: 16),
        KarigarDropdown<IssueStatus>(
          label: KarigarStrings.lblStatus,
          icon: KarigarIcons.status,
          value: _ctrl.status,
          items: IssueStatus.values,
          itemLabel: (e) => e.label,
          onChanged: (v) {
            if (v != null) _ctrl.setStatus(v);
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return KarigarInputField(
      label: KarigarStrings.lblNotes,
      hint: KarigarStrings.hintNotes,
      icon: KarigarIcons.notes,
      controller: _notesCtrl,
      maxLines: 4,
    );
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
          foregroundColor: KarigarColors.textMuted,
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
                : KarigarStrings.btnSaveIssue,
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

  Future<void> _showAddKarigarDialog() async {
    final added = await showDialog<KarigarMaster>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => AddKarigarDialog(masterCtrl: _masterCtrl),
    );
    if (added != null) {
      _ctrl.selectKarigar(added);
    }
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PRIVATE SUB-WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _SelectedKarigarCard extends StatelessWidget {
  final KarigarMaster karigar;
  final VoidCallback onClear;
  const _SelectedKarigarCard({required this.karigar, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KarigarColors.brandGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: KarigarColors.brandGold.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: KarigarColors.brandGold.withValues(alpha: 0.15),
          radius: 22,
          child: Text(
            _initials(karigar.name),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: KarigarColors.brandGold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(karigar.name, style: KarigarStyles.sectionTitle),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(KarigarIcons.phone,
                  size: 11, color: KarigarColors.textMuted),
              const SizedBox(width: 4),
              Text(karigar.phone, style: KarigarStyles.caption),
              const SizedBox(width: 12),
              const Icon(KarigarIcons.speciality,
                  size: 11, color: KarigarColors.textMuted),
              const SizedBox(width: 4),
              Text(karigar.specialization, style: KarigarStyles.caption),
            ]),
          ],
        )),
        IconButton(
          onPressed: onClear,
          icon: const Icon(KarigarIcons.close,
              color: KarigarColors.textMuted, size: 18),
          tooltip: 'Change karigar',
        ),
      ]),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _KarigarPickerButton extends StatelessWidget {
  final bool hasKarigar;
  final KarigarMasterController masterCtrl;
  final Function(KarigarMaster) onSelected;
  final VoidCallback onAddNew;
  const _KarigarPickerButton({
    required this.hasKarigar,
    required this.masterCtrl,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showPicker(context),
          icon: Icon(
            hasKarigar ? KarigarIcons.karigar : KarigarIcons.search,
            size: 18,
            color: KarigarColors.brandGold,
          ),
          label: Text(
            hasKarigar ? 'Change Karigar' : 'Select Karigar',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KarigarColors.brandGold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: KarigarColors.brandGold, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      OutlinedButton.icon(
        onPressed: onAddNew,
        icon: const Icon(KarigarIcons.addKarigar,
            size: 18, color: KarigarColors.info),
        label: Text('Add New',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KarigarColors.info,
            )),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: KarigarColors.info, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]);
  }

  Future<void> _showPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KarigarColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _KarigarPickerSheet(
        masterCtrl: masterCtrl,
        onSelected: (k) {
          Navigator.pop(context);
          onSelected(k);
        },
      ),
    );
  }
}

class _KarigarPickerSheet extends StatelessWidget {
  final KarigarMasterController masterCtrl;
  final Function(KarigarMaster) onSelected;
  const _KarigarPickerSheet(
      {required this.masterCtrl, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scroll) => Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: KarigarColors.cardBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            autofocus: true,
            onChanged: masterCtrl.onSearchChanged,
            style: KarigarStyles.fieldInput,
            decoration: InputDecoration(
              hintText: 'Search by name or phone...',
              hintStyle: KarigarStyles.fieldHint,
              prefixIcon: const Icon(KarigarIcons.search,
                  color: KarigarColors.textHint, size: 20),
              filled: true,
              fillColor: KarigarColors.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: KarigarColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: KarigarColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: KarigarColors.brandGold, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        // List
        Expanded(
          child: ListenableBuilder(
            listenable: masterCtrl,
            builder: (context, _) {
              final list = masterCtrl.filteredKarigars;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(KarigarIcons.emptyKarigar,
                          size: 48, color: KarigarColors.textHint),
                      const SizedBox(height: 12),
                      Text(KarigarStrings.emptyKarigarTitle,
                          style: KarigarStyles.sectionTitle),
                      const SizedBox(height: 4),
                      Text(KarigarStrings.emptyKarigarSub,
                          style: KarigarStyles.caption),
                    ],
                  ),
                );
              }
              return ListView.separated(
                controller: scroll,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final k = list[i];
                  return InkWell(
                    onTap: () => onSelected(k),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KarigarColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KarigarColors.cardBorder),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: KarigarColors.brandGoldLight,
                          child: Text(
                            _initials(k.name),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: KarigarColors.brandGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k.name, style: KarigarStyles.jobTitle),
                            const SizedBox(height: 2),
                            Text('${k.phone} â€¢ ${k.specialization}',
                                style: KarigarStyles.caption),
                          ],
                        )),
                        const Icon(Icons.chevron_right_rounded,
                            color: KarigarColors.textHint, size: 20),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isOptional;
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.isOptional = false,
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
                    style: isOptional && value.startsWith('Select')
                        ? KarigarStyles.fieldHint
                        : KarigarStyles.fieldInput.copyWith(fontSize: 13)),
              ),
              const Icon(Icons.edit_calendar_rounded,
                  color: KarigarColors.textHint, size: 16),
            ]),
          ),
        ),
      ],
    );
  }
}
