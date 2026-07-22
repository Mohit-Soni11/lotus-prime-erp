import 'package:lotus_erp/features/stock/shared/application/add_stock_models.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_purity_utils.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

final class AddStockRowValidator {
  const AddStockRowValidator._();

  static String? validate({
    required StockRowEntry row,
    required StockCategory selectedMetal,
    required double selectedPurityBasePercent,
    required String purityDisplay,
  }) {
    if (!row.hasAnyInput) {
      return null;
    }

    if (row.itemName.trim().isEmpty) {
      return AddStockStrings.errItemName;
    }
    if (row.itemName.trim().length < 2) {
      return AddStockStrings.errItemNameShort;
    }
    if (row.quantity < 1) {
      return AddStockStrings.errQtyMin;
    }
    if (row.grossWeight <= 0) {
      return AddStockStrings.errWeightInvalid;
    }
    if (row.grossWeight < 0 || row.stoneWeight < 0) {
      return AddStockStrings.errWeightNeg;
    }
    if (row.stoneWeight > row.grossWeight) {
      return AddStockStrings.errStoneWeightExceeds;
    }

    if (selectedMetal == StockCategory.gold) {
      final touch = row.resolveTouch(selectedPurityBasePercent);
      if (touch <= 0 || touch > 100) {
        return 'Touch must be between 0 and 100';
      }
      if (row.makingCharges < 0) {
        return AddStockStrings.errPriceNeg;
      }
    } else if (row.purchaseRate < 0 ||
        row.makingCharges < 0 ||
        row.stoneValue < 0 ||
        row.mrp < 0) {
      return AddStockStrings.errPriceNeg;
    }

    if (selectedMetal == StockCategory.silver &&
        row.subCategoryLabel.trim().isEmpty) {
      return 'Category is required';
    }
    if (selectedMetal == StockCategory.silver) {
      final purityLabel = row.purityLabel.trim().isNotEmpty
          ? row.purityLabel.trim()
          : purityDisplay.trim();
      if (purityLabel.isEmpty) {
        return 'Base purity is required';
      }

      final touch =
          row.touchPercent > 0 ? row.touchPercent : selectedPurityBasePercent;
      if (touch <= 0 || touch > 100) {
        return 'Total purity must be between 0 and 100';
      }

      if (row.purchaseRate <= 0) {
        return 'Silver daily rate is missing. Update silver jewellery rate before saving.';
      }
    }

    if (row.gstRate < 0 || row.gstRate > 100) {
      return AddStockStrings.errGstRange;
    }

    final rowHuids = row.huids.isNotEmpty
        ? row.huids
        : [
            if (row.huid.trim().isNotEmpty) row.huid.trim(),
          ];
    final invalidHuid = rowHuids
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .any((value) => value.length != 6);
    if (invalidHuid) {
      return AddStockStrings.errHuidLength;
    }
    if (selectedMetal != StockCategory.gold &&
        row.huid.trim().isNotEmpty &&
        row.quantity != 1) {
      return 'HUID item must have quantity 1';
    }
    return null;
  }

  static bool purityMatchesTouch({
    required String purityLabel,
    required double touch,
  }) {
    final basePercent = AddStockPurityUtils.resolvePurityPercent(purityLabel);
    return basePercent <= 0 || AddStockPurityUtils.near(basePercent, touch);
  }
}
