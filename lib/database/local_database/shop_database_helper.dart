import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/logging/app_logger.dart';
import 'shop_database_schema.dart';

/// Data access for the Shop Profile master configuration.
class ShopDatabaseHelper {
  static final ShopDatabaseHelper _instance = ShopDatabaseHelper._internal();
  static Database? _database;

  final Database? _databaseOverride;

  static const int _dbVersion = ShopDatabaseSchema.currentVersion;

  factory ShopDatabaseHelper() => _instance;

  ShopDatabaseHelper._internal() : _databaseOverride = null;

  /// Creates an isolated helper for migration and persistence tests.
  ShopDatabaseHelper.forTesting(Database database)
      : _databaseOverride = database;

  Future<Database> get database async {
    if (_databaseOverride != null) return _databaseOverride;
    if (_database != null) return _database!;

    _database = await _initDB('erp_master_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, filePath);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: ShopDatabaseSchema.configure,
      onCreate: ShopDatabaseSchema.create,
      onUpgrade: ShopDatabaseSchema.upgrade,
    );
  }

  /// Saves all Shop Profile sections in one transaction.
  Future<bool> upsertMasterPayload(Map<String, dynamic> payload) async {
    final db = await database;
    final tenantId = payload['tenant_id']?.toString();
    if (tenantId == null || tenantId.isEmpty) {
      AppLogger.error('[SHOP PROFILE DB] Missing tenant ID in master payload.');
      return false;
    }

    try {
      await db.transaction((transaction) async {
        await transaction.insert(
          'shop_profile',
          {...payload['basic_info'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await transaction.insert(
          'shop_address',
          {...payload['address'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await transaction.insert(
          'shop_tax_gst',
          {...payload['tax_compliance'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await transaction.insert(
          'shop_branding',
          {...payload['branding_social'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await transaction.update(
          'shop_bank_accounts',
          {'is_active': 0},
          where: 'tenant_id = ?',
          whereArgs: [tenantId],
        );

        final bankingList = payload['banking_details'] as List<dynamic>? ?? [];
        for (final bank in bankingList) {
          await transaction.insert(
            'shop_bank_accounts',
            {
              ...Map<String, dynamic>.from(bank as Map),
              'tenant_id': tenantId,
              'is_active': 1
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      AppLogger.debug(
        '[SHOP PROFILE DB] Master payload saved for tenant $tenantId.',
      );
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('[SHOP PROFILE DB] Transaction failed: $error');
      AppLogger.debug(stackTrace.toString());
      return false;
    }
  }

  /// Returns the complete saved Shop Profile, or null when setup has not run.
  Future<Map<String, dynamic>?> getMasterPayload(String tenantId) async {
    final db = await database;

    final basicInfo = await db.query(
      'shop_profile',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
    if (basicInfo.isEmpty) return null;

    final address = await db.query(
      'shop_address',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
    final tax = await db.query(
      'shop_tax_gst',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
    final branding = await db.query(
      'shop_branding',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
    final banks = await db.query(
      'shop_bank_accounts',
      where: 'tenant_id = ? AND is_active = 1',
      whereArgs: [tenantId],
    );

    return <String, dynamic>{
      'tenant_id': tenantId,
      'basic_info': basicInfo.first,
      'address': address.isNotEmpty ? address.first : <String, dynamic>{},
      'tax_compliance': tax.isNotEmpty ? tax.first : <String, dynamic>{},
      'branding_social':
          branding.isNotEmpty ? branding.first : <String, dynamic>{},
      'banking_details': banks,
    };
  }
}
