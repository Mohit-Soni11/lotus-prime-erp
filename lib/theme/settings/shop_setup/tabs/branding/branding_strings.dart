// -----------------------------------------------------------------------------
// FILE: branding_strings.dart
// TYPE: Theme Layer / Strings Constants
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized string constants for the Branding tab to eliminate
//              hardcoded text and ensure a clean, maintainable UI architecture.
// -----------------------------------------------------------------------------

class BrandingStrings {
  // Private constructor to prevent instantiation
  BrandingStrings._();

  // --- Page Header ---
  static const String pageTitle = "Digital Brand Assets";
  static const String pageSubtitle =
      "Manage public brand channels for invoice footer and customer marketing";

  // --- Card Titles ---
  static const String cardChannelsTitle = "Brand Channels";

  // --- Toggle & Action Identifiers ---
  static const String toggleChannels = "Brand Channels";

  // --- Button States ---
  static const String btnSave = "Save";
  static const String btnSaving = "Saving...";
  static const String btnLocked = "Locked";

  static const String lblWebsite = "Official Website";
  static const String lblInstagram = "Instagram";
  static const String lblFacebook = "Facebook";
  static const String lblYoutube = "YouTube";
  static const String lblWhatsappChannel = "WhatsApp Channel";

  static const String hntWebsite = "www.yourbrand.com";
  static const String hntInstagram = "@yourbrand or instagram.com/yourbrand";
  static const String hntFacebook = "facebook.com/yourbrand";
  static const String hntYoutube = "youtube.com/@yourbrand";
  static const String hntWhatsappChannel = "whatsapp.com/channel/...";
}
