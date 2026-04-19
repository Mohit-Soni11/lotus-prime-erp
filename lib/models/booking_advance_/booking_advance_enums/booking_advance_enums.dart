// =============================================================================
// FILE        : booking_advance_enums.dart
// MODULE      : Sales → Booking & Advance
// LAYER       : Models / Enums
// =============================================================================

enum BookingStatus {
  pending('PENDING'),
  delivered('DELIVERED'),
  cancelled('CANCELLED');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String s) =>
      BookingStatus.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
        orElse: () => BookingStatus.pending,
      );
}

enum BookingType {
  open('OPEN'),
  locked('LOCKED');

  final String value;
  const BookingType(this.value);

  static BookingType fromString(String s) =>
      BookingType.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
        orElse: () => BookingType.open,
      );
}

enum MetalTypeBA {
  gold('GOLD'),
  silver('SILVER'),
  platinum('PLATINUM'),
  diamond('DIAMOND');

  final String value;
  const MetalTypeBA(this.value);

  static MetalTypeBA fromString(String s) =>
      MetalTypeBA.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
        orElse: () => MetalTypeBA.gold,
      );
}

enum AdvancePaymentMode {
  cash,
  upi,
  card,
}

enum BookingFilterTab {
  all,
  pending,
  delivered,
  cancelled,
}