class AppConfig {
  AppConfig._();

  static const String appName = "Lotus ERP";
  static const String appTagline = "Professional Jewellery Operations Platform";
  static const String appVersion = "1.1.0";
  static const String buildNumber = "1";

  static const String defaultRole = "OWNER";
  static const String defaultCurrencySymbol = "₹";

  static const int mobileNumberLength = 10;
  static const double maxGSTPercentage = 28.0;

  static String get semanticVersion => "$appVersion+$buildNumber";
}
