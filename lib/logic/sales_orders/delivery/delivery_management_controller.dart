// =============================================================================
// FILE        : delivery_management_controller.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Logic / Controller
// DESCRIPTION : Master controller for the Delivery Management screen.
//               Manages 4 tabs, search, filtering, side panel, and
//               the full Order-to-Cash pipeline actions.
//
// CHANGELOG:
//   v1 — Initial controller for Delivery Management module.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/sales_orders/delivery/delivery_model.dart';
import '../../../models/sales_orders/delivery/delivery_enums.dart';
import '../../../repositories/sales_orders/delivery/delivery_repository.dart';
import '../../../core/logging/app_logger.dart';

class DeliveryManagementController extends ChangeNotifier {
  final DeliveryRepository _repo;

  DeliveryManagementController({DeliveryRepository? repo})
      : _repo = repo ?? DeliveryRepository() {
    _init();
    searchCtrl.addListener(_onSearchChanged);
  }

  // ── STATE ──────────────────────────────────────────────────────────────────

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  DeliveryTab _activeTab = DeliveryTab.activeOrders;
  DeliverySummaryModel _summary = DeliverySummaryModel.empty();
  DeliveryOrderUiModel? _selectedOrder;
  DeliverySortBy _sortBy = DeliverySortBy.deliveryDateAsc;

  List<DeliveryOrderUiModel> _activeOrders = [];
  List<DeliveryOrderUiModel> _actionRequired = [];
  List<DeliveryOrderUiModel> _dueLedger = [];
  List<DeliveryOrderUiModel> _completedBills = [];

  // Partial delivery: selected item IDs
  final Set<int> _selectedItemIds = {};

  // ── CONTROLLERS ────────────────────────────────────────────────────────────
  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController finalAmtCtrl = TextEditingController();
  final TextEditingController paidNowCtrl = TextEditingController();

  Timer? _searchDebounce;

  // ── GETTERS ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  DeliveryTab get activeTab => _activeTab;
  DeliverySummaryModel get summary => _summary;
  DeliveryOrderUiModel? get selectedOrder => _selectedOrder;
  DeliverySortBy get sortBy => _sortBy;
  Set<int> get selectedItemIds => _selectedItemIds;

  List<DeliveryOrderUiModel> get currentList {
    switch (_activeTab) {
      case DeliveryTab.activeOrders:
        return _sortedList(_activeOrders);
      case DeliveryTab.actionRequired:
        return _sortedList(_actionRequired);
      case DeliveryTab.dueLedger:
        return _sortedList(_dueLedger);
      case DeliveryTab.completedBills:
        return _sortedList(_completedBills);
    }
  }

  int get currentListCount => currentList.length;

  bool get hasSelectedItems => _selectedItemIds.isNotEmpty;

