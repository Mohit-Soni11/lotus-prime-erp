import 'package:sqflite/sqflite.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';

/// Defines the isolated Shop Profile database schema and upgrades.
///
/// Keeping this outside the repository helper allows the production migration
/// path to be tested without opening or altering an operator's local database.
class ShopDatabaseSchema {
  ShopDatabaseSchema._();

  static const int currentVersion = 6;

  static Future<void> configure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> create(Database db, int version) async {
    AppLogger.debug('[SHOP PROFILE DB] Creating schema v$currentVersion.');

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

    await db.execute('''
      CREATE TABLE shop_address (
        tenant_id TEXT PRIMARY KEY,
        type TEXT, addr1 TEXT, addr2 TEXT, city TEXT,
        state TEXT, pincode TEXT, country TEXT,
        latitude REAL, longitude REAL,
        FOREIGN KEY (tenant_id) REFERENCES shop_profile (tenant_id) ON DELETE CASCADE
      )
    ''');

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

    await db.execute('''
      CREATE TABLE shop_branding (
        tenant_id TEXT PRIMARY KEY,
        instagram TEXT, facebook TEXT, youtube TEXT, website TEXT,
        whatsapp_channel TEXT, whatsapp_business TEXT, support_email TEXT, support_phone TEXT,
        FOREIGN KEY (tenant_id) REFERENCES shop_profile (tenant_id) ON DELETE CASCADE
      )
    ''');

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
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    AppLogger.debug(
      '[SHOP PROFILE DB] Upgrading from v$oldVersion to v$newVersion.',
    );

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

  static Future<void> _addColumnIfMissing(
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
}
