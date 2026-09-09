part of 'booking_advance_controller.dart';

extension BookingAdvanceControllerEntryOperations on BookingAdvanceController {
  void _toggleBookingType(BookingType t) {
    bookingType = t;
    if (t == BookingType.open) lockedRateCtrl.clear();
    _emitChanged();
  }

  void _setDeliveryDate(DateTime? d) {
    deliveryDate = d;
    _emitChanged();
  }

  void _addBookingItem() {
    final item = BookingItemModel();
    item.addListener(_onChildChanged);
    bookingItems.add(item);
    activeItemIndex = bookingItems.length - 1;
    _syncSmartRatePreference();
    _emitChanged();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (tableScrollCtrl.hasClients) {
        tableScrollCtrl.animateTo(
          tableScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      item.firstFieldFocus.requestFocus();
    });
  }

  void _removeBookingItem(int index) {
    if (index < 0 || index >= bookingItems.length) return;
    bookingItems[index].removeListener(_onChildChanged);
    bookingItems[index].dispose();
    bookingItems.removeAt(index);
    if (activeItemIndex >= bookingItems.length) {
      activeItemIndex = bookingItems.length - 1;
    }
    _syncSmartRatePreference();
    _emitChanged();
  }

  void _removeActiveItem() {
    if (activeItemIndex != -1 && bookingItems.isNotEmpty) {
      final idx = activeItemIndex;
      _removeBookingItem(idx);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (bookingItems.isNotEmpty) {
          final fi = idx > 0 ? idx - 1 : 0;
          bookingItems[fi].firstFieldFocus.requestFocus();
          activeItemIndex = fi;
        }
      });
    }
  }

  void _addScrapItem() {
    final item = BookingScrapModel();
    item.addListener(_onChildChanged);
    scrapItems.add(item);
    _syncSmartRatePreference();
    _emitChanged();
  }

  void _removeScrapItem(int index) {
    if (index < 0 || index >= scrapItems.length) return;
    scrapItems[index].removeListener(_onChildChanged);
    scrapItems[index].dispose();
    scrapItems.removeAt(index);
    _syncSmartRatePreference();
    _emitChanged();
  }
}
