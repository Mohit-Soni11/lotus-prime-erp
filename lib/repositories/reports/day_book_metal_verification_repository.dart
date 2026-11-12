import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_metal_count.dart';
import '../../models/reports/day_book/day_book_owned_stock_position.dart';

/// An append-only physical count. It never changes inventory or Girvi custody.
class DayBookMetalVerificationRepository {
  const DayBookMetalVerificationRepository(this._db);

  final AppDatabase _db;

  Future<List<DayBookMetalCountLine>> expected() async {
    final unitRows = await _db.customSelect('''
      SELECT u.stock_item_id, u.metal_type, u.item_name, u.purity_percent,
        COUNT(*) AS pieces, SUM(u.gross_weight) AS gross_grams,
        SUM(u.net_weight) AS net_grams,
        SUM(CASE WHEN u.actual_fine_weight > 0
          THEN u.actual_fine_weight
          WHEN u.purity_percent > 0
          THEN u.net_weight * u.purity_percent / 100.0
          ELSE NULL END) AS fine_grams,
        SUM(CASE WHEN u.purity_percent <= 0 THEN 1 ELSE 0 END) AS unknown_purity
      FROM stock_item_units u
      WHERE LOWER(u.status) = 'available'
        AND LOWER(TRIM(u.metal_type)) IN ('gold', 'silver')
      GROUP BY u.stock_item_id, LOWER(TRIM(u.metal_type)),
        u.item_name, u.purity_percent
      ORDER BY u.stock_item_id, u.purity_percent, u.item_name
    ''').get();
    final legacyRows = await _db.customSelect('''
      SELECT s.id, s.metal_type, s.item_name, s.purity, s.quantity,
        s.gross_weight, s.net_weight
      FROM stock_items s
      WHERE LOWER(s.status) = 'available' AND s.is_active = 1
        AND LOWER(TRIM(s.metal_type)) IN ('gold', 'silver')
        AND NOT EXISTS (SELECT 1 FROM stock_item_units u
          WHERE u.stock_item_id = s.id)
      ORDER BY s.id
    ''', readsFrom: {_db.stockItems}).get();
    final lines = <DayBookMetalCountLine>[
      for (final row in unitRows)
        DayBookMetalCountLine(
          key: 'unit:${row.read<int>('stock_item_id')}:'
              '${row.read<double>('purity_percent')}:'
              '${row.read<String>('item_name')}',
          metal: row.read<String>('metal_type'),
          item: row.read<String>('item_name'),
          purity: row.read<double>('purity_percent') > 0
              ? '${row.read<double>('purity_percent').toStringAsFixed(3)}%'
              : 'Unknown',
          pieces: row.read<int>('pieces'),
          grossGrams: row.read<double>('gross_grams'),
          netGrams: row.read<double>('net_grams'),
          fineGrams: row.read<int>('unknown_purity') == 0
              ? row.readNullable<double>('fine_grams')
              : null,
        ),
      for (final row in legacyRows)
        DayBookMetalCountLine(
          key: 'legacy:${row.read<int>('id')}',
          metal: row.read<String>('metal_type'),
          item: row.read<String>('item_name'),
          purity: row.readNullable<String>('purity')?.trim().isNotEmpty == true
              ? row.read<String>('purity')
              : 'Unknown',
          pieces: row.read<int>('quantity'),
          grossGrams: row.read<double>('gross_weight'),
          netGrams: row.read<double>('net_weight'),
        ),
    ];
    return List.unmodifiable(lines..sort((a, b) => a.key.compareTo(b.key)));
  }

