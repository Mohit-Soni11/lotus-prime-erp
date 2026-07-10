// -----------------------------------------------------------------------------
// FILE: shop_setup_wizard.dart
// TYPE: Master Layout / Navigation Controller
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 UPGRADED: Added Auto-Fetch Engine on App Start.
//              Fetches permanent Tenant ID and pre-fills all UI Tabs.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// --- MODEL IMPORTS ---
import '../../../../models/setting/shop_setup/shop_step_model.dart';
import '../../../../models/setting/shop_setup/shop_profile_model.dart';
import '../../../../models/setting/shop_setup/enums/basic_info_enums.dart';

// --- TABS & REPOSITORY IMPORTS ---
import '../../../../models/setting/shop_setup/tabs/tax_gst_model.dart';
import '../../../../models/setting/shop_setup/tabs/shop_branding_model.dart';
import '../../../../models/setting/shop_setup/tabs/bank_account_model.dart';
import '../../../../repositories/setting/shop_setup/shop_setup_repository.dart';

// 🚀 UPGRADE: Session Manager imported to lock the permanent ID
import '../../../../repositories/setting/shop_setup/shop_session_manager.dart';

// --- UI LAYOUT IMPORT ---
import 'layout/shop_setup_layout.dart';

// --- TABS IMPORTS ---
import 'tabs/basic_info_tab.dart';
import 'tabs/address_card_tab.dart';
import 'tabs/tax_gst_tab.dart';
import 'tabs/banking_tab.dart';
import 'tabs/branding_tab.dart';
import '../../../core/logging/app_logger.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class ShopSetupWizard extends StatefulWidget {
  const ShopSetupWizard({super.key});

  @override
  State<ShopSetupWizard> createState() => _ShopSetupWizardState();
}

class _ShopSetupWizardState extends State<ShopSetupWizard> {
  // --- STATE ---
  int _currentStep = 1;
  bool _isLoading = false;
  bool _isFetchingInitialData = true;

  ShopProfileModel _masterData = const ShopProfileModel();

  // 🚀 NEW: Store the complete fetched payload from SQLite
  Map<String, dynamic>? _fetchedMasterData;

  final ShopSetupRepository _repository = ShopSetupRepository();

  // SMART LAZY LOADING TRACKER
  final List<bool> _activatedSteps = List.generate(5, (index) => index == 0);

  // DYNAMIC GLOBAL KEYS FOR DATA EXTRACTION
  final GlobalKey<BasicInfoTabState> _basicInfoKey =
      GlobalKey<BasicInfoTabState>();
  final GlobalKey<dynamic> _addressKey = GlobalKey();
  final GlobalKey<dynamic> _gstKey = GlobalKey();
  final GlobalKey<dynamic> _bankingKey = GlobalKey();
  final GlobalKey<dynamic> _brandingKey = GlobalKey();

