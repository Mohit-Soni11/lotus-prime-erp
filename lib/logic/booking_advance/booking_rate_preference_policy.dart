import '../../models/booking_advance/booking_advance/booking_advance_model.dart';

class BookingRatePreferencePolicy {
  const BookingRatePreferencePolicy();

  BookingItemModel? firstPricedItem(Iterable<BookingItemModel> items) {
    for (final item in items) {
      if (item.rate > 0) return item;
    }
    return null;
  }

  bool hasMetalRate(Iterable<BookingItemModel> items) {
    return firstPricedItem(items) != null;
  }

  String? firstMetalRateText(Iterable<BookingItemModel> items) {
    final item = firstPricedItem(items);
    if (item == null) return null;
    final text = item.rateCtrl.text.trim();
    return text.isEmpty ? null : text;
  }
}
