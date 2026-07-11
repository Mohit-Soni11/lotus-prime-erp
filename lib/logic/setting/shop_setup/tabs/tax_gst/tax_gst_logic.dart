// -----------------------------------------------------------------------------
// FILE: tax_gst_logic.dart
// TYPE: Business Logic / ViewModel
// AUTHOR: Senior Enterprise Architect
// DESCRIPTION: Highly optimized ViewModel with Enums, Model injection, strict
//              memory management, robust error validation, and routing helpers.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';

// --- CORE IMPORTS ---
// NOTE: Adjust these paths according to your actual folder structure.
import '../../../../../models/setting/shop_setup/enums/tax_gst_enums.dart';
import '../../../../../models/setting/shop_setup/tabs/tax_gst_model.dart';
import '../../../../../helpers/tax_gst/tax_gst_validators.dart';

class TaxGstLogic extends ChangeNotifier {
  // --- STATE ENUMS (Replaces confusing booleans) ---
  SectionEditState gstSectionState = SectionEditState.locked;
  SectionEditState bisSectionState = SectionEditState.locked;

  // --- DATA MODEL ---
  TaxGstModel taxData = const TaxGstModel();

  // --- UPLOADED FILES STATE ---
  File? gstCertFile;
  File? bisLicenseFile;

  // --- CONTROLLERS ---
  final TextEditingController gstinCtrl = TextEditingController();
  final TextEditingController legalNameCtrl = TextEditingController();
  final TextEditingController regDateCtrl = TextEditingController();
  final TextEditingController bisLicCtrl = TextEditingController();
  final TextEditingController goldBisLicCtrl = TextEditingController();
  final TextEditingController silverBisLicCtrl = TextEditingController();

  // --- DROPDOWN STATE ---
  TaxpayerType selectedTaxpayer = TaxpayerType.regular;
  HallmarkingScope selectedHallmarkingScope = HallmarkingScope.goldAndSilver;

  // Exposing enum values for the UI dropdown
  List<String> get taxpayerTypes =>
      TaxpayerType.values.map((e) => e.displayName).toList();
  bool get coversGold => selectedHallmarkingScope.coversGold;
  bool get coversSilver => selectedHallmarkingScope.coversSilver;

  // --- FOCUS NODES ---
  final FocusNode gstinFocus = FocusNode();
  final FocusNode legalNameFocus = FocusNode();
  final FocusNode regDateFocus = FocusNode();
  final FocusNode bisLicFocus = FocusNode();
  final FocusNode goldBisLicFocus = FocusNode();
  final FocusNode silverBisLicFocus = FocusNode();

