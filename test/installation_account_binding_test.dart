import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotus_erp/ui/auth/services/installation_account_binding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first verified owner claims an installation once', () async {
    final binding = InstallationAccountBinding();

    expect(await binding.canCreateOwner(), isTrue);
    expect(await binding.claimOrVerify('owner-a'), isTrue);
    expect(await binding.canCreateOwner(), isFalse);
    expect(await binding.claimOrVerify('owner-a'), isTrue);
    expect(await binding.claimOrVerify('owner-b'), isFalse);
  });
}
