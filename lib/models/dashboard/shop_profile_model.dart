// File: lib/models/dashboard/shop_profile_model.dart

class ShopProfileModel {
  final String displayName;
  final String ownerName;
  final String city;
  final String state;
  final String mobile;
  final String email;
  final String website;
  final String gstin;
  final String bisLicense;
  final String huidNo;
  final String? logoPath;
  final String logoShape;

  // Visibility Flags (ERP Control)
  final bool showMobile;
  final bool showEmail;
  final bool showGst;

  const ShopProfileModel({
    required this.displayName,
    required this.ownerName,
    required this.city,
    required this.state,
    required this.mobile,
    required this.email,
    required this.website,
    required this.gstin,
    required this.bisLicense,
    required this.huidNo,
    this.logoPath,
    this.logoShape = "circle",
    this.showMobile = true,
    this.showEmail = true,
    this.showGst = true,
  });

  // Empty Factory for Initial State
  factory ShopProfileModel.empty() {
    return const ShopProfileModel(
      displayName: "Loading Shop...",
      ownerName: "--",
      city: "",
      state: "",
      mobile: "",
      email: "",
      website: "",
      gstin: "",
      bisLicense: "",
      huidNo: "",
      logoPath: null,
      logoShape: "circle",
    );
  }
}