  TaxGstLogic() {
    // Attach listeners safely
    gstinFocus.addListener(_onFocusChange);
    legalNameFocus.addListener(_onFocusChange);
    bisLicFocus.addListener(_onFocusChange);
    goldBisLicFocus.addListener(_onFocusChange);
    silverBisLicFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() => notifyListeners();

  // --- STATE GETTERS FOR UI ---
  bool get isGstLocked => gstSectionState != SectionEditState.editing;
  bool get isBisLocked => bisSectionState != SectionEditState.editing;

  // 🚀 BUG FIX: Added the missing helper method for UI routing
  bool isSectionLocked(String sectionId) {
    if (sectionId == 'gst') return isGstLocked;
    if (sectionId == 'bis') return isBisLocked;
    return true; // Safe fallback
  }

  String? get loadingSection {
    if (gstSectionState == SectionEditState.saving) return 'gst';
    if (bisSectionState == SectionEditState.saving) return 'bis';
    return null;
  }

  // --- LOCK & UNLOCK LOGIC ---
  FocusNode? unlockSection(String sectionId) {
    FocusNode? targetFocus;
    if (sectionId == 'gst') {
      gstSectionState = SectionEditState.editing;
      targetFocus = gstinFocus;
    } else if (sectionId == 'bis') {
      bisSectionState = SectionEditState.editing;
      targetFocus = coversGold ? goldBisLicFocus : silverBisLicFocus;
    }
    notifyListeners();
    return targetFocus;
  }

  // --- SMART ERROR TRAVERSAL & VALIDATION ---
  List<FocusNode> _validateGstSection() {
    List<FocusNode> errors = [];
    if (TaxGstValidators.validateGstin(gstinCtrl.text) != null) {
      errors.add(gstinFocus);
    }
    if (TaxGstValidators.validateLegalName(legalNameCtrl.text) != null) {
      errors.add(legalNameFocus);
    }
    if (TaxGstValidators.validateDate(regDateCtrl.text, "Registration Date") !=
        null) {
      errors.add(regDateFocus);
    }
    return errors;
  }

  List<FocusNode> _validateBisSection() {
    List<FocusNode> errors = [];
    if (coversGold &&
        TaxGstValidators.validateOptionalBisLicense(goldBisLicCtrl.text) !=
            null) {
      errors.add(goldBisLicFocus);
    }
    if (coversSilver &&
        TaxGstValidators.validateOptionalBisLicense(silverBisLicCtrl.text) !=
            null) {
      errors.add(silverBisLicFocus);
    }
    return errors;
  }

  // --- ASYNC SAVE LOGIC ---
  Future<bool> saveSection(String sectionId) async {
    List<FocusNode> errors = [];

    if (sectionId == 'gst') {
      errors = _validateGstSection();
      if (errors.isEmpty) gstSectionState = SectionEditState.saving;
    } else if (sectionId == 'bis') {
      errors = _validateBisSection();
      if (errors.isEmpty) bisSectionState = SectionEditState.saving;
    }

    if (errors.isNotEmpty) {
      errors.first.requestFocus(); // Auto-focus on first error
      notifyListeners();
      return false;
    }

    notifyListeners();

    // Simulating API Call
    await Future.delayed(const Duration(milliseconds: 300));

    // Sync data to Immutable Model
    _syncDataToModel();

    if (sectionId == 'gst') {
      gstSectionState = SectionEditState.locked;
    } else if (sectionId == 'bis') {
      bisSectionState = SectionEditState.locked;
    }

    notifyListeners();
    return true;
  }

  TaxGstModel? validateAndGenerateFinalModel() {
    final errors = <FocusNode>[
      ..._validateGstSection(),
      ..._validateBisSection(),
    ];

    if (errors.isNotEmpty) {
      errors.first.requestFocus();
      notifyListeners();
      return null;
    }

    return generateFinalModel();
  }

  // --- DATA UPDATERS ---
  void _syncDataToModel() {
    generateFinalModel();
  }

  // --- FINAL EXPORT ---
  TaxGstModel generateFinalModel({
    String? gstin,
    String? legalName,
    String? regDate,
    String? taxpayerType,
    String? bisLic,
    String? goldBisLic,
    String? silverBisLic,
    HallmarkingScope? hallmarkingScope,
  }) {
    final scope = hallmarkingScope ?? selectedHallmarkingScope;
    final rawGoldRegistration = goldBisLic ?? goldBisLicCtrl.text;
    final rawSilverRegistration = silverBisLic ?? silverBisLicCtrl.text;
    final hasExplicitMetalRegistration =
        rawGoldRegistration.trim().isNotEmpty ||
            rawSilverRegistration.trim().isNotEmpty;
    final fallbackBisRegistration = hasExplicitMetalRegistration
        ? ''
        : _normalizeUpper(bisLic ?? bisLicCtrl.text);
    final goldRegistration = scope.coversGold
        ? _resolveMetalRegistration(
            rawGoldRegistration,
            fallbackBisRegistration,
          )
        : '';
    final silverRegistration = scope.coversSilver
        ? _resolveMetalRegistration(
            rawSilverRegistration,
            fallbackBisRegistration,
          )
        : '';
    final bisRegistration =
        _combinedBisRegistration(goldRegistration, silverRegistration);

    taxData = TaxGstModel(
      gstin: _normalizeUpper(gstin ?? gstinCtrl.text),
      legalName: _normalizeText(legalName ?? legalNameCtrl.text),
      regDate: _normalizeText(regDate ?? regDateCtrl.text),
      taxpayerType: taxpayerType == null
          ? selectedTaxpayer
          : TaxpayerType.fromString(taxpayerType),
      bisLicenseNo: bisRegistration,
      hallmarkingScope: scope,
      goldBisLicenseNo: goldRegistration,
      silverBisLicenseNo: silverRegistration,
      gstCertPath: gstCertFile?.existsSync() == true ? gstCertFile!.path : null,
      bisLicensePath:
          bisLicenseFile?.existsSync() == true ? bisLicenseFile!.path : null,
    );
    return taxData;
  }

  String _normalizeText(String value) => value.trim();

  String _normalizeUpper(String value) => value.trim().toUpperCase();

  String _resolveMetalRegistration(String value, String fallback) {
    final normalized = _normalizeUpper(value);
    return normalized.isNotEmpty ? normalized : fallback;
  }

  String _combinedBisRegistration(String gold, String silver) {
    if (gold.isNotEmpty && silver.isNotEmpty) {
      if (gold.toUpperCase() == silver.toUpperCase()) return gold;
      return 'Gold: $gold | Silver: $silver';
    }
    if (gold.isNotEmpty) return gold;
    return silver;
  }

  void setTaxpayer(String val) {
    selectedTaxpayer = TaxpayerType.fromString(val);
    notifyListeners();
  }

  void setHallmarkingScope(String val) {
    selectedHallmarkingScope = HallmarkingScope.fromString(val);
    notifyListeners();
  }

  void setHallmarkingMetal({
    required HallmarkingScope metal,
    required bool selected,
  }) {
    final nextGold = metal == HallmarkingScope.gold ? selected : coversGold;
    final nextSilver =
        metal == HallmarkingScope.silver ? selected : coversSilver;
    if (!nextGold && !nextSilver) return;

    selectedHallmarkingScope = switch ((nextGold, nextSilver)) {
      (true, true) => HallmarkingScope.goldAndSilver,
      (true, false) => HallmarkingScope.gold,
      (false, true) => HallmarkingScope.silver,
      _ => selectedHallmarkingScope,
    };
    notifyListeners();
  }

  void setRegDate(String val) {
    regDateCtrl.text = val;
    notifyListeners();
  }

  void updateGstFile(File? file) {
    gstCertFile = file;
    notifyListeners();
  }

  void updateBisFile(File? file) {
    bisLicenseFile = file;
    notifyListeners();
  }

  // --- 🚀 MEMORY LEAK PREVENTION ---
  @override
  void dispose() {
    // 1. Remove listeners first to prevent zombie callbacks
    gstinFocus.removeListener(_onFocusChange);
    legalNameFocus.removeListener(_onFocusChange);
    bisLicFocus.removeListener(_onFocusChange);
    goldBisLicFocus.removeListener(_onFocusChange);
    silverBisLicFocus.removeListener(_onFocusChange);

    // 2. Dispose Nodes
    gstinFocus.dispose();
    legalNameFocus.dispose();
    regDateFocus.dispose();
    bisLicFocus.dispose();
    goldBisLicFocus.dispose();
    silverBisLicFocus.dispose();

    // 3. Dispose Controllers
    gstinCtrl.dispose();
    legalNameCtrl.dispose();
    regDateCtrl.dispose();
    bisLicCtrl.dispose();
    goldBisLicCtrl.dispose();
    silverBisLicCtrl.dispose();

    super.dispose();
  }
}