  // --- STEPS DEFINITION ---
  final List<ShopStepModel> _allSteps = [
    const ShopStepModel(
        id: 1,
        title: "Basic Info",
        subTitle: "Identity & Operations",
        icon: Icons.store_mall_directory_rounded),
    const ShopStepModel(
        id: 2,
        title: "Address",
        subTitle: "Location & Geo-Tag",
        icon: Icons.location_on_rounded),
    const ShopStepModel(
        id: 3,
        title: "GST & Legal",
        subTitle: "Tax Compliance",
        icon: Icons.receipt_long_rounded),
    const ShopStepModel(
        id: 4,
        title: "Banking",
        subTitle: "Financial Setup",
        icon: Icons.account_balance_rounded),
    const ShopStepModel(
        id: 5,
        title: "Branding",
        subTitle: "Social & Support",
        icon: Icons.verified_user_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingConfiguration();
  }

  // --- 🚀 UPGRADED: THE READ CYCLE (Auto-Fetch from SQLite) ---
  Future<void> _loadExistingConfiguration() async {
    try {
      // 1. Get the permanent secure ID
      final String permanentId =
          await ShopSessionManager.getPermanentTenantId();

      // 2. Fetch data from SQLite
      _fetchedMasterData = await _repository.fetchExistingSetup(permanentId);

      if (_fetchedMasterData != null) {
        // 3. Map the basic info raw map to ShopProfileModel for BasicInfoTab
        final basicMap = _fetchedMasterData!['basic_info'] ?? {};

        _masterData = ShopProfileModel(
          legalName: basicMap['legal_name']?.toString() ?? "",
          displayName: basicMap['display_name']?.toString() ?? "",
          tagline: basicMap['tagline']?.toString() ?? "",
          ownerName: basicMap['owner_name']?.toString() ?? "",
          ownerPhone: basicMap['owner_phone']?.toString() ?? "",
          ownerWhatsapp: basicMap['owner_whatsapp']?.toString() ?? "",
          estYear: basicMap['est_year']?.toString() ?? "",
          branchCode: basicMap['branch_code']?.toString() ?? "",
          openTime: basicMap['open_time']?.toString() ?? "10:00 AM",
          closeTime: basicMap['close_time']?.toString() ?? "08:00 PM",
          weeklyOff: basicMap['weekly_off']?.toString() ?? "None",
          brandDisplayName: basicMap['brand_display_name']?.toString() ?? "",
          businessEmail: basicMap['business_email']?.toString() ?? "",
          shopPhone: basicMap['shop_phone']?.toString() ?? "",
          shopWhatsapp: basicMap['shop_whatsapp']?.toString() ?? "",
          logoPath: basicMap['logo_path']?.toString(),
          signaturePath: basicMap['signature_path']?.toString(),
          logoShape: basicMap['logo_shape']?.toString() ?? "circle",
          signatureShape: basicMap['signature_shape']?.toString() ?? "square",
        );
      }

      if (mounted) {
        setState(() => _isFetchingInitialData = false);
      }
    } catch (e) {
      AppLogger.error("❌ Fetch Error: $e");
      if (mounted) setState(() => _isFetchingInitialData = false);
    }
  }

  // --- NAVIGATION LOGIC ---
  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _triggerSafeAutoFetch();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleJumpToStep(int stepId) {
    setState(() {
      _currentStep = stepId;
      _activatedSteps[stepId - 1] = true;
    });
    _triggerSafeAutoFetch();
  }

  Future<void> _handleNext() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    bool isValid = true;

    if (_currentStep == 1) {
      try {
        if (_basicInfoKey.currentState != null) {
          final data = _basicInfoKey.currentState!.validateAndSave();
          if (data != null) {
            _masterData = data;
          } else {
            isValid = false;
          }
        }
      } catch (e) {
        AppLogger.debug("Validation Crash Blocked: $e");
      }
    }

    if (!isValid) {
      setState(() => _isLoading = false);
      _showErrorFeedback(
          "Please correct the errors in the form before proceeding.");
      return;
    }

    if (_currentStep < _allSteps.length) {
      setState(() {
        _currentStep++;
        _activatedSteps[_currentStep - 1] = true;
        _isLoading = false;
      });
      _triggerSafeAutoFetch();
    } else {
      await _submitMasterConfiguration();
    }
  }

