import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/application/girvi_billing_controller.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/data/girvi_billing_settings_repository.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/girvi_billing_repo.dart';

void main() {
  late AppDatabase db;
  late GirviBillingRepo repo;
  late GirviBillingController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GirviBillingRepo(db: db);
    controller = GirviBillingController(
      repository: GirviBillingSettingsRepository(repo: repo),
    );
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('Girvi Billing loads default policy and receipt state', () async {
    await controller.load();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.isDirty, isFalse);
    expect(controller.state.input.girviPrefix, 'GRV-');
    expect(controller.state.model.defaultInterestRate, 1.5);
    expect(controller.state.selectedInvoiceMetal, GirviBillingMetal.gold);
    expect(controller.state.model.visibleInvoiceFieldCount, greaterThan(0));
    expect(controller.state.model.visibleDocumentFieldCount, greaterThan(0));
  });

  test('Girvi Billing saves validated loan policy settings', () async {
    await controller.load();

    controller
      ..updateInput(
        controller.state.input.copyWith(
          girviPrefix: 'PLEDGE-',
          startingNumber: '42',
          defaultInterestRate: '2.25',
          gracePeriodDays: '5',
          reminderDays: '10',
          noticeDays: '45',
          termsAndConditions: 'Interest is payable every month.',
          customerDeclaration: 'I have verified the pledged articles.',
          footerMessage: 'Please keep this pledge receipt safely.',
        ),
      )
      ..updateInterestType('Compound')
      ..updateDefaultDuration('12 Months')
      ..updateAutoPrint(false)
      ..updateModel(
        controller.state.model.copyWith(
          showDuration: true,
          showMaturityDate: true,
          showDisbursementDetails: true,
        ),
      );

    expect(controller.state.isDirty, isTrue);
    expect(await controller.save(), isTrue);

    final saved = await repo.fetch();
    expect(saved.girviPrefix, 'PLEDGE-');
    expect(saved.startingNumber, 42);
    expect(saved.defaultInterestRate, 2.25);
    expect(saved.gracePeriodDays, 5);
    expect(saved.reminderDays, 10);
    expect(saved.noticeDays, 45);
    expect(saved.interestType, 'Compound');
    expect(saved.defaultDuration, '12 Months');
    expect(saved.autoPrint, isFalse);
    expect(saved.showDuration, isTrue);
    expect(saved.showMaturityDate, isTrue);
    expect(saved.showDisbursementDetails, isTrue);
    expect(controller.state.isDirty, isFalse);
  });

  test('Girvi Billing preserves exact bilingual policy copy when saving',
      () async {
    await controller.load();

    const exactTerms =
        'Interest is payable every month.\n'
        'Original receipt is required for release.';
    const exactTermsHindi =
        'ब्याज हर महीने देय होगा।\n'
        'छुड़ाने के लिए मूल रसीद आवश्यक है।';
    const exactDeclaration =
        'I have verified all pledge details.\n'
        'I accept the shop valuation.';
    const exactDeclarationHindi =
        'मैंने सभी गिरवी विवरण जांच लिए हैं।\n'
        'मैं दुकान का मूल्यांकन स्वीकार करता हूं।';
    const exactFooter =
        'Please keep this pledge receipt safely.\n'
        'कृपया यह गिरवी रसीद सुरक्षित रखें।';

    controller.updateInput(
      controller.state.input.copyWith(
        termsAndConditions: exactTerms,
        termsAndConditionsHindi: exactTermsHindi,
        customerDeclaration: exactDeclaration,
        customerDeclarationHindi: exactDeclarationHindi,
        footerMessage: exactFooter,
      ),
    );

    expect(await controller.save(), isTrue);

    final saved = await repo.fetch();
    expect(saved.termsAndConditions, exactTerms);
    expect(saved.termsAndConditionsHindi, exactTermsHindi);
    expect(saved.customerDeclaration, exactDeclaration);
    expect(saved.customerDeclarationHindi, exactDeclarationHindi);
    expect(saved.footerMessage, exactFooter);
  });

  test('Girvi Billing blocks invalid policy values before saving', () async {
    await controller.load();

    controller.updateInput(
      controller.state.input.copyWith(
        girviPrefix: 'GRV#',
        startingNumber: '0',
        defaultInterestRate: '150',
        gracePeriodDays: '500',
        noticeDays: '500',
        termsAndConditions: '',
        customerDeclaration: '',
        footerMessage: '',
      ),
    );

    expect(await controller.save(), isFalse);
    expect(controller.state.validationMessages, isNotEmpty);

    final saved = await repo.fetch();
    expect(saved.girviPrefix, GirviBillingModel.defaults.girviPrefix);
    expect(saved.startingNumber, GirviBillingModel.defaults.startingNumber);
  });

  test('Girvi Billing keeps metal invoice settings independent', () async {
    await controller.load();

    final goldSettings = controller.state.model
        .settingsForMetal(GirviBillingMetal.gold)
        .copyWith(
          showHuid: false,
          showValuationAmount: true,
        );
    final updated = controller.state.model.withMetalSettings(
      GirviBillingMetal.gold,
      goldSettings,
    );
    controller.updateModel(updated);

    expect(await controller.save(), isTrue);

    final saved = await repo.fetch();
    expect(
      saved.settingsForMetal(GirviBillingMetal.gold).showHuid,
      isFalse,
    );
    expect(
      saved.settingsForMetal(GirviBillingMetal.gold).showValuationAmount,
      isTrue,
    );
    expect(
      saved.settingsForMetal(GirviBillingMetal.silver).showValuationAmount,
      isFalse,
    );
  });
}
