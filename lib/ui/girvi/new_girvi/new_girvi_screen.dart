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
import '../../../theme/girvi/girvi_theme.dart';
import 'new_girvi_app_bar.dart'; // NAYA IMPORT
import '../shared/girvi_shared_widgets.dart';
import '../shared/select_customer_dialog.dart';

part 'parts/new_girvi_actions.dart';
part 'parts/new_girvi_layout.dart';
part 'parts/new_girvi_sections.dart';
part 'parts/new_girvi_widgets.dart';

class NewGirviScreen extends StatefulWidget {
  const NewGirviScreen({super.key});

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
  final _interestCtrl = TextEditingController(text: '2.0');
  final _durationCtrl = TextEditingController(text: '12');
  final _idProofNoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _itemPhotoPath;

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

  void _setItemPhotoPath(String? path) {
    if (!mounted) return;
    setState(() => _itemPhotoPath = path);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _dateLogic.dispose();
    for (final c in [
      _itemDescCtrl,
      _huidCtrl,
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
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1120;
                      return wide ? const SizedBox.shrink() : _buildHeaderRow();
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeaderDeck(),
                                  const SizedBox(height: 16),
                                  _buildMainEntryColumn(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 30,
                              child: _buildTicketSummaryPanel(),
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

      // â”€â”€ Bottom Action Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    );
  }
}