  // --- 🚀 THE WRITE CYCLE: Smart Data Extraction Engine ---
  Future<void> _submitMasterConfiguration() async {
    try {
      // 1. SMART ADDRESS EXTRACTION
      Map<String, dynamic> addressData = {};
      try {
        final addressState = _addressKey.currentState;
        final formLogic = addressState?.formLogic;
        final mapLogic = addressState?.mapLogic;

        String addrType = "Head Office";
        if (formLogic != null) {
          try {
            addrType = (formLogic.selectedAddressType is ValueNotifier)
                ? formLogic.selectedAddressType.value
                : formLogic.selectedAddressType.toString();
          } catch (_) {}
        }

        double? lat, lng;
        if (mapLogic != null) {
          try {
            if (mapLogic.selectedLocation is ValueNotifier) {
              lat = mapLogic.selectedLocation.value?.latitude;
              lng = mapLogic.selectedLocation.value?.longitude;
            } else {
              lat = mapLogic.selectedLocation?.latitude;
              lng = mapLogic.selectedLocation?.longitude;
            }
          } catch (_) {}
        }

        addressData = {
          "type": addrType,
          "addr1":
              addressState?.addr1Ctrl?.text ?? formLogic?.addr1Ctrl?.text ?? "",
          "addr2":
              addressState?.addr2Ctrl?.text ?? formLogic?.addr2Ctrl?.text ?? "",
          "city":
              addressState?.cityCtrl?.text ?? formLogic?.cityCtrl?.text ?? "",
          "state":
              addressState?.stateCtrl?.text ?? formLogic?.stateCtrl?.text ?? "",
          "pincode":
              addressState?.pinCtrl?.text ?? formLogic?.pinCtrl?.text ?? "",
          "country": addressState?.countryCtrl?.text ??
              formLogic?.countryCtrl?.text ??
              "India",
          "latitude": lat,
          "longitude": lng,
        };
      } catch (e) {
        AppLogger.error("Address Extraction Error: $e");
      }

      // 2. SMART GST EXTRACTION
      TaxGstModel gstData = const TaxGstModel();
      try {
        final gstLogic = _gstKey.currentState?.logic;
        if (gstLogic != null) {
          try {
            gstData = gstLogic.generateFinalModel();
          } catch (_) {
            gstData = gstLogic.taxData ?? const TaxGstModel();
          }
        }
      } catch (e) {
        AppLogger.error("GST Extraction Error: $e");
      }

      // 3. SMART BANKING EXTRACTION
      List<BankAccountModel> bankingList = [];
      try {
        final bankLogic = _bankingKey.currentState?.logic;
        if (bankLogic?.accountsNotifier != null) {
          bankingList = bankLogic!.accountsNotifier.value;
        }
      } catch (e) {
        AppLogger.error("Banking Extraction Error: $e");
      }

      // 4. SMART BRANDING EXTRACTION
      ShopBrandingModel brandingData = const ShopBrandingModel();
      try {
        final brandLogic = _brandingKey.currentState?.logic;
        if (brandLogic?.brandingData != null) {
          brandingData = brandLogic!.brandingData;
        }
      } catch (e) {
        AppLogger.error("Branding Extraction Error: $e");
      }

      // 🎯 MASTER PAYLOAD SUBMISSION
      bool isSuccess = await _repository.submitMasterPayload(
        basicInfo: _masterData,
        addressData: addressData,
        taxGst: gstData,
        bankingList: bankingList,
        branding: brandingData,
      );

      setState(() => _isLoading = false);

      if (isSuccess) {
        _finishSetup();
      } else {
        _showErrorFeedback("Failed to sync configuration with the database.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorFeedback("System Error: Setup could not be saved.");
      AppLogger.debug("Master Submission Crash Log: $e");
    }
  }

  // --- THE AUTO-FETCH ENGINE ---
  void _triggerSafeAutoFetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        String fetchedPhone = _masterData.shopPhone;
        String fetchedWa = _masterData.shopWhatsapp;
        String fetchedEmail = _masterData.businessEmail;

        if (fetchedPhone.isNotEmpty || fetchedEmail.isNotEmpty) {
          final brandState = _brandingKey.currentState;
          if (brandState != null) {
            try {
              brandState.logic?.autoSyncData(
                  phone: fetchedPhone,
                  whatsapp: fetchedWa,
                  email: fetchedEmail);
            } catch (_) {
              try {
                brandState.autoSyncData(
                    phone: fetchedPhone,
                    whatsapp: fetchedWa,
                    email: fetchedEmail);
              } catch (e) {
                AppLogger.debug("Auto Sync Ignored: $e");
              }
            }
          }
        }
      } catch (e) {
        AppLogger.debug("Auto Fetch Engine Blocked a Crash: $e");
      }
    });
  }

  void _finishSetup() {
    AppFeedback.show(
      context,
      type: AppFeedbackType.success,
      message: "Setup Saved Securely! Redirecting...",
    );
  }

  void _showErrorFeedback(String msg) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.error,
      message: msg,
    );
  }

  // --- MAIN BUILDER ---
  @override
  Widget build(BuildContext context) {
    if (_isFetchingInitialData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final updatedSteps = _allSteps.map((step) {
      if (step.id < _currentStep) {
        return step.copyWith(status: StepStatus.completed);
      } else if (step.id == _currentStep) {
        return step.copyWith(status: StepStatus.active);
      } else {
        return step.copyWith(status: StepStatus.locked);
      }
    }).toList();

    return ShopSetupLayout(
      currentStep: _currentStep,
      steps: updatedSteps,
      onBack: _handleBack,
      onNext: _handleNext,
      onJumpToStep: _handleJumpToStep,
      isLoading: _isLoading,
      child: IndexedStack(
        index: _currentStep - 1,
        children: [
          // 🚀 DATA IS NOW BEING PASSED TO ALL TABS
          _activatedSteps[0]
              ? BasicInfoTab(key: _basicInfoKey, initialData: _masterData)
              : const SizedBox.shrink(),
          _activatedSteps[1]
              ? AddressTab(
                  key: _addressKey, initialData: _fetchedMasterData?['address'])
              : const SizedBox.shrink(),
          _activatedSteps[2]
              ? TaxGstTab(
                  key: _gstKey,
                  initialData: _fetchedMasterData?['tax_compliance'])
              : const SizedBox.shrink(),
          _activatedSteps[3]
              ? BankingTab(
                  key: _bankingKey,
                  initialData: _fetchedMasterData?['banking_details'])
              : const SizedBox.shrink(),
          _activatedSteps[4]
              ? BrandingTab(
                  key: _brandingKey,
                  initialData: _masterData,
                  brandingData: _fetchedMasterData?['branding_social'])
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
