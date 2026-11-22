import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/backup_record.dart';
import 'backup_locations.dart';

Future<void> writeBackupJson(File file, Object value) async {
  await file.parent.create(recursive: true);
  final pending = File('${file.path}.pending');
  await pending.writeAsString(jsonEncode(value), flush: true);
  // File.rename replaces an existing regular destination on supported desktops.
  await pending.rename(file.path);
}

abstract interface class BusinessPreferences {
  Future<Map<String, Object>> read();
  Future<void> replace(Map<String, Object> values);
}

class SharedBusinessPreferences implements BusinessPreferences {
  bool _included(String key) =>
      !key.startsWith('backup.') &&
      !key.contains('owner_session') &&
      !key.contains('access_token') &&
      !key.contains('refresh_token');
  @override
  Future<Map<String, Object>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getKeys().where(_included))
        if (prefs.get(key) != null) key: prefs.get(key)!
    };
  }

  @override
  Future<void> replace(Map<String, Object> values) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where(_included).toList()) {
      if (!values.containsKey(key) && !await prefs.remove(key)) {
        throw StateError('Could not restore application preferences.');
      }
    }
    for (final item in values.entries.where((entry) => _included(entry.key))) {
      final value = item.value;
      final saved = switch (value) {
        bool value => await prefs.setBool(item.key, value),
        int value => await prefs.setInt(item.key, value),
        double value => await prefs.setDouble(item.key, value),
        String value => await prefs.setString(item.key, value),
        List value when value.every((item) => item is String) =>
          await prefs.setStringList(item.key, value.cast<String>()),
        _ => throw const FormatException(
            'Unsupported preference value in backup.'),
      };
      if (!saved) throw StateError('Could not save restored preferences.');
    }
    await prefs.reload();
  }
}

class BackupStore {
  BackupStore(this.locations);
  final BackupLocations locations;
  String? warning;
  File get _settings => File(p.join(locations.root.path, 'settings.json'));
  File get _catalog => File(p.join(locations.root.path, 'catalog.json'));
  Future<BackupSettings> settings() => _read(
      _settings,
      (value) => BackupSettings.fromJson(
          Map<String, dynamic>.from(value as Map), locations.local.path),
      BackupSettings(localFolder: locations.local.path));
  Future<void> saveSettings(BackupSettings settings) =>
      writeBackupJson(_settings, settings.toJson());
  Future<List<BackupRecord>> records() async {
    final items = await _read(
        _catalog,
        (value) => (value as List)
            .map((item) =>
                BackupRecord.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        <BackupRecord>[]);
    items.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return items;
  }

  Future<T> _read<T>(File file, T Function(Object?) parse, T fallback) async {
    if (!await file.exists()) return fallback;
    try {
      return parse(jsonDecode(await file.readAsString()));
    } on FormatException {
      await _preserveDamagedMetadata(file);
      return fallback;
    } on TypeError {
      await _preserveDamagedMetadata(file);
      return fallback;
    }
  }

  Future<void> _preserveDamagedMetadata(File file) async {
    await file.rename(
        '${file.path}.unreadable-${DateTime.now().microsecondsSinceEpoch}');
    warning =
        'Backup settings or history could not be read and were preserved for recovery. Your business data and backup files are unchanged. Choose your backup folder or use Restore Local File.';
  }

  Future<void> put(BackupRecord record) async {
    final items = await records();
    items.removeWhere((item) => item.id == record.id);
    items.add(record);
    items.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    await writeBackupJson(
        _catalog, items.map((item) => item.toJson()).toList());
  }
}
