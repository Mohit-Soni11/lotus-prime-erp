import '../../../../../models/setting/shop_setup/shop_profile_model.dart';

abstract final class RegistrationShopProfilePrefill {
  static ShopProfileModel fromOwnerDetails(Map<String, dynamic> owner) {
    final companyName =
        (owner['registrationCompanyName'] as String? ?? '').trim();
    final identifier = (owner['username'] as String? ?? '').trim();
    final mobile = (owner['mobile'] as String? ?? '').trim();
    return ShopProfileModel(
      legalName: companyName,
      displayName: companyName,
      brandDisplayName: companyName,
      ownerName: (owner['name'] as String? ?? '').trim(),
      ownerPhone: mobile,
      shopPhone: mobile,
      businessEmail: identifier.contains('@') ? identifier : '',
    );
  }
}
