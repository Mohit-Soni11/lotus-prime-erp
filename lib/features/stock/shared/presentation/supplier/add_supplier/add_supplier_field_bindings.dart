part of 'add_supplier_screen.dart';

extension _SupplierFieldBindings on _AddSupplierScreenState {
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required FocusNode focus,
    required IconData icon,
    required ValueChanged<String> onChanged,
    String? errorText,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization textCap = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return _addSupplierField(
      label: label,
      hint: hint,
      ctrl: ctrl,
      focus: focus,
      icon: icon,
      onChanged: onChanged,
      errorText: errorText,
      keyboard: keyboard,
      textCap: textCap,
      formatters: formatters,
      maxLength: maxLength,
      maxLines: maxLines,
      enabled: enabled,
    );
  }

  Widget _buildSupplierTypeDropdown(AddSupplierFormModel form) {
    return _buildDropdown<SupplierType>(
      label: AddSupplierStrings.lblSupplierType,
      icon: AddSupplierIcons.supplierType,
      value: form.supplierType,
      items: SupplierType.values,
      itemLabel: (type) => type.label,
      onChanged: _logic.setSupplierType,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return _addSupplierDropdown<T>(
      label: label,
      icon: icon,
      value: value,
      items: items,
      itemLabel: itemLabel,
      onChanged: onChanged,
    );
  }

  Widget _buildCheckboxLine({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    return _addSupplierCheckboxLine(
      value: value,
      label: label,
      onChanged: onChanged,
    );
  }

  Widget _buildErrorBanner(String message) {
    return _addSupplierErrorBanner(message);
  }
}
