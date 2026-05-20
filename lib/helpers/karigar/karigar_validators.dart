// =============================================================================
// FILE        : karigar_validators.dart
// MODULE      : Karigar
// LAYER       : Helpers / Validators
// DESCRIPTION : All form field validation functions for the Karigar module.
//               Returns null on success, error string on failure.
//               Stateless pure functions — zero Flutter dependency.
// =============================================================================

class KarigarValidators {
  KarigarValidators._();

  // ── KARIGAR MASTER ─────────────────────────────────────────────────────────

  static String? validateKarigarName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Karigar name is required';
    }
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 150) return 'Name is too long';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid 10-digit phone number';
    if (digits.length > 15) return 'Phone number is too long';
    return null;
  }

  static String? validateAlternatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? validateRateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid amount';
    if (d < 0) return 'Rate cannot be negative';
    return null;
  }

  static String? validateOpeningBalance(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid balance';
    return null;
  }

  // ── ISSUE TO KARIGAR ──────────────────────────────────────────────────────

  static String? validateItemDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item description is required';
    }
    if (value.trim().length < 2) return 'Description is too short';
    if (value.trim().length > 300) return 'Description is too long';
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required';
    final i = int.tryParse(value);
    if (i == null) return 'Enter a valid whole number';
    if (i < 1) return 'Quantity must be at least 1';
    if (i > 9999) return 'Quantity seems too large';
    return null;
  }

  static String? validateWeight(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Weight is required';
      return null;
    }
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid weight in grams';
    if (d < 0) return 'Weight cannot be negative';
    if (d > 99999) return 'Weight value seems too large';
    return null;
  }

  static String? validateGrossWeight(String? value) {
    return validateWeight(value, required: true);
  }

  static String? validateStoneWeight(String? value,
      {required double grossWeight}) {
    if (value == null || value.trim().isEmpty) return null;
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid stone weight';
    if (d < 0) return 'Stone weight cannot be negative';
    if (d >= grossWeight) return 'Stone weight must be less than gross weight';
    return null;
  }

  // ── RECEIVE FROM KARIGAR ──────────────────────────────────────────────────

  static String? validateReceivedWeight(
    String? value, {
    required double issuedWeight,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Received weight is required';
    }
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid weight in grams';
    if (d <= 0) return 'Received weight must be greater than zero';
    // Allow slight excess (e.g. stone additions) up to 20% over issued
    if (d > issuedWeight * 1.2) {
      return 'Received weight exceeds issued weight by more than 20%';
    }
    return null;
  }

  static String? validateMakingChargeRate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid rate';
    if (d < 0) return 'Rate cannot be negative';
    return null;
  }

  static String? validateMakingChargesAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid amount';
    if (d < 0) return 'Amount cannot be negative';
    return null;
  }

  static String? validatePaidAmount(String? value, {required double totalDue}) {
    if (value == null || value.trim().isEmpty) return null;
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid amount';
    if (d < 0) return 'Paid amount cannot be negative';
    if (d > totalDue * 1.01) {
      return 'Paid amount cannot exceed total due (₹${totalDue.toStringAsFixed(2)})';
    }
    return null;
  }

  // ── WASTAGE BUSINESS RULES ────────────────────────────────────────────────

  /// Returns a warning message if wastage is high, or null if acceptable.
  static String? wastageWarning(double wastagePercent) {
    if (wastagePercent > 5.0) {
      return '⚠ Wastage ${wastagePercent.toStringAsFixed(2)}% is critically high (>5%)';
    }
    if (wastagePercent > 2.0) {
      return 'Wastage ${wastagePercent.toStringAsFixed(2)}% is above the standard 2% threshold';
    }
    return null;
  }
}
