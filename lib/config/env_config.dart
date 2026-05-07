// =============================================================================
// FILE        : env_config.dart
// LAYER       : Config
// DESCRIPTION : Environment configuration — dev/prod toggle + API keys
//
// ✅ FIX: Gemini API key yahan se manage hota hai.
//
// HOW TO RUN (Best Practice):
//   flutter run --dart-define-from-file=.env
//
// VS CODE — launch.json mein add karo:
//   "args": ["--dart-define-from-file=.env"]
//
// ANDROID STUDIO — Run > Edit Configurations > Additional run args mein add:
//   --dart-define-from-file=.env
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

  // ── ✅ Gemini API Key (SmartInputService ke liye) ─────────────────────────
  // Reads from .env file or command line arguments
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Empty string = key nahi mili
  );

  // Key valid hai ya nahi check karo (Gemini keys start with 'AIza')
  static bool get hasValidGeminiKey =>
      geminiApiKey.isNotEmpty && geminiApiKey.startsWith('AIza');
}
