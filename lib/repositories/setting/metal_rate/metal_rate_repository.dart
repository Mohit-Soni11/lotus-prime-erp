// =============================================================================
// FILE        : lib/repositories/setting/metal_rate/metal_rate_repository.dart
// MODULE      : Metal Rate Setting
// LAYER       : Repository / Data Access
// DESCRIPTION : Persists daily metal rate profiles and compact history locally.
// =============================================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/setting/metal_rate/metal_rate_model.dart';

class MetalRateRepository {
  static const String _profilesKey = 'metal_rate_profiles_v2';
  static const String _historyKey = 'metal_rate_history_v2';
  static const int _historyLimit = 25;

  Future<List<MetalRateProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    final profiles = <MetalRateProfile>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        profiles.addAll(
          decoded
              .whereType<Map>()
              .map(
                (item) => MetalRateProfile.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      } catch (_) {
        profiles.clear();
      }
    }

    final existingKeys = profiles.map((profile) => profile.metal.key).toSet();
    for (final metal in MetalRateMetal.values) {
      if (!existingKeys.contains(metal.key)) {
        profiles.add(MetalRateProfile.defaultFor(metal));
      }
    }

    await _writeProfiles(prefs, profiles);
    return profiles;
  }

  Future<MetalRateProfile> loadProfile(MetalRateMetal metal) async {
    final profiles = await loadProfiles();
    return profiles.firstWhere(
      (profile) => profile.metal == metal,
      orElse: () => MetalRateProfile.defaultFor(metal),
    );
  }

  Future<void> saveProfile(MetalRateProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await loadProfiles();
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    final index = profiles.indexWhere((item) => item.metal == profile.metal);

    if (index == -1) {
      profiles.add(updatedProfile);
    } else {
      profiles[index] = updatedProfile;
    }

    await _writeProfiles(prefs, profiles);
    await _appendHistory(prefs, updatedProfile);
  }

  Future<void> resetProfile(MetalRateMetal metal) async {
    await saveProfile(MetalRateProfile.defaultFor(metal));
  }

  Future<List<MetalRateHistoryEntry>> loadHistory(MetalRateMetal metal) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .whereType<Map>()
          .map(
            (item) => MetalRateHistoryEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((entry) => entry.profile.metal == metal)
          .toList();
      entries.sort((a, b) => b.changedAt.compareTo(a.changedAt));
      return entries.take(_historyLimit).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeProfiles(
    SharedPreferences prefs,
    List<MetalRateProfile> profiles,
  ) {
    return prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  Future<void> _appendHistory(
    SharedPreferences prefs,
    MetalRateProfile profile,
  ) async {
    final raw = prefs.getString(_historyKey);
    final entries = <MetalRateHistoryEntry>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        entries.addAll(
          decoded
              .whereType<Map>()
              .map(
                (item) => MetalRateHistoryEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      } catch (_) {
        entries.clear();
      }
    }

    entries.insert(
      0,
      MetalRateHistoryEntry(
        profile: profile,
        changedAt: profile.updatedAt,
        source: profile.marketSource,
      ),
    );

    final compact = entries.take(_historyLimit * MetalRateMetal.values.length);
    await prefs.setString(
      _historyKey,
      jsonEncode(compact.map((entry) => entry.toJson()).toList()),
    );
  }
}
