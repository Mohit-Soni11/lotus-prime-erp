part of 'add_supplier_screen.dart';

extension _SupplierBusinessSection on _AddSupplierScreenState {
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required int stepNumber,
    required Widget child,
  }) {
    return _addSupplierSection(
      icon: icon,
      title: title,
      subtitle: subtitle,
      accent: accent,
      stepNumber: stepNumber,
      child: child,
    );
  }

  Widget _buildBusinessSection(AddSupplierFormModel form) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblBusinessName,
                hint: AddSupplierStrings.hintBusinessName,
                ctrl: _businessNameCtrl,
                focus: _businessNameFocus,
                icon: AddSupplierIcons.businessName,
                errorText: form.businessNameError,
                onChanged: _logic.onBusinessNameChanged,
                textCap: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: AddSupplierStrings.lblContactPerson,
                hint: AddSupplierStrings.hintContactPerson,
                ctrl: _contactPersonCtrl,
                focus: _contactPersonFocus,
                icon: AddSupplierIcons.contactPerson,
                onChanged: _logic.onContactPersonChanged,
                textCap: TextCapitalization.words,
              ),
            ),
          ],
        ),
        _buildSupplierTypeDropdown(form),
      ],
    );
  }
}
