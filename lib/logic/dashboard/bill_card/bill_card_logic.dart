import 'dart:async';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/dashboard/bill_stats_model.dart';

class BillCardLogic {
  // ❌ Singleton Removed: Har widget ka apna dimag (logic) hona chahiye

  // Dependency Injection (Testable)
  final AppDatabase _db;
  BillCardLogic({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ✅ Simple Controller (Broadcast nahi chahiye kyunki 1-to-1 connection hai)
  final StreamController<BillStatsModel> _controller =
      StreamController<BillStatsModel>();

  Stream<BillStatsModel> get statsStream => _controller.stream;
  StreamSubscription? _dbSubscription;

  void init() {
    _startOptimizedMonitoring();
  }

  void _startOptimizedMonitoring() {
    try {
      final now = DateTime.now();
      // Drift helpers for optimized date query
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // ✅ Expressions for faster SQL
      final countExpr = _db.bills.id.count();
      final sumExpr = _db.bills.finalAmount.sum();

      final query = _db.selectOnly(_db.bills)
        ..addColumns([countExpr, sumExpr])
        ..where(_db.bills.billDate.isBetweenValues(todayStart, todayEnd))
        ..where(_db.bills.status.equals('ACTIVE'));

      // ✅ Live Watcher
      _dbSubscription = query.watch().listen((List<TypedResult> results) {
        if (_controller.isClosed) return;

        if (results.isNotEmpty) {
          final row = results.first;
          final int totalCount = row.read(countExpr) ?? 0;
          final double totalAmount = row.read(sumExpr) ?? 0.0;

          // Formatting: ₹ 1,200.50
          final formattedRevenue = NumberFormat.currency(
                  locale: 'en_IN', symbol: '₹ ', decimalDigits: 2)
              .format(totalAmount);

          _controller.add(BillStatsModel(
            count: totalCount
                .toString()
                .padLeft(2, '0'), // 01, 05 format looks better
            totalRevenue: formattedRevenue,
          ));
        } else {
          _controller.add(BillStatsModel.zero());
        }
      }, onError: (e) {
        print("❌ DB ERROR (BillLogic): $e");
        if (!_controller.isClosed) _controller.add(BillStatsModel.zero());
      });
    } catch (e) {
      print("❌ INIT ERROR: $e");
    }
  }

  // ✅ 100% Safe Disposal
  void dispose() {
    _dbSubscription?.cancel();
    _controller.close(); // Ab safe hai kyunki ye instance destroy hone wala hai
  }

  BillStatsModel get initialData => BillStatsModel.loading();
}
