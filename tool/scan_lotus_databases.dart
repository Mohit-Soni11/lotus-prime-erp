// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

const _signalTables = <String>[
  'customers',
  'suppliers',
  'stock_items',
  'stock_item_units',
  'stock_movements',
  'purchase_vouchers',
  'purchase_voucher_items',
  'bills',
  'bill_items',
  'customer_account_ledger',
  'cash_transactions',
  'bank_transactions',
  'sales_orders',
  'girvi_loans',
  'girvi_payments',
];

const _skipNames = <String>{
  '.git',
  '.dart_tool',
  'build',
  'node_modules',
  '.pub-cache',
  'Cache',
  'Code Cache',
  'GPUCache',
  'GrShaderCache',
  'DawnCache',
  'Service Worker',
  'Microsoft',
  'Google',
  'NVIDIA',
  'NVIDIA Corporation',
  'Packages',
  'CrashDumps',
  'Temp',
  'tmp',
};

void main(List<String> args) {
  final roots = args.isEmpty
      ? _defaultRoots()
      : args.map((path) => Directory(path)).toList(growable: false);
  final candidates = <_DatabaseCandidate>[];
  var scannedFiles = 0;
  var sqliteFiles = 0;

  for (final root in roots) {
    if (!root.existsSync()) {
      continue;
    }

    stderr.writeln('Scanning ${root.path}');
    for (final entity in _safeList(root)) {
      if (entity is! File) {
        continue;
      }
      scannedFiles += 1;
      if (!_looksLikeDatabaseFile(entity.path)) {
        continue;
      }
      if (!_hasSqliteHeader(entity)) {
        continue;
      }
      sqliteFiles += 1;

      final candidate = _inspect(entity.path);
      if (candidate != null) {
        candidates.add(candidate);
      }
    }
  }

  candidates.sort((a, b) => b.totalRows.compareTo(a.totalRows));

  print('');
  print('Scanned files: $scannedFiles');
  print('SQLite files checked: $sqliteFiles');
  print('Lotus candidates: ${candidates.length}');
  print('');

  if (candidates.isEmpty) {
    print('No Lotus ERP data-bearing database found in scanned roots.');
    exitCode = 2;
    return;
  }

  for (final candidate in candidates) {
    print(candidate.path);
    print('  total_signal_rows=${candidate.totalRows}');
    for (final entry in candidate.counts.entries) {
      if (entry.value > 0) {
        print('  ${entry.key}=${entry.value}');
      }
    }
    print('');
  }
}

List<Directory> _defaultRoots() {
  final values = <String>{};

  void add(String? value) {
    if (value == null) {
      return;
    }
    final clean = value.trim();
    if (clean.isNotEmpty) {
      values.add(clean);
    }
  }

  void addChild(String? value, String child) {
    if (value == null) {
      return;
    }
    final clean = value.trim();
    if (clean.isNotEmpty) {
      values.add(p.join(clean, child));
    }
  }

  addChild(Platform.environment['USERPROFILE'], 'Documents');
  add(Platform.environment['OneDrive']);
  add(Platform.environment['LOCALAPPDATA']);
  add(Platform.environment['APPDATA']);
  add(r'D:\lotus-prime-erp');

  return values.map(Directory.new).toList(growable: false);
}

Iterable<FileSystemEntity> _safeList(Directory root) sync* {
  final queue = <Directory>[root];

  while (queue.isNotEmpty) {
    final directory = queue.removeLast();
    List<FileSystemEntity> children;
    try {
      children = directory.listSync(followLinks: false);
    } on FileSystemException {
      continue;
    }

    for (final child in children) {
      final name = p.basename(child.path);
      if (child is Directory) {
        if (!_skipNames.contains(name)) {
          queue.add(child);
        }
        continue;
      }
      yield child;
    }
  }
}

bool _looksLikeDatabaseFile(String path) {
  final lower = path.toLowerCase();
  final extension = p.extension(lower);
  if (extension == '.sqlite' || extension == '.sqlite3' || extension == '.db') {
    return true;
  }
  final filename = p.basename(lower);
  return filename.contains('lotus') || filename.contains('erp');
}

bool _hasSqliteHeader(File file) {
  try {
    if (file.lengthSync() < 16) {
      return false;
    }
    final raf = file.openSync();
    try {
      final header = raf.readSync(16);
      return String.fromCharCodes(header) == 'SQLite format 3\u0000';
    } finally {
      raf.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

_DatabaseCandidate? _inspect(String path) {
  Database? database;
  try {
    database = sqlite3.open(path, mode: OpenMode.readOnly);
    final existingTables = database
        .select(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
    final hasLotusSchema = _signalTables.any(existingTables.contains) ||
        existingTables.any(
          (name) =>
              name.startsWith('stock_') ||
              name.startsWith('purchase_') ||
              name.startsWith('girvi_'),
        );
    if (!hasLotusSchema) {
      return null;
    }

    final counts = <String, int>{};
    for (final table in _signalTables) {
      if (!existingTables.contains(table)) {
        continue;
      }
      final rows = database.select('SELECT COUNT(*) AS count FROM $table');
      counts[table] = rows.first['count'] as int;
    }

    final totalRows = counts.values.fold<int>(0, (sum, count) => sum + count);
    return _DatabaseCandidate(path: path, totalRows: totalRows, counts: counts);
  } on SqliteException catch (error) {
    stderr.writeln('Skipped $path (${error.message})');
    return null;
  } on FileSystemException catch (error) {
    stderr.writeln('Skipped $path (${error.message})');
    return null;
  } finally {
    database?.dispose();
  }
}

class _DatabaseCandidate {
  const _DatabaseCandidate({
    required this.path,
    required this.totalRows,
    required this.counts,
  });

  final String path;
  final int totalRows;
  final Map<String, int> counts;
}
