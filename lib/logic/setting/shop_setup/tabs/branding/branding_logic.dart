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
  bool isChannelsLocked = true;

  // 🚀 UPGRADE: Changed to String to perfectly match UI requirements
  String? loadingSection;
  String? lastValidationError;

  // 🚀 UPGRADE: Added Missing GlobalKeys to prevent UI runtime crashes
  final GlobalKey<FormState> channelsKey = GlobalKey<FormState>();

  final TextEditingController webCtrl = TextEditingController();
  final TextEditingController instaCtrl = TextEditingController();
  final TextEditingController fbCtrl = TextEditingController();
  final TextEditingController ytCtrl = TextEditingController();
  final TextEditingController waChannelCtrl = TextEditingController();

  final FocusNode webFocus = FocusNode();
  final FocusNode instaFocus = FocusNode();
  final FocusNode fbFocus = FocusNode();
  final FocusNode ytFocus = FocusNode();
  final FocusNode waChannelFocus = FocusNode();

  // --- SMART INITIALIZATION ---
  void init(ShopProfileModel? basicInfoData) {
    // Website branding is intentionally independent from Basic Info contacts.
  }

  // --- UI HELPER METHODS ---

  /// Checks if a specific section is currently locked.
  bool isSectionLocked(String sectionId) {
    return isChannelsLocked;
  }

  /// Unlocks a section and returns the first FocusNode to auto-focus the keyboard.
  FocusNode? unlockSection(String sectionId) {
    isChannelsLocked = false;
    notifyListeners();
    return webFocus;
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
    brandingData = generateFinalModel(notify: false);
    isChannelsLocked = true;

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

  ShopBrandingModel generateFinalModel({bool notify = true}) {
    brandingData = ShopBrandingModel(
      website: webCtrl.text.trim(),
      instagram: instaCtrl.text.trim(),
      facebook: fbCtrl.text.trim(),
      youtube: ytCtrl.text.trim(),
      whatsappChannel: waChannelCtrl.text.trim(),
    );
    if (notify) notifyListeners();
    return brandingData;
  }

  List<_BrandingValidationFailure> _validationFailures({String? sectionId}) {
    final failures = <_BrandingValidationFailure>[];
    _addFailure(
      failures,
      fieldLabel: 'Official Website',
      sectionId: 'website',
      focusNode: webFocus,
      error: BrandingValidators.validateOptionalWebsite(webCtrl.text),
      fallbackMessage: 'enter a domain like lotusjewellers.com.',
    );
    _addFailure(
      failures,
      fieldLabel: 'Instagram',
      sectionId: 'channels',
      focusNode: instaFocus,
      error: BrandingValidators.validateOptionalHandleOrUrl(instaCtrl.text),
      fallbackMessage: 'enter a handle or link without spaces.',
    );
    _addFailure(
      failures,
      fieldLabel: 'Facebook',
      sectionId: 'channels',
      focusNode: fbFocus,
      error: BrandingValidators.validateOptionalHandleOrUrl(fbCtrl.text),
      fallbackMessage: 'enter a page link without spaces.',
    );
    _addFailure(
      failures,
      fieldLabel: 'YouTube',
      sectionId: 'channels',
      focusNode: ytFocus,
      error: BrandingValidators.validateOptionalHandleOrUrl(ytCtrl.text),
      fallbackMessage: 'enter a channel link without spaces.',
    );
    _addFailure(
      failures,
      fieldLabel: 'WhatsApp Channel',
      sectionId: 'channels',
      focusNode: waChannelFocus,
      error: BrandingValidators.validateOptionalWhatsAppChannel(
        waChannelCtrl.text,
      ),
      fallbackMessage: 'paste a link like whatsapp.com/channel/...',
    );

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
    if (normalized.contains('spaces')) {
      return 'remove spaces from the handle or link.';
    }
    return fallbackMessage;
  }

  void _handleValidationFailures(List<_BrandingValidationFailure> failures) {
    final invalidSections =
        failures.map((failure) => failure.sectionId).toSet();
    if (invalidSections.contains('website') ||
        invalidSections.contains('channels')) {
      isChannelsLocked = false;
    }

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
      case SocialPlatform.website:
        urlString =
            cleanValue.startsWith('http') ? cleanValue : "https://$cleanValue";
        break;
      case SocialPlatform.instagram:
        urlString = cleanValue.startsWith('http')
            ? cleanValue
            : "https://instagram.com/${cleanValue.replaceAll('@', '')}";
        break;
      case SocialPlatform.facebook:
        urlString = cleanValue.startsWith('http')
            ? cleanValue
            : "https://facebook.com/$cleanValue";
        break;
      case SocialPlatform.youtube:
        urlString = cleanValue.startsWith('http')
            ? cleanValue
            : "https://youtube.com/$cleanValue";
        break;
      case SocialPlatform.whatsappChannel:
        urlString =
            cleanValue.startsWith('http') ? cleanValue : "https://$cleanValue";
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
    webCtrl.dispose();
    instaCtrl.dispose();
    fbCtrl.dispose();
    ytCtrl.dispose();
    waChannelCtrl.dispose();
    webFocus.dispose();
    instaFocus.dispose();
    fbFocus.dispose();
    ytFocus.dispose();
    waChannelFocus.dispose();

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
