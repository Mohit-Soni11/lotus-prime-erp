part of 'add_customer_screen.dart';

extension _CustomerAccountSections on _AddCustomerScreenState {
  Widget _buildKycSection() {
    final isCorp = _logic.form.isCorporate;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field(
        label: 'PAN Number',
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
                label: 'ID Proof Type',
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
                label: 'ID Proof Number',
                icon: Icons.numbers_rounded,
                ctrl: _idProofNoCtrl,
                focus: _idProofNoFocus,
                hint: 'ID number',
                error: _logic.form.idProofError,
                onChanged: _logic.onIdProofNumberChanged)),
      ]),
      const SizedBox(height: 14),
      _buildUploadButton(
          label: 'Upload ID Document',
          icon: Icons.upload_file_rounded,
          filePath: _logic.form.idProofDocPath,
          onTap: _pickIdDoc,
          onRemove: () => _logic.setIdProofDocPath(null),
          accentColor: const Color(0xFFD97706)),
      const SizedBox(height: 14),
      _field(
          label: isCorp ? 'GST Number' : 'GST Number (Optional)',
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
  // SECTION 5: BILLING

  Widget _buildBillingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CUSTOMER CATEGORY', style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 10),
      Row(
        children: CustomerTier.values.map((t) {
          final isSelected = _logic.form.customerTier == t;
          final isLast = t == CustomerTier.values.last;
          return Expanded(
              child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () => _logic.setCustomerTier(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _tierColor(t).withValues(alpha: 0.12)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          isSelected ? _tierColor(t) : const Color(0xFFE5E7EB),
                      width: isSelected ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tierIcon(t),
                      color: isSelected ? _tierColor(t) : Colors.black54,
                      size: 18,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? _tierColor(t) : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
        }).toList(),
      ),
      const SizedBox(height: 20),
      Text('MEMBERSHIP ID', style: AddCustomerStyles.fieldLabel),
      const SizedBox(height: 8),
      Container(
        height: 50,
        decoration: BoxDecoration(
          color: AddCustomerColors.brandGoldLight,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AddCustomerColors.brandGoldBorder, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          const Icon(Icons.card_membership_rounded,
              color: AddCustomerColors.brandGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  _logic.form.membershipId.isEmpty
                      ? 'Assigned after saving'
                      : _logic.form.membershipId,
                  style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 1.2))),
        ]),
      ),
      const SizedBox(height: 4),
      Text('A unique membership ID is assigned automatically when saved.',
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87)),
    ]);
  }

  Color _tierColor(CustomerTier t) {
    switch (t) {
      case CustomerTier.regular:
        return const Color(0xFF64748B);
      case CustomerTier.silver:
        return const Color(0xFF94A3B8);
      case CustomerTier.gold:
        return const Color(0xFFB8960C);
      case CustomerTier.vip:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _tierIcon(CustomerTier t) {
    switch (t) {
      case CustomerTier.regular:
        return Icons.person_rounded;
      case CustomerTier.silver:
        return Icons.star_half_rounded;
      case CustomerTier.gold:
        return Icons.star_rounded;
      case CustomerTier.vip:
        return Icons.workspace_premium_rounded;
    }
  }
  // SECTION 6: PREFERENCES
}
