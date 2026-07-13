class GoldPurityProfile {
  final String id;
  final String name;
  final String displayValue;
  final String description;
  final double purityPercent;
  final bool isSystem;

  const GoldPurityProfile({
    required this.id,
    required this.name,
    required this.displayValue,
    required this.description,
    required this.purityPercent,
    required this.isSystem,
  });

  bool get isCustom => !isSystem;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'displayValue': displayValue,
      'description': description,
      'purityPercent': purityPercent,
      'isSystem': isSystem,
    };
  }

  factory GoldPurityProfile.fromJson(Map<String, Object?> json) {
    return GoldPurityProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayValue: json['displayValue']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      purityPercent:
          double.tryParse(json['purityPercent']?.toString() ?? '') ?? 0,
      isSystem: json['isSystem'] == true,
    );
  }
}
