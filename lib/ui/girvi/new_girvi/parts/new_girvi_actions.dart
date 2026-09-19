part of '../new_girvi_screen.dart';

enum _SavedTicketAction { newTicket, openAccount, stay }

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

    await _handleSavedTicket(invoiceGenerated: false);
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
        final remaining = _ctrl.loanAmount - totalDisbursed;
        _showError(
          'Disbursement total must match the loan amount. Remaining ${_formatSmartMoney(remaining)}.',
        );
        return false;
      }
    }
    _syncPrimaryDisbursementMode();
    return true;
  }

  Future<bool> _saveCurrentGirvi({required bool invoiceGenerated}) {
    return _ctrl.saveLoan(
      items: _buildPersistenceItems(),
      disbursements: _buildPersistenceDisbursements(),
      invoiceGenerated: invoiceGenerated,
      idProofNumber: _ctrl.idProofType == null ? null : _idProofNoCtrl.text,
      idProofImagePath: _ctrl.idProofType == null ? null : _idProofImagePath,
      notes: _notesCtrl.text,
    );
  }

  List<GirviLoanItemInput> _buildPersistenceItems() {
    return _pledgedItems
        .map(
          (item) => GirviLoanItemInput(
            serialNo: item.serialNo,
            itemName: item.descriptionCtrl.text.trim(),
            metalType: item.metalType.dbValue,
            purity: item.purityLabel,
            purityFactor: item.entryPurityFactor,
            pieces: item.itemCount,
            huidNumber: item.huidCtrl.text.trim(),
            grossWeight: item.grossWeight,
            lessWeight: item.lessWeight,
            netWeight: item.netWeight,
            valuationMethod:
                item.usesDirectSilverRate ? 'DIRECT_RATE' : 'PURITY',
            valuationPurityPercent:
                item.usesDirectSilverRate ? null : item.valuationPurityPercent,
            fineWeight: item.fineWeight,
            ratePerGram: item.ratePerGram,
            valuationAmount: item.itemValue,
            photoPaths: List.unmodifiable(item.validPhotoPaths),
          ),
        )
        .toList(growable: false);
  }

  List<GirviDisbursementInput> _buildPersistenceDisbursements() {
    final entries = <GirviDisbursementInput>[];
    for (final mode in _visibleDisbursementModes) {
      final amount = _disbursementAmountFor(mode);
      if (amount <= 0) continue;
      entries.add(
        GirviDisbursementInput(
          sequenceNo: entries.length + 1,
          mode: mode.dbValue,
          displayLabel: _disbursementModeLabel(mode),
          amount: amount,
        ),
      );
    }
    return List.unmodifiable(entries);
  }

  Future<void> _openGirviInvoiceHub() async {
    final draft = _buildGirviInvoiceDraft();
    final finalized = await GirviInvoiceHubScreen.push(
      context,
      draft: draft,
      onFinalize: () => _saveCurrentGirvi(invoiceGenerated: true),
    );
    if (finalized == true && mounted) {
      await _handleSavedTicket(invoiceGenerated: true);
    }
  }

  Future<void> _handleSavedTicket({required bool invoiceGenerated}) async {
    final loanId = _ctrl.lastSavedLoanId;
    final action = await _showSavedTicketDialog(
      invoiceGenerated: invoiceGenerated,
      canOpenAccount: loanId != null,
    );
    if (!mounted) return;

    switch (action) {
      case _SavedTicketAction.openAccount:
        if (loanId != null) {
          context.go(RoutePaths.girviAccountFor(loanId));
        }
        return;
      case _SavedTicketAction.newTicket:
        if (!_ctrl.isEditMode) {
          await _resetAll();
        }
        return;
      case _SavedTicketAction.stay:
      case null:
        return;
    }
  }

  Future<_SavedTicketAction?> _showSavedTicketDialog({
    required bool invoiceGenerated,
    required bool canOpenAccount,
  }) {
    final isEditMode = _ctrl.isEditMode;
    final title = invoiceGenerated
        ? 'Girvi Invoice Finalized'
        : isEditMode
            ? 'Girvi Ticket Updated'
            : 'Girvi Ticket Saved';
    final subtitle = invoiceGenerated
        ? 'Invoice, pledged item details and disbursement records are saved.'
        : 'The Girvi ticket is saved in the ledger with structured item records.';

    return showDialog<_SavedTicketAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GirviColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: GirviColors.shadowMedium,
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GirviColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: GirviColors.success.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      GirviIcons.markDone,
                      color: GirviColors.success,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.manrope(
                            color: GirviColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: GirviColors.textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GirviColors.inputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GirviColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _SavedTicketSummaryRow(
                      label: 'Ticket Number',
                      value: _ctrl.ticketNo,
                    ),
                    const SizedBox(height: 10),
                    _SavedTicketSummaryRow(
                      label: 'Customer',
                      value:
                          _ctrl.selectedCustomer?.name ?? 'Selected customer',
                    ),
                    const SizedBox(height: 10),
                    _SavedTicketSummaryRow(
                      label: 'Loan Amount',
                      value: _formatSmartMoney(_ctrl.loanAmount),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                canOpenAccount
                    ? 'Open the account to review the ledger, payment history, notice status and delivery workflow.'
                    : 'Ticket saved. Account link will be available after the ledger refreshes.',
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(
                      isEditMode
                          ? _SavedTicketAction.stay
                          : _SavedTicketAction.newTicket,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: GirviColors.textDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text(isEditMode ? 'Stay Here' : 'New Ticket'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: canOpenAccount
                        ? () => Navigator.of(dialogContext)
                            .pop(_SavedTicketAction.openAccount)
                        : null,
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('Open Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GirviColors.shellBg,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: GirviColors.inputBgLocked,
                      disabledForegroundColor: GirviColors.textMuted,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      customerAddress: _formatInvoiceCustomerAddress(customer),
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
          ratePerGram: item.ratePerGram,
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

  String _formatInvoiceCustomerAddress(Customer customer) {
    final parts = <String>[
      customer.addressLine1 ?? '',
      customer.addressLine2 ?? '',
      customer.city ?? '',
      customer.state ?? '',
      customer.pincode ?? '',
      customer.country.trim().toLowerCase() == 'india' ? '' : customer.country,
    ];
    final uniqueParts = <String>[];
    for (final part in parts) {
      final value = part.trim();
      if (value.isNotEmpty && !uniqueParts.contains(value)) {
        uniqueParts.add(value);
      }
    }
    return uniqueParts.join(', ');
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
    await _ctrl.resetForm();
    _interestCtrl.clear();
    _durationCtrl.clear();
    _resetPledgedItems();
  }

  void _showError(String msg) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.error,
      message: msg,
      duration: const Duration(seconds: 3),
    );
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
      AppLogger.debug('NewGirviScreen._saveKycPhoto error: $e');
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
}
