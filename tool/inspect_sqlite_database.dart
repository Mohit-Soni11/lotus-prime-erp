// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr
        .writeln('Usage: dart run tool/inspect_sqlite_database.dart <db-path>');
    exitCode = 64;
    return;
  }

  final dbPath = args.single;
  final database = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  try {
    final tables = database
        .select(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
          "ORDER BY name",
        )
        .map((row) => row['name'] as String)
        .toList(growable: false);

    print(dbPath);
    print('tables=${tables.length}');
    for (final table in tables) {
      final count = database.select('SELECT COUNT(*) AS count FROM $table');
      print('$table=${count.first['count']}');
    }
  } finally {
    database.dispose();
  }
}
