import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../models/reports/day_book/day_book_balance_verification.dart';
import '../../../../models/reports/day_book/day_book_models.dart';
import '../../../../models/reports/day_book/day_book_metal_count.dart';

class DayBookExportData {
  const DayBookExportData({
    required this.summary,
    this.openingVerification,
    this.closing,
    this.legacyClosedAt,
    this.legacyClosedBy,
  });

  final DayBookSummary summary;
  final DayBookBalanceVerification? openingVerification;
  final DayBookCloseEvidence? closing;

  /// A historical day lock created before physical close snapshots existed.
  final DateTime? legacyClosedAt;
  final String? legacyClosedBy;
}

class DayBookCloseEvidence {
  const DayBookCloseEvidence({
    required this.physicalCash,
    required this.physicalBank,
    required this.denominations,
    required this.sourceHash,
    this.closedAt,
    this.closedBy,
    this.metal,
  });

  final double physicalCash;
  final double? physicalBank;
  final Map<String, num> denominations;
  final String sourceHash;
  final DateTime? closedAt;
  final String? closedBy;
  final DayBookCloseMetalEvidence? metal;

  factory DayBookCloseEvidence.fromSnapshot(
    String snapshotJson, {
    required String sourceHash,
    DateTime? closedAt,
    String? closedBy,
  }) {
    final decoded = jsonDecode(snapshotJson);
    if (decoded is! Map<String, dynamic> || decoded['physicalCash'] is! num) {
      throw const FormatException('Day closing snapshot is invalid.');
    }
    if (decoded['sourceHash'] != sourceHash) {
      throw const FormatException('Day closing snapshot hash does not match.');
    }
    final bank = decoded['physicalBank'];
    if (bank != null && bank is! num) {
      throw const FormatException('Day closing bank balance is invalid.');
    }
    final rawCounts = decoded['denominations'];
    if (rawCounts != null && rawCounts is! Map) {
      throw const FormatException('Day closing note counts are invalid.');
    }
    final counts = <String, num>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        if (entry.key is! String || entry.value is! num) {
          throw const FormatException('Day closing note counts are invalid.');
        }
        counts[entry.key as String] = entry.value as num;
      }
    }
    return DayBookCloseEvidence(
      physicalCash: (decoded['physicalCash'] as num).toDouble(),
      physicalBank: (bank as num?)?.toDouble(),
      denominations: Map.unmodifiable(counts),
      sourceHash: sourceHash,
      closedAt: closedAt,
      closedBy: closedBy,
      metal: DayBookCloseMetalEvidence.fromSnapshot(decoded['ownedMetal']),
    );
  }
}

class DayBookCloseMetalEvidence {
  const DayBookCloseMetalEvidence({
    required this.sourceHash,
    required this.verifiedAt,
    required this.verifiedBy,
    required this.expected,
    required this.counted,
  });

  final String sourceHash;
  final DateTime verifiedAt;
  final String verifiedBy;
  final List<DayBookMetalCountLine> expected;
  final List<DayBookPhysicalMetalCount> counted;

  static DayBookCloseMetalEvidence? fromSnapshot(Object? ownedMetal) {
    if (ownedMetal is! Map<String, dynamic>) return null;
    final saved = ownedMetal['physicalVerification'];
    if (saved == null) return null;
    if (saved is! Map<String, dynamic> ||
        saved['sourceHash'] is! String ||
        saved['verifiedAt'] is! String ||
        saved['verifiedBy'] is! String ||
        saved['expectedLines'] is! List ||
        saved['countedLines'] is! List) {
      throw const FormatException('Saved physical metal evidence is invalid.');
    }
    final expected = <DayBookMetalCountLine>[];
    for (final raw in saved['expectedLines'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Saved physical metal source is invalid.');
      }
      expected.add(DayBookMetalCountLine(
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
    final counted = <DayBookPhysicalMetalCount>[];
    for (final raw in saved['countedLines'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Saved physical metal count is invalid.');
      }
      counted.add(DayBookPhysicalMetalCount(
        key: raw['key'] as String,
        pieces: raw['pieces'] as int,
        grossGrams: (raw['grossGrams'] as num).toDouble(),
        netGrams: (raw['netGrams'] as num).toDouble(),
        fineGrams: (raw['fineGrams'] as num).toDouble(),
      ));
    }
    if (sha256
            .convert(utf8.encode(jsonEncode(saved['expectedLines'])))
            .toString() !=
        saved['sourceHash']) {
      throw const FormatException('Saved physical metal source hash differs.');
    }
    final countedKeys = {for (final line in counted) line.key};
    if (countedKeys.length != counted.length ||
        countedKeys.length != expected.length ||
        expected.any((line) => !countedKeys.contains(line.key))) {
      throw const FormatException('Saved physical metal count is incomplete.');
    }
    return DayBookCloseMetalEvidence(
      sourceHash: saved['sourceHash'] as String,
      verifiedAt: DateTime.parse(saved['verifiedAt'] as String),
      verifiedBy: saved['verifiedBy'] as String,
      expected: List.unmodifiable(expected),
      counted: List.unmodifiable(counted),
    );
  }
}
