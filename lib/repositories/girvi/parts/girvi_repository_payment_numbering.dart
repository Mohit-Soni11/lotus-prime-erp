part of '../girvi_repository.dart';

extension GirviRepositoryPaymentNumbering on GirviRepository {
  Future<String> generateNextPaymentReceiptNo({
    String prefix = 'GIP-',
    int startingNumber = 1,
  }) async {
    final rows = await (_db.select(_db.girviPayments)
          ..where((payment) => payment.receiptNo.like('$prefix%')))
        .get();

    var highest = startingNumber - 1;
    final trailingNumber = RegExp(r'(\d+)$');
    for (final row in rows) {
      final match = trailingNumber.firstMatch(row.receiptNo ?? '');
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > highest) highest = value;
    }

    final next = highest + 1;
    return '$prefix${next.toString().padLeft(5, '0')}';
  }

  // CREATE LOAN
}
