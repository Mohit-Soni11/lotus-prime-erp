class CustomerStatsModel {
  final String count; // e.g. "12"
  final String status; // "High Growth" or "Stable"
  final bool isHighGrowth; // Logic ke liye flag
  final String syncTime;

  const CustomerStatsModel({
    required this.count,
    required this.status,
    required this.isHighGrowth,
    required this.syncTime,
  });

  // Default Empty State
  factory CustomerStatsModel.empty() {
    return const CustomerStatsModel(
      count: "--",
      status: "Syncing...",
      isHighGrowth: false,
      syncTime: "",
    );
  }
}
