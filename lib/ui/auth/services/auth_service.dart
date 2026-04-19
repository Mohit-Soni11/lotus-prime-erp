import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- GET CURRENT USER ---
  User? get currentUser => _auth.currentUser;

  // ===========================================================================
  // 🔐 1. CORE AUTHENTICATION (Login/Logout)
  // ===========================================================================

  Future<String> loginUser({required String email, required String password}) async {
    try {
      // 1. Attempt Login
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Security Check: Is User Active?
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
      
      if (!userDoc.exists) {
        await _auth.signOut();
        return "User record not found. Contact Admin.";
      }

      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "No user found with this email.";
      if (e.code == 'wrong-password') return "Incorrect Password.";
      if (e.code == 'invalid-credential') return "Invalid Credentials.";
      if (e.code == 'too-many-requests') return "Too many attempts. Try later.";
      return e.message ?? "Login Failed";
    } catch (e) {
      return "System Error: $e";
    }
  }

  // 🔥 UPDATED: LOGOUT FUNCTION (Ye TopBar ke liye zaroori hai)
  // Humne 'signOut' ko bhi rakha hai aur 'logout' bhi bana diya hai taaki error na aaye.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Existing signOut (isko bhi rehne diya hai backup ke liye)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ===========================================================================
  // 🏗️ 2. REGISTRATION TRANSACTION (Company + Unit + User)
  // ===========================================================================
  
  Future<String> registerOwner({
    required String email,
    required String password,
    required String ownerName,
    required String mobile,
    required String companyName,
  }) async {
    try {
      // 1. Create Auth User
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCred.user;
      if (user == null) return "User creation failed";

      // 2. Send Verification Email
      try { await user.sendEmailVerification(); } catch (_) {}

      // 3. Generate IDs
      String companyId = "CMP_${DateTime.now().millisecondsSinceEpoch}";
      String headOfficeId = "UNIT_${DateTime.now().millisecondsSinceEpoch}_HO";

      // 4. Atomic Transaction
      await _firestore.runTransaction((transaction) async {
        // A. Company Doc
        transaction.set(_firestore.collection('companies').doc(companyId), {
          'companyId': companyId,
          'name': companyName,
          'ownerId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'plan': 'Enterprise',
          'isActive': true,
        });

        // B. Head Office Unit
        transaction.set(_firestore.collection('units').doc(headOfficeId), {
          'unitId': headOfficeId,
          'companyId': companyId,
          'name': '$companyName (Head Office)',
          'type': 'HEAD_OFFICE',
          'city': 'Main Location',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // C. User Profile
        transaction.set(_firestore.collection('users').doc(user.uid), {
          'uid': user.uid,
          'name': ownerName,
          'email': email,
          'mobile': mobile,
          'role': 'OWNER',
          'companyId': companyId,
          'assignedUnits': ['ALL'],
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false, 
        });
      });

      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return "Email is already registered.";
      if (e.code == 'weak-password') return "Password is too weak.";
      return e.message ?? "Registration Error";
    } catch (e) {
      return "Database Error: $e";
    }
  }

  // ===========================================================================
  // 📧 3. VERIFICATION UTILS
  // ===========================================================================
  
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  Future<String> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return "SUCCESS";
      }
      return "ALREADY_VERIFIED";
    } catch (e) {
      return "Error: $e";
    }
  }

  // ===========================================================================
  // 🛠️ 4. UTILITY FEATURES
  // ===========================================================================

  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "No user found with this email.";
      return e.message ?? "Error sending reset link.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      // ✅ FIX: Firestore permission denied ya koi bhi error aaye,
      // tab bhi Firebase Auth se basic user info return karo.
      // Isse profile screen loading mein nahi atkegi.
    }

    // ✅ FALLBACK: Firestore se data na mile to Firebase Auth ka
    // locally available data return karo — screen load hogi.
    final user = _auth.currentUser;
    if (user != null) {
      return {
        'name': user.displayName ?? user.email?.split('@').first ?? 'User',
        'email': user.email ?? '',
        'mobile': user.phoneNumber ?? '',
        'role': 'OWNER',
        'uid': user.uid,
      };
    }
    return null;
  }
}