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

  bool get isConfigured => id == 'social_media_qr' || value.trim().isNotEmpty;
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

  bool get isQrField => id == 'social_media_qr';

  String get displayText {
    if (isQrField) return '';

    switch (group) {
      case ShopPrintFieldGroup.identity:
        if (id == 'shop_name' || id == 'tagline') return value;
        if (id == 'legal_name') return 'Legal Name: $value';
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
    final selectedFields = _removeDuplicateContactFields(
      state.fields.where(state.isEnabled),
    );
    final textFields = <ShopPrintDocumentField>[
      for (final field in selectedFields)
        if (!_assetFieldIds.contains(field.id))
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
    final shopName = valueOf('shop_name').trim();
    final legalName = valueOf('legal_name').trim();
    if (_shouldPreferFormalName(shopName, legalName)) return legalName;
    if (shopName.isNotEmpty) return shopName;
    return legalName;
  }

  String get primaryAddress {
    final fullAddress = valueOf('business_address');
    if (fullAddress.isNotEmpty) return fullAddress;
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
    final primary = primaryName.toLowerCase();
    return fields
        .where((field) {
          if (field.id == 'shop_name') return false;
          if (field.id == 'legal_name' &&
              field.value.trim().toLowerCase() == primary) {
            return false;
          }
          return true;
        })
        .map((field) => field.displayText)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  static bool _shouldPreferFormalName(String shopName, String legalName) {
    if (shopName.isEmpty || legalName.isEmpty) return false;
    final normalizedShop = shopName.toLowerCase();
    final normalizedLegal = legalName.toLowerCase();
    if (normalizedShop == normalizedLegal) return false;
    final shopWordCount = shopName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    final legalWordCount = legalName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    return shopWordCount <= 1 &&
        legalWordCount > shopWordCount &&
        normalizedLegal.contains(normalizedShop);
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

  static Iterable<ShopPrintField> _removeDuplicateContactFields(
    Iterable<ShopPrintField> fields,
  ) sync* {
    final selected = fields.toList(growable: false);
    final mobile = _digitsOnly(_fieldValue(selected, 'mobile_number'));
    final whatsapp = _digitsOnly(_fieldValue(selected, 'whatsapp_number'));
    for (final field in selected) {
      if (field.id == 'whatsapp_number' &&
          mobile.isNotEmpty &&
          mobile == whatsapp) {
        continue;
      }
      yield field;
    }
  }

  static String _fieldValue(List<ShopPrintField> fields, String id) {
    for (final field in fields) {
      if (field.id == id) return field.value;
    }
    return '';
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');
}

class ShopPrintInformationCatalog {
  ShopPrintInformationCatalog._();

  static List<ShopPrintField> fromPayload(Map<String, dynamic>? payload) {
    final basic = _map(payload?['basic_info']);
    final address = _map(payload?['address']);
    final tax = _map(payload?['tax_compliance']);
    final branding = _map(payload?['branding_social']);
    final banking = _firstMap(payload?['banking_details']);
    final mobileNumber = _value(basic['shop_phone']);
    final whatsappNumber = _value(basic['shop_whatsapp']);
    final helpDeskNumber = _firstValue([
      basic['help_desk_number'],
      basic['alternate_phone'],
      basic['support_phone'],
    ]);
    final fullAddress = _join([
      address['addr1'],
      address['addr2'],
      address['city'],
      address['state'],
      address['pincode'],
      address['country'],
    ]);
    final socialQrPayload = _socialDirectoryPayload(branding);

    final shopName = _firstValue([
      basic['display_name'],
      basic['legal_name'],
      basic['brand_display_name'],
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
        label: 'Business Mobile',
        description: 'Primary customer-facing business number.',
        sourceSection: 'Basic Info',
        value: mobileNumber,
        group: ShopPrintFieldGroup.contact,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'whatsapp_number',
        label: 'WhatsApp Number',
        description: 'Printed once with business mobile when both are same.',
        sourceSection: 'Basic Info',
        value: whatsappNumber,
        group: ShopPrintFieldGroup.contact,
        defaultEnabled: true,
      ),
      ShopPrintField(
        id: 'help_desk_number',
        label: 'Help Desk Number',
        description: 'Alternate support or help desk contact number.',
        sourceSection: 'Basic Info',
        value: helpDeskNumber,
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
        label: 'BIS Registration Number',
        description: 'Single or metal-wise BIS registration reference.',
        sourceSection: 'GST & Legal',
        value: _bisRegistrationValue(tax),
        group: ShopPrintFieldGroup.statutory,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'business_address',
        label: 'Business Address',
        description: 'Complete billing address in one clean invoice line.',
        sourceSection: 'Address',
        value: fullAddress,
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
        label: 'Instagram',
        description: 'Instagram profile for offers and brand updates.',
        sourceSection: 'Branding',
        value: _value(branding['instagram']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'facebook',
        label: 'Facebook',
        description: 'Facebook page for customer engagement.',
        sourceSection: 'Branding',
        value: _value(branding['facebook']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'youtube',
        label: 'YouTube',
        description: 'YouTube channel for brand and product videos.',
        sourceSection: 'Branding',
        value: _value(branding['youtube']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'whatsapp_channel',
        label: 'WhatsApp Channel',
        description: 'WhatsApp channel for promotions and announcements.',
        sourceSection: 'Branding',
        value: _value(branding['whatsapp_channel']),
        group: ShopPrintFieldGroup.social,
        defaultEnabled: false,
      ),
      ShopPrintField(
        id: 'social_media_qr',
        label: 'Social Media QR',
        description: 'QR payload with all configured brand channel links.',
        sourceSection: 'Branding',
        value: socialQrPayload,
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
    final entries = tax.entries
        .where((entry) =>
            entry.key.endsWith('_bis_license_no') &&
            entry.key != 'bis_license_no')
        .map((entry) {
          final value = _value(entry.value);
          if (value.isEmpty) return '';
          final metal = entry.key
              .replaceFirst(RegExp(r'_bis_license_no$'), '')
              .split('_')
              .where((part) => part.isNotEmpty)
              .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
              .join(' ');
          if (metal.isEmpty) return '';
          return '$metal: $value';
        })
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (entries.isNotEmpty) return entries.join(' | ');
    return _value(tax['bis_license_no']);
  }

  static String _pathStatus(Object? value) {
    final path = _value(value);
    return path.isEmpty ? '' : 'Configured';
  }

  static String _value(Object? value) => value?.toString().trim() ?? '';

  static String _socialDirectoryPayload(Map<String, dynamic> branding) {
    final entries = <String>[
      _socialLine('Website', branding['website']),
      _socialLine('Instagram', branding['instagram']),
      _socialLine('Facebook', branding['facebook']),
      _socialLine('YouTube', branding['youtube']),
      _socialLine('WhatsApp Channel', branding['whatsapp_channel']),
    ].where((line) => line.isNotEmpty).toList(growable: false);
    return entries.join('\n');
  }

  static String _socialLine(String label, Object? value) {
    final text = _value(value);
    if (text.isEmpty) return '';
    return '$label: $text';
  }
}
