import 'dart:io';

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

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../database/db/app_database.dart';
import '../../../logic/dashboard/date_card/date_card_logic.dart';
import '../../../logic/girvi/new_girvi_controller.dart';
import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_invoice_draft.dart';
import '../../../models/girvi/girvi_persistence_models.dart';
import '../../../repositories/girvi/girvi_details_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import '../invoice_hub/girvi_invoice_hub_screen.dart';
import 'new_girvi_app_bar.dart'; // NAYA IMPORT
import '../shared/girvi_shared_widgets.dart';
import '../shared/select_customer_dialog.dart';

part 'parts/new_girvi_actions.dart';
part 'parts/new_girvi_kyc_camera.dart';
part 'parts/new_girvi_layout.dart';
part 'parts/new_girvi_pledged_items.dart';
part 'parts/new_girvi_sections.dart';
part 'parts/new_girvi_widgets.dart';

class NewGirviScreen extends StatefulWidget {
  final int? editLoanId;
  final VoidCallback? onBack;

  const NewGirviScreen({
    super.key,
    this.editLoanId,
    this.onBack,
  });

  @override
  State<NewGirviScreen> createState() => _NewGirviScreenState();
}

class _NewGirviScreenState extends State<NewGirviScreen>
    with TickerProviderStateMixin {
  // â”€â”€ Controller â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final NewGirviController _ctrl;
  late final DateCardLogic _dateLogic;
  final AppDatabase _db = AppDatabase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // â”€â”€ Text Controllers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _itemDescCtrl = TextEditingController();
  final _huidCtrl = TextEditingController();
  final _grossWtCtrl = TextEditingController();
  final _stoneWtCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _loanAmtCtrl = TextEditingController();
  final _interestCtrl = TextEditingController(text: '5.0');
  final _durationCtrl = TextEditingController(text: '12');
  final _cashDisbursementCtrl = TextEditingController();
  final _upiDisbursementCtrl = TextEditingController();
  final _bankDisbursementCtrl = TextEditingController();
  final _chequeDisbursementCtrl = TextEditingController();
  final _idProofNoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _itemPhotoPath;
  String? _idProofImagePath;
  late final List<_PledgedItemDraft> _pledgedItems;

  // â”€â”€ Focus Nodes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _itemDescFocus = FocusNode();
  final _huidFocus = FocusNode();
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
    _dateLogic = DateCardLogic();
    _dateLogic.init();
    _pledgedItems = [];

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
    _idProofNoCtrl.addListener(_onSummaryTextChanged);
    for (final c in _disbursementControllers) {
      c.addListener(_onDisbursementAmountChanged);
    }

    _loanAmtCtrl.addListener(() {
      _ctrl.onLoanAmountChanged(_loanAmtCtrl.text);
    });

    _ctrl.addListener(_onControllerUpdate);
    _initializeController();
  }

  Future<void> _initializeController() async {
    if (widget.editLoanId != null) {
      final loaded = await _ctrl.initializeForEdit(widget.editLoanId!);
      if (!mounted) return;
      final details = _ctrl.editingDetails;
      if (loaded && details != null) {
        _applyLoadedGirviToForm(details);
      }
    } else {
      await _ctrl.initialize();
    }
    if (!mounted) return;
    _setControllerTextIfChanged(
      _interestCtrl,
      _ctrl.interestRate.toStringAsFixed(2),
    );
    _setControllerTextIfChanged(
      _durationCtrl,
      _ctrl.durationMonths.toString(),
    );
    _setControllerTextIfChanged(
      _loanAmtCtrl,
      _ctrl.loanAmount > 0 ? _ctrl.loanAmount.toStringAsFixed(2) : '',
    );
  }

  void _applyLoadedGirviToForm(GirviLoanDetails details) {
    final loan = details.loan;

    for (final item in _pledgedItems) {
      item.dispose();
    }
    _pledgedItems.clear();

    for (final itemDetails in details.items) {
      final draft = _createPledgedItemDraft(itemDetails.item.serialNo);
      _pledgedItems.add(draft);
      _populatePledgedDraft(draft, itemDetails);
    }

    _setControllerTextIfChanged(_idProofNoCtrl, loan.idProofNumber ?? '');
    _setControllerTextIfChanged(_notesCtrl, loan.notes ?? '');
    _setControllerTextIfChanged(
      _interestCtrl,
      loan.interestRate.toStringAsFixed(2),
    );
    _setControllerTextIfChanged(
      _durationCtrl,
      loan.durationMonths.toString(),
    );
    _setControllerTextIfChanged(
      _loanAmtCtrl,
      loan.loanAmount > 0 ? loan.loanAmount.toStringAsFixed(2) : '',
    );
    _idProofImagePath = loan.idProofImagePath;

    for (final controller in _disbursementControllers) {
      _setControllerTextIfChanged(controller, '');
    }
    for (final disbursement in details.disbursements) {
      final mode = GirviPaymentMode.fromDb(disbursement.mode);
      _setControllerTextIfChanged(
        _disbursementControllerFor(mode),
        disbursement.amount.toStringAsFixed(2),
      );
    }

    _syncPledgedItemsToController();
    _syncPrimaryDisbursementMode();
    _itemPhotoPath = _firstAttachedItemPhoto();
    if (mounted) setState(() {});
  }

  void _populatePledgedDraft(
    _PledgedItemDraft draft,
    GirviLoanItemDetails details,
  ) {
    final item = details.item;
    final metal = MetalType.fromDb(item.metalType);
    draft.metalType = metal;

    final matchedPurity = _matchPurityText(metal, item.purity);
    if (matchedPurity == null) {
      draft.purity = MetalPurity.other;
      _setControllerTextIfChanged(draft.customPurityCtrl, item.purity);
    } else {
      draft.purity = matchedPurity;
      _setControllerTextIfChanged(
          draft.customPurityCtrl, matchedPurity.dbValue);
    }

    _setControllerTextIfChanged(draft.descriptionCtrl, item.itemName);
    _setControllerTextIfChanged(draft.piecesCtrl, item.pieces.toString());
    _setControllerTextIfChanged(draft.huidCtrl, item.huidNumber ?? '');
    _setControllerTextIfChanged(
      draft.grossCtrl,
      item.grossWeight > 0 ? item.grossWeight.toStringAsFixed(3) : '',
    );
    _setControllerTextIfChanged(
      draft.lessCtrl,
      item.lessWeight > 0 ? item.lessWeight.toStringAsFixed(3) : '',
    );
    _setControllerTextIfChanged(
      draft.valuationPurityCtrl,
      item.valuationPurityPercent == null
          ? ''
          : _formatPurityPercent(item.valuationPurityPercent!),
    );
    _setControllerTextIfChanged(
      draft.rateCtrl,
      item.ratePerGram > 0 ? item.ratePerGram.toStringAsFixed(2) : '',
    );
    draft.photoPaths
      ..clear()
      ..addAll(details.photos.map((photo) => photo.filePath));
  }

  _PledgedItemDraft _createPledgedItemDraft(int serialNo) {
    return _PledgedItemDraft(
      serialNo: serialNo,
      onChanged: _onPledgedItemChanged,
    );
  }

  void _onPledgedItemChanged() {
    _syncPledgedItemsToController();
    if (mounted) setState(() {});
  }

  void _addPledgedItem() {
    if (!mounted) return;
    late final _PledgedItemDraft item;
    setState(() {
      item = _createPledgedItemDraft(_pledgedItems.length + 1);
      _pledgedItems.add(item);
    });
    _syncPledgedItemsToController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      item.descriptionFocus.requestFocus();
    });
  }

  void _removePledgedItem(_PledgedItemDraft item) {
    if (!mounted) return;
    setState(() {
      _pledgedItems.remove(item);
      for (var i = 0; i < _pledgedItems.length; i++) {
        _pledgedItems[i].serialNo = i + 1;
      }
    });
    item.dispose();
    _syncPledgedItemsToController();
  }

  void _addPledgedItemPhotoPaths(_PledgedItemDraft item, List<String> paths) {
    if (!mounted) return;
    setState(() => item.photoPaths.addAll(paths));
    _syncPledgedItemsToController();
  }

  void _removePledgedItemPhotoPath(_PledgedItemDraft item, String path) {
    if (!mounted) return;
    setState(() => item.photoPaths.remove(path));
    _syncPledgedItemsToController();
  }

  void _clearPledgedItemPhotos(_PledgedItemDraft item) {
    if (!mounted) return;
    setState(() => item.photoPaths.clear());
    _syncPledgedItemsToController();
  }

  void _resetPledgedItems() {
    for (final item in _pledgedItems) {
      item.dispose();
    }
    _pledgedItems.clear();
    _syncPledgedItemsToController();
    if (mounted) setState(() {});
  }

  void _syncPledgedItemsToController() {
    if (_pledgedItems.isEmpty) {
      _setControllerTextIfChanged(_grossWtCtrl, '');
      _setControllerTextIfChanged(_stoneWtCtrl, '');
      _setControllerTextIfChanged(_rateCtrl, '');
      _setControllerTextIfChanged(_loanAmtCtrl, '');
      _setControllerTextIfChanged(_itemDescCtrl, '');
      _setControllerTextIfChanged(_huidCtrl, '');
      _itemPhotoPath = null;
      if (_ctrl.itemCount != 1) {
        _ctrl.setItemCount(1);
      }
      return;
    }

    final totalGross =
        _pledgedItems.fold<double>(0, (sum, item) => sum + item.grossWeight);
    final totalLess =
        _pledgedItems.fold<double>(0, (sum, item) => sum + item.lessWeight);
    final totalNet =
        _pledgedItems.fold<double>(0, (sum, item) => sum + item.netWeight);
    final totalValue =
        _pledgedItems.fold<double>(0, (sum, item) => sum + item.itemValue);
    final totalPieces =
        _pledgedItems.fold<int>(0, (sum, item) => sum + item.itemCount);
    final weightedRate = totalNet > 0 ? totalValue / totalNet : 0.0;
    final first = _pledgedItems.first;

    _setControllerTextIfChanged(
      _grossWtCtrl,
      totalGross > 0 ? totalGross.toStringAsFixed(3) : '',
    );
    _setControllerTextIfChanged(
      _stoneWtCtrl,
      totalLess > 0 ? totalLess.toStringAsFixed(3) : '',
    );
    _setControllerTextIfChanged(
      _rateCtrl,
      weightedRate > 0 ? weightedRate.toStringAsFixed(2) : '',
    );
    _setControllerTextIfChanged(_itemDescCtrl, _combinedItemDescription());
    _setControllerTextIfChanged(_huidCtrl, _combinedHuidNumbers());
    _itemPhotoPath = _firstAttachedItemPhoto();

    if (_ctrl.itemCount != totalPieces.clamp(1, 99)) {
      _ctrl.setItemCount(totalPieces);
    }
    if (_ctrl.metalType != first.metalType) {
      _ctrl.setMetalType(first.metalType);
    }
    if (_ctrl.metalPurity != first.purity) {
      _ctrl.setMetalPurity(first.purity);
    }
  }

  void _setControllerTextIfChanged(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) return;
    controller.text = value;
  }

  String _combinedItemDescription() {
    final lines = <String>[];
    for (final item in _pledgedItems) {
      final description = item.descriptionCtrl.text.trim();
      final title = description.isEmpty ? 'Pledged item' : description;
      lines.add(
        '#${item.serialNo} $title | ${item.metalType.displayName} | '
        '${item.purityLabel} | ${item.itemCount} pcs | '
        'Net ${item.netWeight.toStringAsFixed(3)} g | '
        'Valuation ${item.valuationPurityLabel} | '
        'Value Rs ${_fmt.format(item.itemValue)}',
      );
    }
    return lines.join('\n');
  }

  String _combinedHuidNumbers() {
    return _pledgedItems
        .map((item) => item.huidCtrl.text.trim())
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  String? _firstAttachedItemPhoto() {
    for (final item in _pledgedItems) {
      final paths = item.validPhotoPaths;
      if (paths.isNotEmpty) return paths.first;
    }
    return null;
  }

  void _onControllerUpdate() {
    // Sync loanAmt field when controller recomputes via LTV slider
    final ctrlVal = _ctrl.loanAmount.toStringAsFixed(2);
    if (_loanAmtCtrl.text != ctrlVal && !_loanAmtFocus.hasFocus) {
      _loanAmtCtrl.text = ctrlVal == '0.00' ? '' : ctrlVal;
    }
  }

  void _setItemPhotoPath(String? path) {
    if (!mounted) return;
    setState(() => _itemPhotoPath = path);
  }

  void _setIdProofImagePath(String? path) {
    if (!mounted) return;
    setState(() => _idProofImagePath = path);
  }

  void _onSummaryTextChanged() {
    if (mounted) setState(() {});
  }

  void _handleBackNavigation() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  List<TextEditingController> get _disbursementControllers => [
        _cashDisbursementCtrl,
        _upiDisbursementCtrl,
        _bankDisbursementCtrl,
        _chequeDisbursementCtrl,
      ];

  TextEditingController _disbursementControllerFor(GirviPaymentMode mode) {
    switch (mode) {
      case GirviPaymentMode.cash:
        return _cashDisbursementCtrl;
      case GirviPaymentMode.upi:
        return _upiDisbursementCtrl;
      case GirviPaymentMode.bankTransfer:
        return _bankDisbursementCtrl;
      case GirviPaymentMode.cheque:
        return _chequeDisbursementCtrl;
      case GirviPaymentMode.neft:
        return _bankDisbursementCtrl;
    }
  }

  double _parseAmount(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0.0;
  }

  double _disbursementAmountFor(GirviPaymentMode mode) =>
      _parseAmount(_disbursementControllerFor(mode));

  double get _totalDisbursementAmount =>
      _disbursementControllers.fold(0.0, (sum, c) => sum + _parseAmount(c));

  double get _remainingDisbursementAmount =>
      (_ctrl.loanAmount - _totalDisbursementAmount);

  String get _disbursementSummaryLabel {
    final parts = <String>[];
    for (final mode in _visibleDisbursementModes) {
      final amount = _disbursementAmountFor(mode);
      if (amount > 0) {
        parts.add('${_disbursementModeLabel(mode)} Rs ${_fmt.format(amount)}');
      }
    }
    if (parts.isEmpty) return _ctrl.disbursementMode.displayName;
    return parts.join(' + ');
  }

  String _disbursementModeLabel(GirviPaymentMode mode) {
    switch (mode) {
      case GirviPaymentMode.cash:
        return 'Cash';
      case GirviPaymentMode.upi:
        return 'UPI';
      case GirviPaymentMode.bankTransfer:
        return 'Bank / IMPS';
      case GirviPaymentMode.cheque:
        return 'Cheque';
      case GirviPaymentMode.neft:
        return 'Bank / IMPS';
    }
  }

  IconData _disbursementModeIcon(GirviPaymentMode mode) {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      case GirviPaymentMode.bankTransfer:
      case GirviPaymentMode.neft:
        return GirviIcons.bank;
      case GirviPaymentMode.cheque:
        return Icons.receipt_long_outlined;
    }
  }

  Color _disbursementModeColor(GirviPaymentMode mode) {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviColors.success;
      case GirviPaymentMode.upi:
        return GirviColors.info;
      case GirviPaymentMode.bankTransfer:
      case GirviPaymentMode.neft:
        return GirviColors.purple;
      case GirviPaymentMode.cheque:
        return GirviColors.warning;
    }
  }

  List<GirviPaymentMode> get _visibleDisbursementModes => const [
        GirviPaymentMode.cash,
        GirviPaymentMode.upi,
        GirviPaymentMode.bankTransfer,
        GirviPaymentMode.cheque,
      ];

  void _onDisbursementAmountChanged() {
    _syncPrimaryDisbursementMode();
    if (mounted) setState(() {});
  }

  void _syncPrimaryDisbursementMode() {
    for (final mode in _visibleDisbursementModes) {
      if (_disbursementAmountFor(mode) > 0) {
        if (_ctrl.disbursementMode != mode) _ctrl.setDisbursementMode(mode);
        return;
      }
    }
  }

  void _activateDisbursementMode(GirviPaymentMode mode) {
    final controller = _disbursementControllerFor(mode);
    if (_parseAmount(controller) <= 0 && _ctrl.loanAmount > 0) {
      final remaining = _remainingDisbursementAmount;
      final fill = remaining > 0
          ? remaining
          : (_totalDisbursementAmount <= 0 ? _ctrl.loanAmount : 0.0);
      if (fill > 0) controller.text = fill.toStringAsFixed(2);
    }
    _ctrl.setDisbursementMode(mode);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _dateLogic.dispose();
    for (final item in _pledgedItems) {
      item.dispose();
    }
    for (final c in [
      _itemDescCtrl,
      _huidCtrl,
      _grossWtCtrl,
      _stoneWtCtrl,
      _rateCtrl,
      _loanAmtCtrl,
      _interestCtrl,
      _durationCtrl,
      _cashDisbursementCtrl,
      _upiDisbursementCtrl,
      _bankDisbursementCtrl,
      _chequeDisbursementCtrl,
      _idProofNoCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _itemDescFocus,
      _huidFocus,
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

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): _addPledgedItem,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: GirviColors.bodyBg,
          // NAYA APP BAR CALL YAHAN HAI
          appBar: NewGirviAppBar(
            title: _ctrl.isEditMode
                ? 'Edit Girvi Ticket'
                : GirviStrings.newGirviTitle,
            onBack: _handleBackNavigation,
          ),
          body: ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              if (_ctrl.isLoadingEdit) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: GirviColors.brandGold,
                  ),
                );
              }

              return Form(
                key: _formKey,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // â”€â”€ Ticket Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 1120;
                          return wide
                              ? const SizedBox.shrink()
                              : _buildHeaderRow();
                        },
                      ),
                    ),

                    // â”€â”€ Error Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (_ctrl.errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: GirviErrorBanner(message: _ctrl.errorMessage!),
                        ),
                      ),

                    // â”€â”€ Sections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 1120;
                            if (!wide) {
                              return Column(
                                children: [
                                  _buildMainEntryColumn(),
                                  const SizedBox(height: 16),
                                  _buildTicketSummaryPanel(),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 70,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHeaderDeck(),
                                      const SizedBox(height: 16),
                                      _buildMainEntryColumn(includeKyc: false),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 30,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _animated(7, _buildSection7KYC()),
                                      const SizedBox(height: 16),
                                      _buildTicketSummaryPanel(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),

      // â”€â”€ Bottom Action Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    );
  }
}
