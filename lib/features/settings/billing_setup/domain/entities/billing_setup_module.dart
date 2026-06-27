enum BillingSetupModuleId {
  sales,
  purchase,
  girvi,
  printTemplates,
}

class BillingSetupModule {
  final BillingSetupModuleId id;
  final String title;
  final String subtitle;
  final String statusLabel;
  final String primaryMetric;
  final String secondaryMetric;
  final String actionLabel;
  final List<String> capabilities;

  const BillingSetupModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.primaryMetric,
    required this.secondaryMetric,
    required this.actionLabel,
    required this.capabilities,
  });
}

class BillingSetupModules {
  BillingSetupModules._();

  static const List<BillingSetupModule> all = [
    BillingSetupModule(
      id: BillingSetupModuleId.sales,
      title: 'Sales Billing',
      subtitle:
          'Invoice fields, return rules, buyback terms, and print output.',
      statusLabel: 'Active',
      primaryMetric: '4 metals',
      secondaryMetric: 'Invoice controls',
      actionLabel: 'Open Sales',
      capabilities: [
        'Item field visibility',
        'Return and buyback policy',
        'Customer invoice copy',
      ],
    ),
    BillingSetupModule(
      id: BillingSetupModuleId.purchase,
      title: 'Purchase Billing',
      subtitle:
          'Supplier voucher fields, purity deductions, and return policy.',
      statusLabel: 'Active',
      primaryMetric: '4 metals',
      secondaryMetric: 'Voucher controls',
      actionLabel: 'Open Purchase',
      capabilities: [
        'Supplier voucher layout',
        'Purity deduction rules',
        'Purchase return policy',
      ],
    ),
    BillingSetupModule(
      id: BillingSetupModuleId.girvi,
      title: 'Girvi Billing',
      subtitle: 'Interest rules, pledge receipt fields, notices, and terms.',
      statusLabel: 'Active',
      primaryMetric: 'Loan flow',
      secondaryMetric: 'Receipt controls',
      actionLabel: 'Open Girvi',
      capabilities: [
        'Interest and grace period',
        'Notice and auction terms',
        'Receipt display settings',
      ],
    ),
    BillingSetupModule(
      id: BillingSetupModuleId.printTemplates,
      title: 'Print Templates',
      subtitle: 'Shared invoice, voucher, and receipt print formats.',
      statusLabel: 'Shared',
      primaryMetric: 'Default format',
      secondaryMetric: 'Print engine',
      actionLabel: 'Open Templates',
      capabilities: [
        'Sales invoice format',
        'Purchase voucher format',
        'Girvi receipt format',
      ],
    ),
  ];
}
