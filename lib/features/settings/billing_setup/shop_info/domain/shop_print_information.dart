enum ShopPrintFieldGroup {
  identity,
  contact,
  statutory,
  address,
  social,
  banking,
}

class ShopPrintField {
  final String id;
  final String label;
  final String description;
  final String sourceSection;
  final String value;
  final ShopPrintFieldGroup group;
  final bool defaultEnabled;

  const ShopPrintField({
    required this.id,
    required this.label,
    required this.description,
    required this.sourceSection,
    required this.value,
    required this.group,
    required this.defaultEnabled,
  });

  bool get isConfigured => value.trim().isNotEmpty;
}

class ShopPrintInformationState {
  final String tenantId;
  final List<ShopPrintField> fields;
  final Set<String> enabledFieldIds;

  const ShopPrintInformationState({
    required this.tenantId,
    required this.fields,
    required this.enabledFieldIds,
  });

  int get configuredCount => fields.where((field) => field.isConfigured).length;

  int get enabledCount => fields
      .where(
          (field) => field.isConfigured && enabledFieldIds.contains(field.id))
      .length;

  int get missingCount => fields.length - configuredCount;

  Set<String> get configuredFieldIds => {
        for (final field in fields)
          if (field.isConfigured) field.id,
      };

  bool isEnabled(ShopPrintField field) =>
      field.isConfigured && enabledFieldIds.contains(field.id);

  ShopPrintInformationState copyWith({
    Set<String>? enabledFieldIds,
  }) {
    return ShopPrintInformationState(
      tenantId: tenantId,
      fields: fields,
      enabledFieldIds: enabledFieldIds ?? this.enabledFieldIds,
    );
  }
}

class ShopPrintDocumentField {
  final String id;
  final String label;
  final String value;
  final ShopPrintFieldGroup group;

  const ShopPrintDocumentField({
    required this.id,
    required this.label,
    required this.value,
    required this.group,
  });

  String get displayText {
    switch (group) {
      case ShopPrintFieldGroup.identity:
        if (id == 'shop_name' || id == 'tagline') return value;
        if (id == 'legal_name') return 'Legal Name: $value';
        if (id == 'branch_code') return 'Branch: $value';
        return '$label: $value';
      case ShopPrintFieldGroup.address:
        return value;
      case ShopPrintFieldGroup.contact:
      case ShopPrintFieldGroup.statutory:
      case ShopPrintFieldGroup.social:
      case ShopPrintFieldGroup.banking:
        return '$label: $value';
    }
  }
}

class ShopPrintDocumentProfile {
  static const Set<String> _assetFieldIds = {'logo', 'signature'};

  final String tenantId;
  final List<ShopPrintDocumentField> fields;
  final String? logoPath;
  final String logoShape;
  final String? signaturePath;
  final String signatureShape;

  const ShopPrintDocumentProfile({
    required this.tenantId,
    required this.fields,
    this.logoPath,
    this.logoShape = 'square',
    this.signaturePath,
    this.signatureShape = 'square',
  });

  static const empty = ShopPrintDocumentProfile(
    tenantId: '',
    fields: <ShopPrintDocumentField>[],
  );

  factory ShopPrintDocumentProfile.fromState(
    ShopPrintInformationState state,
    Map<String, dynamic>? payload,
  ) {
    final basic = ShopPrintInformationCatalog._map(payload?['basic_info']);
    final enabledIds = state.enabledFieldIds;
    final textFields = <ShopPrintDocumentField>[
      for (final field in state.fields)
        if (state.isEnabled(field) && !_assetFieldIds.contains(field.id))
          ShopPrintDocumentField(
            id: field.id,
            label: field.label,
            value: field.value,
            group: field.group,
          ),
    ];

    return ShopPrintDocumentProfile(
      tenantId: state.tenantId,
      fields: textFields,
      logoPath: enabledIds.contains('logo')
          ? _nullablePath(basic['logo_path'])
          : null,
      logoShape: _shape(basic['logo_shape']),
      signaturePath: enabledIds.contains('signature')
          ? _nullablePath(basic['signature_path'])
          : null,
      signatureShape: _shape(basic['signature_shape']),
    );
  }

  String valueOf(String id) {
    for (final field in fields) {
      if (field.id == id) return field.value;
    }
    return '';
  }

