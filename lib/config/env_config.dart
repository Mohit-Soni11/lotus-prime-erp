// =============================================================================
// FILE        : env_config.dart
// LAYER       : Config
// DESCRIPTION : Environment configuration — dev/prod toggle + API keys
//
// ✅ UPDATED: Ab Google Gemini API use hoti hai — FREE & FAST!
//
// HOW TO GET FREE API KEY:
//   1. https://aistudio.google.com/app/apikey
//   2. "Create API Key" click karo — FREE hai!
//
// HOW TO RUN:
//   flutter run --dart-define=GEMINI_API_KEY=AIzaXXXXXXXXXXXXXXXXXXXXXXXX
//
// VS CODE — launch.json mein add karo:
//   "args": ["--dart-define=GEMINI_API_KEY=AIzaXXXXXXXXXXXXXXXXXXXXXXXX"]
//
// ANDROID STUDIO — Run > Edit Configurations > Additional run args:
//   --dart-define=GEMINI_API_KEY=AIzaXXXXXXXXXXXXXXXXXXXXXXXX
//
// FREE LIMITS (Gemini 1.5 Flash):
//   ✅ 15 requests/minute
//   ✅ 1500 requests/day
//   ✅ 1 million tokens/minute
//   ✅ Cost = ZERO Rs.!
// =============================================================================

enum Environment { dev, prod }

class EnvConfig {
  // ── Current Environment ───────────────────────────────────────────────────
  static const Environment currentEnv = Environment.dev;

  // ── Debug Mode ────────────────────────────────────────────────────────────
  static bool get isDebug => currentEnv == Environment.dev;

  // ── Future API URLs (Cloud Sync ke liye) ──────────────────────────────────
  static String get apiUrl {
    if (currentEnv == Environment.dev) {
      return 'https://dev-api.lotuserp.com';
    }
    return 'https://api.lotuserp.com';
  }

  // ── Google Gemini API Key (FREE!) ─────────────────────────────────────────
  // Key lene ke liye: https://aistudio.google.com/app/apikey
  // Run: flutter run --dart-define=GEMINI_API_KEY=AIzaXXXXXX
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Key valid hai ya nahi
  static bool get hasValidGeminiKey =>
      geminiApiKey.isNotEmpty && geminiApiKey.startsWith('AIza');
}
