import 'day_book_money_flow.dart';

enum DayBookOutflowPurpose {
  operations('Operating Expenses'),
  purchases('Purchase Payments'),
  girvi('Girvi Disbursements'),
  refunds('Customer Refunds'),
  owner('Owner Drawings'),
  taxRemittance('Tax Remittances'),
  financing('Financing Payments'),
  other('Other Payments');

  const DayBookOutflowPurpose(this.label);
  final String label;
}

class DayBookExpenseClassification {
  const DayBookExpenseClassification._();

  static const _operatingCategories = {
    'SHOP_RENT',
    'STAFF_SALARY',
    'ELECTRICITY',
    'MAINTENANCE',
    'ADVERTISING',
    'TRANSPORT',
    'BANK_CHARGES',
    'GOVT_FEES',
    'INSURANCE',
    'MISC_EXPENSE',
    'OTHER_EXPENSE',
  };
  static const _purchaseCategories = {'PURCHASE_PAYMENT', 'SUPPLIER_PAYMENT'};
  static const _girviCategories = {'GIRVI_GIVEN'};
  static const _refundCategories = {
    'REFUND',
    'REFUND_PAID',
    'SALES_REFUND',
    'CUSTOMER_REFUND',
    'CHANGE_RETURNED',
  };
  static const _ownerCategories = {
    'OWNER_DRAWING',
    'OWNER_DRAWINGS',
    'DRAWING',
    'DRAWINGS',
  };
  static const _financingCategories = {'LOAN_REPAYMENT'};
  static const _taxCategories = {'GST_PAYMENT'};

  static DayBookOutflowPurpose purposeOf(DayBookMoneyEntry entry) {
    final category = entry.category.trim().toUpperCase();
    if (_operatingCategories.contains(category)) {
      return DayBookOutflowPurpose.operations;
    }
    if (_purchaseCategories.contains(category)) {
      return DayBookOutflowPurpose.purchases;
    }
    if (_girviCategories.contains(category)) return DayBookOutflowPurpose.girvi;
    if (_refundCategories.contains(category)) {
      return DayBookOutflowPurpose.refunds;
    }
    if (_ownerCategories.contains(category) ||
        category.startsWith('OWNER_DRAWING_')) {
      return DayBookOutflowPurpose.owner;
    }
    if (_taxCategories.contains(category)) {
      return DayBookOutflowPurpose.taxRemittance;
    }
    if (_financingCategories.contains(category)) {
      return DayBookOutflowPurpose.financing;
    }
    return DayBookOutflowPurpose.other;
  }

  static Map<DayBookOutflowPurpose, double> totals(DayBookMoneyFlow flow) {
    final values = <DayBookOutflowPurpose, double>{};
    for (final entry in flow.entries) {
      if (entry.incoming || entry.isInternalTransfer) continue;
      final purpose = purposeOf(entry);
      values[purpose] = (values[purpose] ?? 0) + entry.amount;
    }
    return Map.unmodifiable(values);
  }
}
