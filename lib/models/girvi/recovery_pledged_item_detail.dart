import 'girvi_loan_model.dart';

class RecoveryPledgedItemDetail {
  const RecoveryPledgedItemDetail({
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.pieces,
    required this.netWeight,
  });

  final String itemName;
  final String metalType;
  final String purity;
  final int pieces;
  final double netWeight;

  factory RecoveryPledgedItemDetail.fromLoan(GirviLoanModel loan) {
    final name = loan.itemDescription
        .split('|')
        .first
        .replaceFirst(RegExp(r'^#?\d+\s*'), '')
        .trim();
    return RecoveryPledgedItemDetail(
      itemName: name.isEmpty ? 'Pledged item' : name,
      metalType: loan.metalType,
      purity: loan.metalPurity,
      pieces: loan.itemCount > 0 ? loan.itemCount : 1,
      netWeight: loan.netWeight,
    );
  }
}
