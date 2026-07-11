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
import '../../../../../core/logging/app_logger.dart';

class BrandingLogic extends ChangeNotifier {
  // --- CORE DATA MODEL ---
  ShopBrandingModel brandingData = const ShopBrandingModel();

  // --- STATE LOCKS ---
  bool isSocialLocked = true;
  bool isSupportLocked = true;

  // 🚀 UPGRADE: Changed to String to perfectly match UI requirements
  String? loadingSection;
  String? lastValidationError;

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
  Future<bool> saveSection(String sectionId) async {
    // 1. Validation & Auto-Focus Error Routing
    final failures = _validationFailures(sectionId: sectionId);
    if (failures.isNotEmpty) {
      _handleValidationFailures(failures);
      return false;
    }

    // 2. Start Loading State
    lastValidationError = null;
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
    return true;
  }

  ShopBrandingModel? validateAndGenerateFinalModel() {
    final failures = _validationFailures();
    if (failures.isNotEmpty) {
      _handleValidationFailures(failures);
      return null;
    }

    lastValidationError = null;
    return generateFinalModel();
  }

  ShopBrandingModel generateFinalModel() {
    brandingData = ShopBrandingModel(
      instagram: instaCtrl.text.trim(),
      facebook: fbCtrl.text.trim(),
      youtube: ytCtrl.text.trim(),
      website: webCtrl.text.trim(),
      whatsappChannel: waChannelCtrl.text.trim(),
      whatsappBusiness: waBizCtrl.text.trim(),
      supportEmail: emailCtrl.text.trim(),
      supportPhone: phoneCtrl.text.trim(),
    );
    notifyListeners();
    return brandingData;
  }

  List<_BrandingValidationFailure> _validationFailures({String? sectionId}) {
    final failures = <_BrandingValidationFailure>[];
    final includeSocial = sectionId == null || sectionId == 'social';
    final includeSupport = sectionId == null || sectionId == 'support';

    if (includeSocial) {
      _addFailure(
        failures,
        fieldLabel: 'Instagram Handle',
        sectionId: 'social',
        focusNode: instaFocus,
        error: BrandingValidators.validateOptionalSocialLink(instaCtrl.text),
        fallbackMessage: 'remove spaces from the handle or link.',
      );
      _addFailure(
        failures,
        fieldLabel: 'Facebook Page',
        sectionId: 'social',
        focusNode: fbFocus,
        error: BrandingValidators.validateOptionalSocialLink(fbCtrl.text),
        fallbackMessage: 'remove spaces from the page link.',
      );
      _addFailure(
        failures,
        fieldLabel: 'YouTube Channel',
        sectionId: 'social',
        focusNode: ytFocus,
        error: BrandingValidators.validateOptionalSocialLink(ytCtrl.text),
        fallbackMessage: 'remove spaces from the channel link.',
      );
      _addFailure(
        failures,
        fieldLabel: 'Official Website',
        sectionId: 'social',
        focusNode: webFocus,
        error: BrandingValidators.validateOptionalWebsite(webCtrl.text),
        fallbackMessage: 'enter a domain like lotusjewellers.com.',
      );
    }

    if (includeSupport) {
      _addFailure(
        failures,
        fieldLabel: 'WhatsApp Channel Link',
        sectionId: 'support',
        focusNode: waChannelFocus,
        error: BrandingValidators.validateOptionalWhatsAppChannel(
          waChannelCtrl.text,
        ),
        fallbackMessage: 'paste a link like whatsapp.com/channel/...',
      );
      _addFailure(
        failures,
        fieldLabel: 'WhatsApp Business API',
        sectionId: 'support',
        focusNode: waBizFocus,
        error: BrandingValidators.validateOptionalPhone(waBizCtrl.text),
        fallbackMessage: 'enter 10-15 digits only.',
      );
      _addFailure(
        failures,
        fieldLabel: 'Official Support Email',
        sectionId: 'support',
        focusNode: emailFocus,
        error: BrandingValidators.validateOptionalEmail(emailCtrl.text),
        fallbackMessage: 'enter an email like help@brand.com.',
      );
      _addFailure(
        failures,
        fieldLabel: 'Helpline / Toll Free',
        sectionId: 'support',
        focusNode: phoneFocus,
        error: BrandingValidators.validateOptionalPhone(phoneCtrl.text),
        fallbackMessage: 'enter 10-15 digits only.',
      );
    }

    return failures;
  }

  void _addFailure(
    List<_BrandingValidationFailure> failures, {
    required String fieldLabel,
    required String sectionId,
    required FocusNode focusNode,
    required String? error,
    required String fallbackMessage,
  }) {
    if (error == null) return;
    failures.add(
      _BrandingValidationFailure(
        sectionId: sectionId,
        focusNode: focusNode,
        message:
            '$fieldLabel: ${_friendlyValidationMessage(error, fallbackMessage)}',
      ),
    );
  }

  String _friendlyValidationMessage(String error, String fallbackMessage) {
    final normalized = error.toLowerCase();
    if (normalized.contains('website')) {
      return 'enter a domain like lotusjewellers.com.';
    }
    if (normalized.contains('whatsapp channel')) {
      return 'paste a link like whatsapp.com/channel/...';
    }
    if (normalized.contains('email')) {
      return 'enter an email like help@brand.com.';
    }
    if (normalized.contains('digit') || normalized.contains('number')) {
      return 'enter 10-15 digits only.';
    }
    if (normalized.contains('space')) {
      return 'remove spaces from the handle or link.';
    }
    return fallbackMessage;
  }

  void _handleValidationFailures(List<_BrandingValidationFailure> failures) {
    final invalidSections =
        failures.map((failure) => failure.sectionId).toSet();
    if (invalidSections.contains('social')) isSocialLocked = false;
    if (invalidSections.contains('support')) isSupportLocked = false;

    lastValidationError =
        failures.take(3).map((failure) => failure.message).join('\n');
    failures.first.focusNode.requestFocus();
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
        final digits = cleanValue.replaceAll(RegExp(r'\D'), '');
        final normalized = digits.length == 10
            ? '91$digits'
            : (digits.startsWith('91') ? digits : '91$digits');
        urlString = "https://wa.me/$normalized";
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
        AppLogger.debug('System Error: Could not launch $url');
      }
    } catch (e) {
      AppLogger.debug('Launch Error: $e');
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

class _BrandingValidationFailure {
  final String sectionId;
  final FocusNode focusNode;
  final String message;

  const _BrandingValidationFailure({
    required this.sectionId,
    required this.focusNode,
    required this.message,
  });
}
