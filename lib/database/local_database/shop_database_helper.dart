import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';
import '../../core/storage/app_storage_paths.dart';
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
    final databaseDirectory = await AppStoragePaths.shopDatabaseDirectory();
    final path = join(databaseDirectory.path, filePath);

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
    return db.transaction((transaction) async {
      final basicInfo = await transaction.query(
        'shop_profile',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );
      if (basicInfo.isEmpty) return null;

      final address = await transaction.query(
        'shop_address',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );
      final tax = await transaction.query(
        'shop_tax_gst',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );
      final branding = await transaction.query(
        'shop_branding',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );
      final banks = await transaction.query(
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
    });
  }

  Future<Map<String, int>> financeAccountLinksForTenant(String tenantId) async {
    final db = await database;
    final rows = await db.query(
      'shop_profile_finance_account_links',
      columns: const ['shop_bank_account_id', 'finance_bank_account_id'],
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
    return {
      for (final row in rows)
        row['shop_bank_account_id']!.toString():
            row['finance_bank_account_id'] as int,
    };
  }

  /// Supports a restored database when platform preferences were reset.
  Future<String?> firstPersistedTenantId() async {
    final db = await database;
    final rows = await db.query(
      'shop_profile',
      columns: const ['tenant_id'],
      orderBy: 'tenant_id ASC',
      limit: 1,
    );
    final tenantId = rows.isEmpty ? null : rows.first['tenant_id']?.toString();
    return tenantId == null || tenantId.isEmpty ? null : tenantId;
  }

  Future<void> replaceFinanceAccountLinks({
    required String tenantId,
    required Map<String, int> links,
  }) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'shop_profile_finance_account_links',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );
      for (final entry in links.entries) {
        await transaction.insert('shop_profile_finance_account_links', {
          'tenant_id': tenantId,
          'shop_bank_account_id': entry.key,
          'finance_bank_account_id': entry.value,
        });
      }
    });
  }
}
