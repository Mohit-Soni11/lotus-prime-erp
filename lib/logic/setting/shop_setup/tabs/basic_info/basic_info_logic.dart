// -----------------------------------------------------------------------------
// FILE: basic_info_logic.dart
// TYPE: Business Logic / ViewModel Layer
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 UPGRADED: 100% Decoupled from UI. Fixed Memory Leaks.
//              Uses granular ValueNotifiers for true Zero-Lag 60-FPS rebuilds.
//              FocusNodes and Controllers are strictly removed from Logic.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// NOTE: Adjust paths according to your structure
import '../../../../../../../models/setting/shop_setup/shop_profile_model.dart';
import '../../../../../../../models/setting/shop_setup/enums/basic_info_enums.dart';
import '../../../../../../../helpers/basic_info/basic_info_validators.dart';
import '../../../../../theme/settings/shop_setup/tabs/basic_info_tab/basic_info_strings.dart';

class BasicInfoLogic {
  // --- 🚀 UPGRADE: GRANULAR STATE NOTIFIERS (Zero-Lag UI Fix) ---
  final ValueNotifier<bool> enterpriseLocked = ValueNotifier(true);
  final ValueNotifier<bool> commLocked = ValueNotifier(true);

  final ValueNotifier<FormSection?> loadingSection = ValueNotifier(null);

  final ValueNotifier<File?> logoFile = ValueNotifier(null);
  final ValueNotifier<File?> signatureFile = ValueNotifier(null);
  final ValueNotifier<String> logoShape = ValueNotifier("circle");
  final ValueNotifier<String> signatureShape = ValueNotifier("square");
  bool _logoRemoved = false;
  bool _signatureRemoved = false;

  static const int _maxFileSize = 5 * 1024 * 1024; // 5 MB

  ShopProfileModel? _initialData;

  // --- SMART SYNC FLAGS (Maintained in Logic for Business Rules) ---
  bool _isShopPhoneTouched = false;
  bool _isBrandDisplayTouched = false;
  bool _isShopWaTouched = false;

  // --- INITIALIZATION ---
  void init(ShopProfileModel? initialData) {
    if (_initialData != null) return;
    _initialData = initialData;

    logoShape.value = initialData?.logoShape ?? "circle";
    signatureShape.value = initialData?.signatureShape ?? "square";
  }

  // --- FILE HANDLING (Pure Logic) ---
  Future<String?> updateLogo(File? file, String shape) async {
    logoShape.value = _normalizeShape(shape, "circle");
    if (file == null) {
      logoFile.value = null;
      _logoRemoved = true;
      return null;
    }
    final int size = await file.length();
    if (size > _maxFileSize) return BasicInfoStrings.errFileTooLarge;

    logoFile.value = await _persistIdentityImage(file, "shop_logo");
    _logoRemoved = false;
    return null;
  }

  Future<String?> updateSignature(File? file, String shape) async {
    signatureShape.value = _normalizeShape(shape, "square");
    if (file == null) {
      signatureFile.value = null;
      _signatureRemoved = true;
      return null;
    }
    final int size = await file.length();
    if (size > _maxFileSize) return BasicInfoStrings.errFileTooLarge;

    signatureFile.value =
        await _persistIdentityImage(file, "authorized_signature");
    _signatureRemoved = false;
    return null;
  }

  // --- SECTION TOGGLE LOGIC ---
  void unlockSection(FormSection section) {
    switch (section) {
      case FormSection.enterprise:
        enterpriseLocked.value = false;
        break;
      case FormSection.communication:
        commLocked.value = false;
        break;
    }
  }

  // --- 🚀 UPGRADE: PURE VALIDATION (Returns Field Keys, Not FocusNodes) ---
  List<String> validateEnterprise(
      {required String legalName,
      required String displayName,
      required String ownerName,
      required String ownerPhone}) {
    List<String> errors = [];
    if (BasicInfoValidators.required(
            legalName, BasicInfoStrings.lblLegalName) !=
        null) {
      errors.add(BasicInfoStrings.keyLegalName);
    }
    if (BasicInfoValidators.required(
            displayName, BasicInfoStrings.lblDisplayName) !=
        null) {
      errors.add(BasicInfoStrings.keyDisplayName);
    }
    if (BasicInfoValidators.required(ownerName, BasicInfoStrings.lblOwner) !=
        null) {
      errors.add(BasicInfoStrings.keyOwnerName);
    }
    if (BasicInfoValidators.requiredPhone(ownerPhone) != null) {
      errors.add(BasicInfoStrings.keyOwnerPhone);
    }
    return errors;
  }

