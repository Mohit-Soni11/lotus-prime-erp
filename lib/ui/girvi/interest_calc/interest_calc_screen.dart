import 'dart:math' as math;

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
  final _releaseDiscountCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
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
    _releaseDiscountCtrl.dispose();
    _monthsCtrl.dispose();
    _notesCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
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
        _showInfoSnack('Girvi invoice details could not be loaded.');
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
          _showInfoSnack('Girvi invoice PDF could not be generated.');
          return;
        }
        await _showReceiptPreview(pdfBytes: bytes);
      } finally {
        controller.dispose();
      }
    } catch (error) {
      if (mounted) {
        _showInfoSnack('Girvi invoice preview could not be opened.');
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
}
