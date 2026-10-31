part of 'add_customer_screen.dart';

extension _CustomerAccountSections on _AddCustomerScreenState {
  Widget _buildKycSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
        label: 'PAN Number (Optional)',
        icon: Icons.credit_card_rounded,
        ctrl: _panCtrl,
        focus: _panFocus,
        next: _idProofNoFocus,
        hint: 'ABCDE1234F',
        error: _logic.form.panError,
        onChanged: (v) {
          _panCtrl.value = TextEditingValue(
            text: v.toUpperCase(),
            selection: TextSelection.collapsed(offset: v.length),
          );
          _logic.onPanChanged(v);
        },
        maxLength: 10,
        formatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(10),
        ],
        suffix:
            (_logic.form.panNumber.length == 10 && _logic.form.panError == null)
                ? const Icon(Icons.verified_rounded,
                    color: AddCustomerColors.success, size: 20)
                : null,
      ),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildDropdown<IdProofType>(
                label: 'ID Proof Type (Optional)',
                icon: Icons.badge_outlined,
                value: _logic.form.idProofType,
                items: IdProofType.values,
                itemLabel: (t) => t.label,
                onChanged: _logic.setIdProofType,
                hint: 'Select ID type',
                nullable: true)),
        const SizedBox(width: 14),
        Expanded(
            child: _field(
                label: 'ID Proof Number (Optional)',
                icon: Icons.numbers_rounded,
                ctrl: _idProofNoCtrl,
                focus: _idProofNoFocus,
                hint: 'ID number',
                error: _logic.form.idProofError,
                onChanged: _logic.onIdProofNumberChanged)),
      ]),
      const SizedBox(height: 14),
      _buildUploadButton(
          label: 'Upload ID Document (Optional)',
          icon: Icons.upload_file_rounded,
          filePath: _logic.form.idProofDocPath,
          onTap: _pickIdDoc,
          onRemove: () => _logic.setIdProofDocPath(null),
          accentColor: const Color(0xFFD97706)),
      const SizedBox(height: 14),
      _field(
          label: 'GST Number (Optional)',
          icon: Icons.receipt_long_rounded,
          ctrl: _gstCtrl,
          focus: _gstFocus,
          hint: '22ABCDE1234F1Z5',
          error: _logic.form.gstError,
          onChanged: (v) {
            _gstCtrl.value = TextEditingValue(
              text: v.toUpperCase(),
              selection: TextSelection.collapsed(offset: v.length),
            );
            _logic.onGstChanged(v);
          },
          maxLength: 15,
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(15),
          ]),
    ]);
  }
  // SECTION 4: ADDRESS

  Widget _buildAddressSection() {
    IndiaState? selectedIndiaState;
    for (final state in IndiaState.values) {
      if (state.label == _selectedState) {
        selectedIndiaState = state;
        break;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
          label: 'Address Line 1',
          icon: Icons.home_rounded,
          ctrl: _addr1Ctrl,
          focus: _addr1Focus,
          next: _addr2Focus,
          hint: 'House no., Street, Area',
          onChanged: _logic.onAddressLine1Changed,
          capitalization: TextCapitalization.sentences),
      const SizedBox(height: 14),
      _field(
          label: 'Address Line 2 (Optional)',
          icon: Icons.location_on_outlined,
          ctrl: _addr2Ctrl,
          focus: _addr2Focus,
          hint: 'Landmark, Locality',
          onChanged: _logic.onAddressLine2Changed,
          capitalization: TextCapitalization.sentences),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _buildSimpleDropdown(
                label: 'Country',
                icon: Icons.public_rounded,
                value: _selectedCountry,
                items: _AddCustomerScreenState._countries,
                onChanged: _changeCountry)),
        const SizedBox(width: 14),
        Expanded(
          child: _selectedCountry == 'India'
              ? _buildDropdown<IndiaState>(
                  label: 'State',
                  icon: Icons.map_outlined,
                  value: selectedIndiaState,
                  items: IndiaState.values,
                  itemLabel: (s) => s.label,
                  onChanged: (s) {
                    if (s != null) {
                      _changeIndianState(s);
                    }
                  },
                  hint: 'Select state',
                  nullable: true)
              : _field(
                  label: 'State / Province',
                  icon: Icons.map_outlined,
                  ctrl: _stateProvinceCtrl,
                  hint: 'Enter state',
                  onChanged: _logic.setState_),
        ),
      ]),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: _field(
                label: AddCustomerStrings.lblCity,
                icon: AddCustomerIcons.city,
                ctrl: _cityCtrl,
                focus: _cityFocus,
                next: _pincodeFocus,
                hint: AddCustomerStrings.hintCity,
                onChanged: _logic.onCityChanged,
                capitalization: TextCapitalization.words)),
        const SizedBox(width: 14),
        Expanded(
            child: _field(
                label: _selectedCountry == 'India' ? 'Pincode' : 'Postal Code',
                icon: Icons.pin_drop_rounded,
                ctrl: _pincodeCtrl,
                focus: _pincodeFocus,
                hint: _selectedCountry == 'India'
                    ? '6-digit pincode'
                    : 'Postal or ZIP code',
                error: _logic.form.pincodeError,
                onChanged: _logic.onPincodeChanged,
                keyboardType: _selectedCountry == 'India'
                    ? TextInputType.number
                    : TextInputType.text,
                maxLength: _selectedCountry == 'India' ? 6 : 12,
                formatters: [
              FilteringTextInputFormatter.allow(
                _selectedCountry == 'India'
                    ? RegExp(r'[0-9]')
                    : RegExp(r'[A-Za-z0-9 -]'),
              ),
            ])),
      ]),
    ]);
  }

  Widget _buildBillingSection() {
    final tier = _logic.form.customerTier;
    final accent = tier == CustomerType.alert
        ? const Color(0xFFDC2626)
        : tier == CustomerType.elite
            ? const Color(0xFF7C3AED)
            : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(
            tier == CustomerType.alert
                ? Icons.priority_high_rounded
                : tier == CustomerType.elite
                    ? Icons.workspace_premium_rounded
                    : Icons.verified_user_rounded,
            color: accent,
            size: 24),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tier.displayLabel} Customer',
                style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
            const SizedBox(height: 4),
            Text(
                _isEditMode
                    ? 'Category updates automatically from verified account activity.'
                    : 'New customers start at 5/10 in the Standard category.',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
          ],
        )),
        const Icon(Icons.lock_outline_rounded, color: Colors.black87),
      ]),
    );
  }
}