  List<String> validateCommunication(
      {required String email,
      required String shopPhone,
      required String shopWa,
      required String helpDeskNumber}) {
    List<String> errors = [];
    if (email.isNotEmpty && BasicInfoValidators.email(email) != null) {
      errors.add(BasicInfoStrings.keyEmail);
    }
    if (BasicInfoValidators.requiredPhone(shopPhone) != null) {
      errors.add(BasicInfoStrings.keyShopPhone);
    }
    if (shopWa.isNotEmpty && BasicInfoValidators.phone(shopWa) != null) {
      errors.add(BasicInfoStrings.keyShopWa);
    }
    if (helpDeskNumber.isNotEmpty &&
        BasicInfoValidators.phone(helpDeskNumber) != null) {
      errors.add(BasicInfoStrings.keyHelpDesk);
    }
    return errors;
  }

  // --- ASYNC SAVE OPERATIONS ---
  Future<bool> saveEnterprise(List<String> errors) async {
    if (errors.isNotEmpty) return false;
    loadingSection.value = FormSection.enterprise;
    await Future.delayed(const Duration(milliseconds: 300)); // Simulating API
    loadingSection.value = null;
    enterpriseLocked.value = true;
    return true;
  }

  Future<bool> saveCommunication(List<String> errors) async {
    if (errors.isNotEmpty) return false;
    loadingSection.value = FormSection.communication;
    await Future.delayed(const Duration(milliseconds: 300)); // Simulating API
    loadingSection.value = null;
    commLocked.value = true;
    return true;
  }

  // --- SMART DATA SYNC RULES ---
  void markShopPhoneTouched() => _isShopPhoneTouched = true;
  void markBrandDisplayTouched() => _isBrandDisplayTouched = true;
  void markShopWaTouched() => _isShopWaTouched = true;

  bool get shouldSyncShopPhone =>
      !_isShopPhoneTouched && !enterpriseLocked.value;
  bool get shouldSyncShopWa => !_isShopWaTouched && !enterpriseLocked.value;
  bool get shouldSyncBrandDisplay =>
      !_isBrandDisplayTouched && !enterpriseLocked.value;

  // --- FINAL EXPORT ---
  ShopProfileModel generateFinalModel({
    required String legalName,
    required String displayName,
    required String tagline,
    required String ownerName,
    required String ownerPhone,
    required String brandDisplayName,
    required String businessEmail,
    required String shopPhone,
    required String shopWhatsapp,
    required String helpDeskNumber,
  }) {
    return ShopProfileModel(
      legalName: legalName.trim(),
      displayName: displayName.trim(),
      tagline: tagline.trim(),
      ownerName: ownerName.trim(),
      ownerPhone: ownerPhone.trim(),
      brandDisplayName: brandDisplayName.trim(),
      businessEmail: businessEmail.trim(),
      shopPhone: shopPhone.trim(),
      shopWhatsapp: shopWhatsapp.trim(),
      helpDeskNumber: helpDeskNumber.trim(),
      // 🚀 FIXED: Mapping to logoPath and signaturePath instead of Base64
      // Yeh check karega ki naya file select hua hai ya nahi, warna initial data se le lega
      logoPath: _logoRemoved
          ? null
          : _existingPath(logoFile.value?.path, _initialData?.logoPath),
      signaturePath: _signatureRemoved
          ? null
          : _existingPath(
              signatureFile.value?.path,
              _initialData?.signaturePath,
            ),
      logoShape: logoShape.value,
      signatureShape: signatureShape.value,
    );
  }

  String _normalizeShape(String value, String fallback) {
    final normalized = value.trim().toLowerCase();
    return normalized == "square" || normalized == "circle"
        ? normalized
        : fallback;
  }

  String? _existingPath(String? path, String? fallbackPath) {
    final candidate = path ?? fallbackPath;
    if (candidate == null || candidate.trim().isEmpty) return null;
    return File(candidate).existsSync() ? candidate : null;
  }

  Future<File> _persistIdentityImage(File source, String fileStem) async {
    final supportDir = await getApplicationSupportDirectory();
    final identityDir = Directory(p.join(supportDir.path, "shop_identity"));
    await identityDir.create(recursive: true);
    final extension = p.extension(source.path).toLowerCase();
    final safeExtension =
        extension == ".jpg" || extension == ".jpeg" || extension == ".png"
            ? extension
            : ".png";
    for (final entry in identityDir.listSync()) {
      if (entry is File && p.basename(entry.path).startsWith("${fileStem}_")) {
        try {
          await entry.delete();
        } catch (_) {
          // A stale cached file should not block the new identity image.
        }
      }
    }
    final target = File(
      p.join(
        identityDir.path,
        "${fileStem}_${DateTime.now().millisecondsSinceEpoch}$safeExtension",
      ),
    );
    await target.writeAsBytes(await source.readAsBytes(), flush: true);
    return target;
  }

  // --- MEMORY CLEANUP ---
  void dispose() {
    enterpriseLocked.dispose();
    commLocked.dispose();
    loadingSection.dispose();
    logoFile.dispose();
    signatureFile.dispose();
    logoShape.dispose();
    signatureShape.dispose();
  }
}
