// =============================================================================
// FILE        : add_customer_validator.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Helpers / Validators
// VERSION     : 2.0
// =============================================================================

class AddCustomerValidator {
  AddCustomerValidator._();

  static final RegExp _mobileRx = RegExp(r'^[6-9][0-9]{9}$');
  static final RegExp _panRx    = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  static final RegExp _emailRx  = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  // ── NAME ─────────────────────────────────────────────────────────────────
  static String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'First name is required';
    if (v.trim().length < 2)           return 'Name is too short';
    return null;
  }

  static String? validateCompanyName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Company name is required';
    if (v.trim().length < 2)           return 'Name is too short';
    return null;
  }

  // ── MOBILE ───────────────────────────────────────────────────────────────
  static String? validateMobile(String? v) {
    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
    final c = v.trim();
    if (c.length != 10)               return 'Enter valid 10-digit number';
    if (!_mobileRx.hasMatch(c))       return 'Invalid mobile number';
    return null;
  }

  static String? validateMobileLive(String v) {
    if (v.isEmpty)                            return null;
    if (!RegExp(r'^[0-9]*$').hasMatch(v))     return 'Only digits allowed';
    return null;
  }

  // ── EMAIL ────────────────────────────────────────────────────────────────
  static String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    if (!_emailRx.hasMatch(v.trim())) return 'Enter valid email address';
    return null;
  }

  static String? validateEmailLive(String v) {
    if (v.isEmpty) return null;
    if (v.contains('@') && !_emailRx.hasMatch(v)) return 'Invalid email';
    return null;
  }

  // ── PAN ──────────────────────────────────────────────────────────────────
  static String? validatePan(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    if (!_panRx.hasMatch(v.trim().toUpperCase())) {
      return 'Invalid PAN (e.g. ABCDE1234F)';
    }
    return null;
  }

  static String? validatePanLive(String v) {
    if (v.isEmpty) return null;
    if (v.length == 10 && !_panRx.hasMatch(v.toUpperCase())) {
      return 'Invalid PAN format';
    }
    return null;
  }

  // ── GST ──────────────────────────────────────────────────────────────────
  static String? validateGst(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final gstRx = RegExp(
        r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!gstRx.hasMatch(v.trim().toUpperCase())) return 'Invalid GST number';
    return null;
  }

  // ── PINCODE ───────────────────────────────────────────────────────────────
  static String? validatePincode(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length != 6)          return 'Enter 6-digit pincode';
    return null;
  }
}