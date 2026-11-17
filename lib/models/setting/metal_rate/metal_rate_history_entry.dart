part of 'metal_rate_model.dart';

class MetalRateHistoryEntry {
  final MetalRateProfile profile;
  final DateTime changedAt;
  final String source;

  const MetalRateHistoryEntry({
    required this.profile,
    required this.changedAt,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'changedAt': changedAt.millisecondsSinceEpoch,
        'source': source,
      };

  factory MetalRateHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MetalRateHistoryEntry(
      profile: MetalRateProfile.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
      ),
      changedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['changedAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      source: json['source'] as String? ?? 'Manual Rate Master',
    );
  }
}
