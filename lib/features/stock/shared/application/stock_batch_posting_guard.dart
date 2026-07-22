import 'package:drift/drift.dart' as drift;
import 'package:lotus_erp/database/db/app_database.dart';

final class StockBatchPostingGuard {
  const StockBatchPostingGuard._();

  static Future<bool> isVoucherPosted({
    required AppDatabase db,
    required String batchCode,
  }) async {
    final code = batchCode.trim();
    if (code.isEmpty) {
      return false;
    }

    try {
      final rows = await db.customSelect(
        '''
        SELECT 1
        FROM purchase_vouchers
        WHERE voucher_no = ?
        LIMIT 1
        ''',
        variables: [drift.Variable.withString(code)],
      ).get();
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
