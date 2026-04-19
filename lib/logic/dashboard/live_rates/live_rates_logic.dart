import 'dart:async';
import '../../../models/live_rates/live_rates_model.dart';
import '../../../repositories/live_rates/live_rates_repository.dart';

// ============================================================
// 🧠 LIVE RATES LOGIC
// UI aur Repository ke beech ka bridge
// Expand/Collapse state bhi yahan manage hoga
// ============================================================

class LiveRatesLogic {
  final LiveRatesRepository _repository = LiveRatesRepository();

  // UI State
  bool isExpanded = false;

  // Stream passthrough
  Stream<LiveRatesModel> get ratesStream => _repository.ratesStream;
  LiveRatesModel get initialData => LiveRatesModel.loading;

  void init() {
    _repository.init();
  }

  void toggleExpand() {
    isExpanded = !isExpanded;
  }

  void dispose() {
    _repository.dispose();
  }
}