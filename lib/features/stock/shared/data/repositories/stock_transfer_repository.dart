import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_lifecycle_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';

class StockTransferRepository {
  final AppDatabase _db;

  StockTransferRepository(this._db);

  Future<void> ensureSchema() async {
    await StockLifecycleSchema.ensure(_db);
    await _ensureStockUnitLocationColumn();

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS "stock_transfers" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "transfer_no" TEXT NOT NULL UNIQUE,
        "from_location" TEXT NOT NULL,
        "to_location" TEXT NOT NULL,
        "transfer_type" TEXT NOT NULL,
        "status" TEXT NOT NULL,
        "carrier_name" TEXT,
        "authorized_by" TEXT,
        "expected_date" INTEGER,
        "notes" TEXT,
        "total_units" INTEGER NOT NULL DEFAULT 0,
        "total_gross_weight" REAL NOT NULL DEFAULT 0.0,
        "total_net_weight" REAL NOT NULL DEFAULT 0.0,
        "total_fine_weight" REAL NOT NULL DEFAULT 0.0,
        "created_at" INTEGER NOT NULL,
        "updated_at" INTEGER,
        "received_at" INTEGER,
        "cancelled_at" INTEGER
      )
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS "stock_transfer_lines" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "transfer_id" INTEGER NOT NULL,
        "stock_unit_id" INTEGER NOT NULL,
        "stock_item_id" INTEGER NOT NULL,
        "unit_code" TEXT NOT NULL,
        "huid" TEXT,
        "item_name" TEXT NOT NULL,
        "metal_type" TEXT NOT NULL,
        "gross_weight" REAL NOT NULL DEFAULT 0.0,
        "net_weight" REAL NOT NULL DEFAULT 0.0,
        "fine_weight" REAL NOT NULL DEFAULT 0.0,
        "unit_cost" REAL NOT NULL DEFAULT 0.0,
        "from_status" TEXT NOT NULL,
        "to_status" TEXT NOT NULL,
        "created_at" INTEGER NOT NULL,
        FOREIGN KEY ("transfer_id") REFERENCES "stock_transfers" ("id") ON DELETE CASCADE,
        FOREIGN KEY ("stock_unit_id") REFERENCES "stock_item_units" ("id") ON DELETE RESTRICT
      )
    ''');

    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_stock_transfers_status" ON "stock_transfers" ("status")',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_stock_transfers_created" ON "stock_transfers" ("created_at")',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_stock_transfer_lines_transfer" ON "stock_transfer_lines" ("transfer_id")',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_stock_transfer_lines_unit" ON "stock_transfer_lines" ("stock_unit_id")',
    );
  }

  Future<StockTransferSummary> loadSummary() async {
    await ensureSchema();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final available = await _db.customSelect('''
      SELECT COUNT(*) AS units
      FROM stock_item_units
      WHERE LOWER(status) = 'available'
    ''').getSingle();

    final active = await _db.customSelect(
      '''
      SELECT
        COUNT(*) AS transfers,
        COALESCE(SUM(total_units), 0) AS units,
        COALESCE(SUM(total_net_weight), 0.0) AS net_weight
      FROM stock_transfers
      WHERE status = ?
      ''',
      variables: [drift.Variable.withString(StockTransferStatus.inTransit)],
    ).getSingle();

    final day = await _db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN created_at >= ? AND created_at < ? THEN total_units ELSE 0 END), 0) AS transferred_today,
        COALESCE(SUM(CASE WHEN received_at >= ? AND received_at < ? THEN total_units ELSE 0 END), 0) AS received_today
      FROM stock_transfers
      ''',
      variables: [
        drift.Variable.withDateTime(start),
        drift.Variable.withDateTime(end),
        drift.Variable.withDateTime(start),
        drift.Variable.withDateTime(end),
      ],
    ).getSingle();

    return StockTransferSummary(
      availableUnits: _readInt(available, 'units'),
      inTransitTransfers: _readInt(active, 'transfers'),
      inTransitUnits: _readInt(active, 'units'),
      transferredToday: _readInt(day, 'transferred_today'),
      receivedToday: _readInt(day, 'received_today'),
      inTransitNetWeight: _readDouble(active, 'net_weight'),
    );
  }

  Future<List<StockTransferUnit>> searchAvailableUnits({
    String query = '',
    String metal = 'All',
    int limit = 80,
  }) async {
    await ensureSchema();
    final clauses = <String>["LOWER(u.status) = 'available'"];
    final variables = <drift.Variable>[];

    final cleanMetal = metal.trim();
    if (cleanMetal.isNotEmpty && cleanMetal.toLowerCase() != 'all') {
      clauses.add('LOWER(u.metal_type) = LOWER(?)');
      variables.add(drift.Variable.withString(cleanMetal));
    }

    final cleanQuery = query.trim();
    if (cleanQuery.isNotEmpty) {
      final pattern = '%${cleanQuery.toLowerCase()}%';
      clauses.add('''
        (
          LOWER(u.unit_code) LIKE ?
          OR LOWER(COALESCE(u.huid, '')) LIKE ?
          OR LOWER(u.item_name) LIKE ?
          OR LOWER(COALESCE(u.item_type, '')) LIKE ?
          OR LOWER(COALESCE(u.batch_code, '')) LIKE ?
          OR LOWER(COALESCE(u.supplier_name, '')) LIKE ?
        )
      ''');
      for (var i = 0; i < 6; i++) {
        variables.add(drift.Variable.withString(pattern));
      }
    }

    variables.add(drift.Variable.withInt(limit));
    final rows = await _db.customSelect(
      '''
      SELECT
        u.id,
        u.stock_item_id,
        COALESCE(u.unit_code, '') AS unit_code,
        COALESCE(u.batch_code, '') AS batch_code,
        COALESCE(u.metal_type, '') AS metal_type,
        COALESCE(u.item_type, '') AS item_type,
        COALESCE(u.item_name, '') AS item_name,
        COALESCE(u.huid, '') AS huid,
        COALESCE(u.supplier_name, '') AS supplier_name,
        COALESCE(u.current_location, 'Main Showroom') AS current_location,
        COALESCE(u.gross_weight, 0.0) AS gross_weight,
        COALESCE(u.net_weight, 0.0) AS net_weight,
        COALESCE(u.actual_fine_weight, 0.0) AS fine_weight,
        COALESCE(u.purity_percent, 0.0) AS purity_percent,
        COALESCE(u.unit_cost, 0.0) AS unit_cost
      FROM stock_item_units u
      WHERE ${clauses.join(' AND ')}
      ORDER BY u.updated_at DESC, u.created_at DESC, u.id DESC
      LIMIT ?
      ''',
      variables: variables,
    ).get();

    return rows.map(_mapUnit).toList(growable: false);
  }

  Future<List<StockTransferRecord>> loadRecentTransfers(
      {int limit = 20}) async {
    await ensureSchema();
    final rows = await _db.customSelect(
      '''
      SELECT *
      FROM stock_transfers
      ORDER BY created_at DESC, id DESC
      LIMIT ?
      ''',
      variables: [drift.Variable.withInt(limit)],
    ).get();
    return rows.map(_mapTransfer).toList(growable: false);
  }

  Future<List<StockTransferLine>> loadTransferLines(int transferId) async {
    await ensureSchema();
    final rows = await _db.customSelect(
      '''
      SELECT *
      FROM stock_transfer_lines
      WHERE transfer_id = ?
      ORDER BY id
      ''',
      variables: [drift.Variable.withInt(transferId)],
    ).get();
    return rows.map(_mapLine).toList(growable: false);
  }

  Future<StockTransferCreated> createTransfer({
    required StockTransferForm form,
    required List<StockTransferUnit> units,
  }) async {
    await ensureSchema();
    _validateForm(form, units);

    final now = DateTime.now();
    final unitIds = units.map((unit) => unit.id).toSet().toList();
    final freshUnits = await _loadUnitsByIds(unitIds);
    if (freshUnits.length != unitIds.length) {
      throw StateError('Some selected stock units are no longer available.');
    }
    for (final unit in freshUnits) {
      final status = await _unitStatus(unit.id);
      if (status.toLowerCase() != StockStatus.available.label.toLowerCase()) {
        throw StateError('${unit.unitCode} is already $status.');
      }
    }

    final transferNo = await _nextTransferNo(now);
    final totalGross = freshUnits.fold<double>(
      0,
      (sum, unit) => sum + unit.grossWeight,
    );
    final totalNet = freshUnits.fold<double>(
      0,
      (sum, unit) => sum + unit.netWeight,
    );
    final totalFine = freshUnits.fold<double>(
      0,
      (sum, unit) => sum + unit.fineWeight,
    );

    await _db.transaction(() async {
      await _db.customStatement(
        '''
        INSERT INTO stock_transfers (
          transfer_no,
          from_location,
          to_location,
          transfer_type,
          status,
          carrier_name,
          authorized_by,
          expected_date,
          notes,
          total_units,
          total_gross_weight,
          total_net_weight,
          total_fine_weight,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          transferNo,
          form.fromLocation.trim(),
          form.toLocation.trim(),
          form.transferType.trim(),
          StockTransferStatus.inTransit,
          form.carrierName.trim(),
          form.authorizedBy.trim(),
          _dateVariable(form.expectedDate),
          form.notes.trim(),
          freshUnits.length,
          totalGross,
          totalNet,
          totalFine,
          now.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
        ],
      );

      final transferId = await _lastInsertId();
      for (final unit in freshUnits) {
        await _insertTransferLine(
          transferId: transferId,
          unit: unit,
          now: now,
        );
        await _moveUnitToInTransit(
          unit: unit,
          form: form,
          transferNo: transferNo,
          now: now,
        );
      }
      await _syncStockItems(freshUnits.map((unit) => unit.stockItemId).toSet());
    });

    return StockTransferCreated(
      transferNo: transferNo,
      unitCount: freshUnits.length,
    );
  }

  Future<void> receiveTransfer({
    required StockTransferRecord transfer,
    required String receivedBy,
  }) async {
    await ensureSchema();
    final cleanReceiver = receivedBy.trim();
    if (cleanReceiver.length < 2) {
      throw ArgumentError('Receiver name is required.');
    }
    final current = await _transferById(transfer.id);
    if (!current.isInTransit) {
      throw StateError('Only in-transit transfers can be received.');
    }
    final lines = await loadTransferLines(transfer.id);
    if (lines.isEmpty) {
      throw StateError('Transfer has no stock lines.');
    }

    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.customStatement(
        '''
        UPDATE stock_transfers
        SET status = ?, received_at = ?, updated_at = ?, notes = TRIM(COALESCE(notes, '') || ?)
        WHERE id = ?
        ''',
        [
          StockTransferStatus.received,
          now.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
          '\nReceived by: $cleanReceiver',
          transfer.id,
        ],
      );

      for (final line in lines) {
        await _db.customStatement(
          '''
          UPDATE stock_item_units
          SET status = ?, current_location = ?, updated_at = ?
          WHERE id = ?
          ''',
          [
            StockStatus.available.label,
            current.toLocation,
            now.millisecondsSinceEpoch,
            line.stockUnitId,
          ],
        );
        await _insertStatusEvent(
          stockUnitId: line.stockUnitId,
          stockItemId: line.stockItemId,
          unitCode: line.unitCode,
          huid: line.huid,
          batchCode: '',
          previousStatus: StockStatus.transferred.label,
          newStatus: StockStatus.available.label,
          sourceNumber: current.transferNo,
          reason: 'Received at ${current.toLocation} by $cleanReceiver',
          now: now,
        );
        await _insertMovement(
          unit: _unitFromLine(line, current.toLocation),
          movementType: 'TRANSFER_IN',
          sourceNumber: current.transferNo,
          quantityDelta: 1,
          reason: 'Received transfer at ${current.toLocation}',
          now: now,
        );
      }
      await _syncStockItems(lines.map((line) => line.stockItemId).toSet());
    });
  }

  Future<void> cancelTransfer({
    required StockTransferRecord transfer,
    required String reason,
  }) async {
    await ensureSchema();
    final cleanReason = reason.trim();
    if (cleanReason.length < 3) {
      throw ArgumentError('Cancel reason is required.');
    }
    final current = await _transferById(transfer.id);
    if (!current.isInTransit) {
      throw StateError('Only in-transit transfers can be cancelled.');
    }
    final lines = await loadTransferLines(transfer.id);
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.customStatement(
        '''
        UPDATE stock_transfers
        SET status = ?, cancelled_at = ?, updated_at = ?, notes = TRIM(COALESCE(notes, '') || ?)
        WHERE id = ?
        ''',
        [
          StockTransferStatus.cancelled,
          now.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
          '\nCancelled: $cleanReason',
          transfer.id,
        ],
      );

      for (final line in lines) {
        await _db.customStatement(
          '''
          UPDATE stock_item_units
          SET status = ?, current_location = ?, updated_at = ?
          WHERE id = ?
          ''',
          [
            StockStatus.available.label,
            current.fromLocation,
            now.millisecondsSinceEpoch,
            line.stockUnitId,
          ],
        );
        await _insertStatusEvent(
          stockUnitId: line.stockUnitId,
          stockItemId: line.stockItemId,
          unitCode: line.unitCode,
          huid: line.huid,
          batchCode: '',
          previousStatus: StockStatus.transferred.label,
          newStatus: StockStatus.available.label,
          sourceNumber: current.transferNo,
          reason: 'Transfer cancelled: $cleanReason',
          now: now,
        );
        await _insertMovement(
          unit: _unitFromLine(line, current.fromLocation),
          movementType: 'TRANSFER_CANCEL',
          sourceNumber: current.transferNo,
          quantityDelta: 1,
          reason: cleanReason,
          now: now,
        );
      }
      await _syncStockItems(lines.map((line) => line.stockItemId).toSet());
    });
  }

  Future<void> _ensureStockUnitLocationColumn() async {
    final columns = await _db
        .customSelect(
          "PRAGMA table_info('stock_item_units')",
        )
        .get();
    final names = columns
        .map((row) => (row.data['name'] as String?)?.toLowerCase())
        .whereType<String>()
        .toSet();
    if (!names.contains('current_location')) {
      await _db.customStatement(
        'ALTER TABLE stock_item_units ADD COLUMN current_location TEXT',
      );
    }
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_location" ON "stock_item_units" ("current_location")',
    );
  }

  Future<List<StockTransferUnit>> _loadUnitsByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.customSelect(
      '''
      SELECT
        id,
        stock_item_id,
        COALESCE(unit_code, '') AS unit_code,
        COALESCE(batch_code, '') AS batch_code,
        COALESCE(metal_type, '') AS metal_type,
        COALESCE(item_type, '') AS item_type,
        COALESCE(item_name, '') AS item_name,
        COALESCE(huid, '') AS huid,
        COALESCE(supplier_name, '') AS supplier_name,
        COALESCE(current_location, 'Main Showroom') AS current_location,
        COALESCE(gross_weight, 0.0) AS gross_weight,
        COALESCE(net_weight, 0.0) AS net_weight,
        COALESCE(actual_fine_weight, 0.0) AS fine_weight,
        COALESCE(purity_percent, 0.0) AS purity_percent,
        COALESCE(unit_cost, 0.0) AS unit_cost
      FROM stock_item_units
      WHERE id IN ($placeholders)
      ''',
      variables: ids.map(drift.Variable.withInt).toList(),
    ).get();
    return rows.map(_mapUnit).toList(growable: false);
  }

  Future<String> _unitStatus(int unitId) async {
    final row = await _db.customSelect(
      'SELECT COALESCE(status, "") AS status FROM stock_item_units WHERE id = ?',
      variables: [drift.Variable.withInt(unitId)],
    ).getSingleOrNull();
    return (row?.data['status'] as String?)?.trim() ?? '';
  }

  Future<String> _nextTransferNo(DateTime now) async {
    final day = DateFormat('yyyyMMdd').format(now);
    final prefix = 'ST-$day-';
    final row = await _db.customSelect(
      '''
      SELECT transfer_no
      FROM stock_transfers
      WHERE transfer_no LIKE ?
      ORDER BY transfer_no DESC
      LIMIT 1
      ''',
      variables: [drift.Variable.withString('$prefix%')],
    ).getSingleOrNull();
    final last = (row?.data['transfer_no'] as String?) ?? '';
    final lastNo = int.tryParse(last.split('-').last) ?? 0;
    return '$prefix${(lastNo + 1).toString().padLeft(3, '0')}';
  }

  Future<int> _lastInsertId() async {
    final row =
        await _db.customSelect('SELECT last_insert_rowid() AS id').getSingle();
    return _readInt(row, 'id');
  }

  Future<StockTransferRecord> _transferById(int id) async {
    final row = await _db.customSelect(
      'SELECT * FROM stock_transfers WHERE id = ?',
      variables: [drift.Variable.withInt(id)],
    ).getSingleOrNull();
    if (row == null) throw StateError('Transfer record was not found.');
    return _mapTransfer(row);
  }

  Future<void> _insertTransferLine({
    required int transferId,
    required StockTransferUnit unit,
    required DateTime now,
  }) {
    return _db.customStatement(
      '''
      INSERT INTO stock_transfer_lines (
        transfer_id,
        stock_unit_id,
        stock_item_id,
        unit_code,
        huid,
        item_name,
        metal_type,
        gross_weight,
        net_weight,
        fine_weight,
        unit_cost,
        from_status,
        to_status,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        transferId,
        unit.id,
        unit.stockItemId,
        unit.unitCode,
        unit.huid,
        unit.itemName,
        unit.metalType,
        unit.grossWeight,
        unit.netWeight,
        unit.fineWeight,
        unit.unitCost,
        StockStatus.available.label,
        StockStatus.transferred.label,
        now.millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> _moveUnitToInTransit({
    required StockTransferUnit unit,
    required StockTransferForm form,
    required String transferNo,
    required DateTime now,
  }) async {
    await _db.customStatement(
      '''
      UPDATE stock_item_units
      SET status = ?, current_location = ?, updated_at = ?
      WHERE id = ? AND LOWER(status) = 'available'
      ''',
      [
        StockStatus.transferred.label,
        'In Transit: ${form.toLocation.trim()}',
        now.millisecondsSinceEpoch,
        unit.id,
      ],
    );
    await _insertStatusEvent(
      stockUnitId: unit.id,
      stockItemId: unit.stockItemId,
      unitCode: unit.unitCode,
      huid: unit.huid,
      batchCode: unit.batchCode,
      previousStatus: StockStatus.available.label,
      newStatus: StockStatus.transferred.label,
      sourceNumber: transferNo,
      reason: '${form.fromLocation.trim()} to ${form.toLocation.trim()}',
      now: now,
    );
    await _insertMovement(
      unit: unit,
      movementType: 'TRANSFER_OUT',
      sourceNumber: transferNo,
      quantityDelta: -1,
      reason:
          '${form.transferType.trim()} transfer to ${form.toLocation.trim()}',
      now: now,
    );
  }

  Future<void> _insertStatusEvent({
    required int stockUnitId,
    required int stockItemId,
    required String unitCode,
    required String huid,
    required String batchCode,
    required String previousStatus,
    required String newStatus,
    required String sourceNumber,
    required String reason,
    required DateTime now,
  }) {
    return _db.customStatement(
      '''
      INSERT INTO stock_unit_status_events (
        stock_unit_id,
        stock_item_id,
        unit_code,
        huid,
        batch_code,
        previous_status,
        new_status,
        reason,
        source_type,
        source_number,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockUnitId,
        stockItemId,
        unitCode,
        huid,
        batchCode,
        previousStatus,
        newStatus,
        reason,
        'STOCK_TRANSFER',
        sourceNumber,
        now.millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> _insertMovement({
    required StockTransferUnit unit,
    required String movementType,
    required String sourceNumber,
    required int quantityDelta,
    required String reason,
    required DateTime now,
  }) {
    final sign = quantityDelta < 0 ? -1.0 : 1.0;
    return _db.customStatement(
      '''
      INSERT INTO stock_movements (
        stock_item_id,
        movement_type,
        source_type,
        source_id,
        source_number,
        sku_snapshot,
        metal_type_snapshot,
        item_name_snapshot,
        quantity_delta,
        gross_weight_delta,
        net_weight_delta,
        fine_weight_delta,
        reason,
        occurred_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        unit.stockItemId,
        movementType,
        'STOCK_TRANSFER',
        unit.id.toString(),
        sourceNumber,
        unit.unitCode,
        unit.metalType,
        unit.itemName,
        quantityDelta,
        unit.grossWeight * sign,
        unit.netWeight * sign,
        unit.fineWeight * sign,
        reason,
        now.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> _syncStockItems(Set<int> stockItemIds) async {
    for (final stockItemId in stockItemIds.where((id) => id > 0)) {
      await _db.customStatement(
        '''
        UPDATE stock_items
        SET
          quantity = (
            SELECT COUNT(*)
            FROM stock_item_units
            WHERE stock_item_id = ? AND LOWER(status) = 'available'
          ),
          status = CASE
            WHEN (
              SELECT COUNT(*)
              FROM stock_item_units
              WHERE stock_item_id = ? AND LOWER(status) = 'available'
            ) > 0 THEN ?
            ELSE ?
          END,
          updated_at = ?
        WHERE id = ?
        ''',
        [
          stockItemId,
          stockItemId,
          StockStatus.available.label,
          StockStatus.transferred.label,
          DateTime.now().millisecondsSinceEpoch,
          stockItemId,
        ],
      );
    }
  }

  void _validateForm(StockTransferForm form, List<StockTransferUnit> units) {
    if (units.isEmpty) throw ArgumentError('Select at least one stock unit.');
    if (form.fromLocation.trim().length < 2) {
      throw ArgumentError('From location is required.');
    }
    if (form.toLocation.trim().length < 2) {
      throw ArgumentError('To location is required.');
    }
    if (form.fromLocation.trim().toLowerCase() ==
        form.toLocation.trim().toLowerCase()) {
      throw ArgumentError('From and To locations cannot be the same.');
    }
    if (form.transferType.trim().isEmpty) {
      throw ArgumentError('Transfer type is required.');
    }
    if (form.authorizedBy.trim().length < 2) {
      throw ArgumentError('Authorized by is required.');
    }
  }

  StockTransferUnit _mapUnit(drift.QueryRow row) {
    return StockTransferUnit(
      id: _readInt(row, 'id'),
      stockItemId: _readInt(row, 'stock_item_id'),
      unitCode: _readString(row, 'unit_code'),
      batchCode: _readString(row, 'batch_code'),
      metalType: _readString(row, 'metal_type'),
      itemType: _readString(row, 'item_type'),
      itemName: _readString(row, 'item_name'),
      huid: _readString(row, 'huid'),
      supplierName: _readString(row, 'supplier_name'),
      currentLocation: _readString(row, 'current_location'),
      grossWeight: _readDouble(row, 'gross_weight'),
      netWeight: _readDouble(row, 'net_weight'),
      fineWeight: _readDouble(row, 'fine_weight'),
      purityPercent: _readDouble(row, 'purity_percent'),
      unitCost: _readDouble(row, 'unit_cost'),
    );
  }

  StockTransferRecord _mapTransfer(drift.QueryRow row) {
    return StockTransferRecord(
      id: _readInt(row, 'id'),
      transferNo: _readString(row, 'transfer_no'),
      fromLocation: _readString(row, 'from_location'),
      toLocation: _readString(row, 'to_location'),
      transferType: _readString(row, 'transfer_type'),
      status: _readString(row, 'status'),
      carrierName: _readString(row, 'carrier_name'),
      authorizedBy: _readString(row, 'authorized_by'),
      notes: _readString(row, 'notes'),
      totalUnits: _readInt(row, 'total_units'),
      totalGrossWeight: _readDouble(row, 'total_gross_weight'),
      totalNetWeight: _readDouble(row, 'total_net_weight'),
      totalFineWeight: _readDouble(row, 'total_fine_weight'),
      createdAt: _readDate(row, 'created_at') ?? DateTime(1970),
      expectedDate: _readDate(row, 'expected_date'),
      receivedAt: _readDate(row, 'received_at'),
      cancelledAt: _readDate(row, 'cancelled_at'),
    );
  }

  StockTransferLine _mapLine(drift.QueryRow row) {
    return StockTransferLine(
      id: _readInt(row, 'id'),
      transferId: _readInt(row, 'transfer_id'),
      stockUnitId: _readInt(row, 'stock_unit_id'),
      stockItemId: _readInt(row, 'stock_item_id'),
      unitCode: _readString(row, 'unit_code'),
      huid: _readString(row, 'huid'),
      itemName: _readString(row, 'item_name'),
      metalType: _readString(row, 'metal_type'),
      grossWeight: _readDouble(row, 'gross_weight'),
      netWeight: _readDouble(row, 'net_weight'),
      fineWeight: _readDouble(row, 'fine_weight'),
      unitCost: _readDouble(row, 'unit_cost'),
    );
  }

  StockTransferUnit _unitFromLine(
    StockTransferLine line,
    String currentLocation,
  ) {
    return StockTransferUnit(
      id: line.stockUnitId,
      stockItemId: line.stockItemId,
      unitCode: line.unitCode,
      batchCode: '',
      metalType: line.metalType,
      itemType: '',
      itemName: line.itemName,
      huid: line.huid,
      supplierName: '',
      currentLocation: currentLocation,
      grossWeight: line.grossWeight,
      netWeight: line.netWeight,
      fineWeight: line.fineWeight,
      purityPercent: 0,
      unitCost: line.unitCost,
    );
  }

  int _dateVariable(DateTime? value) {
    return value?.millisecondsSinceEpoch ?? 0;
  }

  int _readInt(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toInt() : 0;
  }

  double _readDouble(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toDouble() : 0;
  }

  String _readString(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is String ? value.trim() : '';
  }

  DateTime? _readDate(drift.QueryRow row, String column) {
    final value = row.data[column];
    if (value is DateTime) return value;
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
