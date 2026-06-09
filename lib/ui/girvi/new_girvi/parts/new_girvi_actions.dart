part of '../new_girvi_screen.dart';

extension NewGirviActions on _NewGirviScreenState {
  // â”€â”€ ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _onSave({bool generateInvoice = false}) async {
    FocusScope.of(context).unfocus();
    _syncPledgedItemsToController();
    if (_pledgedItems.isEmpty) {
      _showError('Please add at least one pledged item before saving.');
      return;
    }
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
    _resetPledgedItems();
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

  Future<void> _pickPledgedItemPhoto(_PledgedItemDraft item) async {
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
          '${safeTicket}_item_${item.serialNo}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedPath = p.join(photoDir.path, fileName);
      await source.copy(savedPath);

      if (!mounted) return;
      _setPledgedItemPhotoPath(item, savedPath);
    } catch (e) {
      debugPrint('NewGirviScreen._pickPledgedItemPhoto error: $e');
      if (mounted) {
        _showError('Item photo could not be attached. Please try again.');
      }
    }
  }

  void _removePledgedItemPhoto(_PledgedItemDraft item) {
    if (!mounted) return;
    _setPledgedItemPhotoPath(item, null);
  }

  // ignore: unused_element
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
      _setItemPhotoPath(savedPath);
    } catch (e) {
      debugPrint('NewGirviScreen._pickItemPhoto error: $e');
      if (mounted) {
        _showError('Item photo could not be attached. Please try again.');
      }
    }
  }

  // ignore: unused_element
  void _removeItemPhoto() {
    if (!mounted) return;
    _setItemPhotoPath(null);
  }

  Future<void> _printGirviInvoice() async {
    _syncPledgedItemsToController();
    final customer = _ctrl.selectedCustomer;
    if (customer == null) return;
    final pdf = pw.Document();
    final createdAt = DateTime.now();
    final itemPhotos = _pledgedItems
        .where((item) =>
            item.photoPath != null && File(item.photoPath!).existsSync())
        .map((item) => MapEntry(item.serialNo, File(item.photoPath!)))
        .toList();

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
              'Fine',
              'HUID',
              'Value',
            ],
            data: _pledgedItems.map((item) {
              final description = item.descriptionCtrl.text.trim();
              final huid = item.huidCtrl.text.trim();
              return [
                item.serialNo.toString(),
                item.metalType.displayName,
                description.isEmpty ? '-' : description,
                item.purityLabel,
                item.itemCount.toString(),
                '${item.grossWeight.toStringAsFixed(3)} g',
                '${item.lessWeight.toStringAsFixed(3)} g',
                '${item.netWeight.toStringAsFixed(3)} g',
                '${item.fineWeight.toStringAsFixed(3)} g',
                huid.isEmpty ? '-' : huid,
                amount(item.itemValue),
              ];
            }).toList(),
            headerStyle:
                pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7.2),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE4)),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          if (itemPhotos.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            sectionTitle('Pledged Item Photos'),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: itemPhotos.map((entry) {
                final bytes = entry.value.readAsBytesSync();
                return pw.Container(
                  width: 126,
                  height: 108,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Item #${entry.key}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Expanded(
                        child: pw.Image(
                          pw.MemoryImage(bytes),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
}
