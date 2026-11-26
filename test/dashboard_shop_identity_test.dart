import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/events/shop_identity_updates.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/application/shop_identity_controller.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/data/shop_identity_repository.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/domain/shop_identity.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/presentation/shop_identity_card.dart';

void main() {
  group('ShopIdentityRepository', () {
    test('maps the complete persisted Shop Setup identity', () async {
      final repository = ShopIdentityRepository(
        payloadLoader: () async => {
          'basic_info': {
            'brand_display_name': 'Anjali Jewellers',
            'display_name': 'Anjali Jewellery House',
            'owner_name': 'Mohit Soni',
            'shop_phone': '9876543210',
            'business_email': 'hello@anjali.example',
            'logo_path': r'D:\\shop_identity\\official_logo.png',
            'logo_shape': 'square',
          },
          'address': {'city': 'Patna', 'state': 'Bihar'},
          'tax_compliance': {
            'gstin': '10ABCDE1234F1Z5',
            'bis_license_no': 'BIS-1234',
          },
          'branding_social': {'website': 'anjali.example'},
        },
      );

      final identity = await repository.load();

      expect(identity.status, ShopIdentityStatus.configured);
      expect(identity.displayName, 'Anjali Jewellers');
      expect(identity.ownerName, 'Mohit Soni');
      expect(identity.formattedLocation, 'Patna, Bihar');
      expect(identity.mobile, '9876543210');
      expect(identity.email, 'hello@anjali.example');
      expect(identity.website, 'anjali.example');
      expect(identity.gstin, '10ABCDE1234F1Z5');
      expect(identity.bisLicense, 'BIS-1234');
      expect(identity.logoPath, r'D:\\shop_identity\\official_logo.png');
      expect(identity.logoShape, 'square');
    });

    test('returns an explicit not-configured state without master data',
        () async {
      final identity = await ShopIdentityRepository(
        payloadLoader: () async => null,
      ).load();

      expect(identity.status, ShopIdentityStatus.notConfigured);
      expect(identity.displayName, isEmpty);
    });
  });

  test('reloads automatically after a committed Shop Setup update', () async {
    var currentName = 'First Name';
    final controller = ShopIdentityController(
      _FakeShopIdentityReader(() async => ShopIdentity(
            status: ShopIdentityStatus.configured,
            displayName: currentName,
            ownerName: '',
            city: '',
            state: '',
            mobile: '',
            email: '',
            website: '',
            gstin: '',
            bisLicense: '',
            logoPath: null,
            logoShape: 'circle',
          )),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.identity.displayName, 'First Name');

    currentName = 'Updated Name';
    ShopIdentityUpdates.instance.publish();
    await _settle();

    expect(controller.identity.displayName, 'Updated Name');
  });

  testWidgets('renders a compact card, fallback logo and expandable details',
      (tester) async {
    const identity = ShopIdentity(
      status: ShopIdentityStatus.configured,
      displayName: 'Anjali Jewellers',
      ownerName: 'Mohit Soni',
      city: 'Patna',
      state: 'Bihar',
      mobile: '9876543210',
      email: 'hello@anjali.example',
      website: '',
      gstin: '',
      bisLicense: '',
      logoPath: null,
      logoShape: 'circle',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: ShopIdentityCard(
              reader: _FakeShopIdentityReader(() async => identity),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Anjali Jewellers'), findsOneWidget);
    expect(find.text('AJ'), findsOneWidget);
    expect(find.text('Patna, Bihar'), findsOneWidget);
    expect(find.text('9876543210'), findsNothing);

    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    expect(find.text('9876543210'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeShopIdentityReader implements ShopIdentityReader {
  _FakeShopIdentityReader(this._loader);

  final Future<ShopIdentity> Function() _loader;

  @override
  Future<ShopIdentity> load() => _loader();
}
