import 'package:flutter/foundation.dart';

/// Broadcasts a committed Shop Setup change to interested presentation layers.
/// The persisted Shop Setup payload remains the source of truth; this notifier
/// only tells consumers when they should reload that persisted data.
class ShopIdentityUpdates {
  ShopIdentityUpdates._();

  static final ShopIdentityUpdates instance = ShopIdentityUpdates._();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void publish() {
    revision.value += 1;
  }
}
