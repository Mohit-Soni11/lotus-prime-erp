import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DayBookCloseAuthorization {
  DayBookCloseAuthorization({
    String? Function()? currentUid,
    Future<Map<String, dynamic>?> Function(String uid)? loadProfile,
  })  : _currentUid =
            currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
        _loadProfile = loadProfile ??
            ((uid) async => (await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get())
                .data());

  final String? Function() _currentUid;
  final Future<Map<String, dynamic>?> Function(String uid) _loadProfile;

  Future<String> authorizedActorId({String action = 'close the day'}) async {
    final uid = _currentUid()?.trim();
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in before you $action.');
    }
    final profile = await _loadProfile(uid);
    if (profile == null || profile['isActive'] == false) {
      throw StateError('Your account is not active for this action.');
    }
    final role = (profile['role'] as String? ?? '').trim().toUpperCase();
    if (role != 'OWNER' && role != 'MANAGER') {
      throw StateError('Owner or manager access is required to $action.');
    }
    return uid;
  }
}
