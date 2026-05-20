// -----------------------------------------------------------------------------
// FILE: branding_enums.dart
// TYPE: Core Foundation / Enums
// AUTHOR: Senior System Architect
// DESCRIPTION: Strongly typed enumerations to replace magic strings, ensuring
//              compile-time safety and preventing typo-related silent bugs.
// -----------------------------------------------------------------------------

/// Represents the different configuration sections in the Branding Tab.
enum BrandingSection {
  social,
  support,
}

/// Represents the supported social media and communication platforms.
/// Used strictly for URL launching and UI icon mapping.
enum SocialPlatform {
  instagram,
  facebook,
  youtube,
  website,
  whatsapp,
  email,
  phone;

  /// Helper method to return the exact string needed for our switch cases
  /// or API payloads, eliminating human spelling errors.
  String get value {
    switch (this) {
      case SocialPlatform.instagram:
        return 'instagram';
      case SocialPlatform.facebook:
        return 'facebook';
      case SocialPlatform.youtube:
        return 'youtube';
      case SocialPlatform.website:
        return 'website';
      case SocialPlatform.whatsapp:
        return 'whatsapp';
      case SocialPlatform.email:
        return 'email';
      case SocialPlatform.phone:
        return 'phone';
    }
  }

  /// 🚀 UPGRADE: Safe String-to-Enum Parser
  /// Fixes the compile-time crash when UI passes a string platformType.
  /// Converts string dynamically into strict Enum.
  static SocialPlatform fromString(String type) {
    return SocialPlatform.values.firstWhere(
      (e) => e.value.toLowerCase() == type.toLowerCase(),
      orElse: () =>
          SocialPlatform.website, // Safe fallback to prevent runtime crashes
    );
  }
}
