enum BillingSetupModuleId {
  sales,
  purchase,
  girvi,
  shopPrintInformation,
}

class BillingSetupModule {
  final BillingSetupModuleId id;
  final String title;
  final String subtitle;
  final String tag;
  final String actionLabel;

  const BillingSetupModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.actionLabel,
  });
}

class BillingSetupModules {
  BillingSetupModules._();

  static const List<BillingSetupModule> all = [
    BillingSetupModule(
      id: BillingSetupModuleId.sales,
      title: 'Sales Billing',
      subtitle: 'Invoice display, return policy and terms per metal type.',
      tag: 'Gold, Silver, Diamond, Platinum',
      actionLabel: 'Configure Sales',
    ),
    BillingSetupModule(
      id: BillingSetupModuleId.purchase,
      title: 'Purchase Billing',
      subtitle: 'Seller KYC, valuation, payout policy and terms per metal.',
      tag: 'Gold, Silver, Diamond, Platinum',
      actionLabel: 'Configure Purchase',
    ),
    BillingSetupModule(
      id: BillingSetupModuleId.girvi,
      title: 'Girvi Billing',
      subtitle: 'Interest rules, notice controls, receipt terms and footer.',
      tag: 'Interest, Notice, Terms',
      actionLabel: 'Configure Girvi',
    ),
    BillingSetupModule(
      id: BillingSetupModuleId.shopPrintInformation,
      title: 'Shop Print Information',
      subtitle:
          'Choose shop, tax, contact and social details printed on bills.',
      tag: 'Name, GSTIN, BIS, Mobile, Social',
      actionLabel: 'Configure Shop Info',
    ),
  ];
}
