import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_setup_repository.dart';

class ShopPrintInformationRepository {
  static const String _preferencePrefix =
      'billing_setup.shop_print_information.enabled_fields';

  final Future<Map<String, dynamic>?> Function(String tenantId)
      _shopSetupLoader;
  final AppDatabase _db;

  ShopPrintInformationRepository({
    ShopSetupRepository? shopSetupRepository,
    Future<Map<String, dynamic>?> Function(String tenantId)? shopSetupLoader,
    AppDatabase? db,
  })  : _shopSetupLoader = shopSetupLoader ??
            (shopSetupRepository ?? ShopSetupRepository()).fetchExistingSetup,
        _db = db ?? AppDatabase();

  Future<ShopPrintInformationState> load() async {
    final result = await _loadStateAndPayload();
    return result.state;
  }

  Future<ShopPrintDocumentProfile> loadDocumentProfile() async {
    final result = await _loadStateAndPayload();
    return ShopPrintDocumentProfile.fromState(result.state, result.payload);
  }

  Future<_ShopPrintLoadResult> _loadStateAndPayload() async {
    final tenantId = await ShopSessionManager.getPermanentTenantId();
    final payload = await _shopSetupLoader(tenantId);
    final fields = ShopPrintInformationCatalog.fromPayload(payload);
    final enabledIds = await _loadEnabledFieldIds(
      tenantId: tenantId,
      fields: fields,
    );

    return _ShopPrintLoadResult(
      payload: payload,
      state: ShopPrintInformationState(
        tenantId: tenantId,
        fields: fields,
        enabledFieldIds: enabledIds,
      ),
    );
  }

  Future<void> save(ShopPrintInformationState state) async {
    await _saveEnabledFieldIds(
      tenantId: state.tenantId,
      configuredIds: state.configuredFieldIds,
      enabledFieldIds: state.enabledFieldIds,
    );
  }

  Future<Set<String>> _loadEnabledFieldIds({
    required String tenantId,
    required List<ShopPrintField> fields,
  }) async {
    await _db.ensureBillingSetupSchema();

    final existing = await (_db.select(_db.shopPrintInformationSettings)
          ..where((tbl) => tbl.tenantId.equals(tenantId))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      return _resolveEnabledIds(
        fields,
        _decodeEnabledFieldIds(existing.enabledFieldIdsJson),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final legacySaved = prefs.getStringList(_keyFor(tenantId));
    final enabledIds = _resolveEnabledIds(fields, legacySaved);
    await _saveEnabledFieldIds(
      tenantId: tenantId,
      configuredIds: {
        for (final field in fields)
          if (field.isConfigured) field.id,
      },
      enabledFieldIds: enabledIds,
    );
    return enabledIds;
  }

  Future<void> _saveEnabledFieldIds({
    required String tenantId,
    required Set<String> configuredIds,
    required Set<String> enabledFieldIds,
  }) async {
    await _db.ensureBillingSetupSchema();

    final enabledIds = enabledFieldIds
        .where(configuredIds.contains)
        .toList(growable: false)
      ..sort();
    final payload = jsonEncode(enabledIds);
    final existing = await (_db.select(_db.shopPrintInformationSettings)
          ..where((tbl) => tbl.tenantId.equals(tenantId))
          ..limit(1))
        .getSingleOrNull();
    final companion = ShopPrintInformationSettingsCompanion(
      tenantId: Value(tenantId),
      enabledFieldIdsJson: Value(payload),
      updatedAt: Value(DateTime.now()),
    );

    if (existing == null) {
      await _db.into(_db.shopPrintInformationSettings).insert(companion);
      return;
    }

    await (_db.update(_db.shopPrintInformationSettings)
          ..where((tbl) => tbl.id.equals(existing.id)))
        .write(companion);
  }

  List<String>? _decodeEnabledFieldIds(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is List) {
        return decoded.map((value) => value.toString()).toList();
      }
    } catch (_) {}
    return null;
  }

  Set<String> _resolveEnabledIds(
    List<ShopPrintField> fields,
    List<String>? saved,
  ) {
    final configuredIds = {
      for (final field in fields)
        if (field.isConfigured) field.id,
    };

    if (saved == null) {
      return fields
          .where((field) => field.defaultEnabled && field.isConfigured)
          .map((field) => field.id)
          .toSet();
    }

    return saved.where(configuredIds.contains).toSet();
  }

  String _keyFor(String tenantId) => '$_preferencePrefix.$tenantId.v1';
}

class _ShopPrintLoadResult {
  final Map<String, dynamic>? payload;
  final ShopPrintInformationState state;

  const _ShopPrintLoadResult({
    required this.payload,
    required this.state,
  });
}
