import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';

class PosInvoiceReadinessInput {
  const PosInvoiceReadinessInput({
    required this.saleItems,
    required this.oldGoldItems,
    required this.billingMode,
    required this.finalPayableAmount,
    required this.hasChangeReturn,
    required this.hasConfirmedChangeReturn,
    required this.changeReturnMethod,
    required this.balanceDue,
    required this.hasSelectedCustomer,
    required this.hasPromiseDate,
    required this.advanceInput,
    this.amountTolerance = 0.005,
    this.weightTolerance = 0.0001,
  });

  final List<SaleItemModel> saleItems;
  final List<OldGoldItemModel> oldGoldItems;
  final BillingMode billingMode;
  final double finalPayableAmount;
  final bool hasChangeReturn;
  final bool hasConfirmedChangeReturn;
  final RefundMethod? changeReturnMethod;
  final double balanceDue;
  final bool hasSelectedCustomer;
  final bool hasPromiseDate;
  final double advanceInput;
  final double amountTolerance;
  final double weightTolerance;
}

class PosInvoiceReadinessValidator {
  const PosInvoiceReadinessValidator();

  String? validate(PosInvoiceReadinessInput input) {
    if (input.saleItems.isEmpty && input.oldGoldItems.isEmpty) {
      return 'The cart is empty. Please add at least one item before generating an invoice.';
    }

    final duplicateItemError = _validateUniqueSaleItemReferences(
      input.saleItems,
    );
    if (duplicateItemError != null) {
      return duplicateItemError;
    }

    for (int index = 0; index < input.saleItems.length; index++) {
      final item = input.saleItems[index];
      final rowNumber = index + 1;
      if (item.netWt <= input.weightTolerance) {
        return 'Enter gross weight for item row $rowNumber before generating an invoice.';
      }
      if (input.billingMode == BillingMode.retail && item.rate <= 0) {
        return 'Enter a valid rate for item row $rowNumber before generating an invoice.';
      }
      if (input.billingMode == BillingMode.retail &&
          item.totalValue <= input.amountTolerance) {
        return 'Complete item row $rowNumber before generating an invoice.';
      }
    }

    for (int index = 0; index < input.oldGoldItems.length; index++) {
      final item = input.oldGoldItems[index];
      final rowNumber = index + 1;
      if (item.netWt <= input.weightTolerance) {
        return 'Enter gross weight for exchange row $rowNumber before generating an invoice.';
      }
      if (item.rate <= 0) {
        return 'Enter a valid rate for exchange row $rowNumber before generating an invoice.';
      }
      if (item.totalValue <= input.amountTolerance) {
        return 'Complete exchange row $rowNumber before generating an invoice.';
      }
    }

    if (!_hasBillableItem(input)) {
      return 'Complete at least one billable item before generating an invoice.';
    }

    if (input.finalPayableAmount < -input.amountTolerance) {
      return 'This bill creates a refund or exchange balance. Please use the separate refund or exchange flow.';
    }

    if (input.hasChangeReturn) {
      if (input.changeReturnMethod == null) {
        return 'Settle the excess amount before generating the invoice.';
      }
      if (!input.hasConfirmedChangeReturn) {
        return 'Select or create a customer before adding excess amount to customer account.';
      }
    }

    if (input.balanceDue > input.amountTolerance) {
      if (!input.hasSelectedCustomer) {
        return 'Select or create a customer before saving a due bill.';
      }
      if (!input.hasPromiseDate) {
        return 'Select a promise date before saving a due bill.';
      }
    }

    if (input.advanceInput > input.amountTolerance &&
        !input.hasSelectedCustomer) {
      return 'Select or create a customer before using advance payment.';
    }

    return null;
  }

  bool _hasBillableItem(PosInvoiceReadinessInput input) {
    return input.saleItems.any(
          (item) =>
              item.netWt > input.weightTolerance &&
              (input.billingMode == BillingMode.wholesale || item.rate > 0) &&
              (input.billingMode == BillingMode.wholesale ||
                  item.totalValue > input.amountTolerance),
        ) ||
        input.oldGoldItems.any(
          (item) =>
              item.netWt > input.weightTolerance &&
              item.rate > 0 &&
              item.totalValue > input.amountTolerance,
        );
  }

  String? _validateUniqueSaleItemReferences(List<SaleItemModel> saleItems) {
    final huidRows = <String, int>{};
    final stockRows = <int, int>{};

    for (int index = 0; index < saleItems.length; index++) {
      final rowNumber = index + 1;
      final huid = saleItems[index].huidCtrl.text.trim().toUpperCase();
      if (huid.isNotEmpty) {
        final firstRow = huidRows[huid];
        if (firstRow != null) {
          return 'HUID $huid is already used in item row $firstRow. Remove the duplicate from row $rowNumber.';
        }
        huidRows[huid] = rowNumber;
      }

      final stockItemId = saleItems[index].linkedStockItemId;
      if (stockItemId != null) {
        final firstRow = stockRows[stockItemId];
        if (firstRow != null) {
          return 'The same stock item is selected in row $firstRow and row $rowNumber. Select a different item before generating the invoice.';
        }
        stockRows[stockItemId] = rowNumber;
      }
    }

    return null;
  }
}