  String get primaryName {
    final shopName = valueOf('shop_name');
    if (shopName.isNotEmpty) return shopName;
    return valueOf('legal_name');
  }

  String get primaryAddress {
    return _join([
      valueOf('address_line'),
      valueOf('city_state_pin'),
    ]);
  }

  String get primaryPhone {
    final mobile = valueOf('mobile_number');
    if (mobile.isNotEmpty) return mobile;
    return valueOf('whatsapp_number');
  }

  String get gstin => valueOf('gstin');

  List<String> get headerLines {
    return fields
        .where((field) => field.id != 'shop_name')
        .map((field) => field.displayText)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<String> linesForGroups(Set<ShopPrintFieldGroup> groups) {
    return fields
        .where((field) => groups.contains(field.group))
        .map((field) => field.displayText)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  static String? _nullablePath(Object? value) {
    final path = value?.toString().trim() ?? '';
    return path.isEmpty ? null : path;
  }

  static String _shape(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'circle' ? 'circle' : 'square';
  }

  static String _join(List<String> values) {
    return values.where((value) => value.trim().isNotEmpty).join(', ');
  }
}

class ShopPrintInformationCatalog {
  ShopPrintInformationCatalog._();

  static List<ShopPrintField> fromPayload(Map<String, dynamic>? payload) {
    final basic = _map(payload?['basic_info']);
    final address = _map(payload?['address']);
    final tax = _map(payload?['tax_compliance']);
    final branding = _map(payload?['branding_social']);
    final banking = _firstMap(payload?['banking_details']);

    final shopName = _firstValue([
      basic['brand_display_name'],
      basic['display_name'],
      basic['legal_name'],
    ]);

    return [
      ShopPrintField(
        id: 'shop_name',
        label: 'Shop Name',
        description: 'Primary store name printed in the invoice header.',
        sourceSection: 'Basic Info',
        value: shopName,
        group: ShopPrintFieldGroup.identity,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'legal_name',
        label: 'Legal Name',
        description: 'Registered business name for formal documents.',
        sourceSection: 'Basic Info',
        value: _value(basic['legal_name']),
        group: ShopPrintFieldGroup.identity,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'tagline',
        label: 'Tagline',
        description: 'Brand line shown below the shop name.',
        sourceSection: 'Basic Info',
        value: _value(basic['tagline']),
        group: ShopPrintFieldGroup.identity,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'branch_code',
        label: 'Branch Code',
        description: 'Branch identifier for multi-branch billing.',
        sourceSection: 'Basic Info',
        value: _value(basic['branch_code']),
        group: ShopPrintFieldGroup.identity,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'logo',
        label: 'Logo',
        description: 'Shop logo in the invoice header.',
        sourceSection: 'Basic Info',
        value: _pathStatus(basic['logo_path']),
        group: ShopPrintFieldGroup.identity,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'signature',
        label: 'Signature',
        description: 'Authorized signature block on printed bills.',
        sourceSection: 'Basic Info',
        value: _pathStatus(basic['signature_path']),
        group: ShopPrintFieldGroup.identity,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'mobile_number',
        label: 'Mobile Number',
        description: 'Official store phone number.',
        sourceSection: 'Basic Info',
        value: _value(basic['shop_phone']),
        group: ShopPrintFieldGroup.contact,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'whatsapp_number',
        label: 'WhatsApp Number',
        description: 'Official WhatsApp contact number.',
        sourceSection: 'Basic Info',
        value: _value(basic['shop_whatsapp']),
        group: ShopPrintFieldGroup.contact,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'business_email',
        label: 'Business Email',
        description: 'Support or billing email address.',
        sourceSection: 'Basic Info',
        value: _value(basic['business_email']),
        group: ShopPrintFieldGroup.contact,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'gstin',
        label: 'GSTIN',
        description: 'GST registration number printed on GST invoices.',
        sourceSection: 'GST & Legal',
        value: _value(tax['gstin']),
        group: ShopPrintFieldGroup.statutory,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'bis_license',
        label: 'BIS Registration No.',
        description: 'BIS jeweller hallmarking registration number.',
        sourceSection: 'GST & Legal',
        value: _bisRegistrationValue(tax),
        group: ShopPrintFieldGroup.statutory,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'bis_hallmarking_scope',
        label: 'BIS Hallmarking Scope',
        description: 'Gold, silver, or both as covered by registration.',
        sourceSection: 'GST & Legal',
        value: _value(tax['hallmarking_scope']),
        group: ShopPrintFieldGroup.statutory,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'taxpayer_type',
        label: 'Taxpayer Type',
        description: 'GST taxpayer category such as regular or composition.',
        sourceSection: 'GST & Legal',
        value: _value(tax['taxpayer_type']),
        group: ShopPrintFieldGroup.statutory,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'address_line',
        label: 'Address',
        description: 'Primary address line printed below contact details.',
        sourceSection: 'Address',
        value: _join([
          address['addr1'],
          address['addr2'],
        ]),
        group: ShopPrintFieldGroup.address,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'city_state_pin',
        label: 'City, State & PIN',
        description: 'Location line for the invoice footer or header.',
        sourceSection: 'Address',
        value: _join([
          address['city'],
          address['state'],
          address['pincode'],
        ]),
        group: ShopPrintFieldGroup.address,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'website',
        label: 'Website',
        description: 'Official website printed for customer follow-up.',
        sourceSection: 'Branding',
        value: _value(branding['website']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'instagram',
        label: 'Instagram Channel',
        description: 'Instagram handle or page link.',
        sourceSection: 'Branding',
        value: _value(branding['instagram']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'facebook',
        label: 'Facebook Channel',
        description: 'Facebook page or profile link.',
        sourceSection: 'Branding',
        value: _value(branding['facebook']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'whatsapp_channel',
        label: 'WhatsApp Channel',
        description: 'WhatsApp broadcast or channel link.',
        sourceSection: 'Branding',
        value: _value(branding['whatsapp_channel']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'whatsapp_business',
        label: 'WhatsApp Business',
        description: 'WhatsApp Business API or support number.',
        sourceSection: 'Branding',
        value: _value(branding['whatsapp_business']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'youtube',
        label: 'YouTube Channel',
        description: 'YouTube channel link for brand discovery.',
        sourceSection: 'Branding',
        value: _value(branding['youtube']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'bank_name',
        label: 'Bank Name',
        description: 'Primary account bank for payment instructions.',
        sourceSection: 'Banking',
        value: _value(banking['bank']),
        group: ShopPrintFieldGroup.banking,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'account_number',
        label: 'Account Number',
        description: 'Primary account number for customer payments.',
        sourceSection: 'Banking',
        value: _value(banking['acc']),
        group: ShopPrintFieldGroup.banking,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'ifsc_code',
        label: 'IFSC Code',
        description: 'IFSC code for bank transfer details.',
        sourceSection: 'Banking',
        value: _value(banking['ifsc']),
        group: ShopPrintFieldGroup.banking,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'upi_id',
        label: 'UPI ID',
        description: 'UPI payment ID for invoice payment collection.',
        sourceSection: 'Banking',
        value: _value(banking['upi']),
        group: ShopPrintFieldGroup.banking,
        defaultEnabled: false,
      ),
    ];
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static Map<String, dynamic> _firstMap(Object? value) {
    if (value is List && value.isNotEmpty) return _map(value.first);
    return const {};
  }

  static String _firstValue(List<Object?> values) {
    for (final value in values) {
      final text = _value(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _join(List<Object?> values) {
    return values.map(_value).where((value) => value.isNotEmpty).join(', ');
  }

  static String _bisRegistrationValue(Map<String, dynamic> tax) {
    final legacy = _value(tax['bis_license_no']);
    if (legacy.isNotEmpty) return legacy;

    final gold = _value(tax['gold_bis_license_no']);
    final silver = _value(tax['silver_bis_license_no']);
    if (gold.isNotEmpty && silver.isNotEmpty) {
      if (gold.toUpperCase() == silver.toUpperCase()) return gold;
      return 'Gold: $gold | Silver: $silver';
    }
    if (gold.isNotEmpty) return gold;
    return silver;
  }

  static String _pathStatus(Object? value) {
    final path = _value(value);
    return path.isEmpty ? '' : 'Configured';
  }

  static String _value(Object? value) => value?.toString().trim() ?? '';
}
