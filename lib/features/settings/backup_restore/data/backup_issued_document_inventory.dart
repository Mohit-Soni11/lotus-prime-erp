import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../../../../core/documents/issued_invoice_archive.dart';
import 'backup_file_safety.dart';
import 'backup_locations.dart';

/// Reconciles issued documents against the database snapshot in the package.
class BackupIssuedDocumentInventory {
  const BackupIssuedDocumentInventory();

  Future<List<String>> capture(
      BackupLocations locations, Directory workspace) async {
    final resource = locations.resources
        .where((item) => item.id == 'issued_invoices' && !item.isDatabase);
    if (resource.isEmpty) return const [];
    final archive =
        Directory(p.join(workspace.path, 'payload', 'issued_invoices'));
    await _includeLegacy(locations.legacyIssuedInvoicesPath, archive);

    final business = locations.resources
        .where((item) => item.id == 'business' && item.isDatabase);
    if (business.isEmpty) return const [];
    final db = sqlite3.open(
        p.join(workspace.path, 'payload', 'business', 'database.sqlite'),
        mode: OpenMode.readOnly);
    try {
      final missing = <String>[];
      await _inspect(
          db, archive, 'bills', 'bill_no', IssuedInvoiceKind.sales, missing);
      await _inspect(db, archive, 'sales_orders', 'order_no',
          IssuedInvoiceKind.booking, missing,
          condition:
              'EXISTS (SELECT 1 FROM order_advances a WHERE a.order_id = d.id)');
      await _inspect(db, archive, 'return_vouchers', 'voucher_no',
          IssuedInvoiceKind.returnVoucher, missing,
          condition: "UPPER(TRIM(d.status)) = 'POSTED'");
      return missing;
    } finally {
      db.dispose();
    }
  }

  Future<void> _includeLegacy(String? path, Directory archive) async {
    if (path == null || p.equals(path, archive.path)) return;
    await requireNoLinks(path);
    final legacy = Directory(path);
    if (!await legacy.exists()) return;
    await for (final entity
        in legacy.list(recursive: true, followLinks: false)) {
      if (entity is Link) {
        throw StateError('Linked files cannot be included in the backup.');
      }
      if (entity is! File) continue;
      if (!const {'.pdf', '.json'}
          .contains(p.extension(entity.path).toLowerCase())) {
        continue;
      }
      final relative = p.relative(entity.path, from: legacy.path);
      validateArchivePath(
          'payload/issued_invoices/${relative.replaceAll(p.separator, '/')}');
      final destination = File(p.join(archive.path, relative));
      final exists = await destination.exists();
      final replaceDamagedPdf = exists &&
          p.extension(destination.path).toLowerCase() == '.pdf' &&
          !await _hasPdfSignature(destination) &&
          await _hasPdfSignature(entity);
      if (!exists || replaceDamagedPdf) {
        await copyBackupTree(entity.path, destination.path);
      }
    }
  }

  Future<void> _inspect(
    Database db,
    Directory archive,
    String table,
    String numberColumn,
    IssuedInvoiceKind kind,
    List<String> missing, {
    String? condition,
  }) async {
    final exists = db.select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        [table]);
    if (exists.isEmpty) return;
    final columns = db
        .select('PRAGMA table_info("$table")')
        .map((row) => row['name'])
        .toSet();
    if (!columns.contains('id') || !columns.contains(numberColumn)) return;
    if (table == 'sales_orders' &&
        db
            .select("SELECT 1 FROM sqlite_master WHERE type = 'table' AND "
                "name = 'order_advances'")
            .isEmpty) {
      return;
    }

    var cursor = 0;
    while (true) {
      final rows = db.select(
        'SELECT d.id, d."$numberColumn" AS number FROM "$table" d '
        'WHERE d.id > ? ${condition == null ? '' : 'AND $condition'} '
        'ORDER BY d.id LIMIT 500',
        [cursor],
      );
      if (rows.isEmpty) break;
      for (final row in rows) {
        final id = row['id'] as int;
        final number = (row['number'] as String?)?.trim() ?? '';
        if (number.isEmpty ||
            !await _hasReadablePdf(archive, kind, id, number)) {
          missing.add('${kind.name}: $number (record $id)');
        }
      }
      cursor = rows.last['id'] as int;
    }
  }

  Future<bool> _hasReadablePdf(
      Directory archive, IssuedInvoiceKind kind, int id, String number) async {
    final original = File(p.join(
        archive.path, IssuedInvoiceArchive.relativePdfPath(kind, id, number)));
    if (!await _hasPdfSignature(original)) return false;
    final revisionDir = Directory(p.join(original.parent.path, 'revisions',
        p.basenameWithoutExtension(original.path)));
    if (!await revisionDir.exists()) return true;
    final revisions = await revisionDir
        .list(followLinks: false)
        .where((item) => item is File && p.extension(item.path) == '.pdf')
        .cast<File>()
        .toList();
    if (revisions.isEmpty) return true;
    revisions.sort((a, b) => a.path.compareTo(b.path));
    return _hasPdfSignature(revisions.last);
  }

  Future<bool> _hasPdfSignature(File file) async {
    if (!await file.exists()) return false;
    final bytes = await file.openRead(0, 5).toList();
    final signature = bytes.expand((chunk) => chunk).toList();
    return signature.length == 5 &&
        signature[0] == 0x25 &&
        signature[1] == 0x50 &&
        signature[2] == 0x44 &&
        signature[3] == 0x46 &&
        signature[4] == 0x2D;
  }
}
