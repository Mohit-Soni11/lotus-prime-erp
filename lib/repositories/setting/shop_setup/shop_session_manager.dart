// -----------------------------------------------------------------------------
// FILE: shop_session_manager.dart
// TYPE: Core / Session Management
// AUTHOR: Senior System Architect
// DESCRIPTION: Manages the permanent Tenant ID for the shop setup.
//              Ensures data is updated (Upsert) instead of creating new rows.
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ShopSessionManager {
  // Storage key
  static const String _tenantKey = 'lotus_erp_permanent_tenant_id';
  static const Uuid _uuidGenerator = Uuid();

  /// Gets the existing Tenant ID or generates a new one if it's the first time.
  static Future<String> getPermanentTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Check if ID already exists in local storage
    String? existingId = prefs.getString(_tenantKey);
    
    if (existingId != null && existingId.isNotEmpty) {
      return existingId; // Return the saved permanent ID
    } 
    
    // 2. First time setup: Generate and permanently save
    final String newId = "SHOP_${_uuidGenerator.v4()}";
    await prefs.setString(_tenantKey, newId);
    
    return newId;
  }
}