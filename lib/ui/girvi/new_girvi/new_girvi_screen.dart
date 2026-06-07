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

  // â”€â”€ ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _onSave({bool generateInvoice = false}) async {
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
      huidNumber: _huidCtrl.text,
      itemPhotoPath: _itemPhotoPath,
      invoiceGenerated: generateInvoice,
      idProofNumber: _idProofNoCtrl.text,
      notes: _notesCtrl.text,
    );

    if (ok && mounted) {
      if (generateInvoice) {
        try {
          await _printGirviInvoice();
        } catch (e) {
          debugPrint('NewGirviScreen._printGirviInvoice error: $e');
          if (mounted) {
            _showError('Loan saved, but invoice could not be generated.');
          }
        }
      }
      if (!mounted) return;
      _showSuccess(_ctrl.successMessage ?? GirviStrings.successGirviSaved);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _resetAll();
    }
  }

  Future<void> _resetAll() async {
    _formKey.currentState?.reset();
    for (final c in [
      _itemDescCtrl,
      _huidCtrl,
      _grossWtCtrl,
      _stoneWtCtrl,
      _rateCtrl,
      _loanAmtCtrl,
      _idProofNoCtrl,
      _notesCtrl,
    ]) {
      c.clear();
    }
    _itemPhotoPath = null;
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

  Future<void> _pickItemPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Select Pledged Item Photo',
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    try {
      final source = File(path);
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir =
          Directory(p.join(appDir.path, 'lotus_erp', 'girvi_item_photos'));
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final extension = p.extension(path).isEmpty ? '.jpg' : p.extension(path);
      final safeTicket = _ctrl.ticketNo
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final fileName =
          '${safeTicket}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedPath = p.join(photoDir.path, fileName);
      await source.copy(savedPath);

      if (!mounted) return;
      setState(() => _itemPhotoPath = savedPath);
    } catch (e) {
      debugPrint('NewGirviScreen._pickItemPhoto error: $e');
      if (mounted) {
        _showError('Item photo could not be attached. Please try again.');
      }
    }
  }

  void _removeItemPhoto() {
    if (!mounted) return;
    setState(() => _itemPhotoPath = null);
  }

  Future<void> _printGirviInvoice() async {
    final customer = _ctrl.selectedCustomer;
    if (customer == null) return;
    final pdf = pw.Document();
    final createdAt = DateTime.now();
    final huid = _huidCtrl.text.trim();
    final hasPhoto =
        _itemPhotoPath != null && File(_itemPhotoPath!).existsSync();
    final photoBytes =
        hasPhoto ? File(_itemPhotoPath!).readAsBytesSync() : null;

    String amount(double value) => 'Rs ${_fmt.format(value)}';
    String date(DateTime value) => _dateFmt.format(value);

    pw.Widget infoLine(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget sectionTitle(String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF111827)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LOTUS ERP',
                        style: pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('GIRVI LOAN INVOICE',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 3),
                    pw.Text('Pawn loan ticket and pledged item receipt',
                        style: const pw.TextStyle(
                            color: PdfColors.grey300, fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(_ctrl.ticketNo,
                        style: pw.TextStyle(
                            color: PdfColors.amber,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(date(createdAt),
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      sectionTitle('Customer Details'),
                      infoLine('Name', customer.name, bold: true),
                      infoLine('Mobile', customer.mobile),
                      infoLine('City', customer.city ?? '-'),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFBF7ED),
                    border: pw.Border.all(color: PdfColors.amber100),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      sectionTitle('Loan Summary'),
                      infoLine('Principal', amount(_ctrl.loanAmount),
                          bold: true),
                      infoLine('Interest Rate',
                          '${_ctrl.interestRate.toStringAsFixed(2)}% / month'),
                      infoLine('Duration', '${_ctrl.durationMonths} months'),
                      infoLine('Maturity Date', date(_ctrl.maturityDate)),
                      infoLine('Maturity Due', amount(_ctrl.totalDueAtMaturity),
                          bold: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          sectionTitle('Pledged Item'),
          pw.TableHelper.fromTextArray(
            headers: const [
              'S/N',
              'Metal',
              'Description',
              'Purity',
              'Pieces',
              'Gross',
              'Less',
              'Net',
              'HUID',
              'Loan',
            ],
            data: [
              [
                '1',
                _ctrl.metalType.displayName,
                _itemDescCtrl.text.trim(),
                _ctrl.metalPurity.displayName,
                _ctrl.itemCount.toString(),
                '${_ctrl.grossWeight.toStringAsFixed(3)} g',
                '${_ctrl.stoneWeight.toStringAsFixed(3)} g',
                '${_ctrl.netWeight.toStringAsFixed(3)} g',
                huid.isEmpty ? '-' : huid,
                amount(_ctrl.loanAmount),
              ],
            ],
            headerStyle:
                pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7.2),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE4)),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          if (photoBytes != null) ...[
            pw.SizedBox(height: 14),
            sectionTitle('Item Photo'),
            pw.Container(
              width: 140,
              height: 110,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Image(pw.MemoryImage(photoBytes), fit: pw.BoxFit.cover),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF9FAFB),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              'This document records the loan disbursement against the pledged item listed above. Final settlement will be calculated as per actual release date, applicable interest, and any approved charges.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'girvi_invoice_${_ctrl.ticketNo.replaceAll('/', '_')}.pdf',
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                            Expanded(flex: 70, child: _buildMainEntryColumn()),
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

  // â”€â”€ TICKET BANNER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMainEntryColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDeskStatusStrip(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= 760;
            if (!twoColumn) {
              return Column(
                children: [
                  _animated(0, _buildSection0Customer()),
                  const SizedBox(height: 16),
                  _animated(1, _buildSection1ItemDetails()),
                  const SizedBox(height: 16),
                  _animated(2, _buildSection2Weight()),
                  const SizedBox(height: 16),
                  _animated(3, _buildSection3Valuation()),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _animated(0, _buildSection0Customer()),
                      const SizedBox(height: 16),
                      _animated(1, _buildSection1ItemDetails()),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _animated(2, _buildSection2Weight()),
                      const SizedBox(height: 16),
                      _animated(3, _buildSection3Valuation()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _animated(4, _buildSection4LoanTerms()),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= 760;
            if (!twoColumn) {
              return Column(
                children: [
                  _animated(5, _buildSection5Disbursement()),
                  const SizedBox(height: 16),
                  _animated(6, _buildSection6Dates()),
                  const SizedBox(height: 16),
                  _animated(7, _buildSection7KYC()),
                  const SizedBox(height: 16),
                  _animated(8, _buildSection8Notes()),
                ],
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _animated(5, _buildSection5Disbursement())),
                    const SizedBox(width: 16),
                    Expanded(child: _animated(6, _buildSection6Dates())),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _animated(7, _buildSection7KYC())),
                    const SizedBox(width: 16),
                    Expanded(child: _animated(8, _buildSection8Notes())),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeskStatusStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final children = [
            _DeskMetric(
              icon: GirviIcons.customer,
              label: 'Customer',
              value: _ctrl.hasCustomer
                  ? _ctrl.selectedCustomer!.name
                  : 'Not selected',
              color: GirviColors.accentCustomer,
            ),
            _DeskMetric(
              icon: GirviIcons.weight,
              label: 'Net Weight',
              value: '${_ctrl.netWeight.toStringAsFixed(3)} g',
              color: GirviColors.accentWeight,
            ),
            _DeskMetric(
              icon: GirviIcons.valuation,
              label: 'Item Value',
              value: 'Rs ${_fmt.format(_ctrl.totalValue)}',
              color: GirviColors.accentValuation,
            ),
            _DeskMetric(
              icon: GirviIcons.loanTerms,
              label: 'Loan Amount',
              value: 'Rs ${_fmt.format(_ctrl.loanAmount)}',
              color: GirviColors.accentLoan,
            ),
          ];
          if (compact) {
            return Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  children[i],
                ],
              ],
            );
          }
          return Row(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: children[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketSummaryPanel() {
    final customer = _ctrl.selectedCustomer;
    return Container(
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            decoration: const BoxDecoration(
              color: GirviColors.shellBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GirviColors.brandGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(GirviIcons.ticket,
                      color: GirviColors.brandGold, size: 18),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loan Invoice Summary',
                          style: GoogleFonts.manrope(
                              color: GirviColors.shellTextTitle,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        _ctrl.ticketNo.isEmpty
                            ? 'Generating ticket number'
                            : _ctrl.ticketNo,
                        style: GirviStyles.ticketNumber.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: _ctrl.isFormReady ? 'READY' : 'DRAFT',
                  color: _ctrl.isFormReady
                      ? GirviColors.success
                      : GirviColors.warning,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryLine(
                  label: 'Customer',
                  value: customer?.name ?? 'Select customer',
                  highlight: _ctrl.hasCustomer,
                ),
                _SummaryLine(
                  label: 'Mobile',
                  value: customer?.mobile ?? '-',
                ),
                const Divider(height: 24, color: GirviColors.divider),
                _AmountSummaryTile(
                  label: 'Loan Disbursement',
                  value: 'Rs ${_fmt.format(_ctrl.loanAmount)}',
                  color: GirviColors.brandGold,
                ),
                const SizedBox(height: 10),
                _SummaryLine(
                  label: 'Item Value',
                  value: 'Rs ${_fmt.format(_ctrl.totalValue)}',
                ),
                _SummaryLine(
                  label: 'LTV Ratio',
                  value: '${_ctrl.computedLtv.toStringAsFixed(1)}%',
                ),
                _SummaryLine(
                  label: 'Monthly Interest',
                  value: 'Rs ${_fmt.format(_ctrl.monthlyInterest)}',
                ),
                _SummaryLine(
                  label: 'Maturity Due',
                  value: 'Rs ${_fmt.format(_ctrl.totalDueAtMaturity)}',
                  highlight: _ctrl.loanAmount > 0,
                ),
                const Divider(height: 24, color: GirviColors.divider),
                _SummaryLine(
                  label: 'Metal',
                  value:
                      '${_ctrl.metalType.displayName} / ${_ctrl.metalPurity.displayName}',
                ),
                _SummaryLine(
                  label: 'HUID',
                  value: _huidCtrl.text.trim().isEmpty
                      ? '-'
                      : _huidCtrl.text.trim(),
                ),
                _SummaryLine(
                  label: 'Item Photo',
                  value: _itemPhotoPath == null ? 'Not attached' : 'Attached',
                  highlight: _itemPhotoPath != null,
                ),
                _SummaryLine(
                  label: 'Net Weight',
                  value: '${_ctrl.netWeight.toStringAsFixed(3)} g',
                ),
                _SummaryLine(
                  label: 'Duration',
                  value: '${_ctrl.durationMonths} months',
                ),
                _SummaryLine(
                  label: 'Maturity Date',
                  value: _dateFmt.format(_ctrl.maturityDate),
                ),
                _SummaryLine(
                  label: 'Disbursement',
                  value: _ctrl.disbursementMode.displayName,
                ),
                const SizedBox(height: 16),
                _TicketActionButton(
                  label: 'Generate Invoice',
                  icon: GirviIcons.save,
                  filled: true,
                  busy: _ctrl.isSaving,
                  onTap: _ctrl.isSaving
                      ? null
                      : () => _onSave(generateInvoice: true),
                ),
                const SizedBox(height: 10),
                _TicketActionButton(
                  label: 'Save Without Invoice',
                  icon: Icons.inventory_2_outlined,
                  filled: false,
                  onTap: _ctrl.isSaving
                      ? null
                      : () => _onSave(generateInvoice: false),
                ),
                const SizedBox(height: 10),
                _TicketActionButton(
                  label: 'Reset Entry',
                  icon: GirviIcons.refresh,
                  filled: false,
                  onTap: _ctrl.isSaving ? null : _resetAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketBanner() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GirviColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: GirviColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: GirviColors.shadowMedium,
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ticketAccentLine(20, 1.0),
                            const SizedBox(height: 3),
                            _ticketAccentLine(13, 0.45),
                            const SizedBox(height: 3),
                            _ticketAccentLine(7, 0.18),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOAN INVOICE NUMBER',
                              style: GoogleFonts.inter(
                                color: GirviColors.textDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Girvi Loan Invoice',
                              style: GoogleFonts.inter(
                                color: GirviColors.brandGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GirviColors.bodyBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GirviColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: GirviColors.brandGold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'DRAFT',
                            style: GoogleFonts.inter(
                              color: GirviColors.brandDeep,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 1,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  color: GirviColors.cardBorder,
                ),
                SizedBox(
                  height: 52,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoanInvoiceIconBox(),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOAN INVOICE NO.',
                            style: GoogleFonts.inter(
                              color: GirviColors.textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _ctrl.ticketNo.isEmpty
                                ? 'Generating...'
                                : _ctrl.ticketNo,
                            style: GirviStyles.ticketNumber.copyWith(
                              color: GirviColors.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 1,
                        height: 34,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              GirviColors.cardBorder,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      StreamBuilder<DateCardModel>(
                        stream: _dateLogic.timeStream,
                        initialData: _dateLogic.initialData,
                        builder: (context, snapshot) {
                          final data = snapshot.data ?? _dateLogic.initialData;
                          return _buildLoanDateTimeRow(data);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanInvoiceIconBox() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.25)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    GirviColors.brandGold.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.receipt_long_outlined,
              color: GirviColors.brandGold,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDateTimeRow(DateCardModel data) {
    final timeParts = data.time.split(':');
    final cleanTime =
        timeParts.length >= 2 ? '${timeParts[0]} : ${timeParts[1]}' : data.time;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoanChip(
          icon: GirviIcons.dates,
          iconColor: GirviColors.textDark,
          subLabel: 'DATE',
          value: data.date.toUpperCase(),
          valueColor: GirviColors.textDark,
          valueFontSize: 13,
          chipBg: GirviColors.bodyBg,
          chipBorder: GirviColors.cardBorder,
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: GirviColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        _buildLoanChip(
          icon: Icons.schedule_rounded,
          iconColor: GirviColors.success,
          subLabel: 'TIME',
          value: cleanTime,
          valueColor: GirviColors.success,
          valueFontSize: 14,
          chipBg: GirviColors.success.withValues(alpha: 0.07),
          chipBorder: GirviColors.success.withValues(alpha: 0.25),
        ),
      ],
    );
  }

  Widget _buildLoanChip({
    required IconData icon,
    required Color iconColor,
    required String subLabel,
    required String value,
    required Color valueColor,
    required double valueFontSize,
    required Color chipBg,
    required Color chipBorder,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subLabel,
                style: GoogleFonts.inter(
                  color: iconColor.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: valueColor,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ticketAccentLine(double width, double opacity) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: GirviColors.brandGold.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // â”€â”€ SECTION 0: CUSTOMER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection0Customer() {
    return GirviSectionCard(
      icon: GirviIcons.customer,
      title: 'Customer Details',
      subtitle: 'Borrower profile for this loan ticket',
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
      title: 'Pledged Item',
      subtitle: 'Item line, hallmark and metal classification',
      accent: GirviColors.accentItem,
      child: Column(children: [
        _PledgedItemHeader(
          photoPath: _itemPhotoPath,
          onPickPhoto: _pickItemPhoto,
          onRemovePhoto: _removeItemPhoto,
        ),
        const SizedBox(height: 14),
        GirviInputField(
          label: 'Item Description *',
          hint: 'e.g. Gold Necklace with pendant, 2 bangles',
          icon: GirviIcons.itemDetails,
          controller: _itemDescCtrl,
          focusNode: _itemDescFocus,
          nextFocus: _huidFocus,
          maxLines: 2,
          validator: _ctrl.validateItemDescription,
        ),
        const SizedBox(height: 14),
        GirviInputField(
          label: 'HUID / Hallmark Number',
          hint: 'Enter HUID, certificate or tag number',
          icon: Icons.verified_outlined,
          controller: _huidCtrl,
          focusNode: _huidFocus,
          nextFocus: _grossWtFocus,
          keyboardType: TextInputType.text,
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
                      child: Text(e.displayName),
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
            label: 'Less / Stone Weight (g)',
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
          label: 'Market Rate (Rs / gram) *',
          hint: '0.00',
          icon: GirviIcons.valuation,
          controller: _rateCtrl,
          focusNode: _rateFocus,
          nextFocus: _loanAmtFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          prefixText: 'Rs ',
          validator: _ctrl.validateRatePerGram,
        ),
        const SizedBox(height: 14),
        // Computed total value
        GirviReadOnlyField(
          label: 'Total Item Value',
          value: 'Rs ${_fmt.format(_ctrl.totalValue)}',
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
          label: 'Loan Amount (Rs) *',
          hint: '0.00',
          icon: GirviIcons.loanTerms,
          controller: _loanAmtCtrl,
          focusNode: _loanAmtFocus,
          nextFocus: _interestFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          prefixText: 'Rs ',
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
                    'RBI guidelines require ID proof for pawn loans above Rs 1,000.',
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
                value: null, child: Text('- Select ID Type -')),
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
}

// =============================================================================
// HELPER WIDGETS (private to this file)
// =============================================================================

class _PledgedItemHeader extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  const _PledgedItemHeader({
    required this.photoPath,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final hasPhoto = path != null && path.isNotEmpty && File(path).existsSync();
    final file = hasPhoto ? File(path) : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final preview = Container(
            width: compact ? 78 : 92,
            height: compact ? 66 : 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasPhoto
                    ? GirviColors.brandGold.withValues(alpha: 0.35)
                    : GirviColors.cardBorder,
              ),
            ),
            child: hasPhoto && file != null
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: GirviColors.textHint,
                      size: 26,
                    ),
                  )
                : const Icon(
                    Icons.add_a_photo_outlined,
                    color: GirviColors.brandGold,
                    size: 26,
                  ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pledged Item Photo',
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPhoto
                    ? 'Photo attached for this ticket audit trail.'
                    : 'Attach a clear image of the pledged item.',
                style: GirviStyles.caption.copyWith(fontSize: 11),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 4),
                Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.caption.copyWith(
                    fontSize: 10,
                    color: GirviColors.textHint,
                  ),
                ),
              ],
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PhotoActionButton(
                icon: hasPhoto ? Icons.sync_rounded : Icons.upload_rounded,
                label: hasPhoto ? 'Change' : 'Upload',
                filled: true,
                onTap: onPickPhoto,
              ),
              if (hasPhoto)
                _PhotoActionButton(
                  icon: Icons.close_rounded,
                  label: 'Remove',
                  filled: false,
                  onTap: onRemovePhoto,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  preview,
                  const SizedBox(width: 12),
                  Expanded(child: details),
                ]),
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              preview,
              const SizedBox(width: 12),
              Expanded(child: details),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? GirviColors.brandGold : GirviColors.textBody;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: filled ? GirviColors.brandGoldLight : GirviColors.cardBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: filled
                ? GirviColors.brandGold.withValues(alpha: 0.35)
                : GirviColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeskMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DeskMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GirviStyles.caption.copyWith(fontSize: 10)),
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
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GirviStyles.caption.copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: highlight ? GirviColors.brandGold : GirviColors.textDark,
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountSummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback? onTap;

  const _TicketActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.busy = false,
    this.onTap,
  });

  @override
  State<_TicketActionButton> createState() => _TicketActionButtonState();
}

class _TicketActionButtonState extends State<_TicketActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bg = widget.filled
        ? GirviColors.brandGold
        : (_hovered && enabled ? GirviColors.brandGoldLight : Colors.white);
    final fg = widget.filled ? GirviColors.shellBg : GirviColors.brandDeep;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? bg : GirviColors.inputBgLocked,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.filled
                  ? GirviColors.brandGold
                  : GirviColors.brandGold.withValues(alpha: 0.55),
            ),
            boxShadow: widget.filled && enabled
                ? [
                    BoxShadow(
                      color: GirviColors.brandGold.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: GirviColors.shellBg,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: fg, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

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
                      Text('Rs ${fmt.format(amt)}',
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
            _PreviewStat('Monthly Interest', 'Rs ${fmt.format(monthly)}',
                GirviColors.warning),
            _PreviewStat('Total Interest', 'Rs ${fmt.format(total)}',
                GirviColors.danger),
            _PreviewStat('Total Due', 'Rs ${fmt.format(totalDue)}',
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
