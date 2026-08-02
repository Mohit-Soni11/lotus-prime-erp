import 'package:flutter/foundation.dart';

enum Environment {
  dev,
  staging,
  prod,
}

class EnvConfig {
  EnvConfig._();

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: '',
  );

  static Environment get currentEnv {
    switch (_envName.toLowerCase()) {
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      case 'dev':
      case 'development':
        return Environment.dev;
      default:
        return kReleaseMode ? Environment.prod : Environment.dev;
    }
  }

  static bool get isDebug => currentEnv == Environment.dev;
  static bool get isProduction => currentEnv == Environment.prod;
  static bool get enableVerboseLogs =>
      !kReleaseMode && currentEnv != Environment.prod;

  static bool get enableSqlLogging {
    if (kReleaseMode || isProduction) {
      return false;
    }
    return const bool.fromEnvironment(
      'APP_SQL_LOGGING',
      defaultValue: false,
    );
  }

  static String get apiUrl {
    switch (currentEnv) {
      case Environment.dev:
        return 'https://dev-api.lotuserp.com';
      case Environment.staging:
        return 'https://staging-api.lotuserp.com';
      case Environment.prod:
        return 'https://api.lotuserp.com';
    }
  }
}
