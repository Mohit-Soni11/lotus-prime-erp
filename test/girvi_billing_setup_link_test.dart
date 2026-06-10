import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/new_girvi_controller.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/girvi_billing_repo.dart';

void main() {
  late AppDatabase db;
  late GirviBillingRepo repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GirviBillingRepo(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Customer print defaults keep valuation details private', () {
    final settings = GirviBillingModel.defaults;

    expect(settings.visibleInvoiceFieldCount, 9);
    expect(settings.showItemPhotos, isTrue);
    expect(settings.showValuationPurity, isFalse);
    expect(settings.showFineWeight, isFalse);
    expect(settings.showRate, isFalse);
    expect(settings.showTotalValue, isFalse);
    expect(settings.showKycDetails, isFalse);
    expect(settings.showDisbursementDetails, isFalse);
    expect(settings.printTermsAndConditions, isFalse);
    expect(settings.printFooterMessage, isFalse);
  });

  test('Girvi billing invoice preferences persist with existing table',
      () async {
    final settings = GirviBillingModel.defaults.copyWith(
      showHuid: false,
      showRate: false,
      showItemPhotos: false,
      printFooterMessage: false,
      footerMessage: 'Keep this ticket safe.',
    );

    expect(await repo.save(settings), isTrue);
    final saved = await repo.fetch();

    expect(saved.showHuid, isFalse);
    expect(saved.showRate, isFalse);
    expect(saved.showItemPhotos, isFalse);
    expect(saved.printFooterMessage, isFalse);
    expect(saved.footerMessage, 'Keep this ticket safe.');
  });

  test('New Girvi loads prefix, interest and duration from billing setup',
      () async {
    await repo.save(
      GirviBillingModel.defaults.copyWith(
        girviPrefix: 'PLEDGE-',
        startingNumber: 25,
        defaultInterestRate: 2.25,
        defaultDuration: '9 Months',
      ),
    );
    final controller = NewGirviController(db, billingRepo: repo);
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.ticketNo, 'PLEDGE-0025');
    expect(controller.interestRate, 2.25);
    expect(controller.durationMonths, 9);
  });
}
