import 'package:shared_preferences/shared_preferences.dart';

/// Keeps one local business database associated with one verified owner account.
class InstallationAccountBinding {
  static const _ownerUidKey = 'lotus_erp_installation_owner_uid';

  Future<bool> canCreateOwner() async {
    final preferences = await SharedPreferences.getInstance();
    final ownerUid = preferences.getString(_ownerUidKey);
    return ownerUid == null || ownerUid.isEmpty;
  }

  Future<bool> claimOrVerify(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final ownerUid = preferences.getString(_ownerUidKey);
    if (ownerUid != null && ownerUid.isNotEmpty) return ownerUid == uid;
    return preferences.setString(_ownerUidKey, uid);
  }
}
