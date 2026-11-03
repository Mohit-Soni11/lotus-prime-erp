class DayBookCustodyLine {
  const DayBookCustodyLine({
    required this.ticketNo,
    required this.itemName,
    required this.metal,
    required this.purity,
    required this.pieces,
    required this.grossWeight,
    required this.netWeight,
    required this.receivedAt,
    this.fineWeight,
    this.exitedAt,
    this.uncertainFrom,
    this.isLegacy = false,
  });

  final String ticketNo;
  final String itemName;
  final String metal;
  final String purity;
  final int pieces;
  final double grossWeight;
  final double netWeight;
  final double? fineWeight;
  final DateTime receivedAt;
  final DateTime? exitedAt;
  final DateTime? uncertainFrom;
  final bool isLegacy;
}

class DayBookCustodyPosition {
  DayBookCustodyPosition(DateTime date, List<DayBookCustodyLine> lines)
      : date = DateTime(date.year, date.month, date.day),
        lines = List.unmodifiable(lines);

  final DateTime date;
  final List<DayBookCustodyLine> lines;

  DateTime get end => DateTime(date.year, date.month, date.day + 1);

  List<DayBookCustodyLine> get opening =>
      List.unmodifiable(lines.where((line) =>
          line.receivedAt.isBefore(date) &&
          (line.exitedAt == null || !line.exitedAt!.isBefore(date))));
  List<DayBookCustodyLine> get received =>
      List.unmodifiable(lines.where((line) =>
          !line.receivedAt.isBefore(date) && line.receivedAt.isBefore(end)));
  List<DayBookCustodyLine> get released =>
      List.unmodifiable(lines.where((line) =>
          line.exitedAt != null &&
          !line.exitedAt!.isBefore(date) &&
          line.exitedAt!.isBefore(end)));
  List<DayBookCustodyLine> get closing =>
      List.unmodifiable(lines.where((line) =>
          line.receivedAt.isBefore(end) &&
          (line.exitedAt == null || !line.exitedAt!.isBefore(end))));
  bool get closingVerified => closing.every((line) =>
      line.uncertainFrom == null || !line.uncertainFrom!.isBefore(end));
}
