// -----------------------------------------------------------------------------
// FILE: address_map_logic.dart
// TYPE: Business Logic / Map Engine
// AUTHOR: Senior Enterprise Architect
// DESCRIPTION: 🚀 UPGRADED: 100% Pure Geo-spatial Logic.
//              Widgets (Markers), MapControllers, and UI callbacks strictly
//              removed to prevent memory leaks. Uses ValueNotifiers.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AddressMapLogic {
  // --- 🚀 UPGRADE: GRANULAR STATE NOTIFIERS ---
  final ValueNotifier<bool> isMapLocked = ValueNotifier(true);
  final ValueNotifier<bool> isLocating = ValueNotifier(false);
  final ValueNotifier<LatLng?> selectedLocation = ValueNotifier(null);

  // PERFECT INDIA CENTER
  static const LatLng defaultLocation = LatLng(22.5, 79.0);

  // --- ACTIONS ---

  /// Toggles lock state and returns a message for the UI to display
  String toggleLock() {
    isMapLocked.value = !isMapLocked.value;
    return isMapLocked.value
        ? "Geo-Location Locked & Saved"
        : "Map Unlocked: Tap anywhere to set pin";
  }

  void onMapTap(LatLng latLng) {
    if (isMapLocked.value) return;
    selectedLocation.value = latLng;
  }

  /// Fetches GPS location, updates state, and returns LatLng
  /// so the UI layer can safely animate the MapController.
  /// Throws standard Exceptions if GPS fails.
  Future<LatLng> detectCurrentLocation() async {
    isLocating.value = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception("GPS/Location Service is disabled. Please turn it on.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      // Accuracy set to 'best' (Highest Power)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      selectedLocation.value = currentLatLng;

      return currentLatLng;
    } finally {
      isLocating.value = false;
    }
  }

  // --- MEMORY MANAGEMENT ---
  void dispose() {
    isMapLocked.dispose();
    isLocating.dispose();
    selectedLocation.dispose();
  }
}
