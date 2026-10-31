part of 'return_reversal_customer_details_card.dart';

class _CustomerInputGrid extends StatelessWidget {
  final ReturnReversalController controller;
  final ReturnReversalOperationType operationType;

  const _CustomerInputGrid({
    required this.controller,
    required this.operationType,
  });

  String get _sourceNumberLabel {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'SOURCE NUMBER'
        : 'BOOKING NUMBER';
  }

  String get _sourceNumberHint {
    return operationType == ReturnReversalOperationType.salesReturn
        ? 'Invoice or purchase no.'
        : 'Enter booking no.';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _mobileInput()),
                  const SizedBox(width: 12),
                  Expanded(child: _nameInput()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _sourceDocumentInput()),
                  const SizedBox(width: 12),
                  Expanded(child: _addressInput()),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 2, child: _mobileInput()),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _nameInput()),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _sourceDocumentInput()),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: _addressInput()),
          ],
        );
      },
    );
  }

  Widget _mobileInput() {
    return _CustomerDetailInput(
      label: 'MOBILE',
      hint: '10-digit',
      controller: controller.customerMobileCtrl,
      fieldKey: const ValueKey('return_reversal_customer_mobile_field'),
      onSubmitted: _submitSearch,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      icon: SalesPosIcons.mobilePhone,
    );
  }

  Widget _nameInput() {
    return _CustomerDetailInput(
      label: 'CUSTOMER NAME',
      hint: 'Enter full name',
      controller: controller.customerNameCtrl,
      fieldKey: const ValueKey('return_reversal_customer_name_field'),
      onSubmitted: _submitSearch,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
      ],
      icon: SalesPosIcons.customerName,
    );
  }

  Widget _sourceDocumentInput() {
    return _CustomerDetailInput(
      label: _sourceNumberLabel,
      hint: _sourceNumberHint,
      controller: controller.sourceDocumentNumberCtrl,
      fieldKey: const ValueKey('return_reversal_source_number_field'),
      onSubmitted: _submitSearch,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\/]')),
        LengthLimitingTextInputFormatter(32),
      ],
      icon: SalesPosIcons.invoiceOutline,
    );
  }

  Widget _addressInput() {
    return _CustomerDetailInput(
      label: 'ADDRESS',
      hint: 'Customer address',
      controller: controller.customerAddressCtrl,
      fieldKey: const ValueKey('return_reversal_customer_address_field'),
      icon: SalesPosIcons.cityLocation,
    );
  }

  void _submitSearch() {
    if (!controller.state.isSearching) {
      controller.searchRecords();
    }
  }
}

class _CustomerDetailInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final IconData icon;
  final Key? fieldKey;
  final VoidCallback? onSubmitted;

  const _CustomerDetailInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.fieldKey,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: SalesPosColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SalesPosColors.textDark,
                  fontSize: SalesPosStyles.fontLabel,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: onSubmitted == null
                ? TextInputAction.next
                : TextInputAction.search,
            onSubmitted: (_) => onSubmitted?.call(),
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: SalesPosStyles.inputText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: SalesPosColors.textDark.withValues(alpha: 0.82),
                fontSize: SalesPosStyles.fontLabel,
                fontWeight: FontWeight.w800,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: SalesPosColors.textDark,
              ),
              filled: true,
              fillColor: SalesPosColors.formInputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: SalesPosColors.bodyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: SalesPosColors.brandGold,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
