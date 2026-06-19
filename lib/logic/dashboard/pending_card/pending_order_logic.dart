import 'dart:async';
// ✅ FIXED: Removed unused 'drift' import to fix Yellow Warning
import 'package:lotus_erp/database/db/app_database.dart';
// ✅ FIXED: Ensure this path matches where you kept the model
import '../../../models/dashboard/pending_stats_model.dart';
import '../../../core/logging/app_logger.dart';

class PendingOrderLogic {
  final AppDatabase _db;

  // Dependency Injection
  PendingOrderLogic({AppDatabase? db}) : _db = db ?? AppDatabase();

  final StreamController<PendingStatsModel> _controller =
      StreamController<PendingStatsModel>();
  Stream<PendingStatsModel> get statsStream => _controller.stream;

  StreamSubscription? _dbSubscription;

  void init() {
    _startLiveMonitoring();
  }

  void _startLiveMonitoring() {
    try {
      final now = DateTime.now();

      // ✅ QUERY: Sirf 'PENDING' status wale orders fetch karo
      final query = _db.select(_db.salesOrders)
        ..where((tbl) => tbl.status.equals('PENDING'));

      // ✅ LIVE WATCHER
      // Note: Agar 'dynamic' se issue aaye to 'SalesOrder' (generated class) use karna
      _dbSubscription = query.watch().listen((List<dynamic> orders) {
        if (_controller.isClosed) return;

        final int total = orders.length;

        // --- CALCULATION LOGIC ---
        // Filter Gold vs Silver based on 'metalType' column
        final int goldCount = orders.where((o) => o.metalType == 'GOLD').length;
        final int silverCount =
            orders.where((o) => o.metalType == 'SILVER').length;

        _controller.add(PendingStatsModel(
          totalCount: total.toString().padLeft(2, '0'),
          goldCount: goldCount.toString().padLeft(2, '0'),
          silverCount: silverCount.toString().padLeft(2, '0'),
          syncTime: "${now.hour}:${now.minute}",
        ));
      }, onError: (e) {
        AppLogger.error("PendingLogic Error: $e");
        if (!_controller.isClosed) _controller.add(PendingStatsModel.empty());
      });
    } catch (e) {
      AppLogger.error("PendingOrderLogic Init Error: $e");
    }
  }

  void dispose() {
    _dbSubscription?.cancel();
    _controller.close();
  }

  PendingStatsModel get initialData => PendingStatsModel.empty();
}
