part of 'add_supplier_screen.dart';

extension _SupplierAddressSection on _AddSupplierScreenState {
  Widget _buildAddressSection(AddSupplierFormModel form) {
    final isIndia = form.country == 'India';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown<String>(
                label: AddSupplierStrings.lblCountry,
                icon: AddSupplierIcons.country,
                value: _AddSupplierScreenState._countries.contains(form.country)
                    ? form.country
                    : 'Other',
                items: _AddSupplierScreenState._countries,
                itemLabel: (country) => country,
                onChanged: _changeCountry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isIndia
                  ? _buildDropdown<String>(
                      label: AddSupplierStrings.lblState,
                      icon: AddSupplierIcons.state,
                      value: _AddSupplierScreenState._indiaStates
                              .contains(form.state)
                          ? form.state
                          : null,
                      items: _AddSupplierScreenState._indiaStates,
                      itemLabel: (state) => state,
                      onChanged: _logic.setStateName,
                    )
                  : _buildField(
                      label: AddSupplierStrings.lblState,
                      hint: AddSupplierStrings.hintState,
                      ctrl: _stateCtrl,
                      focus: _stateFocus,
                      icon: AddSupplierIcons.state,
                      onChanged: _logic.setStateName,
                      textCap: TextCapitalization.words,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: isIndia ? AddSupplierStrings.lblPincode : 'Postal Code',
                hint: isIndia
                    ? AddSupplierStrings.hintPincode
                    : 'Postal or ZIP code',
                ctrl: _pincodeCtrl,
                focus: _pincodeFocus,
                icon: AddSupplierIcons.pincode,
                errorText: form.pincodeError,
                onChanged: _logic.onPincodeChanged,
                keyboard: isIndia ? TextInputType.number : TextInputType.text,
                formatters: [
                  FilteringTextInputFormatter.allow(
                      isIndia ? RegExp(r'[0-9]') : RegExp(r'[A-Za-z0-9 -]'))
                ],
                maxLength: isIndia ? 6 : 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblAddress1,
                hint: AddSupplierStrings.hintAddress1,
                ctrl: _address1Ctrl,
                focus: _address1Focus,
                icon: AddSupplierIcons.address,
                onChanged: _logic.onAddressLine1Changed,
                textCap: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblAddress2,
                hint: AddSupplierStrings.hintAddress2,
                ctrl: _address2Ctrl,
                focus: _address2Focus,
                icon: AddSupplierIcons.address,
                onChanged: _logic.onAddressLine2Changed,
                textCap: TextCapitalization.words,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _changeCountry(String country) {
    _stateCtrl.clear();
    _pincodeCtrl.clear();
    _logic.setCountry(country);
  }
}
