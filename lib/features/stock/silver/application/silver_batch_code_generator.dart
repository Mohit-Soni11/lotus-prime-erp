import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

final class SilverBatchCodeGenerator {
  final AppDatabase _database;

  const SilverBatchCodeGenerator(this._database);

  static String previewCode(DateTime date) {
    return '${_datePrefix(date)}-0001';
  }

  Future<String> nextCodeFor(DateTime date) async {
    final prefix = _datePrefix(date);
    try {
      final rows = await _database.customSelect(
        '''
        SELECT voucher_no
        FROM purchase_vouchers
        WHERE voucher_no LIKE ?
        ORDER BY voucher_no DESC
        LIMIT 1
        ''',
        variables: [Variable.withString('$prefix-%')],
      ).get();

      final lastCode =
          rows.isEmpty ? '' : rows.first.read<String>('voucher_no');
      final lastSequence = _sequenceFromCode(lastCode);
      return '$prefix-${(lastSequence + 1).toString().padLeft(4, '0')}';
    } catch (_) {
      return '$prefix-0001';
    }
  }

  Future<String> nextAvailableCodeFor(
    DateTime date,
    String preferredCode,
  ) async {
    if (preferredCode.trim().isEmpty) {
      return nextCodeFor(date);
    }

    try {
      final rows = await _database.customSelect(
        '''
        SELECT 1
        FROM purchase_vouchers
        WHERE voucher_no = ?
        LIMIT 1
        ''',
        variables: [Variable.withString(preferredCode)],
      ).get();

      if (rows.isEmpty) {
        return preferredCode;
      }
    } catch (_) {
      return preferredCode;
    }

    return nextCodeFor(date);
  }

  static String _datePrefix(DateTime date) {
    return 'SS-${date.day.toString().padLeft(2, '0')}'
        '${_monthCode(date.month)}'
        '${date.year.toString().padLeft(4, '0')}';
  }

  static String _monthCode(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    if (month < 1 || month > 12) {
      return 'JAN';
    }
    return months[month - 1];
  }

  static int _sequenceFromCode(String code) {
    final match = RegExp(r'-(\d{4})$').firstMatch(code.trim());
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
