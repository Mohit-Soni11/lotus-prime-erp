enum Environment { dev, prod }

class EnvConfig {
  // Current Environment Setting
  static const Environment currentEnv = Environment.dev;

  // Debug Mode Logic
  static bool get isDebug {
    return currentEnv == Environment.dev;
  }
  
  // Future Proofing: API URLs (Jab hum Cloud Sync add karenge)
  static String get apiUrl {
    if (currentEnv == Environment.dev) {
      return "https://dev-api.lotuserp.com";
    }
    return "https://api.lotuserp.com";
  }
}