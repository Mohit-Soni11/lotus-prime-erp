import 'dart:collection';

class DayBookMoneyEntry {
  const DayBookMoneyEntry({
    required this.date,
    required this.amount,
    required this.incoming,
    required this.isCash,
    required this.category,
    required this.paymentMode,
    required this.transactionId,
    this.accountName,
    this.referenceId,
    this.referenceType,
    this.isInternalTransfer = false,
    this.chequeNumber,
    this.chequeStatus,
    this.valueDate,
    this.isReconciled = false,
  });

  final DateTime date;
  final double amount;
  final bool incoming;
  final bool isCash;
  final String category;
  final String paymentMode;
  final String transactionId;
  final String? accountName;
  final String? referenceId;
  final String? referenceType;
  final bool isInternalTransfer;
  final String? chequeNumber;
  final String? chequeStatus;
  final DateTime? valueDate;
  final bool isReconciled;

  bool get isUnclearedCheque =>
      !isCash &&
      paymentMode.toUpperCase() == 'CHEQUE' &&
      chequeStatus?.toUpperCase() != 'CLEARED' &&
      chequeStatus?.toUpperCase() != 'BOUNCED';
}

/// Posted movements only. Non-cash shadow rows in cash_transactions are ignored.
class DayBookMoneyFlow {
  DayBookMoneyFlow({
    required this.openingCash,
    required this.openingBank,
    required List<DayBookMoneyEntry> entries,
    this.bankAccountCount,
  }) : entries = List.unmodifiable(entries);

  final double openingCash;
  final double openingBank;
  final int? bankAccountCount;
  final List<DayBookMoneyEntry> entries;

  double _sum(bool Function(DayBookMoneyEntry) include) => entries
      .where(include)
      .fold(0, (double total, entry) => total + entry.amount);

  double get cashIn => _sum((entry) => entry.isCash && entry.incoming);
  double get cashOut => _sum((entry) => entry.isCash && !entry.incoming);
  double get bankIn => _sum((entry) => !entry.isCash && entry.incoming);
  double get bankOut => _sum((entry) => !entry.isCash && !entry.incoming);
  double get closingCash => openingCash + cashIn - cashOut;
  double get closingBank => openingBank + bankIn - bankOut;
  double get openingTotal => openingCash + openingBank;
  double get closingTotal => closingCash + closingBank;

  double get moneyIn =>
      _sum((entry) => entry.incoming && !entry.isInternalTransfer);
  double get moneyOut =>
      _sum((entry) => !entry.incoming && !entry.isInternalTransfer);
  double get internalIn =>
      _sum((entry) => entry.incoming && entry.isInternalTransfer);
  double get internalOut =>
      _sum((entry) => !entry.incoming && entry.isInternalTransfer);
  double get unclearedChequeIn =>
      _sum((entry) => entry.incoming && entry.isUnclearedCheque);
  double get unclearedChequeOut =>
      _sum((entry) => !entry.incoming && entry.isUnclearedCheque);

  Map<String, double> bySource({required bool incoming}) =>
      _group(incoming: incoming, keyOf: (entry) => _sourceKey(entry.category));

  Map<String, double> byMode({required bool incoming}) =>
      _group(incoming: incoming, keyOf: (entry) => entry.paymentMode);

  Map<String, double> byBankAccount({required bool incoming}) => _group(
        incoming: incoming,
        keyOf: (entry) => entry.accountName ?? 'Unassigned Account',
        bankOnly: true,
      );

  Map<String, double> byBankReconciliation({required bool incoming}) => _group(
        incoming: incoming,
        keyOf: (entry) {
          if (entry.isUnclearedCheque) return 'Uncleared Cheque';
          if (entry.chequeStatus?.toUpperCase() == 'BOUNCED') {
            return 'Bounced Cheque';
          }
          return entry.isReconciled ? 'Statement Matched' : 'Unreconciled';
        },
        bankOnly: true,
      );

  Map<String, double> _group({
    required bool incoming,
    required String Function(DayBookMoneyEntry) keyOf,
    bool bankOnly = false,
  }) {
    final values = <String, double>{};
    for (final entry in entries) {
      if (entry.incoming != incoming ||
          entry.isInternalTransfer ||
          (bankOnly && entry.isCash)) {
        continue;
      }
      final key = keyOf(entry);
      values[key] = (values[key] ?? 0) + entry.amount;
    }
    return UnmodifiableMapView(values);
  }

  static String _sourceKey(String category) => switch (category) {
        'SALE_PAYMENT' => 'SALE',
        'ADVANCE_RECEIVED' => 'ADVANCE',
        'MISC_CREDIT' => 'MISC_INCOME',
        'MISC_DEBIT' => 'MISC_EXPENSE',
        _ => category,
      };
}
