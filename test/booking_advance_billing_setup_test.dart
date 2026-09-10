import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/booking_advance/application/booking_advance_billing_controller.dart';
import 'package:lotus_erp/features/settings/billing_setup/booking_advance/data/booking_advance_billing_settings_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/booking_advance/domain/booking_advance_billing_input.dart';
import 'package:lotus_erp/features/settings/billing_setup/domain/entities/billing_setup_module.dart';
import 'package:lotus_erp/logic/booking_advance/booking_advance_controller.dart';
import 'package:lotus_erp/logic/booking_advance/booking_invoice_pdf_service.dart';
import 'package:lotus_erp/logic/booking_advance/booking_invoice_preview_controller.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/setting/billing_setup/booking_advance_billing_model.dart';
import 'package:lotus_erp/repositories/booking_advance/booking_advance_repository.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/booking_advance_billing_repo.dart';

void main() {
  late AppDatabase database;
  late BookingAdvanceBillingRepo settingsRepo;
  late BookingAdvanceRepository bookingRepo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    settingsRepo = BookingAdvanceBillingRepo(db: database);
    bookingRepo = BookingAdvanceRepository(
      db: database,
      billingSettingsRepository: settingsRepo,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('Billing Setup hub exposes Booking and Advance module card metadata',
      () {
    final bookingModule = BillingSetupModules.all.firstWhere(
      (module) => module.id == BillingSetupModuleId.bookingAdvance,
    );

    expect(bookingModule.title, 'Booking & Advance');
    expect(bookingModule.actionLabel, 'Configure Booking');
  });

  test('Booking and Advance settings persist through controller and repository',
      () async {
    final controller = BookingAdvanceBillingController(
      repository: BookingAdvanceBillingSettingsRepository(repo: settingsRepo),
    );
    addTearDown(controller.dispose);

    await controller.load();
    final input = controller.state.input!;

    controller
      ..updateDefaultPrintFormat(PrintFormat.thermal3inch.name)
      ..updatePrintCopies(3)
      ..updateIncludeRateColumn(false)
      ..updateAllowZeroAdvance(false)
      ..updateInput(
        input.copyWith(
          documentPrefix: 'ADV',
          defaultDeliveryDays: '21',
          minimumAdvancePercent: '15',
          minimumAdvanceAmount: '2500',
          termsAndConditions: 'Advance booking custom terms.',
          footerMessage: 'Bring this receipt at delivery.',
        ),
      );

    expect(await controller.save(), isTrue);

    final saved = await settingsRepo.fetch();
    expect(saved.documentPrefix, 'ADV');
    expect(saved.defaultDeliveryDays, 21);
    expect(saved.minimumAdvancePercent, 15);
    expect(saved.minimumAdvanceAmount, 2500);
    expect(saved.allowZeroAdvance, isFalse);
    expect(saved.defaultPrintFormat, PrintFormat.thermal3inch.name);
    expect(saved.printCopies, 3);
    expect(saved.includeRateColumn, isFalse);
    expect(saved.termsAndConditions, 'Advance booking custom terms.');
    expect(saved.footerMessage, 'Bring this receipt at delivery.');
  });

  test('invalid Booking and Advance settings are blocked before saving',
      () async {
    final controller = BookingAdvanceBillingController(
      repository: BookingAdvanceBillingSettingsRepository(repo: settingsRepo),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.updateInput(
      const BookingAdvanceBillingInput(
        documentPrefix: 'A-',
        defaultDeliveryDays: '500',
        minimumAdvancePercent: '120',
        minimumAdvanceAmount: '-1',
        termsAndConditions: '',
        footerMessage: '',
      ),
    );

    expect(await controller.save(), isFalse);
    expect(controller.state.validationMessages, hasLength(greaterThan(1)));

    final saved = await settingsRepo.fetch();
    expect(
        saved.documentPrefix, BookingAdvanceBillingModel.defaultDocumentPrefix);
  });

  test('custom booking prefix is used for generated booking numbers', () async {
    await settingsRepo.save(
      BookingAdvanceBillingModel.defaults().copyWith(documentPrefix: 'ADV'),
    );
    final controller = BookingAdvanceController(repo: bookingRepo);
    addTearDown(controller.dispose);

    await _waitForBookingNumber(controller);

    controller.nameCtrl.text = 'Prefix Customer';
    controller.mobileCtrl.text = '9876543210';
    controller.cashCtrl.text = '2500';
    controller.addBookingItem();
    final item = controller.bookingItems.single;
    item.descCtrl.text = 'Gold Ring';
    item.grossCtrl.text = '10';
    item.rateCtrl.text = '6000';

    final result = await controller.saveBooking();
    final yearToken = bookingRepo.getCurrentDocumentYearToken();

    expect(result.success, isTrue);
    expect(result.bookingNo, 'SH-ADV-$yearToken-0001');
    expect((await database.select(database.salesOrders).get()).single.orderNo,
        'SH-ADV-$yearToken-0001');
  });

  test('minimum advance setting is enforced during booking save', () async {
    await settingsRepo.save(
      BookingAdvanceBillingModel.defaults().copyWith(
        allowZeroAdvance: false,
        minimumAdvanceAmount: 5000,
      ),
    );
    final controller = BookingAdvanceController(repo: bookingRepo);
    addTearDown(controller.dispose);

    await _waitForBookingNumber(controller);

    controller.nameCtrl.text = 'Advance Customer';
    controller.cashCtrl.text = '2000';
    controller.addBookingItem();
    final item = controller.bookingItems.single;
    item.descCtrl.text = 'Gold Chain';
    item.grossCtrl.text = '8';
    item.rateCtrl.text = '6500';

    final result = await controller.saveBooking();

    expect(result.success, isFalse);
    expect(result.message, contains('Minimum advance required'));
    expect(await database.select(database.salesOrders).get(), isEmpty);
  });

  test('invoice preview loads print defaults from Booking and Advance setup',
      () async {
    await settingsRepo.save(
      BookingAdvanceBillingModel.defaults().copyWith(
        defaultPrintFormat: PrintFormat.thermal2inch.name,
        printCopies: 4,
        includeCustomerAddress: false,
        includeRateColumn: false,
        printTermsAndConditions: false,
        printFooterMessage: false,
      ),
    );
    final entryController = BookingAdvanceController(repo: bookingRepo);
    addTearDown(entryController.dispose);
    await _waitForBookingNumber(entryController);

    entryController.nameCtrl.text = 'Preview Customer';
    entryController.cashCtrl.text = '3000';
    entryController.addBookingItem();
    final item = entryController.bookingItems.single;
    item.descCtrl.text = 'Gold Pendant';
    item.grossCtrl.text = '5';
    item.rateCtrl.text = '6200';

    final saved = await entryController.saveBooking();
    expect(saved.success, isTrue);

    final previewController = BookingInvoicePreviewController(
      orderIds: saved.orderIds,
      repository: bookingRepo,
      pdfService: BookingInvoicePdfService(
        shopProfileRepository: ShopPrintInformationRepository(
          db: database,
          shopSetupLoader: (_) async => null,
        ),
      ),
    );
    addTearDown(previewController.dispose);

    await previewController.load();

    expect(previewController.genState, BookingInvoiceGenerationState.ready);
    expect(previewController.selectedFormat, PrintFormat.thermal2inch);
    expect(previewController.selectedTemplateId,
        PrintTemplateRegistry.defaultTemplateId);
    expect(previewController.printCopies, 4);
    expect(previewController.includeCustomerAddress, isFalse);
    expect(previewController.includeRateColumn, isFalse);
    expect(previewController.includeTerms, isFalse);
    expect(previewController.includeFooterMessage, isFalse);
    expect(previewController.pdfBytes, isNotEmpty);
  });
}

Future<void> _waitForBookingNumber(BookingAdvanceController controller) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (controller.isNumberLoading && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(controller.isNumberLoading, isFalse);
}
