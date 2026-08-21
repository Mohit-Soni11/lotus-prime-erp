import 'package:drift/drift.dart' show Value;
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
    final gold = settings.settingsForMetal(GirviBillingMetal.gold);
    final silver = settings.settingsForMetal(GirviBillingMetal.silver);

    expect(settings.visibleInvoiceFieldCount, 10);
    expect(gold.showItemPhotos, isTrue);
    expect(gold.showHuid, isTrue);
    expect(silver.showHuid, isFalse);
    expect(gold.showValuationPurity, isFalse);
    expect(gold.showFineWeight, isFalse);
    expect(gold.showRatePerGram, isFalse);
    expect(gold.showValuationAmount, isFalse);
    expect(settings.showValuationPurity, isFalse);
    expect(settings.showFineWeight, isFalse);
    expect(settings.showRate, isFalse);
    expect(settings.showTotalValue, isFalse);
    expect(settings.showKycDetails, isFalse);
    expect(settings.showDisbursementDetails, isFalse);
    expect(settings.printTermsAndConditions, isFalse);
    expect(settings.printFooterMessage, isTrue);
    expect(
      settings.footerMessage,
      'Please keep this Girvi receipt safely.',
    );
  });

  test('Girvi billing invoice preferences persist with existing table',
      () async {
    final settings = GirviBillingModel.defaults
        .withMetalSettings(
          GirviBillingMetal.gold,
          GirviBillingModel.defaults
              .settingsForMetal(GirviBillingMetal.gold)
              .copyWith(
                showHuid: false,
                showValuationPurity: true,
                showFineWeight: true,
                showRatePerGram: true,
                showValuationAmount: true,
                showItemPhotos: false,
              ),
        )
        .withMetalSettings(
          GirviBillingMetal.silver,
          GirviBillingModel.defaults
              .settingsForMetal(GirviBillingMetal.silver)
              .copyWith(showLessWeight: false),
        )
        .copyWith(
          footerMessage: 'Keep this ticket safe.',
          termsAndConditions:
              'Interest is charged monthly.\nKeep this receipt safely.',
          termsAndConditionsHindi:
              'ब्याज प्रति माह लिया जाएगा।\nयह रसीद सुरक्षित रखें।',
          customerDeclaration: 'I have verified the pledge and loan details.',
          customerDeclarationHindi: 'मैंने गिरवी और ऋण का विवरण जांच लिया है।',
          showDuration: true,
          showMaturityDate: true,
          showTotalValue: true,
          showDisbursementDetails: true,
          showKycDetails: true,
          showKycPhoto: true,
          showNotes: true,
          printTermsAndConditions: true,
          printCustomerDeclaration: true,
          printFooterMessage: true,
        );

    expect(await repo.save(settings), isTrue);
    final saved = await repo.fetch();
    final gold = saved.settingsForMetal(GirviBillingMetal.gold);
    final silver = saved.settingsForMetal(GirviBillingMetal.silver);

    expect(gold.showHuid, isFalse);
    expect(gold.showValuationPurity, isTrue);
    expect(gold.showFineWeight, isTrue);
    expect(gold.showRatePerGram, isTrue);
    expect(gold.showValuationAmount, isTrue);
    expect(gold.showItemPhotos, isFalse);
    expect(silver.showLessWeight, isFalse);
    expect(saved.showDuration, isTrue);
    expect(saved.showMaturityDate, isTrue);
    expect(saved.showTotalValue, isTrue);
    expect(saved.showDisbursementDetails, isTrue);
    expect(saved.showKycDetails, isTrue);
    expect(saved.showKycPhoto, isTrue);
    expect(saved.showNotes, isTrue);
    expect(saved.printTermsAndConditions, isTrue);
    expect(saved.printFooterMessage, isTrue);
    expect(saved.footerMessage, 'Keep this ticket safe.');
    expect(
      saved.termsAndConditionsHindi,
      'ब्याज प्रति माह लिया जाएगा।\nयह रसीद सुरक्षित रखें।',
    );
    expect(
      saved.customerDeclarationHindi,
      'मैंने गिरवी और ऋण का विवरण जांच लिया है।',
    );
    expect(saved.printCustomerDeclaration, isTrue);
  });

  test('blank saved footer remains the source of truth', () async {
    final legacy = GirviBillingModel.defaults.copyWith(
      footerMessage: '',
      printFooterMessage: false,
    );
    await db.into(db.girviBillingSettings).insert(
          GirviBillingSettingsCompanion(
            footerMessage: const Value(''),
            selectedTemplate: Value(
              GirviBillingTemplateOptions.encode(legacy),
            ),
          ),
        );

    final loaded = await repo.fetch();

    expect(loaded.printFooterMessage, isFalse);
    expect(loaded.footerMessage, '');
  });

  test('Girvi metal settings stay independent', () {
    final settings = GirviBillingModel.defaults.withMetalSettings(
      GirviBillingMetal.diamond,
      GirviBillingModel.defaults
          .settingsForMetal(GirviBillingMetal.diamond)
          .copyWith(
            showGrossWeight: false,
            showHuid: true,
          ),
    );

    expect(
      settings.settingsForMetal(GirviBillingMetal.diamond).showGrossWeight,
      isFalse,
    );
    expect(
      settings.settingsForMetal(GirviBillingMetal.diamond).showHuid,
      isTrue,
    );
    expect(
      settings.settingsForMetal(GirviBillingMetal.gold).showGrossWeight,
      isTrue,
    );
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
