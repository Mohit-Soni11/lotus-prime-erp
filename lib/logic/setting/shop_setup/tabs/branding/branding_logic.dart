// -----------------------------------------------------------------------------
// FILE: branding_logic.dart
// TYPE: Business Logic / ViewModel
// AUTHOR: Senior Enterprise Architect
// DESCRIPTION: Clean architecture state management with Smart Data Pipeline,
//              Enum-driven URL Engine, and strictly decoupled Validation logic.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// --- FOUNDATION IMPORTS ---
import '../../../../../../../models/setting/shop_setup/shop_profile_model.dart';
import '../../../../../models/setting/shop_setup/tabs/shop_branding_model.dart';
import '../../../../../models/setting/shop_setup/enums/branding_enums.dart';
import '../../../../../helpers/branding/branding_validators.dart';

class BrandingLogic extends ChangeNotifier {
  // --- CORE DATA MODEL ---
  ShopBrandingModel brandingData = const ShopBrandingModel();

  // --- STATE LOCKS ---
  bool isSocialLocked = true;
  bool isSupportLocked = true;

  // 🚀 UPGRADE: Changed to String to perfectly match UI requirements
  String? loadingSection;

  // 🚀 UPGRADE: Added Missing GlobalKeys to prevent UI runtime crashes
  final GlobalKey<FormState> socialKey = GlobalKey<FormState>();
  final GlobalKey<FormState> supportKey = GlobalKey<FormState>();

  // --- CONTROLLERS (Social) ---
  final TextEditingController instaCtrl = TextEditingController();
  final TextEditingController fbCtrl = TextEditingController();
  final TextEditingController ytCtrl = TextEditingController();
  final TextEditingController webCtrl = TextEditingController();

  // --- CONTROLLERS (Support) ---
  final TextEditingController waChannelCtrl = TextEditingController();
  final TextEditingController waBizCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  // --- FOCUS NODES ---
  final FocusNode instaFocus = FocusNode();
  final FocusNode fbFocus = FocusNode();
  final FocusNode ytFocus = FocusNode();
  final FocusNode webFocus = FocusNode();

  final FocusNode waChannelFocus = FocusNode();
  final FocusNode waBizFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();

  // --- SMART INITIALIZATION ---
  void init(ShopProfileModel? basicInfoData) {
    if (basicInfoData != null) {
      if (waBizCtrl.text.isEmpty) {
        waBizCtrl.text = basicInfoData.shopWhatsapp.isNotEmpty
            ? basicInfoData.shopWhatsapp
            : basicInfoData.ownerWhatsapp;
      }

      if (emailCtrl.text.isEmpty) {
        emailCtrl.text = basicInfoData.businessEmail;
      }

      if (phoneCtrl.text.isEmpty) {
        phoneCtrl.text = basicInfoData.shopPhone.isNotEmpty
            ? basicInfoData.shopPhone
            : basicInfoData.ownerPhone;
      }
    }
  }

  // --- UI HELPER METHODS ---

  /// Checks if a specific section is currently locked.
  bool isSectionLocked(String sectionId) {
    return sectionId == 'social' ? isSocialLocked : isSupportLocked;
  }

  /// Unlocks a section and returns the first FocusNode to auto-focus the keyboard.
  FocusNode? unlockSection(String sectionId) {
    if (sectionId == 'social') {
      isSocialLocked = false;
      notifyListeners();
      return instaFocus;
    } else if (sectionId == 'support') {
      isSupportLocked = false;
      notifyListeners();
      return waChannelFocus;
    }
    return null;
  }

  // --- LOGIC: ASYNC SAVE & SMART VALIDATION ---
  /// Validates, saves, and intelligently moves focus if an error occurs.
  Future<void> saveSection(String sectionId) async {
    // 1. Validation & Auto-Focus Error Routing
    if (sectionId == 'social') {
      if (BrandingValidators.validateOptionalSocialLink(instaCtrl.text) !=
          null) {
        instaFocus.requestFocus();
        return;
      }
      if (BrandingValidators.validateOptionalSocialLink(fbCtrl.text) != null) {
        fbFocus.requestFocus();
        return;
      }
      if (BrandingValidators.validateOptionalSocialLink(ytCtrl.text) != null) {
        ytFocus.requestFocus();
        return;
      }
      if (BrandingValidators.validateOptionalSocialLink(webCtrl.text) != null) {
        webFocus.requestFocus();
        return;
      }
    } else if (sectionId == 'support') {
      if (BrandingValidators.validateOptionalPhone(waBizCtrl.text) != null) {
        waBizFocus.requestFocus();
        return;
      }
      if (BrandingValidators.validateOptionalEmail(emailCtrl.text) != null) {
        emailFocus.requestFocus();
        return;
      }
      if (BrandingValidators.validateOptionalPhone(phoneCtrl.text) != null) {
        phoneFocus.requestFocus();
        return;
      }
    }

    // 2. Start Loading State
    loadingSection = sectionId;
    notifyListeners();

    // Mock API Delay
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. Save Data & Lock Section
    if (sectionId == 'social') {
      brandingData = brandingData.copyWith(
        instagram: instaCtrl.text.trim(),
        facebook: fbCtrl.text.trim(),
        youtube: ytCtrl.text.trim(),
        website: webCtrl.text.trim(),
      );
      isSocialLocked = true;
    } else if (sectionId == 'support') {
      brandingData = brandingData.copyWith(
        whatsappChannel: waChannelCtrl.text.trim(),
        whatsappBusiness: waBizCtrl.text.trim(),
        supportEmail: emailCtrl.text.trim(),
        supportPhone: phoneCtrl.text.trim(),
      );
      isSupportLocked = true;
    }

    loadingSection = null;
    notifyListeners();
  }

  // --- ENUM-DRIVEN URL LAUNCHER ---
  /// 🚀 UPGRADE: Now accepts String from UI and safely parses it to strict Enum
  Future<void> launchPlatformUrl(String platformType, String value) async {
    if (value.trim().isEmpty) return;

    // Convert string to strict Enum to prevent compile-time crashes
    final SocialPlatform platform = SocialPlatform.fromString(platformType);

    String urlString = "";
    final cleanValue = value.trim();

    switch (platform) {
      case SocialPlatform.instagram:
        urlString = "https://instagram.com/${cleanValue.replaceAll('@', '')}";
        break;
      case SocialPlatform.facebook:
      case SocialPlatform.youtube:
      case SocialPlatform.website:
        urlString =
            cleanValue.startsWith('http') ? cleanValue : "https://$cleanValue";
        break;
      case SocialPlatform.whatsapp:
        urlString = "https://wa.me/91$cleanValue";
        break;
      case SocialPlatform.email:
        urlString = "mailto:$cleanValue";
        break;
      case SocialPlatform.phone:
        urlString = "tel:$cleanValue";
        break;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('System Error: Could not launch $url');
      }
    } catch (e) {
      debugPrint('Launch Error: $e');
    }
  }

  @override
  void dispose() {
    instaCtrl.dispose();
    fbCtrl.dispose();
    ytCtrl.dispose();
    webCtrl.dispose();
    waChannelCtrl.dispose();
    waBizCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();

    instaFocus.dispose();
    fbFocus.dispose();
    ytFocus.dispose();
    webFocus.dispose();
    waChannelFocus.dispose();
    waBizFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();

    super.dispose();
  }
}
