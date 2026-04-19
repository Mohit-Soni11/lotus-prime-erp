class PendingStatsModel {
  final String totalCount;  // Main Big Number
  final String goldCount;   // "02"
  final String silverCount; // "03"
  final String syncTime;

  const PendingStatsModel({
    required this.totalCount,
    required this.goldCount,
    required this.silverCount,
    required this.syncTime,
  });

  // Default Empty State
  factory PendingStatsModel.empty() {
    return const PendingStatsModel(
      totalCount: "--",
      goldCount: "0",
      silverCount: "0",
      syncTime: "",
    );
  }
}