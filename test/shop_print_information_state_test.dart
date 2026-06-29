import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';

void main() {
  test('shop print state ignores enabled fields that are not configured', () {
    const configuredField = ShopPrintField(
      id: 'shop_name',
      label: 'Shop Name',
      description: 'Primary store name printed in the invoice header.',
      sourceSection: 'Basic Info',
      value: 'Lotus Jewellers',
      group: ShopPrintFieldGroup.identity,
      defaultEnabled: true,
    );
    const missingField = ShopPrintField(
      id: 'instagram',
      label: 'Instagram Channel',
      description: 'Instagram handle or page link.',
      sourceSection: 'Branding',
      value: '',
      group: ShopPrintFieldGroup.social,
      defaultEnabled: false,
    );

    const state = ShopPrintInformationState(
      tenantId: 'tenant_001',
      fields: [configuredField, missingField],
      enabledFieldIds: {'shop_name', 'instagram'},
    );

    expect(state.configuredCount, 1);
    expect(state.missingCount, 1);
    expect(state.enabledCount, 1);
    expect(state.configuredFieldIds, {'shop_name'});
    expect(state.isEnabled(configuredField), isTrue);
    expect(state.isEnabled(missingField), isFalse);
  });
}
