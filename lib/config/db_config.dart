class DbConfig {
  // Database Name
  static const String dbName = "lotus_erp_pro.sqlite";
  
  // Database Version (Migration ke liye zaroori)
  static const int dbVersion = 1;
  
  // Future Proof: Log SQL Statements in Debug Mode?
  static const bool logStatements = true;
  
  // Performance Tweaks (Defaults)
  static const int timeoutSeconds = 5;
}