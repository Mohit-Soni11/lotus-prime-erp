import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/settings/shop_setup/services/registration_shop_profile_prefill.dart';

void main() {
  test('registered company details populate the first Shop Information form',
      () {
    final profile = RegistrationShopProfilePrefill.fromOwnerDetails({
      'registrationCompanyName': 'Lotus Jewellers',
      'username': 'owner@example.com',
      'name': 'Shop Owner',
      'mobile': '9876543210',
    });
    expect(profile.legalName, 'Lotus Jewellers');
    expect(profile.displayName, 'Lotus Jewellers');
    expect(profile.brandDisplayName, 'Lotus Jewellers');
    expect(profile.ownerName, 'Shop Owner');
    expect(profile.ownerPhone, '9876543210');
    expect(profile.shopPhone, '9876543210');
    expect(profile.businessEmail, 'owner@example.com');
  });

  test('legacy username is never presented as a business email', () {
    final profile = RegistrationShopProfilePrefill.fromOwnerDetails({
      'username': 'existing-owner',
      'name': 'Existing Owner',
      'mobile': '9876543210',
    });
    expect(profile.businessEmail, isEmpty);
    expect(profile.ownerName, 'Existing Owner');
  });
}