  Future<DayBookMetalVerification?> latest(DateTime day) async {
    final row = await _db.customSelect('''
      SELECT source_hash, snapshot_json, verified_at, verified_by
      FROM day_book_metal_verifications WHERE day_key = ?
      ORDER BY id DESC LIMIT 1
    ''', variables: [Variable.withString(_key(day))]).getSingleOrNull();
    if (row == null) return null;
    final decoded = jsonDecode(row.read<String>('snapshot_json'));
    if (decoded is! Map<String, dynamic> ||
        decoded['physical'] is! List ||
        decoded['expected'] is! List) {
      throw const FormatException('Saved metal count is invalid.');
    }
    final savedHash = row.read<String>('source_hash');
    if (sha256
            .convert(utf8.encode(jsonEncode(decoded['expected'])))
            .toString() !=
        savedHash) {
      throw const FormatException('Saved metal count source hash differs.');
    }
    final physical = <DayBookPhysicalMetalCount>[];
    final expectedLines = <DayBookMetalCountLine>[];
    for (final raw in decoded['expected'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Saved metal source is invalid.');
      }
      expectedLines.add(DayBookMetalCountLine(
        key: raw['key'] as String,
        metal: raw['metal'] as String,
        item: raw['item'] as String,
        purity: raw['purity'] as String,
        pieces: raw['pieces'] as int,
        grossGrams: (raw['grossGrams'] as num).toDouble(),
        netGrams: (raw['netGrams'] as num).toDouble(),
        fineGrams: (raw['fineGrams'] as num?)?.toDouble(),
      ));
    }
    for (final raw in decoded['physical'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Saved metal count is invalid.');
      }
      physical.add(DayBookPhysicalMetalCount(
        key: raw['key'] as String,
        pieces: raw['pieces'] as int,
        grossGrams: (raw['grossGrams'] as num).toDouble(),
        netGrams: (raw['netGrams'] as num).toDouble(),
        fineGrams: (raw['fineGrams'] as num).toDouble(),
      ));
    }
    return DayBookMetalVerification(
      sourceHash: savedHash,
      verifiedAt: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('verified_at') * 1000),
      verifiedBy: row.read<String>('verified_by'),
      physicalCounts: List.unmodifiable(physical),
      expectedLines: List.unmodifiable(expectedLines),
    );
  }

  Future<bool> isVerified(DateTime day) async {
    final saved = await latest(day);
    if (saved == null) return false;
    final closed = await _db.customSelect(
      'SELECT 1 FROM finance_day_closures WHERE day_key = ? LIMIT 1',
      variables: [Variable.withString(_key(day))],
    ).getSingleOrNull();
    if (closed != null) return true;
    if (!_isToday(day)) return false;
    return saved.sourceHash == sourceHash(await expected());
  }

  Future<bool> isVerifiedForPosition(
      DateTime day, DayBookOwnedStockPosition position) async {
    final saved = await latest(day);
    if (saved == null || !(await isVerified(day))) return false;
    return matchesOwnedClosing(saved, position);
  }

  bool matchesOwnedClosing(
      DayBookMetalVerification saved, DayBookOwnedStockPosition position) {
    double total(String metal) => saved.physicalCounts.fold<double>(
          0,
          (sum, count) {
            final source = saved.expectedLines
                .where((line) => line.key == count.key)
                .firstOrNull;
            return source?.metal.trim().toLowerCase() == metal
                ? sum + count.netGrams
                : sum;
          },
        );
    return position.gold.isConsistent &&
        position.silver.isConsistent &&
        _same(total('gold'), position.gold.closingGrams) &&
        _same(total('silver'), position.silver.closingGrams);
  }

  Future<DayBookMetalVerification> verify({
    required DateTime day,
    required String actor,
    required List<DayBookPhysicalMetalCount> physical,
    required bool emptyStockConfirmed,
  }) async {
    if (!_isToday(day)) {
      throw StateError('Physical metal count can only certify today.');
    }
    if (actor.trim().isEmpty) throw StateError('Authorized actor is required.');
    return _db.transaction(() async {
      final closed = await _db.customSelect(
        'SELECT 1 FROM finance_day_closures WHERE day_key = ? LIMIT 1',
        variables: [Variable.withString(_key(day))],
      ).getSingleOrNull();
      if (closed != null) throw StateError('The day is already closed.');
      final stock = await expected();
      if (stock.isEmpty && !emptyStockConfirmed) {
        throw StateError('Confirm that the physical stock is empty.');
      }
      final byKey = <String, DayBookPhysicalMetalCount>{};
      for (final count in physical) {
        if (byKey.containsKey(count.key) ||
            count.pieces < 0 ||
            !count.grossGrams.isFinite ||
            !count.netGrams.isFinite ||
            !count.fineGrams.isFinite ||
            count.grossGrams < 0 ||
            count.netGrams < 0 ||
            count.fineGrams < 0) {
          throw StateError('Invalid or duplicate physical metal count.');
        }
        byKey[count.key] = count;
      }
      if (byKey.length != stock.length) {
        throw StateError('Count every owned stock item before verification.');
      }
      for (final line in stock) {
        if (line.purity == 'Unknown') {
          throw StateError('Purity is missing for ${line.metal} '
              '${line.item}. Correct the inventory source before verification.');
        }
        final count = byKey[line.key];
        if (count == null ||
            count.pieces != line.pieces ||
            !_same(count.grossGrams, line.grossGrams) ||
            !_same(count.netGrams, line.netGrams) ||
            (line.fineGrams != null &&
                !_same(count.fineGrams, line.fineGrams!))) {
          throw StateError('Physical count differs from ${line.metal} '
              '${line.item} (${line.purity}). Resolve stock variance first.');
        }
      }
      final hash = sourceHash(stock);
      final sorted = physical.toList()..sort((a, b) => a.key.compareTo(b.key));
      final now = DateTime.now();
      await _db.customStatement('''
        INSERT INTO day_book_metal_verifications
          (day_key, source_hash, snapshot_json, verified_at, verified_by)
        VALUES (?, ?, ?, ?, ?)
      ''', [
        _key(day),
        hash,
        jsonEncode({
          'expected': [for (final line in stock) line.toJson()],
          'physical': [for (final count in sorted) count.toJson()],
        }),
        now.millisecondsSinceEpoch ~/ 1000,
        actor.trim(),
      ]);
      return DayBookMetalVerification(
        sourceHash: hash,
        verifiedAt: now,
        verifiedBy: actor.trim(),
        physicalCounts: List.unmodifiable(sorted),
        expectedLines: stock,
      );
    });
  }

  String sourceHash(List<DayBookMetalCountLine> lines) => sha256
      .convert(utf8.encode(jsonEncode([
        for (final line in lines) line.toJson(),
      ])))
      .toString();

  bool _same(double a, double b) => (a - b).abs() < 0.001;
  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  String _key(DateTime day) => DateFormat('yyyyMMdd').format(day);
}
