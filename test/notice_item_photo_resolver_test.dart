import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/notice_pdf/notice_item_photo_resolver.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/girvi_billing_repo.dart';

void main() {
  test('notice photo follows the invoice per-metal visibility setting',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final photoDirectory =
        await Directory.systemTemp.createTemp('notice_photo_');
    addTearDown(() async {
      await db.close();
      await photoDirectory.delete(recursive: true);
    });
    final photo = File('${photoDirectory.path}/pledged_item.png');
    await photo.writeAsBytes(img.encodePng(img.Image(width: 2, height: 2)));
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
              name: 'Photo Customer', mobile: '9000000021'),
        );
    final loanId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-PHOTO-001',
            customerId: customerId,
            itemDescription: 'Gold necklace',
          ),
        );
    final itemId = await db.into(db.girviLoanItems).insert(
          GirviLoanItemsCompanion.insert(
            girviId: loanId,
            serialNo: 1,
            itemName: 'Gold necklace',
            metalType: 'Gold',
            purity: '22KT',
          ),
        );
    await db.into(db.girviItemPhotos).insert(
          GirviItemPhotosCompanion.insert(
            itemId: itemId,
            filePath: photo.path,
          ),
        );
    final resolver = NoticeItemPhotoResolver(db);
    expect(await resolver.resolve(loanId), photo.path);

    final billing = GirviBillingRepo(db: db);
    expect(
      await billing.save(GirviBillingModel.defaults.withMetalSettings(
        GirviBillingMetal.gold,
        GirviBillingModel.defaults
            .settingsForMetal(GirviBillingMetal.gold)
            .copyWith(showItemPhotos: false),
      )),
      isTrue,
    );
    expect(await resolver.resolve(loanId), isNull);
  });
}
