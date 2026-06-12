import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/dashboard/dashboard_repository.dart';

void main() {
  test('Dashboard Shop Identity receives synced logo path and shape', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(
          ShopProfilesCompanion.insert(
            shopName: const Value('Anjali Jewellers'),
            ownerName: const Value('Anjali Kumari'),
            contactNumber: const Value('9876543210'),
            city: const Value('Gaya'),
            state: const Value('Bihar'),
            gstin: const Value('10ABCDE1234F1Z5'),
            logoPath: const Value(r'D:\shop_identity\shop_logo.png'),
            logoShape: const Value('square'),
          ),
        );

    final profile = await DashboardRepository(db: db).fetchFullShopDetails();

    expect(profile.displayName, 'Anjali Jewellers');
    expect(profile.ownerName, 'Anjali Kumari');
    expect(profile.gstin, '10ABCDE1234F1Z5');
    expect(profile.logoPath, r'D:\shop_identity\shop_logo.png');
    expect(profile.logoShape, 'square');
  });

  test('Dashboard falls back to Shop Profile identity when Drift path is empty',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(
          ShopProfilesCompanion.insert(
            shopName: const Value('Anjali Jewellers'),
            ownerName: const Value('Anjali Kumari'),
          ),
        );

    final repository = DashboardRepository(
      db: db,
      shopSetupLoader: () async => const {
        'basic_info': {
          'logo_path': r'C:\shop_identity\official_logo.png',
          'logo_shape': 'square',
        },
      },
    );

    final profile = await repository.fetchFullShopDetails();

    expect(profile.logoPath, r'C:\shop_identity\official_logo.png');
    expect(profile.logoShape, 'square');
  });

  test('Dashboard keeps logo empty when no official logo was uploaded',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(
          ShopProfilesCompanion.insert(
            shopName: const Value('Anjali Jewellers'),
          ),
        );

    final repository = DashboardRepository(
      db: db,
      shopSetupLoader: () async => const {
        'basic_info': {
          'logo_path': '',
          'logo_shape': 'circle',
        },
      },
    );

    final profile = await repository.fetchFullShopDetails();

    expect(profile.logoPath, null);
    expect(profile.logoShape, 'circle');
  });
}
