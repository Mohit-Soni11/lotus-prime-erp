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
  SectionEditState hsnSectionState = SectionEditState.locked;

  // --- DATA MODEL ---
  TaxGstModel taxData = const TaxGstModel();

  // --- UPLOADED FILES STATE ---
  File? gstCertFile;
  File? bisLicenseFile;

  // --- CONTROLLERS ---
  final TextEditingController gstinCtrl = TextEditingController();
  final TextEditingController legalNameCtrl = TextEditingController();
  final TextEditingController regDateCtrl = TextEditingController();
  final TextEditingController goldBisLicCtrl = TextEditingController();
  final TextEditingController silverBisLicCtrl = TextEditingController();
  final TextEditingController validFromCtrl = TextEditingController();
  final TextEditingController validUptoCtrl = TextEditingController();

  TextEditingController get bisLicCtrl => goldBisLicCtrl;

  // --- DROPDOWN STATE ---
  TaxpayerType selectedTaxpayer = TaxpayerType.regular;

  // Exposing enum values for the UI dropdown
  List<String> get taxpayerTypes =>
      TaxpayerType.values.map((e) => e.displayName).toList();

  // --- HSN DATA (Mocked for now, usually comes from API) ---
  final List<Map<String, dynamic>> hsnList = [
    {
      "title": "Gold Jewellery",
      "label": "HSN CODE",
      "code": "71131910",
      "rate": "3%"
    },
    {
      "title": "Silver Articles",
      "label": "HSN CODE",
      "code": "71131120",
      "rate": "3%"
    },
    {
      "title": "Diamond / Stones",
      "label": "HSN CODE",
      "code": "71023910",
      "rate": "3%"
    },
  ];

  // --- FOCUS NODES ---
  final FocusNode gstinFocus = FocusNode();
  final FocusNode legalNameFocus = FocusNode();
  final FocusNode regDateFocus = FocusNode();
  final FocusNode goldBisLicFocus = FocusNode();
  final FocusNode silverBisLicFocus = FocusNode();
  final FocusNode validFromFocus = FocusNode();
  final FocusNode validUptoFocus = FocusNode();

  FocusNode get bisLicFocus => goldBisLicFocus;

  TaxGstLogic() {
    // Attach listeners safely
    gstinFocus.addListener(_onFocusChange);
    legalNameFocus.addListener(_onFocusChange);
    goldBisLicFocus.addListener(_onFocusChange);
    silverBisLicFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() => notifyListeners();

  // --- STATE GETTERS FOR UI ---
  bool get isGstLocked => gstSectionState != SectionEditState.editing;
  bool get isBisLocked => bisSectionState != SectionEditState.editing;
  bool get isHsnLocked => hsnSectionState != SectionEditState.editing;

  // 🚀 BUG FIX: Added the missing helper method for UI routing
  bool isSectionLocked(String sectionId) {
    if (sectionId == 'gst') return isGstLocked;
    if (sectionId == 'bis') return isBisLocked;
    if (sectionId == 'hsn') return isHsnLocked;
    return true; // Safe fallback
  }

  String? get loadingSection {
    if (gstSectionState == SectionEditState.saving) return 'gst';
    if (bisSectionState == SectionEditState.saving) return 'bis';
    if (hsnSectionState == SectionEditState.saving) return 'hsn';
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
      targetFocus = goldBisLicFocus;
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
    if (TaxGstValidators.validateOptionalBisLicense(goldBisLicCtrl.text) !=
        null) {
      errors.add(goldBisLicFocus);
    }
    if (TaxGstValidators.validateOptionalBisLicense(silverBisLicCtrl.text) !=
        null) {
      errors.add(silverBisLicFocus);
    }
    if (_hasAnyBisData &&
        TaxGstValidators.validateDate(
                validFromCtrl.text, "Registration Date") !=
            null) {
      errors.add(validFromFocus);
    }
    return errors;
  }

  bool get _hasAnyBisData =>
      goldBisLicCtrl.text.trim().isNotEmpty ||
      silverBisLicCtrl.text.trim().isNotEmpty;

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

  Future<void> toggleHsnLock() async {
    if (hsnSectionState == SectionEditState.editing) {
      hsnSectionState = SectionEditState.saving;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      hsnSectionState = SectionEditState.locked;
    } else {
      hsnSectionState = SectionEditState.editing;
    }
    notifyListeners();
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
    String? validFrom,
    String? validUpto,
  }) {
    final goldBis =
        _normalizeUpper(goldBisLic ?? bisLic ?? goldBisLicCtrl.text);
    final silverBis = _normalizeUpper(silverBisLic ?? silverBisLicCtrl.text);

    taxData = TaxGstModel(
      gstin: _normalizeUpper(gstin ?? gstinCtrl.text),
      legalName: _normalizeText(legalName ?? legalNameCtrl.text),
      regDate: _normalizeText(regDate ?? regDateCtrl.text),
      taxpayerType: taxpayerType == null
          ? selectedTaxpayer
          : TaxpayerType.fromString(taxpayerType),
      bisLicenseNo: _combinedBisLicense(goldBis, silverBis),
      goldBisLicenseNo: goldBis,
      silverBisLicenseNo: silverBis,
      bisValidFrom: _normalizeText(validFrom ?? validFromCtrl.text),
      bisValidUpto: _normalizeText(validUpto ?? validUptoCtrl.text),
      gstCertPath: gstCertFile?.path,
      bisLicensePath: bisLicenseFile?.path,
    );
    return taxData;
  }

  String _normalizeText(String value) => value.trim();

  String _normalizeUpper(String value) => value.trim().toUpperCase();

  String _combinedBisLicense(String gold, String silver) {
    if (gold.isNotEmpty && silver.isNotEmpty) {
      if (gold == silver) return gold;
      return "Gold: $gold | Silver: $silver";
    }
    if (gold.isNotEmpty) return gold;
    return silver;
  }

  void setTaxpayer(String val) {
    selectedTaxpayer = TaxpayerType.fromString(val);
    notifyListeners();
  }

  void setRegDate(String val) {
    regDateCtrl.text = val;
    notifyListeners();
  }

  void setBisDates(String from, String upto) {
    if (from.isNotEmpty) validFromCtrl.text = from;
    if (upto.isNotEmpty) validUptoCtrl.text = upto;
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
    goldBisLicFocus.removeListener(_onFocusChange);
    silverBisLicFocus.removeListener(_onFocusChange);

    // 2. Dispose Nodes
    gstinFocus.dispose();
    legalNameFocus.dispose();
    regDateFocus.dispose();
    goldBisLicFocus.dispose();
    silverBisLicFocus.dispose();
    validFromFocus.dispose();
    validUptoFocus.dispose();

    // 3. Dispose Controllers
    gstinCtrl.dispose();
    legalNameCtrl.dispose();
    regDateCtrl.dispose();
    goldBisLicCtrl.dispose();
    silverBisLicCtrl.dispose();
    validFromCtrl.dispose();
    validUptoCtrl.dispose();

    super.dispose();
  }
}
