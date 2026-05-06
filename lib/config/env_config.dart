// =============================================================================
// FILE        : env_config.dart
// LAYER       : Config
// DESCRIPTION : Environment configuration — dev/prod toggle + API keys
//
// ✅ FIX: Anthropic API key yahan se manage hota hai.
//
// HOW TO RUN:
//   flutter run --dart-define=ANTHROPIC_KEY=sk-ant-xxxxxxxx
//
// VS CODE — launch.json mein add karo:
//   "args": ["--dart-define=ANTHROPIC_KEY=sk-ant-xxxxxxxx"]
//
// ANDROID STUDIO — Run > Edit Configurations > Additional run args mein add:
//   --dart-define=ANTHROPIC_KEY=sk-ant-xxxxxxxx
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

  // ── ✅ Anthropic API Key (SmartInputService ke liye) ──────────────────────
  // Run command: flutter run --dart-define=ANTHROPIC_KEY=sk-ant-xxxxxxxx
  static const String anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_KEY',
    defaultValue: '', // Empty string = key nahi mili
  );

  // Key valid hai ya nahi check karo
  static bool get hasValidAnthropicKey =>
      anthropicApiKey.isNotEmpty && anthropicApiKey.startsWith('sk-ant-');
}
