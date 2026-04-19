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
  static const String pageSubtitle = "Manage social identity, community links, and support channels";

  // --- Card Titles ---
  static const String cardSocialTitle = "Social Media Presence";
  static const String cardSupportTitle = "Support & Community";

  // --- Toggle & Action Identifiers ---
  static const String toggleSocial = "Social Links";
  static const String toggleSupport = "Support Channels";

  // --- Button States ---
  static const String btnSave = "Save";
  static const String btnSaving = "Saving...";
  static const String btnLocked = "Locked";

  // --- Social Field Labels ---
  static const String lblInstagram = "Instagram Handle";
  static const String lblFacebook = "Facebook Page";
  static const String lblYoutube = "YouTube Channel";
  static const String lblWebsite = "Official Website";

  // --- Social Field Hints ---
  static const String hntInstagram = "@brandname";
  static const String hntFacebook = "facebook.com/brand";
  static const String hntYoutube = "youtube.com/@brand";
  static const String hntWebsite = "www.yourbrand.com";

  // --- Support Field Labels ---
  static const String lblWaChannel = "WhatsApp Channel Link";
  static const String lblWaBusiness = "WhatsApp Business API";
  static const String lblSupportEmail = "Official Support Email";
  static const String lblSupportPhone = "Helpline / Toll Free";

  // --- Support Field Hints ---
  static const String hntWaChannel = "whatsapp.com/channel/...";
  static const String hntWaBusiness = "10 Digit Mobile No.";
  static const String hntSupportEmail = "help@brand.com";
  static const String hntSupportPhone = "Enter Phone Number";
}