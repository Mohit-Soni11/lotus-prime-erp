import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_locations.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_store.dart';

class BackupFixture {
  BackupFixture(this.directory)
      : locations = BackupLocations(
            root: Directory(p.join(directory.path, 'Backups')),
            resources: [
              BackupResource(
                  'business', p.join(directory.path, 'Data', 'business.sqlite'),
                  schemaVersion: 3),
              BackupResource(
                  'shop', p.join(directory.path, 'Data', 'shop.sqlite'),
                  schemaVersion: 2),
              BackupResource('media', p.join(directory.path, 'Data', 'Photos')),
              BackupResource('external_media',
                  p.join(directory.path, 'Data', 'RecoveredMedia')),
            ]);
  final Directory directory;
  final BackupLocations locations;
  final preferences = MemoryBusinessPreferences();
  Future<void> seed({int amount = 125}) async {
    await Directory(p.join(directory.path, 'Data')).create(recursive: true);
    final business = sqlite3.open(locations.resources[0].path);
    final shop = sqlite3.open(locations.resources[1].path);
    try {
      business.execute('PRAGMA user_version=3');
      business.execute(
          'CREATE TABLE bills(id INTEGER PRIMARY KEY, amount INTEGER, photo_path TEXT)');
      business.execute('INSERT INTO bills VALUES (1, ?, ?)',
          [amount, p.join(locations.resources[2].path, 'item.jpg')]);
      shop.execute('PRAGMA user_version=2');
      shop.execute(
          'CREATE TABLE local_owner_account(id INTEGER PRIMARY KEY, username TEXT)');
      shop.execute("INSERT INTO local_owner_account VALUES (1, 'test-owner')");
    } finally {
      business.dispose();
      shop.dispose();
    }
    final photo = File(p.join(locations.resources[2].path, 'item.jpg'));
    await photo.parent.create(recursive: true);
    await photo.writeAsBytes([1, 2, 3, 4]);
    preferences.values = {
      'currency': 'INR',
      'profile': photo.path,
      'flags': ['a', 'b']
    };
  }

  int amount() {
    final db =
        sqlite3.open(locations.resources[0].path, mode: OpenMode.readOnly);
    try {
      return db.select('SELECT amount FROM bills').single['amount'] as int;
    } finally {
      db.dispose();
    }
  }
}

class MemoryBusinessPreferences implements BusinessPreferences {
  Map<String, Object> values = {};
  bool failOnce = false;
  @override
  Future<Map<String, Object>> read() async => {...values};
  @override
  Future<void> replace(Map<String, Object> value) async {
    if (failOnce) {
      failOnce = false;
      throw StateError('Simulated preferences write failure');
    }
    values = {...value};
  }
}
