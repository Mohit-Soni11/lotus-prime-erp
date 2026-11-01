part of 'add_supplier_screen.dart';

extension _SupplierContactSection on _AddSupplierScreenState {
  Widget _buildContactSection(AddSupplierFormModel form) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblMobile,
                hint: AddSupplierStrings.hintMobile,
                ctrl: _mobileCtrl,
                focus: _mobileFocus,
                icon: AddSupplierIcons.mobile,
                errorText: form.mobileError,
                onChanged: (value) {
                  _logic.onMobileChanged(value);
                  if (_logic.form.sameAsWhatsApp) {
                    _whatsappCtrl.value = TextEditingValue(
                      text: value,
                      selection: TextSelection.collapsed(offset: value.length),
                    );
                  }
                },
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblWhatsapp,
                hint: AddSupplierStrings.hintWhatsapp,
                ctrl: _whatsappCtrl,
                focus: _whatsappFocus,
                icon: AddSupplierIcons.whatsapp,
                errorText: form.whatsappError,
                onChanged: _logic.onWhatsappChanged,
                enabled: !form.sameAsWhatsApp,
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildCheckboxLine(
            value: form.sameAsWhatsApp,
            label: 'Use mobile number as WhatsApp',
            onChanged: (value) {
              _logic.setSameAsWhatsApp(value);
              _whatsappCtrl.text = value ? _mobileCtrl.text : '';
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblEmail,
                hint: AddSupplierStrings.hintEmail,
                ctrl: _emailCtrl,
                focus: _emailFocus,
                icon: AddSupplierIcons.email,
                errorText: form.emailError,
                onChanged: _logic.onEmailChanged,
                keyboard: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblAltContact,
                hint: AddSupplierStrings.hintAltContact,
                ctrl: _altContactCtrl,
                focus: _altContactFocus,
                icon: AddSupplierIcons.altContact,
                onChanged: _logic.onAlternateContactChanged,
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKycSection(AddSupplierFormModel form) {
    return Row(
      children: [
        Expanded(
          child: _buildField(
            label: AddSupplierStrings.lblGst,
            hint: AddSupplierStrings.hintGst,
            ctrl: _gstCtrl,
            focus: _gstFocus,
            icon: AddSupplierIcons.gst,
            errorText: form.gstError,
            onChanged: _logic.onGstChanged,
            textCap: TextCapitalization.characters,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(15),
              _UpperCaseTextFormatter(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildField(
            label: AddSupplierStrings.lblPan,
            hint: AddSupplierStrings.hintPan,
            ctrl: _panCtrl,
            focus: _panFocus,
            icon: AddSupplierIcons.pan,
            errorText: form.panError,
            onChanged: _logic.onPanChanged,
            textCap: TextCapitalization.characters,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(10),
              _UpperCaseTextFormatter(),
            ],
          ),
        ),
      ],
    );
  }
}
