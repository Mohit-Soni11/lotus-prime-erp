part of '../new_girvi_screen.dart';

extension NewGirviActions on _NewGirviScreenState {
  // â”€â”€ ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _onSave({bool generateInvoice = false}) async {
    FocusScope.of(context).unfocus();
    if (!_validateGirviEntry()) return;

    if (generateInvoice) {
      await _openGirviInvoiceHub();
      return;
    }

    final ok = await _saveCurrentGirvi(invoiceGenerated: false);
    if (!ok || !mounted) return;

    _showSuccess(_ctrl.successMessage ?? GirviStrings.successGirviSaved);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await _resetAll();
  }

  bool _validateGirviEntry() {
    _syncPledgedItemsToController();
    if (_pledgedItems.isEmpty) {
      _showError('Please add at least one pledged item before saving.');
      return false;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showError('Please fix the errors above before saving.');
      return false;
    }
    if (!_ctrl.hasCustomer) {
      _showError('Please select a customer first.');
      return false;
    }
    if (_ctrl.loanAmount > 0) {
      final totalDisbursed = _totalDisbursementAmount;
      if (totalDisbursed <= 0) {
        _showError(
            'Enter the disbursement amount for Cash, UPI, Bank or Cheque.');
        return false;
      }
      if ((totalDisbursed - _ctrl.loanAmount).abs() > 0.50) {
        _showError(
          'Disbursement total must match the loan amount. Remaining Rs ${_fmt.format(_ctrl.loanAmount - totalDisbursed)}.',
        );
        return false;
      }
    }
    _syncPrimaryDisbursementMode();
    return true;
  }

  Future<bool> _saveCurrentGirvi({required bool invoiceGenerated}) {
    return _ctrl.saveLoan(
      itemDescription: _itemDescCtrl.text,
      huidNumber: _huidCtrl.text,
      itemPhotoPath: _itemPhotoPath,
      invoiceGenerated: invoiceGenerated,
      disbursementDetails: _disbursementSummaryLabel,
      idProofNumber: _ctrl.idProofType == null ? null : _idProofNoCtrl.text,
      idProofImagePath: _ctrl.idProofType == null ? null : _idProofImagePath,
      notes: _notesCtrl.text,
    );
  }

  Future<void> _openGirviInvoiceHub() async {
    final draft = _buildGirviInvoiceDraft();
    final finalized = await GirviInvoiceHubScreen.push(
      context,
      draft: draft,
      onFinalize: () => _saveCurrentGirvi(invoiceGenerated: true),
    );
    if (finalized == true && mounted) {
      _showSuccess(_ctrl.successMessage ?? GirviStrings.successGirviSaved);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _resetAll();
    }
  }

  GirviInvoiceDraft _buildGirviInvoiceDraft() {
    final customer = _ctrl.selectedCustomer!;
    final payments = <GirviInvoicePayment>[];
    for (final mode in _visibleDisbursementModes) {
      final amount = _disbursementAmountFor(mode);
      if (amount > 0) {
        payments.add(
          GirviInvoicePayment(
            label: _disbursementModeLabel(mode),
            amount: amount,
          ),
        );
      }
    }

    return GirviInvoiceDraft(
      ticketNo: _ctrl.ticketNo,
      createdAt: DateTime.now(),
      customerName: customer.name,
      customerMobile: customer.mobile,
      customerCity: customer.city ?? '',
      items: _pledgedItems.map((item) {
        final description = item.descriptionCtrl.text.trim();
        return GirviInvoiceItemDraft(
          serialNo: item.serialNo,
          metal: item.metalType.displayName,
          description: description.isEmpty
              ? 'Pledged item ${item.serialNo}'
              : description,
          purity: item.purityLabel,
          pieces: item.itemCount,
          grossWeight: item.grossWeight,
          lessWeight: item.lessWeight,
          netWeight: item.netWeight,
          valuationPurity: item.valuationPurityLabel,
          fineWeight: item.fineWeight,
          huid: item.huidCtrl.text.trim(),
          value: item.itemValue,
          photoPaths: List.unmodifiable(item.validPhotoPaths),
        );
      }).toList(growable: false),
      totalValue: _ctrl.totalValue,
      loanAmount: _ctrl.loanAmount,
      interestRate: _ctrl.interestRate,
      durationMonths: _ctrl.durationMonths,
      startDate: _ctrl.startDate,
      maturityDate: _ctrl.maturityDate,
      monthlyInterest: _ctrl.monthlyInterest,
      totalInterest: _ctrl.totalInterestAtMaturity,
      totalDue: _ctrl.totalDueAtMaturity,
      payments: List.unmodifiable(payments),
      disbursementSummary: _disbursementSummaryLabel,
      idProofType: _ctrl.idProofType?.displayName,
      idProofNumber: _idProofNoCtrl.text.trim(),
      idProofImagePath: _idProofImagePath,
      notes: _notesCtrl.text.trim(),
    );
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
      _cashDisbursementCtrl,
      _upiDisbursementCtrl,
      _bankDisbursementCtrl,
      _chequeDisbursementCtrl,
      _idProofNoCtrl,
      _notesCtrl,
    ]) {
      c.clear();
    }
    _itemPhotoPath = null;
    _idProofImagePath = null;
    _interestCtrl.text = '5.0';
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

  Future<void> _pickKycPhotoFromGallery() async {
    if (_ctrl.idProofType == null) {
      _showError('Select a KYC document before attaching its photo.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Select KYC Document Photo',
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty || !mounted) return;
    await _saveKycPhoto(path);
  }

  Future<void> _captureKycPhoto() async {
    if (_ctrl.idProofType == null) {
      _showError('Select a KYC document before taking its photo.');
      return;
    }

    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _KycCameraDialog(),
    );
    if (path == null || path.isEmpty || !mounted) return;
    await _saveKycPhoto(path);
  }

  Future<void> _saveKycPhoto(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        _showError('Selected KYC photo could not be found.');
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final photoDir =
          Directory(p.join(appDir.path, 'lotus_erp', 'girvi_kyc_photos'));
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final safeTicket = _ctrl.ticketNo
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final extension =
          p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final savedPath = p.join(
        photoDir.path,
        '${safeTicket}_kyc_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      await source.copy(savedPath);

      if (!mounted) return;
      _setIdProofImagePath(savedPath);
    } catch (e) {
      debugPrint('NewGirviScreen._saveKycPhoto error: $e');
      if (mounted) {
        _showError('KYC photo could not be attached. Please try again.');
      }
    }
  }

  void _removeKycPhoto() {
    _setIdProofImagePath(null);
  }

  void _showKycPhotoPreview() {
    final path = _idProofImagePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: GirviColors.brandGold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_ctrl.idProofType?.displayName ?? 'KYC'} photo',
                        style: GoogleFonts.manrope(
                          color: GirviColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GirviColors.divider),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(path), fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPledgedItemPhoto(_PledgedItemDraft item) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      dialogTitle: 'Select Pledged Item Photos',
    );
    final selectedPaths = result?.files
            .map((file) => file.path)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toList() ??
        const <String>[];
    if (selectedPaths.isEmpty || !mounted) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir =
          Directory(p.join(appDir.path, 'lotus_erp', 'girvi_item_photos'));
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final safeTicket = _ctrl.ticketNo
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final savedPaths = <String>[];
      for (var i = 0; i < selectedPaths.length; i++) {
        final path = selectedPaths[i];
        final source = File(path);
        final extension =
            p.extension(path).isEmpty ? '.jpg' : p.extension(path);
        final fileName =
            '${safeTicket}_item_${item.serialNo}_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
        final savedPath = p.join(photoDir.path, fileName);
        await source.copy(savedPath);
        savedPaths.add(savedPath);
      }

      if (!mounted) return;
      _addPledgedItemPhotoPaths(item, savedPaths);
    } catch (e) {
      debugPrint('NewGirviScreen._pickPledgedItemPhoto error: $e');
      if (mounted) {
        _showError('Item photos could not be attached. Please try again.');
      }
    }
  }

  void _removePledgedItemPhoto(_PledgedItemDraft item) {
    if (!mounted) return;
    _clearPledgedItemPhotos(item);
  }

  void _showPledgedItemPhotoPreview(_PledgedItemDraft item, String path) {
    if (!mounted || !File(path).existsSync()) return;
    final description = item.descriptionCtrl.text.trim();
    final title =
        description.isEmpty ? 'Pledged Item ${item.serialNo}' : description;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GirviColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: GirviColors.brandGoldLight,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: GirviColors.brandGold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: GirviColors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Item #${item.serialNo} photo preview',
                              style: GirviStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: GirviColors.divider),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  // Kept temporarily for backward compatibility with older direct-print flow.
  // ignore: unused_element
  Future<void> _printGirviInvoice() async {
    _syncPledgedItemsToController();
    final customer = _ctrl.selectedCustomer;
    if (customer == null) return;
    final pdf = pw.Document();
    final createdAt = DateTime.now();
    final itemPhotos = _pledgedItems
        .expand(
          (item) => item.validPhotoPaths.map(
            (path) => MapEntry(item.serialNo, File(path)),
          ),
        )
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
                      infoLine('Disbursement', _disbursementSummaryLabel),
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
              'Purity',
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
                item.valuationPurityLabel,
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
