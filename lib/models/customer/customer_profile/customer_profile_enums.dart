enum CustomerGender {
  unknown,
  male,
  female,
  other;

  static CustomerGender fromStored(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'male' => CustomerGender.male,
      'female' => CustomerGender.female,
      'other' => CustomerGender.other,
      _ => CustomerGender.unknown,
    };
  }
}

enum CreditStatus {
  clear,
  due,
  defaulter;

  String get label {
    switch (this) {
      case CreditStatus.clear:
        return "DUE CLEAR";
      case CreditStatus.due:
        return "DUE OPEN";
      case CreditStatus.defaulter:
        return "LIMIT EXCEEDED";
    }
  }

  static CreditStatus calculate({
    required double outstanding,
    required double creditLimit,
  }) {
    if (outstanding <= 0) return CreditStatus.clear;
    if (outstanding <= creditLimit) return CreditStatus.due;
    return CreditStatus.defaulter;
  }
}

enum AdvanceOrderStatus {
  pending,
  ready,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case AdvanceOrderStatus.pending:
        return "PENDING";
      case AdvanceOrderStatus.ready:
        return "READY";
      case AdvanceOrderStatus.delivered:
        return "DELIVERED";
      case AdvanceOrderStatus.cancelled:
        return "CANCELLED";
    }
  }

  static AdvanceOrderStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'READY':
        return AdvanceOrderStatus.ready;
      case 'DELIVERED':
        return AdvanceOrderStatus.delivered;
      case 'CANCELLED':
        return AdvanceOrderStatus.cancelled;
      default:
        return AdvanceOrderStatus.pending;
    }
  }
}