  // ── INIT ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await refreshAll();
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([
        _loadSummary(),
        _loadActiveOrders(),
        _loadActionRequired(),
        _loadDueLedger(),
        _loadCompletedBills(),
      ]);
    } catch (e) {
      _errorMessage = 'Data load karne mein error aaya: $e';
      AppLogger.debug('🔴 DeliveryController.refreshAll: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSummary() async => _summary = await _repo.getSummary();
  Future<void> _loadActiveOrders() async =>
      _activeOrders = await _repo.getActiveOrders(
          search:
              searchCtrl.text.trim().isEmpty ? null : searchCtrl.text.trim());
  Future<void> _loadActionRequired() async =>
      _actionRequired = await _repo.getActionRequired();
  Future<void> _loadDueLedger() async => _dueLedger = await _repo.getDueLedger(
      search: searchCtrl.text.trim().isEmpty ? null : searchCtrl.text.trim());
  Future<void> _loadCompletedBills() async =>
      _completedBills = await _repo.getCompletedBills(
          search:
              searchCtrl.text.trim().isEmpty ? null : searchCtrl.text.trim());

  // ── TAB SWITCHING ──────────────────────────────────────────────────────────

  void switchTab(DeliveryTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _selectedOrder = null;
    _selectedItemIds.clear();
    notifyListeners();
    _refreshCurrentTab();
  }

  Future<void> _refreshCurrentTab() async {
    switch (_activeTab) {
      case DeliveryTab.activeOrders:
        await _loadActiveOrders();
      case DeliveryTab.actionRequired:
        await _loadActionRequired();
      case DeliveryTab.dueLedger:
        await _loadDueLedger();
      case DeliveryTab.completedBills:
        await _loadCompletedBills();
    }
    await _loadSummary();
    notifyListeners();
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _refreshCurrentTab();
    });
  }

  void clearSearch() {
    searchCtrl.clear();
  }

  // ── SORT ───────────────────────────────────────────────────────────────────

  void setSortBy(DeliverySortBy sort) {
    _sortBy = sort;
    notifyListeners();
  }

  List<DeliveryOrderUiModel> _sortedList(List<DeliveryOrderUiModel> list) {
    final sorted = List<DeliveryOrderUiModel>.from(list);
    switch (_sortBy) {
      case DeliverySortBy.deliveryDateAsc:
        sorted.sort((a, b) {
          if (a.expectedDeliveryDate == null) return 1;
          if (b.expectedDeliveryDate == null) return -1;
          return a.expectedDeliveryDate!.compareTo(b.expectedDeliveryDate!);
        });
      case DeliverySortBy.deliveryDateDesc:
        sorted.sort((a, b) {
          if (a.expectedDeliveryDate == null) return 1;
          if (b.expectedDeliveryDate == null) return -1;
          return b.expectedDeliveryDate!.compareTo(a.expectedDeliveryDate!);
        });
      case DeliverySortBy.customerName:
        sorted.sort((a, b) => a.customerName.compareTo(b.customerName));
      case DeliverySortBy.statusPipeline:
        const order = {'BOOKED': 0, 'IN_MAKING': 1, 'READY': 2, 'DELIVERED': 3};
        sorted.sort((a, b) => (order[a.status.value] ?? 99)
            .compareTo(order[b.status.value] ?? 99));
    }
    return sorted;
  }

  // ── SELECTION ──────────────────────────────────────────────────────────────

  void selectOrder(DeliveryOrderUiModel order) {
    _selectedOrder = order;
    _selectedItemIds.clear();
    finalAmtCtrl.clear();
    paidNowCtrl.clear();
    notifyListeners();
  }

  void clearSelection() {
    _selectedOrder = null;
    _selectedItemIds.clear();
    notifyListeners();
  }

  // Partial delivery item toggle
  void toggleItemSelection(int itemId) {
    if (_selectedItemIds.contains(itemId)) {
      _selectedItemIds.remove(itemId);
    } else {
      _selectedItemIds.add(itemId);
    }
    notifyListeners();
  }

  void selectAllReadyItems() {
    if (_selectedOrder == null) return;
    for (final item in _selectedOrder!.items) {
      if (item.itemStatus == DeliveryItemStatus.ready) {
        _selectedItemIds.add(item.id);
      }
    }
    notifyListeners();
  }

  // ── STATUS TRANSITIONS ─────────────────────────────────────────────────────

  Future<bool> markInMaking(int orderId,
      {int? karigarId, String? karigarName}) async {
    return _runAction(() async {
      await _repo.markInMaking(orderId,
          karigarId: karigarId, karigarName: karigarName);
      await refreshAll();
    });
  }

  Future<bool> markReady(int orderId) async {
    return _runAction(() async {
      await _repo.markReady(orderId);
      await refreshAll();
    });
  }

  Future<bool> markItemReady(int itemId) async {
    return _runAction(() async {
      await _repo.markItemReady(itemId);
      // Reload selected order's items
      if (_selectedOrder != null) {
        final items = await _repo.getItemsForOrder(_selectedOrder!.id);
        _selectedOrder = DeliveryOrderUiModel(
          id: _selectedOrder!.id,
          deliveryNo: _selectedOrder!.deliveryNo,
          customerId: _selectedOrder!.customerId,
          customerName: _selectedOrder!.customerName,
          customerMobile: _selectedOrder!.customerMobile,
          itemName: _selectedOrder!.itemName,
          metalType: _selectedOrder!.metalType,
          purity: _selectedOrder!.purity,
          approxWeight: _selectedOrder!.approxWeight,
          lockedRate: _selectedOrder!.lockedRate,
          status: _selectedOrder!.status,
          paymentStatus: _selectedOrder!.paymentStatus,
          advancePaid: _selectedOrder!.advancePaid,
          totalAmount: _selectedOrder!.totalAmount,
          dueAmount: _selectedOrder!.dueAmount,
          expectedDeliveryDate: _selectedOrder!.expectedDeliveryDate,
          actualDeliveryDate: _selectedOrder!.actualDeliveryDate,
          imagePath: _selectedOrder!.imagePath,
          notes: _selectedOrder!.notes,
          karigarName: _selectedOrder!.karigarName,
          linkedBillNo: _selectedOrder!.linkedBillNo,
          items: items,
          createdAt: _selectedOrder!.createdAt,
          updatedAt: _selectedOrder!.updatedAt,
        );
      }
      await _loadSummary();
    });
  }

  // ── DELIVER ────────────────────────────────────────────────────────────────

  /// One-click full delivery
  Future<bool> deliverOrder({
    required int orderId,
    required double finalAmount,
    required double paidNow,
    required double advancePaid,
    String paymentMode = 'CASH',
    String? linkedBillNo,
    int? linkedBillId,
  }) async {
    return _runAction(() async {
      await _repo.deliverOrder(
        orderId: orderId,
        finalAmount: finalAmount,
        paidNow: paidNow,
        advancePaid: advancePaid,
        paymentMode: paymentMode,
        linkedBillNo: linkedBillNo,
        linkedBillId: linkedBillId,
      );
      _selectedOrder = null;
      _selectedItemIds.clear();
      await refreshAll();
    });
  }

  /// Partial delivery — selected items only
  Future<bool> partialDeliver({
    required int orderId,
    required double finalAmount,
    required double paidNow,
    required double advancePaid,
    String? linkedBillNo,
    int? linkedBillId,
  }) async {
    if (_selectedItemIds.isEmpty) return false;
    return _runAction(() async {
      await _repo.partialDeliver(
        orderId: orderId,
        deliveredItemIds: _selectedItemIds.toList(),
        finalAmount: finalAmount,
        paidNow: paidNow,
        advancePaid: advancePaid,
        linkedBillNo: linkedBillNo,
        linkedBillId: linkedBillId,
      );
      _selectedOrder = null;
      _selectedItemIds.clear();
      await refreshAll();
    });
  }

  /// Collect due payment
  Future<bool> collectDue({
    required int orderId,
    required double amountCollected,
  }) async {
    return _runAction(() async {
      await _repo.collectDue(
          orderId: orderId, amountCollected: amountCollected);
      _selectedOrder = null;
      await refreshAll();
    });
  }

  Future<bool> cancelOrder(int orderId) async {
    return _runAction(() async {
      await _repo.cancelOrder(orderId);
      _selectedOrder = null;
      await refreshAll();
    });
  }

  // ── HELPER: run action with loading state ──────────────────────────────────
  Future<bool> _runAction(Future<void> Function() action) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = 'Action failed: $e';
      AppLogger.debug('🔴 DeliveryController._runAction: $e');
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── COMPUTED ───────────────────────────────────────────────────────────────

  double get finalAmountValue =>
      double.tryParse(finalAmtCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0.0;

  double get paidNowValue =>
      double.tryParse(paidNowCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0.0;

  double get dueAfterDelivery {
    if (_selectedOrder == null) return 0.0;
    return (finalAmountValue - paidNowValue - _selectedOrder!.advancePaid)
        .clamp(0.0, double.infinity);
  }

  // ── DISPOSE ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    searchCtrl.dispose();
    finalAmtCtrl.dispose();
    paidNowCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
}
