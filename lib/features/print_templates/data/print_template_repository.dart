import '../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../repositories/setting/billing_setup/girvi_billing_repo.dart';
import '../../../repositories/setting/billing_setup/purchase_billing_repo.dart';
import '../../../repositories/setting/billing_setup/sales_billing_repo.dart';
import '../domain/print_template_registry.dart';

class PrintTemplateRepository {
  final SalesBillingRepo _salesRepo;
  final PurchaseBillingRepo _purchaseRepo;
  final GirviBillingRepo _girviRepo;

  PrintTemplateRepository({
    SalesBillingRepo? salesRepo,
    PurchaseBillingRepo? purchaseRepo,
    GirviBillingRepo? girviRepo,
  })  : _salesRepo = salesRepo ?? SalesBillingRepo(),
        _purchaseRepo = purchaseRepo ?? PurchaseBillingRepo(),
        _girviRepo = girviRepo ?? GirviBillingRepo();

  Future<void> applyDefaultTemplate({
    String templateId = PrintTemplateRegistry.defaultTemplateId,
  }) async {
    await _salesRepo.seedDefaults();
    await _purchaseRepo.seedDefaults();
    await _girviRepo.seedDefault();

    for (final metal in BillingMetal.all) {
      final sales = await _salesRepo.fetchForMetal(metal);
      await _salesRepo.saveForMetal(
        sales.copyWith(selectedTemplate: templateId),
      );

      final purchase = await _purchaseRepo.fetchForMetal(metal);
      await _purchaseRepo.saveForMetal(
        purchase.copyWith(selectedTemplate: templateId),
      );
    }

    final girvi = await _girviRepo.fetch();
    await _girviRepo.save(girvi.copyWith(selectedTemplate: templateId));
  }
}
