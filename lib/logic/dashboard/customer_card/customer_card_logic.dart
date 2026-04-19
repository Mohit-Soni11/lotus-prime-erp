import 'dart:async';
import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/dashboard/customer_stats_model.dart';

class CustomerCardLogic {
  // Dependency Injection (Testable Code)
  final AppDatabase _db;
  
  CustomerCardLogic({AppDatabase? db}) : _db = db ?? AppDatabase();

  final StreamController<CustomerStatsModel> _controller = StreamController<CustomerStatsModel>();
  Stream<CustomerStatsModel> get statsStream => _controller.stream;
  
  StreamSubscription? _dbSubscription;

  void init() {
    _startLiveMonitoring();
  }

  void _startLiveMonitoring() {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // ✅ OPTIMIZED QUERY: Count only rows created today
      final countExpr = _db.customers.id.count();
      
      final query = _db.selectOnly(_db.customers)
        ..addColumns([countExpr])
        ..where(_db.customers.createdAt.isBiggerOrEqualValue(todayStart));

      // ✅ LIVE WATCHER
      _dbSubscription = query.watch().listen((List<TypedResult> results) {
        if (_controller.isClosed) return;

        if (results.isNotEmpty) {
          final count = results.first.read(countExpr) ?? 0;
          
          // Logic: > 5 customers in a day is considered "High Growth"
          final bool isHighGrowth = count > 5;
          final String status = isHighGrowth ? "High Growth 🚀" : "Stable";

          _controller.add(CustomerStatsModel(
            count: count.toString().padLeft(2, '0'), // 01, 05 format
            status: status,
            isHighGrowth: isHighGrowth,
            syncTime: "${now.hour}:${now.minute}",
          ));
        } else {
          _controller.add(CustomerStatsModel.empty());
        }
      }, onError: (e) {
        print("🔴 CustomerLogic Error: $e");
      });
    } catch (e) {
      print("🔴 Init Error: $e");
    }
  }

  void dispose() {
    _dbSubscription?.cancel();
    _controller.close();
  }

  CustomerStatsModel get initialData => CustomerStatsModel.empty();
}