// location: lib/logic/dashboard/models/bill_stats_model.dart

class BillStatsModel {
  final String count;
  final String totalRevenue;

  const BillStatsModel({
    required this.count,
    required this.totalRevenue,
  });

  factory BillStatsModel.loading() => 
      const BillStatsModel(count: "--", totalRevenue: "Loading...");

  factory BillStatsModel.zero() => 
      const BillStatsModel(count: "0", totalRevenue: "₹ 0.00");
}