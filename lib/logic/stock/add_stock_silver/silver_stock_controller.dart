import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

class SilverStockController extends AddStockController {
  SilverStockController()
      : _silverBatchCode = _generateSilverBatchCode(),
        super(initialMetal: StockCategory.silver);

  String _silverBatchCode;

  @override
  String get batchCode => _silverBatchCode;

  @override
  void resetForNewBatch() {
    _silverBatchCode = _generateSilverBatchCode();
    super.resetForNewBatch();
  }

  static String _generateSilverBatchCode() {
    final now = DateTime.now();
    final datePart =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timePart =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'SIL-$datePart-$timePart';
  }
}
