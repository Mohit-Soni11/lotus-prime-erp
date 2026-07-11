// -----------------------------------------------------------------------------
// FILE: shop_database_helper.dart
// TYPE: Local Database / Data Layer
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 UPGRADED: Fixed CamelCase vs Snake_Case mismatch.
//              Added Auto-Update Engine (Migration) for future updates.
// -----------------------------------------------------------------------------

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/logging/app_logger.dart';

class ShopDatabaseHelper {
  static final ShopDatabaseHelper _instance = ShopDatabaseHelper._internal();
  static Database? _database;

  // 🚀 AUTO-UPDATE ENGINE: Future mein naya column add karna ho, toh ise '3' kar dena
  static const int _dbVersion = 6;

  factory ShopDatabaseHelper() => _instance;

  ShopDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('erp_master_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _onUpgrade, // 🚀 Ye automatically handle karega future updates
    );
  }

  // --- 1. SCHEMA CREATION (Normalized Tables with EXACT Snake_Case Match) ---
  Future<void> _createSchema(Database db, int version) async {
    AppLogger.debug(
        "🚀 [DB] Creating Enterprise Normalized Schema (v$_dbVersion)...");

    // Table 1: Basic Info (Names strictly matched with payload)
    await db.execute('''
      CREATE TABLE shop_profile (
        tenant_id TEXT PRIMARY KEY,
        legal_name TEXT, display_name TEXT, tagline TEXT,
        owner_name TEXT, owner_phone TEXT, owner_whatsapp TEXT,
        est_year TEXT, branch_code TEXT, open_time TEXT, close_time TEXT,
        weekly_off TEXT, brand_display_name TEXT, business_email TEXT,
        shop_phone TEXT, shop_whatsapp TEXT,
        logo_path TEXT, logo_shape TEXT DEFAULT 'circle',
        signature_path TEXT, signature_shape TEXT DEFAULT 'square'
      )
    ''');

    // Table 2: Address Details
    await db.execute('''
      CREATE TABLE shop_address (
        tenant_id TEXT PRIMARY KEY,
        type TEXT, addr1 TEXT, addr2 TEXT, city TEXT,
        state TEXT, pincode TEXT, country TEXT,
        latitude REAL, longitude REAL,
        FOREIGN KEY (tenant_id) REFERENCES shop_profile (tenant_id) ON DELETE CASCADE
      )
    ''');

    // Table 3: Tax & GST Compliance (Names explicitly fixed)
    await db.execute('''
      CREATE TABLE shop_tax_gst (
        tenant_id TEXT PRIMARY KEY,
        gstin TEXT, legal_name TEXT, reg_date TEXT, taxpayer_type TEXT,
        bis_license_no TEXT, gold_bis_license_no TEXT, silver_bis_license_no TEXT,
        hallmarking_scope TEXT DEFAULT 'Gold & Silver',
        bis_registration_mode TEXT DEFAULT 'Single Registration',
        bis_valid_from TEXT, bis_valid_upto TEXT,
        gst_cert_path TEXT, bis_license_path TEXT,
        FOREIGN KEY (tenant_id) REFERENCES shop_profile (tenant_id) ON DELETE CASCADE
      )
    ''');

    // Table 4: Branding & Social (Names explicitly fixed)
    await db.execute('''
      CREATE TABLE shop_branding (
        tenant_id TEXT PRIMARY KEY,
        instagram TEXT, facebook TEXT, youtube TEXT, website TEXT,
        whatsapp_channel TEXT, whatsapp_business TEXT, support_email TEXT, support_phone TEXT,
        FOREIGN KEY (tenant_id) REFERENCES shop_profile (tenant_id) ON DELETE CASCADE
      )
    ''');

    // Table 5: Bank Accounts (Names explicitly fixed)
    await db.execute('''
      CREATE TABLE shop_bank_accounts (
        id TEXT PRIMARY KEY,
        tenant_id TEXT,
        title TEXT, holder TEXT, bank TEXT, type TEXT,
        acc TEXT, ifsc TEXT, branch TEXT, upi TEXT, qr_image_path TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (tenant_id) REFERENCES shop_profile (tenant_id) ON DELETE CASCADE
      )
    ''');

    AppLogger.debug("✅ [DB] Schema Created Successfully.");
  }

  // --- 🚀 AUTO-UPDATE LOGIC (MIGRATIONS) ---
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.debug(
        "🔄 [DB] Upgrading database from v$oldVersion to v$newVersion...");
    if (oldVersion < 3) {
      await _addColumnIfMissing(
        db,
        'shop_profile',
        'logo_shape',
        "TEXT DEFAULT 'circle'",
      );
      await _addColumnIfMissing(
        db,
        'shop_profile',
        'signature_shape',
        "TEXT DEFAULT 'square'",
      );
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(
        db,
        'shop_tax_gst',
        'gold_bis_license_no',
        'TEXT',
      );
      await _addColumnIfMissing(
        db,
        'shop_tax_gst',
        'silver_bis_license_no',
        'TEXT',
      );
    }
    if (oldVersion < 5) {
      await _addColumnIfMissing(
        db,
        'shop_tax_gst',
        'hallmarking_scope',
        "TEXT DEFAULT 'Gold & Silver'",
      );
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        'shop_tax_gst',
        'bis_registration_mode',
        "TEXT DEFAULT 'Single Registration'",
      );
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String declaration,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $declaration');
    }
  }

  // --- 2. MASTER UPSERT ENGINE (Atomic Transaction) ---
  Future<bool> upsertMasterPayload(Map<String, dynamic> payload) async {
    final db = await database;
    final String tenantId = payload['tenant_id'];

    try {
      await db.transaction((txn) async {
        // 1. Upsert Basic Info
        await txn.insert(
          'shop_profile',
          {...payload['basic_info'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 2. Upsert Address
        await txn.insert(
          'shop_address',
          {...payload['address'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 3. Upsert Tax & GST
        await txn.insert(
          'shop_tax_gst',
          {...payload['tax_compliance'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 4. Upsert Branding
        await txn.insert(
          'shop_branding',
          {...payload['branding_social'], 'tenant_id': tenantId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 5. Upsert Banking (Soft Delete Logic)
        await txn.update(
          'shop_bank_accounts',
          {'is_active': 0},
          where: 'tenant_id = ?',
          whereArgs: [tenantId],
        );

        List<dynamic> bankingList = payload['banking_details'] ?? [];
        for (var bank in bankingList) {
          await txn.insert(
            'shop_bank_accounts',
            {...bank, 'tenant_id': tenantId, 'is_active': 1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      AppLogger.debug(
          "🚀 [DB] Master Payload Saved Successfully for Tenant: $tenantId");
      return true;
    } catch (e, stacktrace) {
      AppLogger.error("❌ [DB TRANSACTION ERROR]: $e");
      AppLogger.debug(stacktrace.toString());
      return false;
    }
  }

  // --- 3. FETCH CONFIGURATION ---
  Future<Map<String, dynamic>?> getMasterPayload(String tenantId) async {
    final db = await database;

    final basicInfo = await db
        .query('shop_profile', where: 'tenant_id = ?', whereArgs: [tenantId]);
    if (basicInfo.isEmpty) return null;

    final address = await db
        .query('shop_address', where: 'tenant_id = ?', whereArgs: [tenantId]);
    final tax = await db
        .query('shop_tax_gst', where: 'tenant_id = ?', whereArgs: [tenantId]);
    final branding = await db
        .query('shop_branding', where: 'tenant_id = ?', whereArgs: [tenantId]);

    final banks = await db.query('shop_bank_accounts',
        where: 'tenant_id = ? AND is_active = 1', whereArgs: [tenantId]);

    return {
      "tenant_id": tenantId,
      "basic_info": basicInfo.first,
      "address": address.isNotEmpty ? address.first : {},
      "tax_compliance": tax.isNotEmpty ? tax.first : {},
      "branding_social": branding.isNotEmpty ? branding.first : {},
      "banking_details": banks,
    };
  }
}
