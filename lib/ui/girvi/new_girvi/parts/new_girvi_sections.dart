part of '../new_girvi_screen.dart';

extension NewGirviSections on _NewGirviScreenState {
  // â”€â”€ SECTION 0: CUSTOMER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€ SECTION 1: ITEM DETAILS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // ignore: unused_element
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

  // ignore: unused_element
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // â”€â”€ SECTION 3: VALUATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // ignore: unused_element
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
      subtitle: 'Principal, repayment terms, dates and disbursement',
      accent: GirviColors.brandGold,
      showAccentBorder: false,
      child: Column(children: [
        _LoanTermsGroupHeader(
          icon: GirviIcons.loanTerms,
          title: 'Loan Value',
          subtitle: 'Loan-to-value control based on the pledged item value.',
          trailing: _ctrl.totalValue > 0
              ? 'Item value Rs ${_fmt.format(_ctrl.totalValue)}'
              : null,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final amountField = GirviInputField(
              label: 'Loan Amount (Rs)',
              hint: '0.00',
              icon: GirviIcons.loanTerms,
              controller: _loanAmtCtrl,
              focusNode: _loanAmtFocus,
              nextFocus: _interestFocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              prefixText: 'Rs ',
              validator: _ctrl.validateLoanAmount,
            );
            final ltvControl = _LtvIndicator(
              ltv: _ctrl.totalValue > 0 ? _ctrl.computedLtv : _ctrl.ltvPercent,
              enabled: _ctrl.totalValue > 0,
              onChanged: (ltv) {
                _ctrl.onLtvChanged(ltv);
                _loanAmtCtrl.text = _ctrl.loanAmount.toStringAsFixed(2);
              },
            );
            if (!wide) {
              return Column(
                children: [
                  amountField,
                  const SizedBox(height: 12),
                  ltvControl,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: amountField),
                const SizedBox(width: 12),
                Expanded(child: ltvControl),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const _LoanTermsGroupHeader(
          icon: GirviIcons.interestRate,
          title: 'Repayment Terms',
          subtitle: 'Monthly interest and loan duration for this ticket.',
        ),
        const SizedBox(height: 12),
        GirviRowTwo(
          left: GirviInputField(
            label: 'Interest Rate (% / month)',
            hint: '5.0',
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
            label: 'Duration (months)',
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
        const SizedBox(height: 18),
        const _LoanTermsGroupHeader(
          icon: GirviIcons.dates,
          title: 'Loan Dates',
          subtitle: 'Start date and system-calculated maturity date.',
        ),
        const SizedBox(height: 14),
        GirviRowTwo(
          left: _DatePickerField(
            label: 'Start Date',
            date: _ctrl.startDate,
            onTap: _pickStartDate,
          ),
          right: _DateDisplayField(
            label: 'Maturity Date',
            date: _ctrl.maturityDate,
          ),
        ),
        const SizedBox(height: 18),
        const _LoanTermsGroupHeader(
          icon: GirviIcons.cash,
          title: 'Disbursement Mode',
          subtitle: 'How the loan amount will be paid to the customer.',
        ),
        const SizedBox(height: 12),
        _DisbursementSplitEditor(
          modes: _visibleDisbursementModes,
          selected: _ctrl.disbursementMode,
          loanAmount: _ctrl.loanAmount,
          totalAmount: _totalDisbursementAmount,
          remainingAmount: _remainingDisbursementAmount,
          controllerFor: _disbursementControllerFor,
          amountFor: _disbursementAmountFor,
          modeLabel: _disbursementModeLabel,
          onModeTap: _activateDisbursementMode,
        ),
        const SizedBox(height: 18),
        _InterestPreviewCard(
          principal: _ctrl.loanAmount,
          monthly: _ctrl.monthlyInterest,
          total: _ctrl.totalInterestAtMaturity,
          totalDue: _ctrl.totalDueAtMaturity,
          annualRate: _ctrl.interestRate * 12,
          durationMonths: _ctrl.durationMonths,
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 5: DISBURSEMENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // ignore: unused_element
  Widget _buildSection5Disbursement() {
    return GirviSectionCard(
      icon: GirviIcons.cash,
      title: GirviStrings.secDisbursement,
      subtitle: GirviStrings.descDisbursement,
      accent: GirviColors.accentInterest,
      child: Column(children: [
        Text('How will the loan amount be paid to the customer?',
            style: GirviStyles.caption.copyWith(fontSize: 12.5)),
        const SizedBox(height: 12),
        _PaymentModeSelector(
          selected: _ctrl.disbursementMode,
          onChanged: _ctrl.setDisbursementMode,
        ),
      ]),
    );
  }

  // â”€â”€ SECTION 6: DATES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // ignore: unused_element
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
                    fontSize: 12.5,
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
      title: 'Customer KYC',
      subtitle: 'Identity proof details and document photo (optional).',
      accent: GirviColors.brandGold,
      showAccentBorder: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: GirviColors.brandGold.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: GirviColors.brandGold.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: GirviColors.brandGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select an ID, enter its number and attach a clear card photo.',
                        style: GoogleFonts.inter(
                          color: GirviColors.textBody,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GirviColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GirviColors.cardBorder),
                      ),
                      child: Text(
                        'OPTIONAL',
                        style: GoogleFonts.inter(
                          color: GirviColors.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GirviDropdown<GirviIdProofType?>(
                label: 'Identity Document',
                icon: GirviIcons.kyc,
                value: _ctrl.idProofType,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Skip KYC for this ticket'),
                  ),
                  ...GirviIdProofType.values.map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  _ctrl.setIdProofType(value);
                  if (value == null) {
                    _idProofNoCtrl.clear();
                    _setIdProofImagePath(null);
                  }
                },
              ),
              const SizedBox(height: 12),
              GirviInputField(
                label: 'Document Number',
                hint: _ctrl.idProofType == null
                    ? 'Select a document first'
                    : 'Enter ${_ctrl.idProofType!.displayName} number',
                icon: Icons.pin_outlined,
                controller: _idProofNoCtrl,
                focusNode: _idProofNoFocus,
                enabled: _ctrl.idProofType != null,
                keyboardType: TextInputType.text,
              ),
            ],
          );
          final photo = _KycPhotoCard(
            enabled: _ctrl.idProofType != null,
            documentName: _ctrl.idProofType?.displayName,
            photoPath: _idProofImagePath,
            onCamera: _captureKycPhoto,
            onGallery: _pickKycPhotoFromGallery,
            onPreview: _showKycPhotoPreview,
            onRemove: _removeKycPhoto,
          );

          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                details,
                const SizedBox(height: 12),
                photo,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: details),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: photo),
            ],
          );
        },
      ),
    );
  }

  // â”€â”€ SECTION 8: NOTES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSection8Notes() {
    return GirviSectionCard(
      icon: GirviIcons.notes,
      title: 'Notes & Remarks',
      subtitle: 'Internal staff notes for this loan ticket.',
      accent: GirviColors.brandGold,
      showAccentBorder: false,
      child: GirviInputField(
        label: 'Staff Remarks',
        hint: 'Add any internal remark, customer instruction or handling note.',
        icon: GirviIcons.notes,
        controller: _notesCtrl,
        minLines: 1,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  // â”€â”€ BOTTOM ACTION BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
}
