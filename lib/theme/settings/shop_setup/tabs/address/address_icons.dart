// -----------------------------------------------------------------------------
// FILE: address_icons.dart
// TYPE: Theme / Icons
// AUTHOR: Senior System Architect
// DESCRIPTION: 100% Centralized icon repository. Enables quick swapping of
//              icon packs across the entire Address module without UI changes.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AddressIcons {
  // --- Headers ---
  static const IconData sectionAddress = Icons.business_rounded;

  // --- Actions & Status ---
  static const IconData edit = Icons.edit_rounded;
  static const IconData save = Icons.check_circle_rounded;
  static const IconData arrowRight = Icons.arrow_right_alt_rounded;
  static const IconData errorOutline = Icons.error_outline;
  static const IconData checkCircle = Icons.check_circle;
  static const IconData lockOutline = Icons.lock_outline;
  static const IconData checkCircleOutline = Icons.check_circle_outline;

  // --- Input Fields ---
  static const IconData addrHome = Icons.domain_rounded; // Building
  static const IconData addrRoad = Icons.edit_road_rounded; // Street
  static const IconData city = Icons.location_city_rounded;
  static const IconData state = Icons.map_outlined;
  static const IconData pincode = Icons.pin_drop_rounded;
  static const IconData country = Icons.public_rounded;

  // --- Address Types ---
  static const IconData typeHead = Icons.apartment_rounded;
  static const IconData typeBranch = Icons.store_rounded;
  static const IconData typeWarehouse = Icons.warehouse_rounded;

}
