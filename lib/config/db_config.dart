class DbConfig {
  DbConfig._();

  static const String dbName = "lotus_erp_pro.sqlite";
  static const int schemaVersion = 50;
  static const bool enableWal = true;
  static const Duration busyTimeout = Duration(seconds: 5);
}
