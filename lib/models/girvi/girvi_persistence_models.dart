class GirviLoanItemInput {
  const GirviLoanItemInput({
    required this.serialNo,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.purityFactor,
    required this.pieces,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    this.huidNumber,
    this.notes,
    this.photoPaths = const [],
  });

  final int serialNo;
  final String itemName;
  final String metalType;
  final String purity;
  final double purityFactor;
  final int pieces;
  final String? huidNumber;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final String? notes;
  final List<String> photoPaths;
}

class GirviDisbursementInput {
  const GirviDisbursementInput({
    required this.sequenceNo,
    required this.mode,
    required this.displayLabel,
    required this.amount,
    this.bankAccountId,
    this.accountName,
    this.referenceNo,
    this.details,
  });

  final int sequenceNo;
  final String mode;
  final String displayLabel;
  final double amount;
  final int? bankAccountId;
  final String? accountName;
  final String? referenceNo;
  final String? details;
}
